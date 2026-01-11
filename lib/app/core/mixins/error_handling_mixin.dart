// ARCH-009 FIX: Consistent Error Handling Mixin
// Provides standardized error handling for all controllers

import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Error category for handling different error types
enum ErrorCategory {
  network,
  authentication,
  authorization,
  validation,
  notFound,
  conflict,
  rateLimit,
  unknown,
}

/// Structured error result
class ErrorResult {
  final String message;
  final String? userMessage;
  final ErrorCategory category;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final bool shouldRetry;

  const ErrorResult({
    required this.message,
    this.userMessage,
    required this.category,
    this.originalError,
    this.stackTrace,
    this.shouldRetry = false,
  });

  @override
  String toString() => 'ErrorResult($category): $message';
}

/// Mixin for consistent error handling in controllers
mixin ErrorHandlingMixin {
  /// Log errors consistently
  void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      print('[$runtimeType] Error in $operation: $error');
      if (context != null) {
        print('  Context: $context');
      }
      if (stackTrace != null) {
        print('  Stack: $stackTrace');
      }
    }
  }

  /// Categorize an error
  ErrorResult categorizeError(dynamic error, {String? operation}) {
    if (error is FirebaseAuthException) {
      return ErrorResult(
        message: error.message ?? 'Authentication error',
        userMessage: _getAuthErrorMessage(error.code),
        category: ErrorCategory.authentication,
        originalError: error,
        shouldRetry: false,
      );
    }

    if (error is FirebaseException) {
      return _categorizeFirebaseError(error);
    }

    if (error is TimeoutException) {
      return ErrorResult(
        message: error.toString(),
        userMessage: 'Request timed out. Please try again.',
        category: ErrorCategory.network,
        originalError: error,
        shouldRetry: true,
      );
    }

    if (error is FormatException) {
      return ErrorResult(
        message: error.message,
        userMessage: 'Invalid data format',
        category: ErrorCategory.validation,
        originalError: error,
        shouldRetry: false,
      );
    }

    // Generic error
    return ErrorResult(
      message: error.toString(),
      userMessage: 'An unexpected error occurred',
      category: ErrorCategory.unknown,
      originalError: error,
      shouldRetry: false,
    );
  }

  ErrorResult _categorizeFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return ErrorResult(
          message: error.message ?? 'Permission denied',
          userMessage: 'You do not have permission to perform this action',
          category: ErrorCategory.authorization,
          originalError: error,
          shouldRetry: false,
        );
      case 'unavailable':
        return ErrorResult(
          message: error.message ?? 'Service unavailable',
          userMessage: 'Service is temporarily unavailable',
          category: ErrorCategory.network,
          originalError: error,
          shouldRetry: true,
        );
      case 'not-found':
        return ErrorResult(
          message: error.message ?? 'Not found',
          userMessage: 'The requested item was not found',
          category: ErrorCategory.notFound,
          originalError: error,
          shouldRetry: false,
        );
      case 'already-exists':
        return ErrorResult(
          message: error.message ?? 'Already exists',
          userMessage: 'This item already exists',
          category: ErrorCategory.conflict,
          originalError: error,
          shouldRetry: false,
        );
      case 'resource-exhausted':
        return ErrorResult(
          message: error.message ?? 'Rate limited',
          userMessage: 'Too many requests. Please wait.',
          category: ErrorCategory.rateLimit,
          originalError: error,
          shouldRetry: true,
        );
      default:
        return ErrorResult(
          message: error.message ?? 'Firebase error',
          userMessage: 'An error occurred. Please try again.',
          category: ErrorCategory.unknown,
          originalError: error,
          shouldRetry: true,
        );
    }
  }

  String _getAuthErrorMessage(String code) {
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
        return 'Authentication failed';
    }
  }

  /// Show error to user
  void showError(String message, {bool isWarning = false}) {
    BotToast.showText(
      text: message,
      contentColor: isWarning ? Colors.orange : ColorsManager.error,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show success message
  void showSuccess(String message) {
    BotToast.showText(
      text: message,
      contentColor: ColorsManager.success,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  /// Show info message
  void showInfo(String message) {
    BotToast.showText(
      text: message,
      contentColor: ColorsManager.primary,
      textStyle: const TextStyle(color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  /// Show loading indicator
  CancelFunc showLoading() {
    return BotToast.showLoading();
  }

  /// Hide loading indicator
  void hideLoading() {
    BotToast.closeAllLoading();
  }

  /// Handle an error with full logging and user feedback
  void handleError(
    dynamic error, {
    String? operation,
    StackTrace? stackTrace,
    bool showToUser = true,
    Map<String, dynamic>? context,
  }) {
    final result = categorizeError(error, operation: operation);

    logError(
      operation ?? 'unknown operation',
      error,
      stackTrace: stackTrace,
      context: context,
    );

    if (showToUser && result.userMessage != null) {
      showError(result.userMessage!);
    }
  }

  /// Wrap an async operation with error handling
  Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool showToUser = true,
    bool showLoading = false,
    T? defaultValue,
  }) async {
    CancelFunc? cancelLoading;

    try {
      if (showLoading) {
        cancelLoading = this.showLoading();
      }

      return await operation();
    } catch (e, stackTrace) {
      handleError(
        e,
        operation: operationName,
        stackTrace: stackTrace,
        showToUser: showToUser,
      );
      return defaultValue;
    } finally {
      if (cancelLoading != null) {
        cancelLoading();
      }
    }
  }

  /// Wrap an async operation with retry logic
  Future<T?> safeAsyncWithRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool showToUser = true,
    T? defaultValue,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;
        final result = categorizeError(e);

        if (!result.shouldRetry || attempts >= maxRetries) {
          handleError(
            e,
            operation: operationName,
            stackTrace: stackTrace,
            showToUser: showToUser,
          );
          return defaultValue;
        }

        // Exponential backoff
        await Future.delayed(retryDelay * attempts);
      }
    }

    return defaultValue;
  }
}

/// Extension for easier error handling on Futures
extension SafeFutureExtension<T> on Future<T> {
  /// Execute future with error handling
  Future<T?> safe({
    String? operation,
    bool showToUser = true,
    T? defaultValue,
    void Function(dynamic error)? onError,
  }) async {
    try {
      return await this;
    } catch (e) {
      if (kDebugMode) {
        print('Error in ${operation ?? 'unknown'}: $e');
      }
      onError?.call(e);
      return defaultValue;
    }
  }
}
