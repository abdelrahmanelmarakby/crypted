/// Custom application exceptions
///
/// These exceptions provide better error categorization and user-friendly messages
library;

/// Base exception class
class AppException implements Exception {
  final String message;
  final String? technicalDetails;
  final dynamic originalError;

  AppException(
    this.message, {
    this.technicalDetails,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException([
    super.message = 'Network error. Please check your connection.',
    String? details,
  ]) : super(technicalDetails: details);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  final String permissionType;

  PermissionException(
    this.permissionType, [
    String? message,
  ]) : super(
          message ?? 'Permission denied for $permissionType',
          technicalDetails: 'Required permission: $permissionType',
        );
}

/// Storage-related exceptions
class StorageException extends AppException {
  StorageException([
    super.message = 'Storage error. Please free up some space.',
    String? details,
  ]) : super(technicalDetails: details);
}

/// Firebase-related exceptions
class FirebaseException extends AppException {
  final String code;

  FirebaseException(
    this.code, [
    String? message,
    String? details,
  ]) : super(
          message ?? 'Server error: $code',
          technicalDetails: details,
        );
}

/// Validation exceptions
class ValidationException extends AppException {
  final String field;

  ValidationException(
    this.field,
    String message,
  ) : super(message, technicalDetails: 'Validation failed for: $field');
}

/// Authentication exceptions
class AuthException extends AppException {
  final String code;

  AuthException(
    this.code, [
    String? message,
  ]) : super(
          message ?? 'Authentication failed: $code',
          technicalDetails: 'Auth error code: $code',
        );
}

/// Media processing exceptions
class MediaException extends AppException {
  final String mediaType;

  MediaException(
    this.mediaType, [
    String? message,
  ]) : super(
          message ?? 'Failed to process $mediaType',
          technicalDetails: 'Media type: $mediaType',
        );
}

/// Encryption exceptions
class EncryptionException extends AppException {
  EncryptionException([
    super.message = 'Encryption/decryption failed',
    String? details,
  ]) : super(technicalDetails: details);
}

/// Rate limit exceptions
class RateLimitException extends AppException {
  final Duration retryAfter;

  RateLimitException([
    this.retryAfter = const Duration(minutes: 1),
    String? message,
  ]) : super(
          message ?? 'Too many requests. Please try again later.',
          technicalDetails: 'Retry after: ${retryAfter.inSeconds}s',
        );
}

/// Not found exceptions
class NotFoundException extends AppException {
  final String resource;

  NotFoundException(
    this.resource, [
    String? message,
  ]) : super(
          message ?? '$resource not found',
          technicalDetails: 'Resource: $resource',
        );
}

/// Timeout exceptions
class TimeoutException extends AppException {
  final Duration timeout;

  TimeoutException([
    this.timeout = const Duration(seconds: 30),
    String? message,
  ]) : super(
          message ?? 'Operation timed out',
          technicalDetails: 'Timeout: ${timeout.inSeconds}s',
        );
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException([
    super.message = 'Cache operation failed',
    String? details,
  ]) : super(technicalDetails: details);
}
