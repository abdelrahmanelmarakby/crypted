/// Error Recovery Utilities for Settings
///
/// Provides error classification, recovery strategies, and user-friendly
/// error messages for settings operations.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Types of recoverable errors
enum SettingsErrorType {
  /// Network connectivity issues
  network,

  /// Server temporarily unavailable
  serverUnavailable,

  /// Authentication expired
  authExpired,

  /// Permission denied
  permissionDenied,

  /// Data conflict (concurrent modification)
  conflict,

  /// Validation failed
  validation,

  /// Storage quota exceeded
  quotaExceeded,

  /// Unknown/unrecoverable error
  unknown,
}

/// Severity of the error
enum ErrorSeverity {
  /// Temporary issue, will likely resolve on retry
  transient,

  /// Requires user action to resolve
  actionRequired,

  /// Critical error, needs support
  critical,
}

/// Classified settings error with recovery options
class SettingsError {
  final SettingsErrorType type;
  final ErrorSeverity severity;
  final String technicalMessage;
  final String userMessage;
  final String? recoveryAction;
  final bool canRetry;
  final Duration? retryAfter;
  final dynamic originalError;

  const SettingsError({
    required this.type,
    required this.severity,
    required this.technicalMessage,
    required this.userMessage,
    this.recoveryAction,
    this.canRetry = false,
    this.retryAfter,
    this.originalError,
  });

  /// Log this error
  void log() {
    developer.log(
      'Settings error: $technicalMessage',
      name: 'SettingsError',
      error: originalError,
    );
  }
}

/// Error classifier for settings operations
class SettingsErrorClassifier {
  /// Classify an exception into a SettingsError
  static SettingsError classify(dynamic error, {String? context}) {
    final contextPrefix = context != null ? '[$context] ' : '';

    // Network errors
    if (error is SocketException || error is TimeoutException) {
      return SettingsError(
        type: SettingsErrorType.network,
        severity: ErrorSeverity.transient,
        technicalMessage: '$contextPrefix${error.toString()}',
        userMessage: 'Unable to connect. Please check your internet connection.',
        recoveryAction: 'Check your connection and try again',
        canRetry: true,
        retryAfter: const Duration(seconds: 2),
        originalError: error,
      );
    }

    // Firebase errors
    if (error is FirebaseException) {
      return _classifyFirebaseError(error, contextPrefix);
    }

    // Validation errors
    if (error is FormatException || error is ArgumentError) {
      return SettingsError(
        type: SettingsErrorType.validation,
        severity: ErrorSeverity.actionRequired,
        technicalMessage: '$contextPrefix${error.toString()}',
        userMessage: 'Invalid data format. Please check your input.',
        recoveryAction: 'Review and correct the entered values',
        canRetry: false,
        originalError: error,
      );
    }

    // State errors
    if (error is StateError) {
      return SettingsError(
        type: SettingsErrorType.unknown,
        severity: ErrorSeverity.critical,
        technicalMessage: '$contextPrefix${error.toString()}',
        userMessage: 'An unexpected error occurred. Please restart the app.',
        recoveryAction: 'Restart the application',
        canRetry: false,
        originalError: error,
      );
    }

    // Unknown errors
    return SettingsError(
      type: SettingsErrorType.unknown,
      severity: ErrorSeverity.critical,
      technicalMessage: '$contextPrefix${error.toString()}',
      userMessage: 'Something went wrong. Please try again later.',
      recoveryAction: 'Try again or contact support',
      canRetry: true,
      retryAfter: const Duration(seconds: 5),
      originalError: error,
    );
  }

  static SettingsError _classifyFirebaseError(
    FirebaseException error,
    String contextPrefix,
  ) {
    switch (error.code) {
      case 'unavailable':
        return SettingsError(
          type: SettingsErrorType.serverUnavailable,
          severity: ErrorSeverity.transient,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'Service temporarily unavailable. Retrying...',
          recoveryAction: 'Wait a moment and try again',
          canRetry: true,
          retryAfter: const Duration(seconds: 3),
          originalError: error,
        );

      case 'permission-denied':
        return SettingsError(
          type: SettingsErrorType.permissionDenied,
          severity: ErrorSeverity.actionRequired,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'You don\'t have permission to perform this action.',
          recoveryAction: 'Sign in again or contact support',
          canRetry: false,
          originalError: error,
        );

      case 'unauthenticated':
        return SettingsError(
          type: SettingsErrorType.authExpired,
          severity: ErrorSeverity.actionRequired,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'Your session has expired. Please sign in again.',
          recoveryAction: 'Sign in to continue',
          canRetry: false,
          originalError: error,
        );

      case 'aborted':
      case 'failed-precondition':
        return SettingsError(
          type: SettingsErrorType.conflict,
          severity: ErrorSeverity.transient,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'Settings were modified elsewhere. Refreshing...',
          recoveryAction: 'Your changes will be merged automatically',
          canRetry: true,
          retryAfter: const Duration(seconds: 1),
          originalError: error,
        );

      case 'resource-exhausted':
        return SettingsError(
          type: SettingsErrorType.quotaExceeded,
          severity: ErrorSeverity.actionRequired,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'Storage limit reached. Please remove some items.',
          recoveryAction: 'Free up space by removing unused settings',
          canRetry: false,
          originalError: error,
        );

      case 'not-found':
        return SettingsError(
          type: SettingsErrorType.unknown,
          severity: ErrorSeverity.transient,
          technicalMessage: '$contextPrefix${error.message}',
          userMessage: 'Settings not found. Creating new settings...',
          recoveryAction: 'Settings will be recreated automatically',
          canRetry: true,
          originalError: error,
        );

      default:
        return SettingsError(
          type: SettingsErrorType.unknown,
          severity: ErrorSeverity.critical,
          technicalMessage: '$contextPrefix${error.code}: ${error.message}',
          userMessage: 'An error occurred. Please try again.',
          recoveryAction: 'Try again or contact support',
          canRetry: true,
          retryAfter: const Duration(seconds: 3),
          originalError: error,
        );
    }
  }
}

