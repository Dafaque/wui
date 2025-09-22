import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:whisperui/services/settings.dart';
import 'package:whisperui/services/exec.dart';
import 'package:whisperui/singletons/logger.dart';
import 'package:whisperui/views/settings.dart';
import 'package:whisperui/models/processing_file.dart';
import 'package:whisperui/widgets/file_card.dart';
import 'package:whisperui/widgets/language_display.dart';
import 'package:whisperui/widgets/format_display.dart';
import 'package:whisperui/utils/whisper_args_builder.dart';
import 'package:open_dir/open_dir.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<ProcessingFile> _processingQueue = [];
  final Exec _exec = Exec();
  final OpenDir _openDir = OpenDir();
  final List<String> _logs = [];
  bool _isLogExpanded = false;
  final ScrollController _logScrollController = ScrollController();
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  bool _isProcessing = false;
  String? _currentLogFilePath;

  @override
  void initState() {
    super.initState();
    _setupLogStreams();
    _loadSettings();
  }

  void _loadSettings() {
    // Загружаем настройки при инициализации
    setState(() {});
  }

  void _setupLogStreams() {
    // Отменяем предыдущие подписки если они есть
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();

    // Создаем новые подписки
    _stdoutSubscription = _exec.stdout.listen((line) {
      setState(() {
        _logs.add(line);
      });
      _writeLogToFile(line);
      _scrollToBottom();
    });

    _stderrSubscription = _exec.stderr.listen((line) {
      setState(() {
        _logs.add(line);
      });
      _writeLogToFile('[STDERR] $line');
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _createLogFile(ProcessingFile file) {
    final outputDir = path.dirname(file.outputPath);
    final logFileName = '${file.fileName}.log';
    _currentLogFilePath = path.join(outputDir, logFileName);
  }

  void _writeLogToFile(String line) {
    if (_currentLogFilePath != null) {
      try {
        final file = File(_currentLogFilePath!);
        final timestamp = DateTime.now().toIso8601String();
        file.writeAsStringSync('[$timestamp] $line\n', mode: FileMode.append);
      } catch (e) {
        logger.e('Error writing to log file', error: e);
      }
    }
  }

  void _clearCurrentLogs() {
    setState(() {
      _logs.clear();
      _currentLogFilePath = null;
    });
  }

  Future<void> _pickFilesOrFolder() async {
    // Показываем диалог выбора типа
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Input'),
        content: const Text('Choose what you want to process:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'files'),
            child: const Text('Audio Files'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'folder'),
            child: const Text('Folder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == 'files') {
      await _pickAudioFiles();
    } else if (choice == 'folder') {
      await _pickFolder();
    }
  }

  Future<void> _pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'ogg', 'flac', 'aac'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _addFilesToQueue(result.files.map((file) => file.path!).toList());
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      _scanFolderForAudioFiles(result);
    }
  }

  void _scanFolderForAudioFiles(String folderPath) {
    final directory = Directory(folderPath);
    final audioExtensions = ['wav', 'mp3', 'm4a', 'ogg', 'flac', 'aac'];

    directory
        .listSync()
        .where((file) {
          if (file is File) {
            final extension = path
                .extension(file.path)
                .toLowerCase()
                .substring(1);
            return audioExtensions.contains(extension);
          }
          return false;
        })
        .forEach((file) {
          _addFilesToQueue([file.path]);
        });
  }

  void _addFilesToQueue(List<String> filePaths) {
    setState(() {
      for (final filePath in filePaths) {
        final fileName = path.basenameWithoutExtension(filePath);
        final processingFile = ProcessingFile(
          id: '${DateTime.now().millisecondsSinceEpoch}_${filePath.hashCode}',
          filePath: filePath,
          fileName: fileName,
          addedAt: DateTime.now(),
        );
        _processingQueue.add(processingFile);
      }
    });
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcription completed successfully!')),
    );
  }

  void _showStoppedMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transcription stopped')));
  }

  Future<void> _startProcessing() async {
    if (_processingQueue.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Очищаем логи при старте нового процесса
    _clearCurrentLogs();
    _setupLogStreams();

    for (int i = 0; i < _processingQueue.length; i++) {
      final file = _processingQueue[i];

      // Пропускаем уже обработанные файлы
      if (file.isCompleted || file.isProcessing) continue;

      // Создаем лог-файл для текущего файла
      _createLogFile(file);

      // Обновляем статус на "обрабатывается"
      _updateFileStatus(
        file.id,
        ProcessingStatus.processing,
        startedAt: DateTime.now(),
      );

      try {
        final settings = SettingsService.instance().settings;
        final args = WhisperArgsBuilder.buildWhisperArgs(file);

        final exitCode = await _exec.run(
          settings.whisperEngine,
          args,
          workingDirectory: path.dirname(file.filePath),
        );

        if (exitCode == 0) {
          _updateFileStatus(
            file.id,
            ProcessingStatus.completed,
            completedAt: DateTime.now(),
          );
        } else {
          _updateFileStatus(
            file.id,
            ProcessingStatus.error,
            errorMessage: 'Process exited with code: $exitCode',
          );
        }
      } catch (e) {
        _updateFileStatus(
          file.id,
          ProcessingStatus.error,
          errorMessage: 'Error: $e',
        );
      }
    }

    setState(() {
      _isProcessing = false;
    });

    _showSuccessMessage();
  }

  void _updateFileStatus(
    String fileId,
    ProcessingStatus status, {
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    setState(() {
      final index = _processingQueue.indexWhere((file) => file.id == fileId);
      if (index != -1) {
        _processingQueue[index] = _processingQueue[index].copyWith(
          status: status,
          startedAt: startedAt,
          completedAt: completedAt,
          errorMessage: errorMessage,
        );
      }
    });
  }

  void _stopProcessing() {
    _exec.stop();
    setState(() {
      _isProcessing = false;
    });
    _showStoppedMessage();
  }

  void _removeFileFromQueue(String fileId) {
    setState(() {
      _processingQueue.removeWhere((file) => file.id == fileId);
    });
  }

  void _clearCompletedFiles() {
    setState(() {
      _processingQueue.removeWhere((file) => file.isCompleted);
    });
  }

  void _setCustomOutputPath(String fileId, String? customPath) {
    setState(() {
      final index = _processingQueue.indexWhere((file) => file.id == fileId);
      if (index != -1) {
        _processingQueue[index] = _processingQueue[index].copyWith(
          customOutputPath: customPath,
        );
      }
    });
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _exec.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Transcribe'),
            const SizedBox(width: 8),
            const LanguageDisplay(),
            const SizedBox(width: 8),
            const FormatDisplay(compact: true),
          ],
        ),
        actions: [
          if (_processingQueue.isNotEmpty)
            IconButton(
              onPressed: _clearCompletedFiles,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear completed files',
            ),
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок и кнопка добавления файлов
            Row(
              children: [
                const Text(
                  'Processing Queue',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickFilesOrFolder,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Files'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопки управления обработкой
            if (_processingQueue.isNotEmpty) ...[
              Row(
                children: [
                  if (_isProcessing) ...[
                    ElevatedButton(
                      onPressed: _stopProcessing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop, size: 20),
                          SizedBox(width: 8),
                          Text('STOP'),
                        ],
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _startProcessing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 8),
                          Text('START PROCESSING'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Text(
                    '${_processingQueue.where((f) => f.isCompleted).length}/${_processingQueue.length} completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Список файлов в очереди
            Expanded(
              child: _processingQueue.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No files in queue',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add audio files or select a folder to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _processingQueue.length,
                      itemBuilder: (context, index) {
                        final file = _processingQueue[index];
                        return FileCard(
                          file: file,
                          onOpenDirectory: () => _openOutputDirectory(file),
                          onEditPath: () => _showOutputPathDialog(file),
                          onOpenLog: () => _openLogFile(file),
                          onRemove: () => _removeFileFromQueue(file.id),
                        );
                      },
                    ),
            ),

            // Лог-окно
            _buildLogWindow(),
          ],
        ),
      ),
    );
  }

  void _openOutputDirectory(ProcessingFile file) {
    final outputDir = path.dirname(file.outputPath);
    final originalFileName = path.basename(file.filePath);
    _openDir.openNativeDir(
      path: outputDir,
      highlightedFileName: originalFileName,
    );
  }

  void _openLogFile(ProcessingFile file) {
    final outputDir = path.dirname(file.outputPath);
    final logFileName = '${file.fileName}.log';

    _openDir.openNativeDir(path: outputDir, highlightedFileName: logFileName);
  }

  void _showOutputPathDialog(ProcessingFile file) async {
    // Показываем диалог выбора типа пути
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set output path for ${file.fileName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to set the output path:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Select directory'),
              subtitle: const Text(
                'Choose output directory, filename will be auto-generated',
              ),
              onTap: () => Navigator.of(context).pop('directory'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Enter custom path'),
              subtitle: const Text('Type the full output path manually'),
              onTap: () => Navigator.of(context).pop('manual'),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset to default'),
              subtitle: const Text('Use default path based on input file'),
              onTap: () => Navigator.of(context).pop('reset'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'reset') {
      _setCustomOutputPath(file.id, null);
      return;
    }

    if (choice == 'manual') {
      _showManualPathDialog(file);
      return;
    }

    if (choice == 'directory') {
      _showDirectoryPicker(file);
      return;
    }
  }

  void _showManualPathDialog(ProcessingFile file) {
    final controller = TextEditingController(text: file.customOutputPath ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter custom output path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Output path',
                hintText: 'Enter full path including filename',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Default: ${file.outputPath}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customPath = controller.text.trim();
              _setCustomOutputPath(
                file.id,
                customPath.isEmpty ? null : customPath,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showDirectoryPicker(ProcessingFile file) async {
    try {
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory != null) {
        // Генерируем имя файла на основе исходного файла
        final fileName = path.basenameWithoutExtension(file.filePath);
        final customPath = path.join(selectedDirectory, fileName);

        _setCustomOutputPath(file.id, customPath);

        _showSnackBar('Output path set to: $customPath');
      }
    } catch (e) {
      logger.e('Error picking directory', error: e);
      _showSnackBar('Error selecting directory: $e', isError: true);
    }
  }

  Widget _buildLogWindow() {
    return Card(
      child: Column(
        children: [
          // Заголовок с кнопкой сворачивания
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Process Logs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_currentLogFilePath != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Saving to: ${path.basename(_currentLogFilePath!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isLogExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _isLogExpanded = !_isLogExpanded;
                });
              },
            ),
          ),

          // Содержимое логов (показывается только если развернуто)
          if (_isLogExpanded) ...[
            const Divider(height: 1),
            Container(
              height: 200, // Фиксированная высота
              padding: const EdgeInsets.all(8.0),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Start transcription to see output.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.contains('[STDERR]');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: isError ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsView()),
    );
    // Обновляем UI после возврата из настроек
    _loadSettings();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
