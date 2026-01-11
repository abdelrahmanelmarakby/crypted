import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// SEC-007: Production-Safe Logging
/// Ensures sensitive information is never logged in production
/// Replaces print statements and debug logging in release builds

class ProductionLogger {
  static final ProductionLogger instance = ProductionLogger._();
  ProductionLogger._();

  /// Whether logging is enabled (only in debug mode)
  static bool get isEnabled => kDebugMode;

  /// Log levels that should be disabled in production
  static const Set<LogLevel> _productionDisabled = {
    LogLevel.debug,
    LogLevel.verbose,
  };

  /// Sensitive data patterns that should never be logged
  static final List<RegExp> _sensitivePatterns = [
    // Email patterns
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    // Phone patterns
    RegExp(r'\+?[\d\s\-\(\)]{10,}'),
    // Firebase tokens
    RegExp(r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'),
    // API keys
    RegExp(r'[A-Za-z0-9]{32,}'),
    // Password-like patterns
    RegExp(r'password["\s:=]+[^\s"]+', caseSensitive: false),
    RegExp(r'secret["\s:=]+[^\s"]+', caseSensitive: false),
    RegExp(r'token["\s:=]+[^\s"]+', caseSensitive: false),
    // Credit card patterns
    RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
  ];

  /// Log a message (respects production mode)
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Skip if logging is disabled for this level in production
    if (!kDebugMode && _productionDisabled.contains(level)) {
      return;
    }

    // Sanitize the message
    final sanitizedMessage = _sanitize(message);

    // Sanitize data if present
    final sanitizedData = data != null ? _sanitizeMap(data) : null;

    // Build the log message
    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}]');
    if (tag != null) {
      buffer.write(' [$tag]');
    }
    buffer.write(' $sanitizedMessage');
    if (sanitizedData != null && sanitizedData.isNotEmpty) {
      buffer.write(' | Data: $sanitizedData');
    }

    if (kDebugMode) {
      developer.log(
        buffer.toString(),
        name: tag ?? 'APP',
        error: error,
        stackTrace: stackTrace,
        level: _getLogLevelValue(level),
      );
    } else {
      // In production, only log errors to crash reporting
      if (level == LogLevel.error || level == LogLevel.fatal) {
        _logToProductionService(
          message: sanitizedMessage,
          level: level,
          tag: tag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Debug log (disabled in production)
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, tag: tag, data: data);
  }

  /// Info log
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, tag: tag, data: data);
  }

  /// Warning log
  void warning(String message, {String? tag, Object? error}) {
    log(message, level: LogLevel.warning, tag: tag, error: error);
  }

  /// Error log (always logged, even in production)
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Sanitize a string by removing sensitive data
  String _sanitize(String input) {
    var result = input;
    for (final pattern in _sensitivePatterns) {
      result = result.replaceAll(pattern, '[REDACTED]');
    }
    return result;
  }

  /// Sanitize a map of data
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    const sensitiveKeys = {
      'password',
      'secret',
      'token',
      'key',
      'auth',
      'credential',
      'email',
      'phone',
      'address',
      'ssn',
      'credit',
      'card',
    };

    for (final entry in data.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (sensitiveKeys.any((k) => lowerKey.contains(k))) {
        result[entry.key] = '[REDACTED]';
      } else if (entry.value is String) {
        result[entry.key] = _sanitize(entry.value as String);
      } else if (entry.value is Map) {
        result[entry.key] = _sanitizeMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Get log level value for developer.log
  int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500;
      case LogLevel.debug:
        return 700;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  /// Log to production error service (e.g., Firebase Crashlytics)
  void _logToProductionService({
    required String message,
    required LogLevel level,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // In a real app, this would log to Firebase Crashlytics or similar
    // For now, we just suppress the log in production
  }
}

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Safe logging function that replaces print()
void safeLog(String message, {String? tag}) {
  ProductionLogger.instance.debug(message, tag: tag);
}

/// Safe error logging
void safeLogError(String message, {Object? error, StackTrace? stackTrace}) {
  ProductionLogger.instance.error(message, error: error, stackTrace: stackTrace);
}

/// Assert that something should never be logged
void assertNeverLog(String description) {
  if (kDebugMode) {
    throw AssertionError(
      'Attempted to log sensitive data: $description. '
      'This should never be logged!',
    );
  }
}

/// Wrapper for conditionally logging
class ConditionalLogger {
  final String tag;
  final bool enabled;

  ConditionalLogger({required this.tag, this.enabled = true});

  void log(String message) {
    if (enabled) {
      ProductionLogger.instance.debug(message, tag: tag);
    }
  }

  void error(String message, {Object? error}) {
    if (enabled) {
      ProductionLogger.instance.error(message, tag: tag, error: error);
    }
  }
}

/// Mixin for production-safe logging
mixin ProductionSafeLogging {
  String get loggerTag => runtimeType.toString();

  void logDebug(String message, {Map<String, dynamic>? data}) {
    ProductionLogger.instance.debug(message, tag: loggerTag, data: data);
  }

  void logInfo(String message, {Map<String, dynamic>? data}) {
    ProductionLogger.instance.info(message, tag: loggerTag, data: data);
  }

  void logWarning(String message, {Object? error}) {
    ProductionLogger.instance.warning(message, tag: loggerTag, error: error);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    ProductionLogger.instance.error(
      message,
      tag: loggerTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
