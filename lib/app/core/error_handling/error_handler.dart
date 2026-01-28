// ARCH-009 FIX: Centralized Error Handling Service
// Provides consistent error handling across the application

import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Error severity levels
enum ErrorSeverity {
  /// Informational - user should be aware but no action needed
  info,

  /// Warning - something might not work as expected
  warning,

  /// Error - operation failed
  error,

  /// Critical - app might be in an inconsistent state
  critical,
}

/// App-specific error types
enum AppErrorType {
  network,
  authentication,
  authorization,
  validation,
  notFound,
  timeout,
  server,
  storage,
  unknown,
}

/// Structured app error
class AppError implements Exception {
  final String message;
  final String? userMessage;
  final AppErrorType type;
  final ErrorSeverity severity;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AppError({
    required this.message,
    this.userMessage,
    this.type = AppErrorType.unknown,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  /// Create from Firebase exception
  factory AppError.fromFirebase(dynamic error, {Map<String, dynamic>? context}) {
    if (error is FirebaseAuthException) {
      return AppError(
        message: error.message ?? 'Authentication error',
        userMessage: _getAuthErrorMessage(error.code),
        type: AppErrorType.authentication,
        severity: ErrorSeverity.error,
        originalError: error,
        context: context,
      );
    }

    if (error is FirebaseException) {
      return AppError(
        message: error.message ?? 'Firebase error',
        userMessage: _getFirebaseErrorMessage(error.code),
        type: _getFirebaseErrorType(error.code),
        severity: ErrorSeverity.error,
        originalError: error,
        context: context,
      );
    }

    return AppError(
      message: error.toString(),
      type: AppErrorType.unknown,
      originalError: error,
      context: context,
    );
  }

  /// Create from network exception
  factory AppError.network(dynamic error, {Map<String, dynamic>? context}) {
    return AppError(
      message: error.toString(),
      userMessage: 'Network error. Please check your connection.',
      type: AppErrorType.network,
      severity: ErrorSeverity.error,
      originalError: error,
      context: context,
    );
  }

  /// Create validation error
  factory AppError.validation(String message, {Map<String, dynamic>? context}) {
    return AppError(
      message: message,
      userMessage: message,
      type: AppErrorType.validation,
      severity: ErrorSeverity.warning,
      context: context,
    );
  }

  /// Create not found error
  factory AppError.notFound(String entity, {Map<String, dynamic>? context}) {
    return AppError(
      message: '$entity not found',
      userMessage: '$entity not found',
      type: AppErrorType.notFound,
      severity: ErrorSeverity.warning,
      context: context,
    );
  }

  /// Create authorization error
  factory AppError.unauthorized(String action, {Map<String, dynamic>? context}) {
    return AppError(
      message: 'Unauthorized to $action',
      userMessage: 'You do not have permission to $action',
      type: AppErrorType.authorization,
      severity: ErrorSeverity.error,
      context: context,
    );
  }

  @override
  String toString() => 'AppError($type): $message';

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'cancelled':
        return 'Operation was cancelled';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  static AppErrorType _getFirebaseErrorType(String code) {
    switch (code) {
      case 'permission-denied':
        return AppErrorType.authorization;
      case 'unavailable':
        return AppErrorType.server;
      case 'deadline-exceeded':
        return AppErrorType.timeout;
      case 'not-found':
        return AppErrorType.notFound;
      default:
        return AppErrorType.unknown;
    }
  }
}

/// Centralized error handler service
class ErrorHandler {
  // Singleton pattern
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Stream controller for error events
  final _errorStreamController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorStreamController.stream;

  /// Error log for debugging
  final List<AppError> _errorLog = [];
  List<AppError> get errorLog => List.unmodifiable(_errorLog);

  /// Maximum errors to keep in log
  static const int _maxLogSize = 100;

  /// Handle an error with optional user notification
  void handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = true,
    ErrorSeverity? overrideSeverity,
  }) {
    final appError = _convertToAppError(error, stackTrace, context);

    // Override severity if specified
    final finalError = overrideSeverity != null
        ? AppError(
            message: appError.message,
            userMessage: appError.userMessage,
            type: appError.type,
            severity: overrideSeverity,
            originalError: appError.originalError,
            stackTrace: appError.stackTrace,
            context: appError.context,
          )
        : appError;

    // Log the error
    _logError(finalError);

    // Emit to stream
    _errorStreamController.add(finalError);

    // Show to user if requested
    if (showToUser) {
      _showErrorToUser(finalError);
    }

    // Log to console in debug mode
    if (kDebugMode) {
      print('ErrorHandler: ${finalError.type} - ${finalError.message}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  /// Handle error and rethrow as AppError
  Never handleAndThrow(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    handle(error, stackTrace: stackTrace, context: context, showToUser: false);
    final appError = _convertToAppError(error, stackTrace, context);
    throw appError;
  }

  /// Wrap an async operation with error handling
  Future<T?> wrap<T>(
    Future<T> Function() operation, {
    String? context,
    bool showToUser = true,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      handle(e, stackTrace: stackTrace, context: context, showToUser: showToUser);
      return defaultValue;
    }
  }

  /// Wrap a sync operation with error handling
  T? wrapSync<T>(
    T Function() operation, {
    String? context,
    bool showToUser = true,
    T? defaultValue,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      handle(e, stackTrace: stackTrace, context: context, showToUser: showToUser);
      return defaultValue;
    }
  }

  /// Show success message to user
  void showSuccess(String message) {
    BotToast.showText(
      text: message,
      contentColor: ColorsManager.success,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  /// Show info message to user
  void showInfo(String message) {
    BotToast.showText(
      text: message,
      contentColor: ColorsManager.primary,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  /// Show warning message to user
  void showWarning(String message) {
    BotToast.showText(
      text: message,
      contentColor: Colors.orange,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// Clear error log
  void clearLog() {
    _errorLog.clear();
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }

  AppError _convertToAppError(dynamic error, StackTrace? stackTrace, String? context) {
    if (error is AppError) {
      return error;
    }

    if (error is FirebaseException || error is FirebaseAuthException) {
      return AppError.fromFirebase(error, context: context != null ? {'context': context} : null);
    }

    if (error is TimeoutException) {
      return AppError(
        message: error.toString(),
        userMessage: 'Operation timed out. Please try again.',
        type: AppErrorType.timeout,
        severity: ErrorSeverity.warning,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      message: error.toString(),
      userMessage: 'An error occurred. Please try again.',
      type: AppErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
      context: context != null ? {'context': context} : null,
    );
  }

  void _logError(AppError error) {
    _errorLog.add(error);

    // Keep log size manageable
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }
  }

  void _showErrorToUser(AppError error) {
    final message = error.userMessage ?? error.message;

    switch (error.severity) {
      case ErrorSeverity.info:
        showInfo(message);
        break;
      case ErrorSeverity.warning:
        showWarning(message);
        break;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        BotToast.showText(
          text: message,
          contentColor: ColorsManager.error,
          textStyle: const TextStyle(color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        break;
    }
  }
}

/// Global error handler instance
final errorHandler = ErrorHandler();

/// Extension for easy error handling on futures
extension ErrorHandlingFutureExtension<T> on Future<T> {
  /// Handle errors and return null on failure
  Future<T?> handleErrors({
    String? context,
    bool showToUser = true,
    T? defaultValue,
  }) {
    return errorHandler.wrap(
      () => this,
      context: context,
      showToUser: showToUser,
      defaultValue: defaultValue,
    );
  }
}
