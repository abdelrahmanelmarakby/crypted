import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:crypted_app/app/core/exceptions/app_exceptions.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// Error types for categorization
enum ErrorType {
  network,
  permission,
  storage,
  firebase,
  validation,
  authentication,
  media,
  encryption,
  rateLimit,
  timeout,
  notFound,
  unknown,
}

/// Error model with user-friendly messages
class AppError {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال.\nNo internet connection. Please check your network.';
      case ErrorType.permission:
        return 'تم رفض الإذن. يرجى منح الأذونات اللازمة.\nPermission denied. Please grant necessary permissions.';
      case ErrorType.storage:
        return 'المساحة التخزينية ممتلئة. يرجى تحرير بعض المساحة.\nStorage full. Please free up some space.';
      case ErrorType.firebase:
        return 'خطأ في الخادم. يرجى المحاولة مرة أخرى.\nServer error. Please try again later.';
      case ErrorType.validation:
        return message; // Use custom validation message
      case ErrorType.authentication:
        return 'فشلت المصادقة. يرجى تسجيل الدخول مرة أخرى.\nAuthentication failed. Please login again.';
      case ErrorType.media:
        return 'فشلت معالجة الملف. يرجى المحاولة مرة أخرى.\nFailed to process file. Please try again.';
      case ErrorType.encryption:
        return 'فشل التشفير. يرجى المحاولة مرة أخرى.\nEncryption failed. Please try again.';
      case ErrorType.rateLimit:
        return 'عدد كبير جداً من المحاولات. يرجى الانتظار قليلاً.\nToo many requests. Please wait a moment.';
      case ErrorType.timeout:
        return 'انتهت مهلة العملية. يرجى المحاولة مرة أخرى.\nOperation timed out. Please try again.';
      case ErrorType.notFound:
        return 'العنصر غير موجود.\nItem not found.';
      case ErrorType.unknown:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.\nAn unexpected error occurred. Please try again.';
    }
  }

  /// Get error color for UI
  Color get color {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.permission:
      case ErrorType.authentication:
        return Colors.amber;
      case ErrorType.validation:
        return Colors.blue;
      case ErrorType.firebase:
      case ErrorType.storage:
      case ErrorType.unknown:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'technicalDetails': technicalDetails,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
      };
}

/// Professional error handling service
///
/// Features:
/// - Automatic error categorization
/// - User-friendly error messages (bilingual)
/// - Error logging integration
/// - Error tracking and analytics
/// - Configurable user notification
///
/// Usage:
/// ```dart
/// try {
///   await riskyOperation();
/// } catch (e, stackTrace) {
///   ErrorHandlerService.instance.handleError(
///     e,
///     stackTrace: stackTrace,
///     context: 'MyController.methodName',
///     showToUser: true,
///   );
/// }
/// ```
class ErrorHandlerService {
  static final ErrorHandlerService instance = ErrorHandlerService._();
  ErrorHandlerService._();

  // Error tracking
  final List<AppError> _errorQueue = [];
  final int _maxQueueSize = 50;

  // Statistics
  int _totalErrors = 0;
  final Map<ErrorType, int> _errorCounts = {};

