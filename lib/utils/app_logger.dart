import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging utility for local development logging.
///
/// Usage:
/// ```dart
/// AppLogger.debug('Debugging information');
/// AppLogger.info('General information');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error occurred', error, stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls for errors
      lineLength: 80, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print emojis for log levels
      printTime: true, // Print timestamp
    ),
    // In debug mode, show all logs. In release, only warnings and errors.
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Debug level: Detailed information for debugging
  /// Only visible in development
  static void debug(String message, [Map<String, dynamic>? extras]) {
    _logger.d(message);
    if (extras != null) {
      _logger.d('Extras: $extras');
    }
  }

  /// Info level: General informational messages
  static void info(String message, [Map<String, dynamic>? extras]) {
    _logger.i(message);
    if (extras != null) {
      _logger.i('Extras: $extras');
    }
  }

  /// Warning level: Warning messages that don't stop execution
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error level: Error messages for exceptions
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (extras != null) {
      _logger.e('Extras: $extras');
    }
  }

  /// Fatal error: Critical errors that crash the app
  static void fatal(
    String message,
    dynamic error,
    StackTrace stackTrace, [
    Map<String, dynamic>? extras,
  ]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    if (extras != null) {
      _logger.f('Extras: $extras');
    }
  }
}
