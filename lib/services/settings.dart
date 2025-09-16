import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:whisperui/singletons/logger.dart';

const String appHome = 'WhisperUI';
const String appSettings = 'settings.json';

class Settings {
  // File paths
  String whisperEngine; // Path to whisper-cli
  String
  whisperModel; // -m FNAME, --model FNAME [models/ggml-base.en.bin] model path
  String
  suppressRegex; // --suppress-regex REGEX [] regular expression matching tokens to suppress
  String grammar; // --grammar GRAMMAR [] GBNF grammar to guide decoding
  String grammarRule; // --grammar-rule RULE [] top-level GBNF grammar rule name
  String prompt; // --prompt PROMPT [] initial prompt (max n_text_ctx/2 tokens)
  String dtwModel; // -dtw MODEL --dtw MODEL [] compute token-level timestamps
  String
  ovEDevice; // -oved D, --ov-e-device DNAME [CPU] the OpenVINO device used for encode inference

  // Numeric parameters
  int
  threads; // -t N, --threads N [4] number of threads to use during computation
  int
  processors; // -p N, --processors N [1] number of processors to use during computation
  int offsetT; // -ot N, --offset-t N [0] time offset in milliseconds
  int offsetN; // -on N, --offset-n N [0] segment index offset
  int
  duration; // -d N, --duration N [0] duration of audio to process in milliseconds
  int
  maxContext; // -mc N, --max-context N [-1] maximum number of text context tokens to store
  int maxLen; // -ml N, --max-len N [0] maximum segment length in characters
  int bestOf; // -bo N, --best-of N [5] number of best candidates to keep
  int beamSize; // -bs N, --beam-size N [5] beam size for beam search
  int audioCtx; // -ac N, --audio-ctx N [0] audio context size (0 - all)
  double
  wordThold; // -wt N, --word-thold N [0.01] word timestamp probability threshold
  double
  entropyThold; // -et N, --entropy-thold N [2.40] entropy threshold for decoder fail
  double
  logprobThold; // -lpt N, --logprob-thold N [-1.00] log probability threshold for decoder fail
  double
  noSpeechThold; // -nth N, --no-speech-thold N [0.60] no speech threshold
  double
  temperature; // -tp, --temperature N [0.00] The sampling temperature, between 0 and 1
  double
  temperatureInc; // -tpi, --temperature-inc N [0.20] The increment of temperature, between 0 and 1
  double
  grammarPenalty; // --grammar-penalty N [100.0] scales down logits of nongrammar tokens

  // Boolean parameters
  bool
  splitOnWord; // -sow, --split-on-word [false] split on word rather than on token
  bool
  debugMode; // -debug, --debug-mode [false] enable debug mode (eg. dump log_mel)
  bool
  translate; // -tr, --translate [false] translate from source language to english
  bool diarize; // -di, --diarize [false] stereo audio diarization
  bool
  tinydiarize; // -tdrz, --tinydiarize [false] enable tinydiarize (requires a tdrz model)
  bool
  noFallback; // -nf, --no-fallback [false] do not use temperature fallback while decoding
  bool outputTxt; // -otxt, --output-txt [false] output result in a text file
  bool outputVtt; // -ovtt, --output-vtt [false] output result in a vtt file
  bool outputSrt; // -osrt, --output-srt [false] output result in a srt file
  bool outputLrc; // -olrc, --output-lrc [false] output result in a lrc file
  bool
  outputWords; // -owts, --output-words [false] output script for generating karaoke video
  bool outputCsv; // -ocsv, --output-csv [false] output result in a CSV file
  bool outputJson; // -oj, --output-json [false] output result in a JSON file
  bool
  outputJsonFull; // -ojf, --output-json-full [false] include more information in the JSON file
  bool
  noPrints; // -np, --no-prints [false] do not print anything other than the results
  bool printSpecial; // -ps, --print-special [false] print special tokens
  bool printColors; // -pc, --print-colors [false] print colors
  bool printConfidence; // --print-confidence [false] print confidence
  bool printProgress; // -pp, --print-progress [false] print progress
  bool noTimestamps; // -nt, --no-timestamps [false] do not print timestamps
  bool
  detectLanguage; // -dl, --detect-language [false] exit after automatically detecting language
  bool logScore; // -ls, --log-score [false] log best decoder scores of tokens
  bool noGpu; // -ng, --no-gpu [false] disable GPU
  bool flashAttn; // -fa, --flash-attn [false] flash attention
  bool suppressNst; // -sns, --suppress-nst [false] suppress non-speech tokens

