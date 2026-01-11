import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// QUALITY-005: Debug Logger Utility
/// Provides a consistent logging interface to replace print statements
/// Only logs in debug mode to prevent sensitive data exposure

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._();
  static DebugLogger get instance => _instance;

  DebugLogger._();

  final LoggerService _logger = LoggerService.instance;

  /// Enable/disable debug logging globally
  static bool enabled = kDebugMode;

  /// Log a debug message (replaces print())
  void log(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final formattedTag = tag ?? 'DEBUG';
    developer.log(
      message,
      name: formattedTag,
      error: error,
      stackTrace: stackTrace,
    );

    _logger.debug(message, context: formattedTag);
  }

  /// Log an info message
  void info(String message, {String? tag}) {
    if (!enabled) return;
    _logger.info(message, context: tag ?? 'INFO');
  }

  /// Log a warning message
  void warning(String message, {String? tag, Object? error}) {
    _logger.warning(message, context: tag ?? 'WARNING');
    if (error != null && kDebugMode) {
      developer.log('Warning: $message', name: tag ?? 'WARNING', error: error);
    }
  }

  /// Log an error message
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.logError(message, error: error, context: tag ?? 'ERROR');
    if (kDebugMode) {
      developer.log(
        'Error: $message',
        name: tag ?? 'ERROR',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log with a specific level
  void logLevel(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
  }) {
    switch (level) {
      case LogLevel.debug:
        log(message, tag: tag);
        break;
      case LogLevel.info:
        info(message, tag: tag);
        break;
      case LogLevel.warning:
        warning(message, tag: tag, error: error);
        break;
      case LogLevel.error:
        this.error(message, tag: tag, error: error);
        break;
    }
  }

  /// Conditional log - only logs if condition is true
  void logIf(bool condition, String message, {String? tag}) {
    if (condition) {
      log(message, tag: tag);
    }
  }

  /// Log with data map
  void logData(String message, Map<String, dynamic> data, {String? tag}) {
    if (!enabled) return;
    _logger.debug(message, context: tag ?? 'DEBUG', data: data);
  }

  /// Performance timing log
  Stopwatch startTimer(String operationName) {
    final stopwatch = Stopwatch()..start();
    log('⏱️ Started: $operationName', tag: 'PERF');
    return stopwatch;
  }

  void endTimer(Stopwatch stopwatch, String operationName) {
    stopwatch.stop();
    log(
      '⏱️ Completed: $operationName in ${stopwatch.elapsedMilliseconds}ms',
      tag: 'PERF',
    );
  }

  /// Scope-based timing
  Future<T> timed<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = startTimer(operationName);
    try {
      return await operation();
    } finally {
      endTimer(stopwatch, operationName);
    }
  }

  /// Sync scope-based timing
  T timedSync<T>(String operationName, T Function() operation) {
    final stopwatch = startTimer(operationName);
    try {
      return operation();
    } finally {
      endTimer(stopwatch, operationName);
    }
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Global debug log function (replacement for print)
void debugLog(
  String message, {
  String? tag,
  Object? error,
  StackTrace? stackTrace,
}) {
  DebugLogger.instance.log(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Global info log function
void infoLog(String message, {String? tag}) {
  DebugLogger.instance.info(message, tag: tag);
}

/// Global warning log function
void warnLog(String message, {String? tag, Object? error}) {
  DebugLogger.instance.warning(message, tag: tag, error: error);
}

/// Global error log function
void errorLog(
  String message, {
  String? tag,
  Object? error,
  StackTrace? stackTrace,
}) {
  DebugLogger.instance.error(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Extension for easier logging on any object
extension DebugLogging on Object {
  void logDebug({String? tag}) {
    debugLog(toString(), tag: tag);
  }

  void logInfo({String? tag}) {
    infoLog(toString(), tag: tag);
  }

  void logWarning({String? tag}) {
    warnLog(toString(), tag: tag);
  }

  void logError({String? tag, StackTrace? stackTrace}) {
    errorLog(toString(), tag: tag, stackTrace: stackTrace);
  }
}

/// Mixin for classes that need logging
mixin LoggingMixin {
  String get logTag => runtimeType.toString();

  void logDebug(String message, {Map<String, dynamic>? data}) {
    if (data != null) {
      DebugLogger.instance.logData(message, data, tag: logTag);
    } else {
      DebugLogger.instance.log(message, tag: logTag);
    }
  }

  void logInfo(String message) {
    DebugLogger.instance.info(message, tag: logTag);
  }

  void logWarning(String message, {Object? error}) {
    DebugLogger.instance.warning(message, tag: logTag, error: error);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    DebugLogger.instance.error(
      message,
      tag: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<T> timedOperation<T>(String name, Future<T> Function() operation) {
    return DebugLogger.instance.timed('$logTag.$name', operation);
  }
}

/// Assert with logging
void assertWithLog(bool condition, String message) {
  if (!condition) {
    errorLog('Assertion failed: $message', tag: 'ASSERT');
    assert(condition, message);
  }
}

/// Print replacement that only works in debug mode
void debugPrint(String message) {
  if (kDebugMode) {
    debugLog(message);
  }
}