/// Error recovery handler with automatic retry and user notification
class SettingsErrorRecovery extends GetxService {
  static SettingsErrorRecovery get instance => Get.find();

  // Currently active errors
  final RxList<SettingsError> activeErrors = <SettingsError>[].obs;

  // Error history
  final RxList<SettingsError> errorHistory = <SettingsError>[].obs;

  // Configuration
  final int maxActiveErrors;
  final int maxHistorySize;

  // Callbacks
  void Function(SettingsError)? onError;
  void Function(SettingsError)? onRecovery;
  void Function()? onAuthRequired;

  SettingsErrorRecovery({
    this.maxActiveErrors = 5,
    this.maxHistorySize = 20,
  });

  /// Handle an error with automatic classification and recovery
  Future<T?> handleError<T>({
    required Future<T> Function() operation,
    required String context,
    T? fallbackValue,
    int maxRetries = 3,
    bool showUserError = true,
  }) async {
    int attempts = 0;
    SettingsError? lastError;

    while (attempts < maxRetries) {
      try {
        final result = await operation();

        // Clear any previous errors for this context
        activeErrors.removeWhere(
          (e) => e.technicalMessage.startsWith('[$context]'),
        );

        return result;
      } catch (e) {
        attempts++;
        lastError = SettingsErrorClassifier.classify(e, context: context);
        lastError.log();

        // Check if we should retry
        if (!lastError.canRetry || attempts >= maxRetries) {
          break;
        }

        // Wait before retry
        if (lastError.retryAfter != null) {
          await Future.delayed(lastError.retryAfter!);
        }
      }
    }

    // Add to active errors
    if (lastError != null) {
      _addActiveError(lastError);
      _addToHistory(lastError);
      onError?.call(lastError);

      // Handle special cases
      if (lastError.type == SettingsErrorType.authExpired) {
        onAuthRequired?.call();
      }

      // Show user error if configured
      if (showUserError) {
        _showUserError(lastError);
      }
    }

    return fallbackValue;
  }

  /// Execute with automatic retry on transient errors
  Future<bool> executeWithRecovery({
    required Future<bool> Function() operation,
    required String context,
    int maxRetries = 3,
  }) async {
    final result = await handleError(
      operation: operation,
      context: context,
      fallbackValue: false,
      maxRetries: maxRetries,
      showUserError: true,
    );
    return result ?? false;
  }

  void _addActiveError(SettingsError error) {
    // Remove duplicate errors
    activeErrors.removeWhere((e) => e.type == error.type);

    activeErrors.insert(0, error);
    if (activeErrors.length > maxActiveErrors) {
      activeErrors.removeLast();
    }
  }

  void _addToHistory(SettingsError error) {
    errorHistory.insert(0, error);
    if (errorHistory.length > maxHistorySize) {
      errorHistory.removeLast();
    }
  }

  void _showUserError(SettingsError error) {
    Get.snackbar(
      _getErrorTitle(error.severity),
      error.userMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: error.canRetry ? 3 : 5),
      mainButton: error.recoveryAction != null
          ? TextButton(
              onPressed: () => Get.back(),
              child: Text(
                error.canRetry ? 'Retry' : 'OK',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  String _getErrorTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.transient:
        return 'Connection Issue';
      case ErrorSeverity.actionRequired:
        return 'Action Required';
      case ErrorSeverity.critical:
        return 'Error';
    }
  }

  /// Clear all active errors
  void clearActiveErrors() {
    activeErrors.clear();
  }

  /// Clear error history
  void clearHistory() {
    errorHistory.clear();
  }

  /// Check if there are any active critical errors
  bool get hasCriticalErrors {
    return activeErrors.any((e) => e.severity == ErrorSeverity.critical);
  }

  /// Get the most recent error
  SettingsError? get mostRecentError {
    return activeErrors.isNotEmpty ? activeErrors.first : null;
  }
}

