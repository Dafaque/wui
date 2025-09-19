import 'package:flutter/material.dart';
import 'package:whisperui/models/processing_file.dart';
import 'package:whisperui/widgets/format_display.dart';

class FileCard extends StatelessWidget {
  final ProcessingFile file;
  final VoidCallback onOpenDirectory;
  final VoidCallback onEditPath;
  final VoidCallback onOpenLog;
  final VoidCallback onRemove;

  const FileCard({
    super.key,
    required this.file,
    required this.onOpenDirectory,
    required this.onEditPath,
    required this.onOpenLog,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с именем файла и кнопками
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Remove from queue',
                ),
              ],
            ),

            // Статус
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(file.status),
                  size: 16,
                  color: _getStatusColor(file.status),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(file.status),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(file.status),
                  ),
                ),
                if (file.hasError && file.errorMessage != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),

            // Время добавления
            const SizedBox(height: 4),
            Text(
              'Added: ${_formatDateTime(file.addedAt)}',
              style: TextStyle(
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
                  onPressed: onOpenDirectory,
                  icon: const Icon(Icons.folder_open, size: 16),
                  tooltip: 'Open output directory',
                ),
                IconButton(
                  onPressed: onEditPath,
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'Edit output path',
                ),
              ],
            ),

            // Форматы файлов
            const SizedBox(height: 4),
            const FormatDisplay(),

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
                    onPressed: onOpenLog,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (file.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Completed: ${_formatDateTime(file.completedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
        return Icons.schedule;
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
        return Colors.orange;
      case ProcessingStatus.processing:
        return Colors.blue;
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
        return 'Processing...';
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
}
