import 'package:flutter/material.dart';
import 'package:whisperui/utils/format_utils.dart';
import 'package:whisperui/services/settings.dart';

class FormatDisplay extends StatefulWidget {
  final bool compact;
  final int maxFormats;

  const FormatDisplay({super.key, this.compact = false, this.maxFormats = 3});

  @override
  State<FormatDisplay> createState() => _FormatDisplayState();
}

class _FormatDisplayState extends State<FormatDisplay> {
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
    final formats = FormatUtils.getEnabledOutputFormats();

    if (formats.isEmpty) return const SizedBox.shrink();

    if (widget.compact) {
      return _buildCompactDisplay(context, formats);
    } else {
      return _buildFullDisplay(context, formats);
    }
  }

  Widget _buildCompactDisplay(
    BuildContext context,
    List<Map<String, dynamic>> formats,
  ) {
    return Container(
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
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          ...formats
              .take(widget.maxFormats)
              .map(
                (format) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Tooltip(
                    message: '${format['name']} (.${format['extension']})',
                    child: Icon(
                      format['icon'] as IconData,
                      size: 16,
                      color: format['color'] as Color,
                    ),
                  ),
                ),
              ),
          if (formats.length > widget.maxFormats) ...[
            const SizedBox(width: 2),
            Text(
              '+${formats.length - widget.maxFormats}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullDisplay(
    BuildContext context,
    List<Map<String, dynamic>> formats,
  ) {
    return Row(
      children: [
        const Text('Formats: '),
        const SizedBox(width: 4),
        ...formats.map(
          (format) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: '${format['name']} format',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (format['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (format['color'] as Color).withOpacity(0.3),
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
    );
  }
}
