/// Structured logging for Kamera Pro.
/// Wraps the logger package with domain-specific log channels.
library;

import 'package:logger/logger.dart';

/// Application-wide logger singleton.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
    level: Level.debug,
  );

  // ─────────────────────────── Channels ───────────────────────────

  /// Logs camera hardware events (init, capability detection, errors).
  void camera(String message, {Object? error, StackTrace? stackTrace}) =>
      error != null
          ? _logger.e('[CAMERA] $message', error: error, stackTrace: stackTrace)
          : _logger.i('[CAMERA] $message');

  /// Logs voice / speech events.
  void voice(String message) => _logger.i('[VOICE] $message');

  /// Logs AI interpretation events.
  void ai(String message, {Object? error, StackTrace? stackTrace}) =>
      error != null
          ? _logger.e('[AI] $message', error: error, stackTrace: stackTrace)
          : _logger.i('[AI] $message');

  /// Logs parameter validation events.
  void params(String message) => _logger.d('[PARAMS] $message');

  /// Logs capture events.
  void capture(String message, {Object? error, StackTrace? stackTrace}) =>
      error != null
          ? _logger.e('[CAPTURE] $message', error: error, stackTrace: stackTrace)
          : _logger.i('[CAPTURE] $message');

  /// Logs general app lifecycle events.
  void app(String message) => _logger.i('[APP] $message');

  /// Logs debug/development information.
  void debug(String message) => _logger.d('[DEBUG] $message');

  /// Logs warnings.
  void warning(String message) => _logger.w('[WARN] $message');

  /// Logs errors that do not fit a specific channel.
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e('[ERROR] $message', error: error, stackTrace: stackTrace);
}

/// Convenience global accessor.
final log = AppLogger.instance;
