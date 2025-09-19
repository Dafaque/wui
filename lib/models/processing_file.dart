enum ProcessingStatus { queued, processing, completed, error, cancelled }

class ProcessingFile {
  final String id;
  final String filePath;
  final String fileName;
  final String? customOutputPath;
  final ProcessingStatus status;
  final String? errorMessage;
  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  ProcessingFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.customOutputPath,
    this.status = ProcessingStatus.queued,
    this.errorMessage,
    required this.addedAt,
    this.startedAt,
    this.completedAt,
  });

  ProcessingFile copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? customOutputPath,
    ProcessingStatus? status,
    String? errorMessage,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ProcessingFile(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      customOutputPath: customOutputPath ?? this.customOutputPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get outputPath {
    return customOutputPath ??
        '${filePath.substring(0, filePath.lastIndexOf('/'))}/$fileName';
  }

  bool get isCompleted => status == ProcessingStatus.completed;
  bool get isProcessing => status == ProcessingStatus.processing;
  bool get isQueued => status == ProcessingStatus.queued;
  bool get hasError => status == ProcessingStatus.error;
  bool get isCancelled => status == ProcessingStatus.cancelled;
}
