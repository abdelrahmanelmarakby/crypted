/// Result monad for type-safe error handling
/// Replaces try-catch with explicit success/failure paths
///
/// Usage:
/// ```dart
/// final result = await repository.sendMessage(...);
/// result.fold(
///   onSuccess: (messageId) => print('Sent: $messageId'),
///   onFailure: (error) => showError(error.message),
/// );
/// ```
library;

/// Sealed class representing either success or failure
sealed class Result<T, E> {
  const Result();

  /// Create a success result
  factory Result.success(T data) = Success<T, E>;

  /// Create a failure result
  factory Result.failure(E error) = Failure<T, E>;

  /// Check if result is success
  bool get isSuccess => this is Success<T, E>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T, E>;

  /// Get data if success, null otherwise
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  /// Get error if failure, null otherwise
  E? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  /// Pattern match on success/failure
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      Failure(error: final e) => onFailure(e),
    };
  }

  /// Transform success value
  Result<U, E> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(transform(d)),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Transform error value
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(d),
      Failure(error: final e) => Result.failure(transform(e)),
    };
  }

  /// Chain async operations
  Future<Result<U, E>> flatMap<U>(
    Future<Result<U, E>> Function(T data) transform,
  ) async {
    return switch (this) {
      Success(data: final d) => await transform(d),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Execute side effect on success
  Result<T, E> onSuccess(void Function(T data) action) {
    if (this is Success<T, E>) {
      action((this as Success<T, E>).data);
    }
    return this;
  }

  /// Execute side effect on failure
  Result<T, E> onFailure(void Function(E error) action) {
    if (this is Failure<T, E>) {
      action((this as Failure<T, E>).error);
    }
    return this;
  }

  /// Get data or throw error
  T getOrThrow() {
    return switch (this) {
      Success(data: final d) => d,
      Failure(error: final e) => throw e as Object,
    };
  }

  /// Get data or return default
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(data: final d) => d,
      Failure() => defaultValue,
    };
  }
}

/// Success case
final class Success<T, E> extends Result<T, E> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failure case
final class Failure<T, E> extends Result<T, E> {
  final E error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

/// Standardized repository error with codes
class RepositoryError {
  final String code;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const RepositoryError({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  // =================== Factory Methods ===================

  /// Resource not found error
  factory RepositoryError.notFound(String entity) => RepositoryError(
        code: 'NOT_FOUND',
        message: '$entity not found',
      );

  /// User not authorized to perform action
  factory RepositoryError.unauthorized(String action) => RepositoryError(
        code: 'UNAUTHORIZED',
        message: 'Not authorized to $action',
      );

  /// Validation error
  factory RepositoryError.validation(String message) => RepositoryError(
        code: 'VALIDATION',
        message: message,
      );

  /// Network/connectivity error
  factory RepositoryError.network([String? details]) => RepositoryError(
        code: 'NETWORK',
        message: details ?? 'Network error occurred',
      );

  /// Resource conflict (e.g., duplicate)
  factory RepositoryError.conflict(String resource) => RepositoryError(
        code: 'CONFLICT',
        message: '$resource already exists',
      );

  /// Rate limit exceeded
  factory RepositoryError.rateLimit(Duration retryAfter) => RepositoryError(
        code: 'RATE_LIMIT',
        message: 'Rate limit exceeded. Retry after ${retryAfter.inSeconds}s',
      );

  /// Server error
  factory RepositoryError.server([String? details]) => RepositoryError(
        code: 'SERVER_ERROR',
        message: details ?? 'Server error occurred',
      );

  /// Timeout error
  factory RepositoryError.timeout() => const RepositoryError(
        code: 'TIMEOUT',
        message: 'Operation timed out',
      );

  /// Permission denied (Firestore rules)
  factory RepositoryError.permissionDenied() => const RepositoryError(
        code: 'PERMISSION_DENIED',
        message: 'Permission denied',
      );

  /// Create from any exception
  factory RepositoryError.fromException(dynamic e, [StackTrace? st]) {
    // Handle Firebase exceptions
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('permission-denied') ||
        errorString.contains('permission denied')) {
      return RepositoryError.permissionDenied();
    }

    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return RepositoryError.notFound('Resource');
    }

    if (errorString.contains('unavailable') ||
        errorString.contains('network')) {
      return RepositoryError.network(e.toString());
    }

    if (errorString.contains('deadline-exceeded') ||
        errorString.contains('timeout')) {
      return RepositoryError.timeout();
    }

    return RepositoryError(
      code: 'UNKNOWN',
      message: e.toString(),
      originalError: e,
      stackTrace: st,
    );
  }

  /// Check if error is retryable
  bool get isRetryable => const [
        'NETWORK',
        'TIMEOUT',
        'SERVER_ERROR',
      ].contains(code);

  /// Check if user should be notified
  bool get shouldNotifyUser => const [
        'VALIDATION',
        'UNAUTHORIZED',
        'RATE_LIMIT',
        'NOT_FOUND',
      ].contains(code);

  @override
  String toString() => 'RepositoryError($code: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryError &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => code.hashCode ^ message.hashCode;
}

/// Exception that can be thrown from repositories
class RepositoryException implements Exception {
  final RepositoryError error;

  const RepositoryException(this.error);

  factory RepositoryException.notFound(String entity) =>
      RepositoryException(RepositoryError.notFound(entity));

  factory RepositoryException.unauthorized(String action) =>
      RepositoryException(RepositoryError.unauthorized(action));

  factory RepositoryException.validation(String message) =>
      RepositoryException(RepositoryError.validation(message));

  @override
  String toString() => 'RepositoryException: ${error.message}';
}
