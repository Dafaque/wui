import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:whisperui/services/settings.dart';

// Я ебал все это руками переносить, потому эту вью делала нейронка
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Settings settings = SettingsService.instance().settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () {
              // Сохраняем настройки
              SettingsService.instance().save(settings);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // === FILE PATHS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'File Paths',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Whisper Engine
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Whisper Engine'),
            subtitle: Text(
              settings.whisperEngine.isEmpty
                  ? 'No file selected'
                  : settings.whisperEngine,
            ),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.any,
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                setState(
                  () => settings.whisperEngine = result.files.first.path!,
                );
              }
            },
          ),

          // Whisper Model
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('Whisper Model'),
            subtitle: Text(
              settings.whisperModel.isEmpty
                  ? 'No file selected'
                  : settings.whisperModel,
            ),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['bin'],
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                setState(
                  () => settings.whisperModel = result.files.first.path!,
                );
              }
            },
          ),

          // DTW Model
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('DTW Model'),
            subtitle: Text(
              settings.dtwModel.isEmpty
                  ? 'No file selected'
                  : settings.dtwModel,
            ),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.any,
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                setState(() => settings.dtwModel = result.files.first.path!);
              }
            },
          ),

          const Divider(),

          // === COMPUTATION PARAMETERS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Computation Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Threads
          _buildNumberField(
            'Threads',
            settings.threads.toString(),
            (value) {
              settings.threads = int.tryParse(value) ?? 4;
            },
            helperText: 'Number of threads to use during computation',
          ),

          // Processors
          _buildNumberField(
            'Processors',
            settings.processors.toString(),
            (value) {
              settings.processors = int.tryParse(value) ?? 1;
            },
            helperText: 'Number of processors to use during computation',
          ),

          // Duration
          _buildNumberField(
            'Duration (ms)',
            settings.duration.toString(),
            (value) {
              settings.duration = int.tryParse(value) ?? 0;
            },
            helperText: 'Duration of audio to process in milliseconds',
          ),

          // Max Context
          _buildNumberField(
            'Max Context',
            settings.maxContext.toString(),
            (value) {
              settings.maxContext = int.tryParse(value) ?? -1;
            },
            helperText: 'Maximum number of text context tokens to store',
          ),

          // Max Length
          _buildNumberField(
            'Max Length',
            settings.maxLen.toString(),
            (value) {
              settings.maxLen = int.tryParse(value) ?? 0;
            },
            helperText: 'Maximum segment length in characters',
          ),

          // Best Of
          _buildNumberField(
            'Best Of',
            settings.bestOf.toString(),
            (value) {
              settings.bestOf = int.tryParse(value) ?? 5;
            },
            helperText: 'Number of best candidates to keep',
          ),

          // Beam Size
          _buildNumberField(
            'Beam Size',
            settings.beamSize.toString(),
            (value) {
              settings.beamSize = int.tryParse(value) ?? 5;
            },
            helperText: 'Beam size for beam search',
          ),

          // Audio Context
          _buildNumberField(
            'Audio Context',
            settings.audioCtx.toString(),
            (value) {
              settings.audioCtx = int.tryParse(value) ?? 0;
            },
            helperText: 'Audio context size (0 - all)',
          ),

          const Divider(),

          // === THRESHOLDS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Thresholds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Word Threshold
          _buildDoubleField(
            'Word Threshold',
            settings.wordThold.toString(),
            (value) {
              settings.wordThold = double.tryParse(value) ?? 0.01;
            },
            helperText: 'Word timestamp probability threshold',
          ),

          // Entropy Threshold
          _buildDoubleField(
            'Entropy Threshold',
            settings.entropyThold.toString(),
            (value) {
              settings.entropyThold = double.tryParse(value) ?? 2.40;
            },
            helperText: 'Entropy threshold for decoder fail',
          ),

          // Logprob Threshold
          _buildDoubleField(
            'Logprob Threshold',
            settings.logprobThold.toString(),
            (value) {
              settings.logprobThold = double.tryParse(value) ?? -1.00;
            },
            helperText: 'Log probability threshold for decoder fail',
          ),

          // No Speech Threshold
          _buildDoubleField(
            'No Speech Threshold',
            settings.noSpeechThold.toString(),
            (value) {
              settings.noSpeechThold = double.tryParse(value) ?? 0.60;
            },
            helperText: 'No speech threshold',
          ),

          // Temperature
          _buildDoubleField(
            'Temperature',
            settings.temperature.toString(),
            (value) {
              settings.temperature = double.tryParse(value) ?? 0.00;
            },
            helperText: 'The sampling temperature, between 0 and 1',
          ),

          // Temperature Increment
          _buildDoubleField(
            'Temperature Increment',
            settings.temperatureInc.toString(),
            (value) {
              settings.temperatureInc = double.tryParse(value) ?? 0.20;
            },
            helperText: 'The increment of temperature, between 0 and 1',
          ),

          // Grammar Penalty
          _buildDoubleField(
            'Grammar Penalty',
            settings.grammarPenalty.toString(),
            (value) {
              settings.grammarPenalty = double.tryParse(value) ?? 100.0;
            },
            helperText: 'Scales down logits of nongrammar tokens',
          ),

          const Divider(),

          // === BOOLEAN FLAGS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Flags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Split on Word
          SwitchListTile(
            title: const Text('Split on Word'),
            subtitle: const Text('Split on word rather than on token'),
            value: settings.splitOnWord,
            onChanged: (value) => setState(() => settings.splitOnWord = value),
          ),

          // Debug Mode
          SwitchListTile(
            title: const Text('Debug Mode'),
            subtitle: const Text('Enable debug mode'),
            value: settings.debugMode,
            onChanged: (value) => setState(() => settings.debugMode = value),
          ),

          // Translate
          SwitchListTile(
            title: const Text('Translate'),
            subtitle: const Text('Translate from source language to english'),
            value: settings.translate,
            onChanged: (value) => setState(() => settings.translate = value),
          ),

          // Diarize
          SwitchListTile(
            title: const Text('Diarize'),
            subtitle: const Text('Stereo audio diarization'),
            value: settings.diarize,
            onChanged: (value) => setState(() => settings.diarize = value),
          ),

          // TinyDiarize
          SwitchListTile(
            title: const Text('TinyDiarize'),
            subtitle: const Text('Enable tinydiarize (requires a tdrz model)'),
            value: settings.tinydiarize,
            onChanged: (value) => setState(() => settings.tinydiarize = value),
          ),

          // No Fallback
          SwitchListTile(
            title: const Text('No Fallback'),
            subtitle: const Text(
              'Do not use temperature fallback while decoding',
            ),
            value: settings.noFallback,
            onChanged: (value) => setState(() => settings.noFallback = value),
          ),

          // Detect Language
          SwitchListTile(
            title: const Text('Detect Language'),
            subtitle: const Text('Exit after automatically detecting language'),
            value: settings.detectLanguage,
            onChanged: (value) =>
                setState(() => settings.detectLanguage = value),
          ),

          // No GPU
          SwitchListTile(
            title: const Text('No GPU'),
            subtitle: const Text('Disable GPU'),
            value: settings.noGpu,
            onChanged: (value) => setState(() => settings.noGpu = value),
          ),

          // Flash Attention
          SwitchListTile(
            title: const Text('Flash Attention'),
            subtitle: const Text('Flash attention'),
            value: settings.flashAttn,
            onChanged: (value) => setState(() => settings.flashAttn = value),
          ),

          // Suppress NST
          SwitchListTile(
            title: const Text('Suppress NST'),
            subtitle: const Text('Suppress non-speech tokens'),
            value: settings.suppressNst,
            onChanged: (value) => setState(() => settings.suppressNst = value),
          ),

          const Divider(),

          // === OUTPUT FORMATS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Output Formats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Output TXT
          SwitchListTile(
            title: const Text('Output TXT'),
            subtitle: const Text('Output result in a text file'),
            value: settings.outputTxt,
            onChanged: (value) => setState(() => settings.outputTxt = value),
          ),

          // Output VTT
          SwitchListTile(
            title: const Text('Output VTT'),
            subtitle: const Text('Output result in a vtt file'),
            value: settings.outputVtt,
            onChanged: (value) => setState(() => settings.outputVtt = value),
          ),

          // Output SRT
          SwitchListTile(
            title: const Text('Output SRT'),
            subtitle: const Text('Output result in a srt file'),
            value: settings.outputSrt,
            onChanged: (value) => setState(() => settings.outputSrt = value),
          ),

          // Output LRC
          SwitchListTile(
            title: const Text('Output LRC'),
            subtitle: const Text('Output result in a lrc file'),
            value: settings.outputLrc,
            onChanged: (value) => setState(() => settings.outputLrc = value),
          ),

          // Output Words
          SwitchListTile(
            title: const Text('Output Words'),
            subtitle: const Text('Output script for generating karaoke video'),
            value: settings.outputWords,
            onChanged: (value) => setState(() => settings.outputWords = value),
          ),

          // Output CSV
          SwitchListTile(
            title: const Text('Output CSV'),
            subtitle: const Text('Output result in a CSV file'),
            value: settings.outputCsv,
            onChanged: (value) => setState(() => settings.outputCsv = value),
          ),

          // Output JSON
          SwitchListTile(
            title: const Text('Output JSON'),
            subtitle: const Text('Output result in a JSON file'),
            value: settings.outputJson,
            onChanged: (value) => setState(() => settings.outputJson = value),
          ),

          // Output JSON Full
          SwitchListTile(
            title: const Text('Output JSON Full'),
            subtitle: const Text('Include more information in the JSON file'),
            value: settings.outputJsonFull,
            onChanged: (value) =>
                setState(() => settings.outputJsonFull = value),
          ),

          const Divider(),

          // === PRINT OPTIONS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Print Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // No Prints
          SwitchListTile(
            title: const Text('No Prints'),
            subtitle: const Text(
              'Do not print anything other than the results',
            ),
            value: settings.noPrints,
            onChanged: (value) => setState(() => settings.noPrints = value),
          ),

          // Print Special
          SwitchListTile(
            title: const Text('Print Special'),
            subtitle: const Text('Print special tokens'),
            value: settings.printSpecial,
            onChanged: (value) => setState(() => settings.printSpecial = value),
          ),

          // Print Colors
          SwitchListTile(
            title: const Text('Print Colors'),
            subtitle: const Text('Print colors'),
            value: settings.printColors,
            onChanged: (value) => setState(() => settings.printColors = value),
          ),

          // Print Confidence
          SwitchListTile(
            title: const Text('Print Confidence'),
            subtitle: const Text('Print confidence'),
            value: settings.printConfidence,
            onChanged: (value) =>
                setState(() => settings.printConfidence = value),
          ),

          // Print Progress
          SwitchListTile(
            title: const Text('Print Progress'),
            subtitle: const Text('Print progress'),
            value: settings.printProgress,
            onChanged: (value) =>
                setState(() => settings.printProgress = value),
          ),

          // No Timestamps
          SwitchListTile(
            title: const Text('No Timestamps'),
            subtitle: const Text('Do not print timestamps'),
            value: settings.noTimestamps,
            onChanged: (value) => setState(() => settings.noTimestamps = value),
          ),

          // Log Score
          SwitchListTile(
            title: const Text('Log Score'),
            subtitle: const Text('Log best decoder scores of tokens'),
            value: settings.logScore,
            onChanged: (value) => setState(() => settings.logScore = value),
          ),

          const Divider(),

          // === TEXT PARAMETERS ===
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Text Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Language
          _buildLanguageDropdown(
            'Language',
            settings.language,
            (value) {
              settings.language = value;
            },
            helperText: 'Spoken language (auto for auto-detect)',
          ),

          // Prompt
          _buildTextField(
            'Prompt',
            settings.prompt,
            (value) {
              settings.prompt = value;
            },
            helperText: 'Initial prompt (max n_text_ctx/2 tokens)',
          ),

          // Suppress Regex
          _buildTextField(
            'Suppress Regex',
            settings.suppressRegex,
            (value) {
              settings.suppressRegex = value;
            },
            helperText: 'Regular expression matching tokens to suppress',
          ),

          // Grammar
          _buildTextField(
            'Grammar',
            settings.grammar,
            (value) {
              settings.grammar = value;
            },
            helperText: 'GBNF grammar to guide decoding',
          ),

          // Grammar Rule
          _buildTextField(
            'Grammar Rule',
            settings.grammarRule,
            (value) {
              settings.grammarRule = value;
            },
            helperText: 'Top-level GBNF grammar rule name',
          ),

          // OpenVINO Device
          _buildTextField(
            'OpenVINO Device',
            settings.ovEDevice,
            (value) {
              settings.ovEDevice = value;
            },
            helperText: 'The OpenVINO device used for encode inference',
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged, {
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDoubleField(
    String label,
    String value,
    Function(String) onChanged, {
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLanguageDropdown(
    String label,
    String value,
    Function(String) onChanged, {
    String? helperText,
  }) {
    final languages = {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: languages.containsKey(value) ? value : 'en',
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        items: languages.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
