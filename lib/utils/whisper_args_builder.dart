import 'package:whisperui/services/settings.dart';
import 'package:whisperui/models/processing_file.dart';

/// Utility class for building Whisper command line arguments
class WhisperArgsBuilder {
  /// Builds command line arguments for Whisper based on settings and processing file
  static List<String> buildWhisperArgs(ProcessingFile processingFile) {
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
}
