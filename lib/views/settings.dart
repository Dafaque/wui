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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search settings...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Type to filter settings',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Filtered settings list
          Expanded(child: ListView(children: _buildFilteredSettings())),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredSettings() {
    final allSettings = _getAllSettings();

    if (_searchQuery.isEmpty) {
      return allSettings;
    }

    return allSettings.where((widget) {
      return _shouldShowWidget(widget);
    }).toList();
  }

  List<Widget> _getAllSettings() {
    return [
      ..._buildFilePathsSection(),
      const Divider(),
      ..._buildComputationParametersSection(),
      const Divider(),
      ..._buildThresholdsSection(),
      const Divider(),
      ..._buildFlagsSection(),
      const Divider(),
      ..._buildOutputFormatsSection(),
      const Divider(),
      ..._buildPrintOptionsSection(),
      const Divider(),
      ..._buildTextParametersSection(),
    ];
  }

  bool _shouldShowWidget(Widget widget) {
    // Check section headers
    if (widget is Padding) {
      final child = widget.child;

      if (child is Text) {
        final textData = child.data?.toLowerCase() ?? '';
        if (textData.contains(_searchQuery)) return true;

        // If this is a section header and we have a search query,
        // check if any items in this section match
        if (_searchQuery.isNotEmpty && _isSectionHeader(textData)) {
          return _hasMatchingItemsInSection(textData);
        }
      }
    }

    // Check ListTiles (file path selectors)
    if (widget is ListTile) {
      final title = widget.title;
      final subtitle = widget.subtitle;

      if (title is Text) {
        final titleText = title.data?.toLowerCase() ?? '';
        if (titleText.contains(_searchQuery)) return true;
      }

      if (subtitle is Text) {
        final subtitleText = subtitle.data?.toLowerCase() ?? '';
        if (subtitleText.contains(_searchQuery)) return true;
      }
    }

    // Check SwitchListTiles
    if (widget is SwitchListTile) {
      final title = widget.title;
      final subtitle = widget.subtitle;

      if (title is Text) {
        final titleText = title.data?.toLowerCase() ?? '';
        if (titleText.contains(_searchQuery)) return true;
      }

      if (subtitle is Text) {
        final subtitleText = subtitle.data?.toLowerCase() ?? '';
        if (subtitleText.contains(_searchQuery)) return true;
      }
    }

    // Always show dividers to maintain section structure
    if (widget is Divider) {
      return true;
    }

    // Check custom field widgets (TextField, DropdownButtonFormField)
    if (widget is Padding && widget.child is TextField) {
      return _checkTextField(widget);
    }

    if (widget is Padding && widget.child is DropdownButtonFormField) {
      return _checkDropdownField(widget);
    }

    return false;
  }

  bool _isSectionHeader(String text) {
    final sectionHeaders = [
      'file paths',
      'computation parameters',
      'thresholds',
      'flags',
      'output formats',
      'print options',
      'text parameters',
    ];
    return sectionHeaders.contains(text);
  }

  bool _hasMatchingItemsInSection(String sectionHeader) {
    // This is a simplified implementation
    // In a more complex scenario, you'd want to track which items belong to which section
    return true; // For now, show section headers if there's a search query
  }

  bool _checkTextField(Widget widget) {
    final padding = widget as Padding;
    final textField = padding.child as TextField;
    final decoration = textField.decoration;

    if (decoration != null) {
      final labelText = decoration.labelText?.toLowerCase() ?? '';
      final helperText = decoration.helperText?.toLowerCase() ?? '';

      if (labelText.contains(_searchQuery) ||
          helperText.contains(_searchQuery)) {
        return true;
      }
    }

    return false;
  }

  bool _checkDropdownField(Widget widget) {
    final padding = widget as Padding;
    final dropdown = padding.child as DropdownButtonFormField;
    final decoration = dropdown.decoration;

    final labelText = decoration.labelText?.toLowerCase() ?? '';
    final helperText = decoration.helperText?.toLowerCase() ?? '';

    if (labelText.contains(_searchQuery) || helperText.contains(_searchQuery)) {
      return true;
    }

    return false;
  }

  List<Widget> _buildFilePathsSection() {
    return [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'File Paths',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _buildFilePickerTile(
        icon: Icons.build,
        title: 'Whisper Engine',
        subtitle: settings.whisperEngine.isEmpty
            ? 'No file selected'
            : settings.whisperEngine,
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
          if (result != null && result.files.isNotEmpty) {
            setState(() => settings.whisperEngine = result.files.first.path!);
          }
        },
      ),
      _buildFilePickerTile(
        icon: Icons.model_training,
        title: 'Whisper Model',
        subtitle: settings.whisperModel.isEmpty
            ? 'No file selected'
            : settings.whisperModel,
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['bin'],
            allowMultiple: false,
          );
          if (result != null && result.files.isNotEmpty) {
            setState(() => settings.whisperModel = result.files.first.path!);
          }
        },
      ),
      _buildFilePickerTile(
        icon: Icons.timeline,
        title: 'DTW Model',
        subtitle: settings.dtwModel.isEmpty
            ? 'No file selected'
            : settings.dtwModel,
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
    ];
  }

  Widget _buildFilePickerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.folder_open),
      onTap: onTap,
    );
  }

  List<Widget> _buildComputationParametersSection() {
    return [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Computation Parameters',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _buildNumberField(
        'Threads',
        settings.threads.toString(),
        (value) => settings.threads = int.tryParse(value) ?? 4,
        helperText: 'Number of threads to use during computation',
      ),
      _buildNumberField(
        'Processors',
        settings.processors.toString(),
        (value) => settings.processors = int.tryParse(value) ?? 1,
        helperText: 'Number of processors to use during computation',
      ),
      _buildNumberField(
        'Duration (ms)',
        settings.duration.toString(),
        (value) => settings.duration = int.tryParse(value) ?? 0,
        helperText: 'Duration of audio to process in milliseconds',
      ),
      _buildNumberField(
        'Max Context',
        settings.maxContext.toString(),
        (value) => settings.maxContext = int.tryParse(value) ?? -1,
        helperText: 'Maximum number of text context tokens to store',
      ),
      _buildNumberField(
        'Max Length',
        settings.maxLen.toString(),
        (value) => settings.maxLen = int.tryParse(value) ?? 0,
        helperText: 'Maximum segment length in characters',
      ),
      _buildNumberField(
        'Best Of',
        settings.bestOf.toString(),
        (value) => settings.bestOf = int.tryParse(value) ?? 5,
        helperText: 'Number of best candidates to keep',
      ),
      _buildNumberField(
        'Beam Size',
        settings.beamSize.toString(),
        (value) => settings.beamSize = int.tryParse(value) ?? 5,
        helperText: 'Beam size for beam search',
      ),
      _buildNumberField(
        'Audio Context',
        settings.audioCtx.toString(),
        (value) => settings.audioCtx = int.tryParse(value) ?? 0,
        helperText: 'Audio context size (0 - all)',
      ),
    ];
  }

  List<Widget> _buildThresholdsSection() {
    return [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Thresholds',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _buildDoubleField(
        'Word Threshold',
        settings.wordThold.toString(),
        (value) => settings.wordThold = double.tryParse(value) ?? 0.01,
        helperText: 'Word timestamp probability threshold',
      ),
      _buildDoubleField(
        'Entropy Threshold',
        settings.entropyThold.toString(),
        (value) => settings.entropyThold = double.tryParse(value) ?? 2.40,
        helperText: 'Entropy threshold for decoder fail',
      ),
      _buildDoubleField(
        'Logprob Threshold',
        settings.logprobThold.toString(),
        (value) => settings.logprobThold = double.tryParse(value) ?? -1.00,
        helperText: 'Log probability threshold for decoder fail',
      ),
      _buildDoubleField(
        'No Speech Threshold',
        settings.noSpeechThold.toString(),
        (value) => settings.noSpeechThold = double.tryParse(value) ?? 0.60,
        helperText: 'No speech threshold',
      ),
      _buildDoubleField(
        'Temperature',
        settings.temperature.toString(),
        (value) => settings.temperature = double.tryParse(value) ?? 0.00,
        helperText: 'The sampling temperature, between 0 and 1',
      ),
      _buildDoubleField(
        'Temperature Increment',
        settings.temperatureInc.toString(),
        (value) => settings.temperatureInc = double.tryParse(value) ?? 0.20,
        helperText: 'The increment of temperature, between 0 and 1',
      ),
      _buildDoubleField(
        'Grammar Penalty',
        settings.grammarPenalty.toString(),
        (value) => settings.grammarPenalty = double.tryParse(value) ?? 100.0,
        helperText: 'Scales down logits of nongrammar tokens',
      ),
    ];
  }

  List<Widget> _buildSwitchSection(
    String title,
    List<Map<String, dynamic>> switches,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      ...switches.map(
        (switchData) => SwitchListTile(
          title: Text(switchData['title']),
          subtitle: Text(switchData['subtitle']),
          value: switchData['value'],
          onChanged: switchData['onChanged'],
        ),
      ),
    ];
  }

  List<Widget> _buildFlagsSection() {
    return _buildSwitchSection('Flags', [
      {
        'title': 'Split on Word',
        'subtitle': 'Split on word rather than on token',
        'value': settings.splitOnWord,
        'onChanged': (value) => setState(() => settings.splitOnWord = value),
      },
      {
        'title': 'Debug Mode',
        'subtitle': 'Enable debug mode',
        'value': settings.debugMode,
        'onChanged': (value) => setState(() => settings.debugMode = value),
      },
      {
        'title': 'Translate',
        'subtitle': 'Translate from source language to english',
        'value': settings.translate,
        'onChanged': (value) => setState(() => settings.translate = value),
      },
      {
        'title': 'Diarize',
        'subtitle': 'Stereo audio diarization',
        'value': settings.diarize,
        'onChanged': (value) => setState(() => settings.diarize = value),
      },
      {
        'title': 'TinyDiarize',
        'subtitle': 'Enable tinydiarize (requires a tdrz model)',
        'value': settings.tinydiarize,
        'onChanged': (value) => setState(() => settings.tinydiarize = value),
      },
      {
        'title': 'No Fallback',
        'subtitle': 'Do not use temperature fallback while decoding',
        'value': settings.noFallback,
        'onChanged': (value) => setState(() => settings.noFallback = value),
      },
      {
        'title': 'Detect Language',
        'subtitle': 'Exit after automatically detecting language',
        'value': settings.detectLanguage,
        'onChanged': (value) => setState(() => settings.detectLanguage = value),
      },
      {
        'title': 'No GPU',
        'subtitle': 'Disable GPU',
        'value': settings.noGpu,
        'onChanged': (value) => setState(() => settings.noGpu = value),
      },
      {
        'title': 'Flash Attention',
        'subtitle': 'Flash attention',
        'value': settings.flashAttn,
        'onChanged': (value) => setState(() => settings.flashAttn = value),
      },
      {
        'title': 'Suppress NST',
        'subtitle': 'Suppress non-speech tokens',
        'value': settings.suppressNst,
        'onChanged': (value) => setState(() => settings.suppressNst = value),
      },
    ]);
  }

  List<Widget> _buildOutputFormatsSection() {
    return _buildSwitchSection('Output Formats', [
      {
        'title': 'Output TXT',
        'subtitle': 'Output result in a text file',
        'value': settings.outputTxt,
        'onChanged': (value) => setState(() => settings.outputTxt = value),
      },
      {
        'title': 'Output VTT',
        'subtitle': 'Output result in a vtt file',
        'value': settings.outputVtt,
        'onChanged': (value) => setState(() => settings.outputVtt = value),
      },
      {
        'title': 'Output SRT',
        'subtitle': 'Output result in a srt file',
        'value': settings.outputSrt,
        'onChanged': (value) => setState(() => settings.outputSrt = value),
      },
      {
        'title': 'Output LRC',
        'subtitle': 'Output result in a lrc file',
        'value': settings.outputLrc,
        'onChanged': (value) => setState(() => settings.outputLrc = value),
      },
      {
        'title': 'Output Words',
        'subtitle': 'Output script for generating karaoke video',
        'value': settings.outputWords,
        'onChanged': (value) => setState(() => settings.outputWords = value),
      },
      {
        'title': 'Output CSV',
        'subtitle': 'Output result in a CSV file',
        'value': settings.outputCsv,
        'onChanged': (value) => setState(() => settings.outputCsv = value),
      },
      {
        'title': 'Output JSON',
        'subtitle': 'Output result in a JSON file',
        'value': settings.outputJson,
        'onChanged': (value) => setState(() => settings.outputJson = value),
      },
      {
        'title': 'Output JSON Full',
        'subtitle': 'Include more information in the JSON file',
        'value': settings.outputJsonFull,
        'onChanged': (value) => setState(() => settings.outputJsonFull = value),
      },
    ]);
  }

  List<Widget> _buildPrintOptionsSection() {
    return _buildSwitchSection('Print Options', [
      {
        'title': 'No Prints',
        'subtitle': 'Do not print anything other than the results',
        'value': settings.noPrints,
        'onChanged': (value) => setState(() => settings.noPrints = value),
      },
      {
        'title': 'Print Special',
        'subtitle': 'Print special tokens',
        'value': settings.printSpecial,
        'onChanged': (value) => setState(() => settings.printSpecial = value),
      },
      {
        'title': 'Print Colors',
        'subtitle': 'Print colors',
        'value': settings.printColors,
        'onChanged': (value) => setState(() => settings.printColors = value),
      },
      {
        'title': 'Print Confidence',
        'subtitle': 'Print confidence',
        'value': settings.printConfidence,
        'onChanged': (value) =>
            setState(() => settings.printConfidence = value),
      },
      {
        'title': 'Print Progress',
        'subtitle': 'Print progress',
        'value': settings.printProgress,
        'onChanged': (value) => setState(() => settings.printProgress = value),
      },
      {
        'title': 'No Timestamps',
        'subtitle': 'Do not print timestamps',
        'value': settings.noTimestamps,
        'onChanged': (value) => setState(() => settings.noTimestamps = value),
      },
      {
        'title': 'Log Score',
        'subtitle': 'Log best decoder scores of tokens',
        'value': settings.logScore,
        'onChanged': (value) => setState(() => settings.logScore = value),
      },
    ]);
  }

  List<Widget> _buildTextParametersSection() {
    return [
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Text Parameters',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _buildLanguageDropdown(
        'Language',
        settings.language,
        (value) => settings.language = value,
        helperText: 'Spoken language (auto for auto-detect)',
      ),
      _buildTextField(
        'Prompt',
        settings.prompt,
        (value) => settings.prompt = value,
        helperText: 'Initial prompt (max n_text_ctx/2 tokens)',
      ),
      _buildTextField(
        'Suppress Regex',
        settings.suppressRegex,
        (value) => settings.suppressRegex = value,
        helperText: 'Regular expression matching tokens to suppress',
      ),
      _buildTextField(
        'Grammar',
        settings.grammar,
        (value) => settings.grammar = value,
        helperText: 'GBNF grammar to guide decoding',
      ),
      _buildTextField(
        'Grammar Rule',
        settings.grammarRule,
        (value) => settings.grammarRule = value,
        helperText: 'Top-level GBNF grammar rule name',
      ),
      _buildTextField(
        'OpenVINO Device',
        settings.ovEDevice,
        (value) => settings.ovEDevice = value,
        helperText: 'The OpenVINO device used for encode inference',
      ),
    ];
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
        initialValue: languages.containsKey(value) ? value : 'en',
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
