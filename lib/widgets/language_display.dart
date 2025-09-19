import 'package:flutter/material.dart';
import 'package:whisperui/utils/format_utils.dart';
import 'package:whisperui/services/settings.dart';

class LanguageDisplay extends StatefulWidget {
  const LanguageDisplay({super.key});

  @override
  State<LanguageDisplay> createState() => _LanguageDisplayState();
}

class _LanguageDisplayState extends State<LanguageDisplay> {
  @override
  void initState() {
    super.initState();
    // Слушаем изменения настроек
    SettingsService.instance().addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance().removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = SettingsService.instance().settings.language;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FormatUtils.getLanguageEmoji(language),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            FormatUtils.getLanguageName(language),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
