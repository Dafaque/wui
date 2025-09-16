import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:whisperui/services/settings.dart';
import 'package:whisperui/services/exec.dart';
import 'package:whisperui/views/settings.dart';
import 'package:open_dir/open_dir.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? selectedAudioFIle;
  String? outputPath;
  final Exec _exec = Exec();
  final OpenDir _openDir = OpenDir();
  final List<String> _logs = [];
  bool _isLogExpanded = false;
  final ScrollController _logScrollController = ScrollController();
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  @override
  void initState() {
    super.initState();
    _updateOutputPath();
    _setupLogStreams();
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
      _scrollToBottom();
    });

    _stderrSubscription = _exec.stderr.listen((line) {
      setState(() {
        _logs.add(line);
      });
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

  void _updateOutputPath() {
    if (selectedAudioFIle != null) {
      final fileName = path.basenameWithoutExtension(selectedAudioFIle!);
      final settings = SettingsService.instance();
      outputPath = '${settings.appHomeDir.path}/$fileName';
    } else {
      outputPath = null;
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'ogg', 'flac', 'aac'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedAudioFIle = result.files.first.path;
        _updateOutputPath();
      });
    }
  }

  List<String> _buildWhisperArgs() {
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
    args.addAll(['--file', selectedAudioFIle!]);

    var filename = path.basename(outputPath!);
    SettingsService.instance().createOutputPath(filename);

    args.addAll(['--output-file', '$outputPath/$filename']);

    return args;
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcription completed successfully!')),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showStoppedMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transcription stopped')));
  }

  Future<void> _startTranscription() async {
    if (selectedAudioFIle == null) return;

    setState(() {
      _logs.clear(); // Очищаем логи при старте
    });

    // Пересоздаем подписки на стримы
    _setupLogStreams();

    try {
      final settings = SettingsService.instance().settings;
      final args = _buildWhisperArgs();

      final exitCode = await _exec.run(
        settings.whisperEngine,
        args,
        workingDirectory: outputPath != null ? path.dirname(outputPath!) : null,
      );

      // Обновляем UI после завершения процесса
      setState(() {});

      if (exitCode == 0) {
        _showSuccessMessage();
      } else {
        _showErrorMessage('Process exited with code: $exitCode');
      }
    } catch (e) {
      // Обновляем UI даже при ошибке
      setState(() {});
      _showErrorMessage('Error: $e');
    }
  }

  void _stopTranscription() {
    _exec.stop();
    setState(() {}); // Обновляем UI после остановки
    _showStoppedMessage();
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
        title: Text('Transcribe'),
        actions: [
          IconButton(
            onPressed: _navigateToSettings,
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            const Text(
              'Select Audio File',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Кнопка выбора файла
            ElevatedButton.icon(
              onPressed: _pickAudioFile,
              icon: const Icon(Icons.audio_file),
              label: const Text('Choose .wav file'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Показываем выбранный файл
            if (selectedAudioFIle != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected File:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        path.basename(selectedAudioFIle!),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedAudioFIle!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Превью пути сохранения
            if (outputPath != null) ...[
              const Text(
                'Output will be saved to:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => _openDir.openNativeDir(path: outputPath!),
                child: const Text(
                  'Open Directory (available after transcription starts)',
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    outputPath!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Кнопки Start/Stop
            if (_exec.isRunning) ...[
              ElevatedButton(
                onPressed: _stopTranscription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'STOP TRANSCRIPTION',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: selectedAudioFIle != null
                    ? _startTranscription
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  'START TRANSCRIPTION',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            // Лог-окно
            _buildLogWindow(),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogWindow() {
    return Card(
      child: Column(
        children: [
          // Заголовок с кнопкой сворачивания
          ListTile(
            title: const Text(
              'Process Logs',
              style: TextStyle(fontWeight: FontWeight.bold),
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

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsView()),
    );
  }
}
