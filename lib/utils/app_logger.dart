import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized logging utility that integrates both local development logging
/// and production crash reporting via Firebase Crashlytics.
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

  /// Flag to track if Crashlytics is initialized
  static bool _crashlyticsEnabled = false;

  /// Get whether Crashlytics is enabled
  static bool get isCrashlyticsEnabled => _crashlyticsEnabled;

  /// Initialize Crashlytics integration
  /// Call this after Firebase.initializeApp()
  /// If Firebase is not initialized, this will disable Crashlytics features gracefully
  static Future<void> initCrashlytics() async {
    try {
      // On web, Firebase Crashlytics has limited support
      // Just check if we can access the instance without errors
      if (kIsWeb) {
        // Crashlytics is not fully supported on web platform
        _crashlyticsEnabled = false;
        _logger.w(
          'Firebase Crashlytics not available on web - logging to console only',
        );
        return;
      }

      // For mobile platforms, try to initialize Crashlytics
      // Just accessing the instance is enough to verify it's available
      FirebaseCrashlytics.instance;

      // Set enabled flag to true if we successfully accessed the instance
      _crashlyticsEnabled = true;
      _logger.i('Firebase Crashlytics initialized successfully');
    } catch (e, stackTrace) {
      _crashlyticsEnabled = false;
      _logger.w('Firebase Crashlytics not available - logging to console only');
      _logger.d('Firebase error: $e\n$stackTrace');
    }
  }

  /// Debug level: Detailed information for debugging
  /// Only visible in development, not sent to Crashlytics
  static void debug(String message, [Map<String, dynamic>? extras]) {
    _logger.d(message);
    if (extras != null) {
      _logger.d('Extras: $extras');
    }
  }

  /// Info level: General informational messages
  /// Sent to Crashlytics as custom logs for better crash context
  static void info(String message, [Map<String, dynamic>? extras]) {
    _logger.i(message);

    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.log('INFO: $message');
        if (extras != null) {
          for (var entry in extras.entries) {
            FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
          }
        }
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to log to Crashlytics: $e');
      }
    }
  }

  /// Warning level: Warning messages that don't stop execution
  /// Sent to Crashlytics as non-fatal issues
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);

    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.log('WARNING: $message');
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: message,
            fatal: false,
          );
        }
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to log warning to Crashlytics: $e');
      }
    }
  }

  /// Error level: Error messages for exceptions
  /// Automatically recorded in Crashlytics as non-fatal errors
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.log('ERROR: $message');

        // Set custom keys for better context
        if (extras != null) {
          for (var entry in extras.entries) {
            FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
          }
        }

        // Record the error in Crashlytics
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace ?? StackTrace.current,
            reason: message,
            fatal: false,
          );
        }
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to log error to Crashlytics: $e');
      }
    }
  }

  /// Fatal error: Critical errors that crash the app
  /// Recorded in Crashlytics as fatal crashes
  static void fatal(
    String message,
    dynamic error,
    StackTrace stackTrace, [
    Map<String, dynamic>? extras,
  ]) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.log('FATAL: $message');

        if (extras != null) {
          for (var entry in extras.entries) {
            FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
          }
        }

        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: true,
        );
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to log fatal error to Crashlytics: $e');
      }
    }
  }

  /// Set user identifier for crash reports
  /// Useful for tracking issues per user (ensure HIPAA compliance!)
  static void setUserId(String userId) {
    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.setUserIdentifier(userId);
        info('User ID set: $userId');
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to set user ID in Crashlytics: $e');
      }
    }
  }

  /// Set custom key-value pairs for crash context
  static void setCustomKey(String key, dynamic value) {
    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.setCustomKey(key, value);
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to set custom key in Crashlytics: $e');
      }
    }
  }

  /// Clear user identifier (e.g., on logout)
  static void clearUserId() {
    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.setUserIdentifier('');
        info('User ID cleared');
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to clear user ID in Crashlytics: $e');
      }
    }
  }

  /// Record a custom event/breadcrumb for debugging
  static void recordBreadcrumb(String message, {Map<String, dynamic>? data}) {
    if (_crashlyticsEnabled) {
      try {
        var logMessage = message;
        if (data != null) {
          logMessage += ' | ${data.toString()}';
        }
        FirebaseCrashlytics.instance.log(logMessage);
      } catch (e) {
        // Firebase not available, continue with console logging only
        debug('Failed to record breadcrumb in Crashlytics: $e');
      }
    }
    debug(message, data);
  }
}
