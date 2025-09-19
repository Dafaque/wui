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

  List<String> _buildWhisperArgs(ProcessingFile processingFile) {
    final settings = SettingsService.instance().settings;
    final args = <String>[];

    // File paths
    if (settings.whisperModel.isNotEmpty) {
      args.addAll(['-m', settings.whisperModel]);
    }
    if (settings.suppressRegex.isNotEmpty) {
      args.addAll(['--suppress-regex', settings.suppressRegex]);
    }
    if (settings.grammar.isNotEmpty) {
      args.addAll(['--grammar', settings.grammar]);
    }
    if (settings.grammarRule.isNotEmpty) {
      args.addAll(['--grammar-rule', settings.grammarRule]);
    }
    if (settings.prompt.isNotEmpty) {
      args.addAll(['--prompt', settings.prompt]);
    }
    if (settings.dtwModel.isNotEmpty) {
      args.addAll(['-dtw', settings.dtwModel]);
    }
    if (settings.ovEDevice.isNotEmpty) {
      args.addAll(['-oved', settings.ovEDevice]);
    }

    // Numeric parameters
    args.addAll(['-t', settings.threads.toString()]);
    args.addAll(['-p', settings.processors.toString()]);
    if (settings.offsetT != 0) {
      args.addAll(['-ot', settings.offsetT.toString()]);
    }
    if (settings.offsetN != 0) {
      args.addAll(['-on', settings.offsetN.toString()]);
    }
    if (settings.duration != 0) {
      args.addAll(['-d', settings.duration.toString()]);
    }
    if (settings.maxContext != -1) {
      args.addAll(['-mc', settings.maxContext.toString()]);
    }
    if (settings.maxLen != 0) {
      args.addAll(['-ml', settings.maxLen.toString()]);
    }
    args.addAll(['-bo', settings.bestOf.toString()]);
    args.addAll(['-bs', settings.beamSize.toString()]);
    if (settings.audioCtx != 0) {
      args.addAll(['-ac', settings.audioCtx.toString()]);
    }
    args.addAll(['-wt', settings.wordThold.toString()]);
    args.addAll(['-et', settings.entropyThold.toString()]);
    args.addAll(['-lpt', settings.logprobThold.toString()]);
    args.addAll(['-nth', settings.noSpeechThold.toString()]);
    args.addAll(['-tp', settings.temperature.toString()]);
    args.addAll(['-tpi', settings.temperatureInc.toString()]);
    args.addAll(['--grammar-penalty', settings.grammarPenalty.toString()]);

    // Boolean parameters (only add if true)
    if (settings.splitOnWord) args.add('-sow');
    if (settings.debugMode) args.add('-debug');
    if (settings.translate) args.add('-tr');
    if (settings.diarize) args.add('-di');
    if (settings.tinydiarize) args.add('-tdrz');
    if (settings.noFallback) args.add('-nf');
    if (settings.outputTxt) args.add('-otxt');
    if (settings.outputVtt) args.add('-ovtt');
    if (settings.outputSrt) args.add('-osrt');
    if (settings.outputLrc) args.add('-olrc');
    if (settings.outputWords) args.add('-owts');
    if (settings.outputCsv) args.add('-ocsv');
    if (settings.outputJson) args.add('-oj');
    if (settings.outputJsonFull) args.add('-ojf');
    if (settings.noPrints) args.add('-np');
    if (settings.printSpecial) args.add('-ps');
    if (settings.printColors) args.add('-pc');
    if (settings.printConfidence) args.add('--print-confidence');
    if (settings.printProgress) args.add('-pp');
    if (settings.noTimestamps) args.add('-nt');
    if (settings.detectLanguage) args.add('-dl');
    if (settings.logScore) args.add('-ls');
    if (settings.noGpu) args.add('-ng');
    if (settings.flashAttn) args.add('-fa');
    if (settings.suppressNst) args.add('-sns');

    // String parameters
    if (settings.language.isNotEmpty) {
      args.addAll(['-l', settings.language]);
    }

    // Input and output files
    args.addAll(['--file', processingFile.filePath]);
    args.addAll(['--output-file', processingFile.outputPath]);

    return args;
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
        final args = _buildWhisperArgs(file);

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
            // Язык
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageEmoji(
                      SettingsService.instance().settings.language,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLanguageName(
                      SettingsService.instance().settings.language,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Форматы
            if (_getEnabledOutputFormats().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Output formats',
                      child: Icon(
                        Icons.file_download,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ..._getEnabledOutputFormats()
                        .take(3)
                        .map(
                          (format) => Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Tooltip(
                              message:
                                  '${format['name']} (.${format['extension']})',
                              child: Icon(
                                format['icon'] as IconData,
                                size: 16,
                                color: format['color'] as Color,
                              ),
                            ),
                          ),
                        ),
                    if (_getEnabledOutputFormats().length > 3) ...[
                      const SizedBox(width: 2),
                      Text(
                        '+${_getEnabledOutputFormats().length - 3}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
                        return _buildFileCard(file);
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

  Widget _buildFileCard(ProcessingFile file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с именем файла и статусом
            Row(
              children: [
                Icon(
                  _getStatusIcon(file.status),
                  color: _getStatusColor(file.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _getStatusText(file.status),
                  style: TextStyle(
                    color: _getStatusColor(file.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeFileFromQueue(file.id),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Remove from queue',
                ),
              ],
            ),

            // Путь к файлу
            const SizedBox(height: 4),
            Text(
              file.filePath,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),

            // Путь сохранения
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Output: '),
                Expanded(
                  child: Text(
                    file.outputPath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _openOutputDirectory(file),
                  icon: const Icon(Icons.folder_open, size: 16),
                  tooltip: 'Open output directory',
                ),
                IconButton(
                  onPressed: () => _showOutputPathDialog(file),
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'Edit output path',
                ),
              ],
            ),

            // Форматы файлов
            if (_getEnabledOutputFormats().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Formats: '),
                  const SizedBox(width: 4),
                  ..._getEnabledOutputFormats().map(
                    (format) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: '${format['name']} format',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (format['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (format['color'] as Color).withOpacity(
                                0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                format['icon'] as IconData,
                                size: 14,
                                color: format['color'] as Color,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                format['extension'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: format['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Лог-файл
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Log: '),
                Expanded(
                  child: Text(
                    '${file.fileName}.log',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (file.isCompleted || file.hasError) ...[
                  IconButton(
                    onPressed: () => _openLogFile(file),
                    icon: const Icon(Icons.description, size: 16),
                    tooltip: 'Open log file',
                  ),
                ],
              ],
            ),

            // Время обработки
            if (file.startedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Started: ${_formatDateTime(file.startedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (file.completedAt != null) ...[
              Text(
                'Completed: ${_formatDateTime(file.completedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            // Сообщение об ошибке
            if (file.hasError && file.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.queued:
        return Icons.queue;
      case ProcessingStatus.processing:
        return Icons.play_circle;
      case ProcessingStatus.completed:
        return Icons.check_circle;
      case ProcessingStatus.error:
        return Icons.error;
      case ProcessingStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.queued:
        return Colors.blue;
      case ProcessingStatus.processing:
        return Colors.orange;
      case ProcessingStatus.completed:
        return Colors.green;
      case ProcessingStatus.error:
        return Colors.red;
      case ProcessingStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.queued:
        return 'Queued';
      case ProcessingStatus.processing:
        return 'Processing';
      case ProcessingStatus.completed:
        return 'Completed';
      case ProcessingStatus.error:
        return 'Error';
      case ProcessingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
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

  String _getLanguageEmoji(String languageCode) {
    const languageEmojis = {
      'auto': '🌐',
      'en': '🇺🇸',
      'ru': '🇷🇺',
      'ja': '🇯🇵',
      'zh': '🇨🇳',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ko': '🇰🇷',
    };
    return languageEmojis[languageCode] ?? '🌐';
  }

  String _getLanguageName(String languageCode) {
    const languageNames = {
      'auto': 'Auto-detect',
      'en': 'English',
      'ru': 'Русский',
      'ja': '日本語 (Japanese)',
      'zh': '中文 (Chinese)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'de': 'Deutsch (German)',
      'it': 'Italiano (Italian)',
      'pt': 'Português (Portuguese)',
      'ko': '한국어 (Korean)',
    };
    return languageNames[languageCode] ?? 'Unknown';
  }

  List<Map<String, dynamic>> _getEnabledOutputFormats() {
    final settings = SettingsService.instance().settings;
    final formats = <Map<String, dynamic>>[];

    if (settings.outputTxt) {
      formats.add({
        'extension': 'txt',
        'name': 'Text',
        'icon': Icons.description,
        'color': Colors.blue,
      });
    }
    if (settings.outputVtt) {
      formats.add({
        'extension': 'vtt',
        'name': 'VTT',
        'icon': Icons.subtitles,
        'color': Colors.orange,
      });
    }
    if (settings.outputSrt) {
      formats.add({
        'extension': 'srt',
        'name': 'SRT',
        'icon': Icons.subtitles,
        'color': Colors.green,
      });
    }
    if (settings.outputLrc) {
      formats.add({
        'extension': 'lrc',
        'name': 'LRC',
        'icon': Icons.music_note,
        'color': Colors.purple,
      });
    }
    if (settings.outputWords) {
      formats.add({
        'extension': 'words',
        'name': 'Words',
        'icon': Icons.auto_fix_high,
        'color': Colors.teal,
      });
    }
    if (settings.outputCsv) {
      formats.add({
        'extension': 'csv',
        'name': 'CSV',
        'icon': Icons.table_chart,
        'color': Colors.indigo,
      });
    }
    if (settings.outputJson) {
      formats.add({
        'extension': 'json',
        'name': 'JSON',
        'icon': Icons.code,
        'color': Colors.brown,
      });
    }
    if (settings.outputJsonFull) {
      formats.add({
        'extension': 'json',
        'name': 'JSON Full',
        'icon': Icons.code_off,
        'color': Colors.deepOrange,
      });
    }

    return formats;
  }
}
