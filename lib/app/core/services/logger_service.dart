import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for categorizing log messages
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  final int value;
  const LogLevel(this.value);
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String? context;
  final Map<String, dynamic>? data;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.context,
    this.data,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (context != null) 'context': context,
        if (data != null) 'data': data,
        if (error != null) 'error': error.toString(),
      };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${_getLevelEmoji(level)} ${timestamp.toIso8601String()}');
    if (context != null) buffer.write(' [$context]');
    buffer.write(': $message');
    return buffer.toString();
  }

  static String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return '📘';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔥';
    }
  }
}

/// Professional logging service with levels and remote capability
///
/// Usage:
/// ```dart
/// LoggerService.instance.info('User logged in', context: 'AuthController');
/// LoggerService.instance.debug('Data loaded', data: {'count': 10});
/// LoggerService.instance.logError('Failed to save', error: e, stackTrace: st);
/// ```
class LoggerService {
  static final LoggerService instance = LoggerService._();
  LoggerService._();

  // Configuration
  bool enableConsoleLogging = true;
  bool enableRemoteLogging = false;
  LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  // Log storage
  final List<LogEntry> _logQueue = [];
  final int _maxQueueSize = 100;
  Timer? _batchTimer;

  // Statistics
  int _totalLogs = 0;
  int _errorCount = 0;
  int _warningCount = 0;

  /// Initialize the logger service
  void initialize({
    LogLevel? minLevel,
    bool? console,
    bool? remote,
  }) {
    minimumLevel = minLevel ?? (kDebugMode ? LogLevel.debug : LogLevel.info);
    enableConsoleLogging = console ?? true;
    enableRemoteLogging = remote ?? false;

    // Start batch timer for remote logging
    if (enableRemoteLogging) {
      _batchTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _sendLogBatch(),
      );
    }

    info('LoggerService initialized', context: 'LoggerService', data: {
      'minLevel': minimumLevel.name,
      'console': enableConsoleLogging,
      'remote': enableRemoteLogging,
    });
  }

  /// Log debug message (development only)
  void debug(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.debug, message, context: context, data: data);
  }

  /// Log info message
  void info(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.info, message, context: context, data: data);
  }

  /// Log warning message
  void warning(
    String message, {
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.warning, message, context: context, data: data);
    _warningCount++;
  }

  /// Log error with optional error object and stack trace
  void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
    _errorCount++;

    // In production, send critical errors immediately
    if (!kDebugMode && enableRemoteLogging) {
      _sendLogImmediately(LogEntry(
        level: LogLevel.error,
        message: message,
        timestamp: DateTime.now(),
        context: context,
        data: data,
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Log critical error (always sent immediately)
  void critical(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.critical,
      message,
      context: context,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
    _errorCount++;

    // Always send critical errors immediately
    if (enableRemoteLogging) {
      _sendLogImmediately(LogEntry(
        level: LogLevel.critical,
        message: message,
        timestamp: DateTime.now(),
        context: context,
        data: data,
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? context,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Check minimum level
    if (level.value < minimumLevel.value) return;

    final entry = LogEntry(
      level: level,
      message: message,
      context: context,
      data: data,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _totalLogs++;

    // Console logging
    if (enableConsoleLogging) {
      _printToConsole(entry);
    }

    // Queue for remote logging
    if (enableRemoteLogging) {
      _addToQueue(entry);
    }
  }

  /// Print log to console with formatting
  void _printToConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final emoji = LogEntry._getLevelEmoji(entry.level);
    final context = entry.context != null ? ' [${entry.context}]' : '';

    // Use developer.log for better Flutter DevTools integration
    developer.log(
      entry.message,
      time: entry.timestamp,
      level: entry.level.value,
      name: entry.context ?? 'App',
      error: entry.error,
      stackTrace: entry.stackTrace,
    );

    // Also print to console for immediate visibility
    debugPrint('$emoji $timestamp$context: ${entry.message}');

    if (entry.data != null) {
      debugPrint('  📊 Data: ${entry.data}');
    }

    if (entry.error != null) {
      debugPrint('  ⚠️ Error: ${entry.error}');
    }

    if (entry.stackTrace != null && entry.level.value >= LogLevel.error.value) {
      debugPrint('  📍 Stack: ${entry.stackTrace}');
    }
  }

  /// Add log to queue for batch sending
  void _addToQueue(LogEntry entry) {
    _logQueue.add(entry);

    // Prevent queue from growing too large
    if (_logQueue.length > _maxQueueSize) {
      _logQueue.removeAt(0); // Remove oldest
    }
  }

  /// Send log batch to remote service
  Future<void> _sendLogBatch() async {
    if (_logQueue.isEmpty) return;

    try {
      // TODO: Implement remote logging service integration
      // Example: Firebase Analytics, Crashlytics, or custom backend
      // await _analyticsService.logBatch(_logQueue.map((e) => e.toJson()).toList());

      debug('Sent log batch', context: 'LoggerService', data: {
        'count': _logQueue.length,
      });

      _logQueue.clear();
    } catch (e) {
      debugPrint('Failed to send log batch: $e');
    }
  }

  /// Send single log immediately (for critical errors)
  Future<void> _sendLogImmediately(LogEntry entry) async {
    try {
      // TODO: Implement immediate remote logging
      // Example: Firebase Crashlytics recordError
      // await FirebaseCrashlytics.instance.recordError(
      //   entry.error,
      //   entry.stackTrace,
      //   reason: entry.message,
      //   fatal: entry.level == LogLevel.critical,
      // );

      debug('Sent critical log immediately', context: 'LoggerService');
    } catch (e) {
      debugPrint('Failed to send critical log: $e');
    }
  }

  /// Get logging statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalLogs': _totalLogs,
      'errorCount': _errorCount,
      'warningCount': _warningCount,
      'queueSize': _logQueue.length,
      'minLevel': minimumLevel.name,
    };
  }

  /// Clear all logs from queue
  void clearQueue() {
    _logQueue.clear();
    debug('Log queue cleared', context: 'LoggerService');
  }

  /// Export logs for debugging
  List<LogEntry> exportLogs() {
    return List.unmodifiable(_logQueue);
  }

  /// Dispose the logger service
  void dispose() {
    _batchTimer?.cancel();
    _sendLogBatch(); // Send remaining logs
    info('LoggerService disposed', context: 'LoggerService');
  }
}