  // String parameters
  String
  language; // -l LANG, --language LANG [en] spoken language ('auto' for auto-detect)

  Settings({
    // File paths
    this.whisperEngine = '',
    this.whisperModel = '',
    this.suppressRegex = '',
    this.grammar = '',
    this.grammarRule = '',
    this.prompt = '',
    this.dtwModel = '',
    this.ovEDevice = 'CPU',

    // Numeric parameters
    this.threads = 4,
    this.processors = 1,
    this.offsetT = 0,
    this.offsetN = 0,
    this.duration = 0,
    this.maxContext = -1,
    this.maxLen = 0,
    this.bestOf = 5,
    this.beamSize = 5,
    this.audioCtx = 0,
    this.wordThold = 0.01,
    this.entropyThold = 2.40,
    this.logprobThold = -1.00,
    this.noSpeechThold = 0.60,
    this.temperature = 0.00,
    this.temperatureInc = 0.20,
    this.grammarPenalty = 100.0,

    // Boolean parameters
    this.splitOnWord = false,
    this.debugMode = false,
    this.translate = false,
    this.diarize = false,
    this.tinydiarize = false,
    this.noFallback = false,
    this.outputTxt = false,
    this.outputVtt = false,
    this.outputSrt = false,
    this.outputLrc = false,
    this.outputWords = false,
    this.outputCsv = false,
    this.outputJson = false,
    this.outputJsonFull = false,
    this.noPrints = false,
    this.printSpecial = false,
    this.printColors = false,
    this.printConfidence = false,
    this.printProgress = false,
    this.noTimestamps = false,
    this.detectLanguage = false,
    this.logScore = false,
    this.noGpu = false,
    this.flashAttn = false,
    this.suppressNst = false,

    // String parameters
    this.language = 'en',
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      // File paths
      whisperEngine: json['whisperEngine'] ?? '',
      whisperModel: json['whisperModel'] ?? '',
      suppressRegex: json['suppressRegex'] ?? '',
      grammar: json['grammar'] ?? '',
      grammarRule: json['grammarRule'] ?? '',
      prompt: json['prompt'] ?? '',
      dtwModel: json['dtwModel'] ?? '',
      ovEDevice: json['ovEDevice'] ?? 'CPU',

      // Numeric parameters
      threads: json['threads'] ?? 4,
      processors: json['processors'] ?? 1,
      offsetT: json['offsetT'] ?? 0,
      offsetN: json['offsetN'] ?? 0,
      duration: json['duration'] ?? 0,
      maxContext: json['maxContext'] ?? -1,
      maxLen: json['maxLen'] ?? 0,
      bestOf: json['bestOf'] ?? 5,
      beamSize: json['beamSize'] ?? 5,
      audioCtx: json['audioCtx'] ?? 0,
      wordThold: (json['wordThold'] ?? 0.01).toDouble(),
      entropyThold: (json['entropyThold'] ?? 2.40).toDouble(),
      logprobThold: (json['logprobThold'] ?? -1.00).toDouble(),
      noSpeechThold: (json['noSpeechThold'] ?? 0.60).toDouble(),
      temperature: (json['temperature'] ?? 0.00).toDouble(),
      temperatureInc: (json['temperatureInc'] ?? 0.20).toDouble(),
      grammarPenalty: (json['grammarPenalty'] ?? 100.0).toDouble(),

      // Boolean parameters
      splitOnWord: json['splitOnWord'] ?? false,
      debugMode: json['debugMode'] ?? false,
      translate: json['translate'] ?? false,
      diarize: json['diarize'] ?? false,
      tinydiarize: json['tinydiarize'] ?? false,
      noFallback: json['noFallback'] ?? false,
      outputTxt: json['outputTxt'] ?? false,
      outputVtt: json['outputVtt'] ?? false,
      outputSrt: json['outputSrt'] ?? false,
      outputLrc: json['outputLrc'] ?? false,
      outputWords: json['outputWords'] ?? false,
      outputCsv: json['outputCsv'] ?? false,
      outputJson: json['outputJson'] ?? false,
      outputJsonFull: json['outputJsonFull'] ?? false,
      noPrints: json['noPrints'] ?? false,
      printSpecial: json['printSpecial'] ?? false,
      printColors: json['printColors'] ?? false,
      printConfidence: json['printConfidence'] ?? false,
      printProgress: json['printProgress'] ?? false,
      noTimestamps: json['noTimestamps'] ?? false,
      detectLanguage: json['detectLanguage'] ?? false,
      logScore: json['logScore'] ?? false,
      noGpu: json['noGpu'] ?? false,
      flashAttn: json['flashAttn'] ?? false,
      suppressNst: json['suppressNst'] ?? false,

      // String parameters
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // File paths
      'whisperEngine': whisperEngine,
      'whisperModel': whisperModel,
      'suppressRegex': suppressRegex,
      'grammar': grammar,
      'grammarRule': grammarRule,
      'prompt': prompt,
      'dtwModel': dtwModel,
      'ovEDevice': ovEDevice,

      // Numeric parameters
      'threads': threads,
      'processors': processors,
      'offsetT': offsetT,
      'offsetN': offsetN,
      'duration': duration,
      'maxContext': maxContext,
      'maxLen': maxLen,
      'bestOf': bestOf,
      'beamSize': beamSize,
      'audioCtx': audioCtx,
      'wordThold': wordThold,
      'entropyThold': entropyThold,
      'logprobThold': logprobThold,
      'noSpeechThold': noSpeechThold,
      'temperature': temperature,
      'temperatureInc': temperatureInc,
      'grammarPenalty': grammarPenalty,

      // Boolean parameters
      'splitOnWord': splitOnWord,
      'debugMode': debugMode,
      'translate': translate,
      'diarize': diarize,
      'tinydiarize': tinydiarize,
      'noFallback': noFallback,
      'outputTxt': outputTxt,
      'outputVtt': outputVtt,
      'outputSrt': outputSrt,
      'outputLrc': outputLrc,
      'outputWords': outputWords,
      'outputCsv': outputCsv,
      'outputJson': outputJson,
      'outputJsonFull': outputJsonFull,
      'noPrints': noPrints,
      'printSpecial': printSpecial,
      'printColors': printColors,
      'printConfidence': printConfidence,
      'printProgress': printProgress,
      'noTimestamps': noTimestamps,
      'detectLanguage': detectLanguage,
      'logScore': logScore,
      'noGpu': noGpu,
      'flashAttn': flashAttn,
      'suppressNst': suppressNst,

      // String parameters
      'language': language,
    };
  }
}

