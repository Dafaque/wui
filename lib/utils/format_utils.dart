import 'package:flutter/material.dart';
import 'package:whisperui/services/settings.dart';

class FormatUtils {
  static const Map<String, String> languageEmojis = {
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

  static const Map<String, String> languageNames = {
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

  static String getLanguageEmoji(String languageCode) {
    return languageEmojis[languageCode] ?? '🌐';
  }

  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? 'Unknown';
  }

  static List<Map<String, dynamic>> getEnabledOutputFormats() {
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
