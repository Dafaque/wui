import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:whisperui/singletons/logger.dart';

class Exec {
  Process? _process;
  bool _isRunning = false;
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  StreamSubscription<int>? _exitCodeSubscription;

  bool get isRunning => _isRunning;
  Stream<String> get stdout => _stdoutController.stream;
  Stream<String> get stderr => _stderrController.stream;

  /// Безопасное декодирование байтов в строку с поддержкой разных кодировок
  String _decodeBytes(List<int> bytes) {
    try {
      // Сначала пробуем UTF-8
      return utf8.decode(bytes, allowMalformed: false);
    } catch (e) {
      try {
        // Если не получилось, пробуем UTF-8 с разрешением некорректных символов
        return utf8.decode(bytes, allowMalformed: true);
      } catch (e) {
        try {
          // Если и это не сработало, пробуем Latin-1
          return latin1.decode(bytes);
        } catch (e) {
          // В крайнем случае используем String.fromCharCodes
          return String.fromCharCodes(bytes);
        }
      }
    }
  }

  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (_isRunning) {
      throw Exception('Process is already running');
    }

    _isRunning = true;

    try {
      logger.d('Executing: $executable ${arguments.join(' ')}');

      // Отменяем предыдущие подписки если они есть
      _stdoutSubscription?.cancel();
      _stderrSubscription?.cancel();
      _exitCodeSubscription?.cancel();

      _process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
      );

      // Слушаем stdout и отправляем в контроллер
      _stdoutSubscription = _process!.stdout.listen(
        (data) {
          final output = _decodeBytes(data).trim();
          if (output.isNotEmpty) {
            _stdoutController.add(output);
            logger.i('STDOUT: $output');
          }
        },
        onError: (error) {
          _stdoutController.add('STDOUT error: $error');
          logger.e('STDOUT error: $error');
        },
      );

      // Слушаем stderr и отправляем в контроллер
      _stderrSubscription = _process!.stderr.listen(
        (data) {
          final output = _decodeBytes(data).trim();
          if (output.isNotEmpty) {
            _stderrController.add(output);
            logger.e('STDERR: $output');
          }
        },
        onError: (error) {
          _stderrController.add('STDERR error: $error');
          logger.e('STDERR error: $error');
        },
      );

      // Подписываемся на завершение процесса
      _exitCodeSubscription = _process!.exitCode.asStream().listen(
        (exitCode) {
          logger.d('Process completed with exit code: $exitCode');
          _isRunning = false;
        },
        onError: (error) {
          logger.e('Process exit error: $error');
          _isRunning = false;
        },
      );

      final exitCode = await _process!.exitCode;
      logger.d('Process completed with exit code: $exitCode');

      return exitCode;
    } catch (e) {
      logger.e('Process execution failed: $e');
      rethrow;
    } finally {
      _isRunning = false;
      _process = null;
      // Отменяем подписки при завершении процесса
      _stdoutSubscription?.cancel();
      _stderrSubscription?.cancel();
      _exitCodeSubscription?.cancel();
    }
  }

  void stop() {
    if (_process != null && _isRunning) {
      logger.d('Stopping process...');
      _process!.kill();
      _isRunning = false;
      _process = null;
    }
    // Отменяем подписки при остановке
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _exitCodeSubscription?.cancel();
  }

  void dispose() {
    stop();
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _exitCodeSubscription?.cancel();
    _stdoutController.close();
    _stderrController.close();
  }
}