class SettingsService {
  static final SettingsService _instance = SettingsService();

  SettingsService();

  Directory? _appHomeDir;
  Directory get appHomeDir => _appHomeDir ?? Directory('');

  bool _initialized = false;
  Settings? _settings;
  static SettingsService instance() {
    return _instance;
  }

  Settings get settings => _settings ?? Settings();

  Future<void> init() async {
    if (_initialized) return;
    return getApplicationDocumentsDirectory().then(_initDirectory).catchError((
      error,
    ) {
      logger.e('failed to init directory: $error');
      throw error;
    });
  }

  Future<void> _initDirectory(Directory home) async {
    logger.d('documents path: ${home.path}');
    _appHomeDir = Directory('${home.path}/$appHome');
    final appHomeDir = _appHomeDir!;
    if (!appHomeDir.existsSync()) {
      appHomeDir.createSync();
    }
    final appSettingsFile = File('${appHomeDir.path}/$appSettings');
    if (!appSettingsFile.existsSync()) {
      appSettingsFile.createSync();
      appSettingsFile.writeAsStringSync(jsonEncode(Settings().toJson()));
    }
    final appSettingsJson = jsonDecode(appSettingsFile.readAsStringSync());
    _settings = Settings.fromJson(appSettingsJson);
    logger.d('loaded settings: ${_settings?.toJson()}');
    _initialized = true;
  }

  Future<void> save(Settings settings) async {
    _settings = settings;
    final appSettingsFile = File('${_appHomeDir!.path}/$appSettings');
    appSettingsFile.writeAsStringSync(jsonEncode(_settings!.toJson()));
  }

  Future<void> createOutputPath(String outputPath) async {
    try {
      final appHomeDir = Directory('${_appHomeDir!.path}/$outputPath');
      if (!appHomeDir.existsSync()) {
        appHomeDir.createSync();
      }
    } catch (e) {
      logger.e('failed to create output path: $e');
    }
  }
}