  /// Handle error with appropriate logging and user feedback
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = true,
    Duration? snackbarDuration,
  }) {
    final appError = _parseError(error, stackTrace, context);

    // Log error
    LoggerService.instance.logError(
      appError.message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      data: {
        'type': appError.type.name,
        'userFriendly': appError.userFriendlyMessage,
      },
    );

    // Show to user if needed
    if (showToUser) {
      _showErrorToUser(appError, snackbarDuration);
    }

    // Track error
    _trackError(appError);
  }

  /// Parse error into AppError model
  AppError _parseError(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  ) {
    ErrorType type = ErrorType.unknown;
    String message = error.toString();
    String? technicalDetails;

    // Parse Firebase exceptions
    if (error is firestore.FirebaseException) {
      type = ErrorType.firebase;
      message = 'Firebase error: ${error.code}';
      technicalDetails = error.message;
    }
    // Parse custom app exceptions
    else if (error is NetworkException) {
      type = ErrorType.network;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is PermissionException) {
      type = ErrorType.permission;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is StorageException) {
      type = ErrorType.storage;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is ValidationException) {
      type = ErrorType.validation;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is AuthException) {
      type = ErrorType.authentication;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is MediaException) {
      type = ErrorType.media;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is EncryptionException) {
      type = ErrorType.encryption;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is RateLimitException) {
      type = ErrorType.rateLimit;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is TimeoutException) {
      type = ErrorType.timeout;
      message = error.message;
      technicalDetails = error.technicalDetails;
    } else if (error is NotFoundException) {
      type = ErrorType.notFound;
      message = error.message;
      technicalDetails = error.technicalDetails;
    }
    // Parse platform exceptions
    else if (error is SocketException) {
      type = ErrorType.network;
      message = 'Network connection failed';
      technicalDetails = error.toString();
    } else if (error is FormatException) {
      type = ErrorType.validation;
      message = 'Invalid data format';
      technicalDetails = error.toString();
    }

    return AppError(
      type: type,
      message: message,
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Show error to user via snackbar
  void _showErrorToUser(AppError error, Duration? duration) {
    Get.snackbar(
      'خطأ / Error',
      error.userFriendlyMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error.color,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: Icon(
        _getErrorIcon(error.type),
        color: Colors.white,
      ),
      shouldIconPulse: true,
      isDismissible: true,
    );
  }

  /// Get appropriate icon for error type
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.permission:
        return Icons.lock_outline;
      case ErrorType.storage:
        return Icons.sd_storage;
      case ErrorType.firebase:
        return Icons.cloud_off;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.authentication:
        return Icons.person_off;
      case ErrorType.media:
        return Icons.image_not_supported;
      default:
        return Icons.error;
    }
  }

  /// Track error for analytics
  void _trackError(AppError error) {
    _totalErrors++;
    _errorCounts[error.type] = (_errorCounts[error.type] ?? 0) + 1;

    _errorQueue.add(error);

    // Prevent queue from growing too large
    if (_errorQueue.length > _maxQueueSize) {
      _errorQueue.removeAt(0);
    }

    // Report critical errors immediately
    if (error.type == ErrorType.firebase ||
        error.type == ErrorType.encryption ||
        error.type == ErrorType.authentication) {
      _reportErrorImmediately(error);
    }
  }

  /// Report critical error immediately to analytics
  Future<void> _reportErrorImmediately(AppError error) async {
    try {
      // Report to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        error.message,
        error.stackTrace,
        reason: error.context ?? 'Unknown context',
        fatal: error.type == ErrorType.authentication ||
               error.type == ErrorType.encryption ||
               error.type == ErrorType.firebase,
        information: [
          'Error Type: ${error.type.name}',
          'Technical Details: ${error.technicalDetails ?? "None"}',
          'Timestamp: ${error.timestamp.toIso8601String()}',
          'User-Friendly Message: ${error.userFriendlyMessage}',
        ],
      );

      // Set custom keys for better error tracking
      await FirebaseCrashlytics.instance.setCustomKey('error_type', error.type.name);
      await FirebaseCrashlytics.instance.setCustomKey('error_context', error.context ?? 'unknown');
      await FirebaseCrashlytics.instance.setCustomKey('timestamp', error.timestamp.toIso8601String());

      LoggerService.instance.debug(
        'Critical error reported to Crashlytics',
        context: 'ErrorHandlerService',
        data: error.toJson(),
      );
    } catch (e) {
      LoggerService.instance.warning(
        'Failed to report error to Crashlytics',
        context: 'ErrorHandlerService',
        data: {'error': e.toString()},
      );
    }
  }

  /// Get error statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalErrors': _totalErrors,
      'errorsByType': _errorCounts.map((key, value) => MapEntry(key.name, value)),
      'recentErrors': _errorQueue.length,
    };
  }

  /// Get recent errors
  List<AppError> getRecentErrors({int limit = 10}) {
    return _errorQueue.reversed.take(limit).toList();
  }

  /// Clear error queue
  void clearErrors() {
    _errorQueue.clear();
    LoggerService.instance.info(
      'Error queue cleared',
      context: 'ErrorHandlerService',
    );
  }

  /// Handle validation errors specifically
  void handleValidationError(String field, String message) {
    handleError(
      ValidationException(field, message),
      showToUser: true,
    );
  }

  /// Handle network errors specifically
  void handleNetworkError({String? details}) {
    handleError(
      NetworkException('Network connection failed', details),
      showToUser: true,
    );
  }

  /// Show success message (opposite of error)
  void showSuccess(
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      'نجح / Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
      shouldIconPulse: true,
    );
  }

  /// Show info message
  void showInfo(
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      'معلومة / Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.info_outline,
        color: Colors.white,
      ),
    );
  }

  /// Show warning message
  void showWarning(
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      'تحذير / Warning',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.warning_amber,
        color: Colors.white,
      ),
    );
  }

  /// Show error message (simple error without handling)
  void showError(
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      'خطأ / Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
      ),
    );
  }
}
