import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

/// A utility class for retrying failed operations with exponential backoff.
///
/// Use this for network operations that may transiently fail due to
/// connectivity issues, server overload, or rate limiting.
///
/// Example:
/// ```dart
/// final result = await RetryHelper.withRetry(
///   () => firestore.collection('users').doc(userId).get(),
///   maxAttempts: 3,
///   initialDelay: Duration(seconds: 1),
/// );
/// ```
class RetryHelper {
  /// Execute an operation with automatic retry on failure.
  ///
  /// [operation] - The async operation to execute
  /// [maxAttempts] - Maximum number of attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 1 second)
  /// [maxDelay] - Maximum delay between retries (default: 30 seconds)
  /// [retryIf] - Optional predicate to determine if error is retryable
  /// [onRetry] - Optional callback when a retry occurs
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(Exception)? retryIf,
    void Function(int attempt, Exception error, Duration nextDelay)? onRetry,
  }) async {
    assert(maxAttempts > 0, 'maxAttempts must be positive');

    Exception? lastException;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // Check if we should retry this error
        if (retryIf != null && !retryIf(e)) {
          rethrow;
        }

        // Don't retry if this was the last attempt
        if (attempt == maxAttempts) {
          break;
        }

        // Calculate delay with exponential backoff and jitter
        final baseDelay = initialDelay * pow(2, attempt - 1);
        final jitter = Duration(
          milliseconds: Random().nextInt(baseDelay.inMilliseconds ~/ 2),
        );
        final delay = Duration(
          milliseconds: min(
            (baseDelay + jitter).inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );

        // Notify about retry
        onRetry?.call(attempt, e, delay);

        developer.log(
          'Retry attempt $attempt/$maxAttempts after ${delay.inMilliseconds}ms',
          name: 'RetryHelper',
          error: e,
        );

        await Future.delayed(delay);
      }
    }

    throw lastException ?? StateError('Retry failed with no exception');
  }

  /// Execute an operation with retry, returning null on failure instead of throwing.
  ///
  /// Useful when you want to gracefully handle failures without exceptions.
  /// The operation itself can return null (e.g., when a document doesn't exist).
  static Future<T?> withRetryOrNull<T>(
    Future<T?> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(Exception)? retryIf,
    void Function(int attempt, Exception error, Duration nextDelay)? onRetry,
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // Check if we should retry this error
        if (retryIf != null && !retryIf(e)) {
          developer.log(
            'Non-retryable error encountered',
            name: 'RetryHelper',
            error: e,
          );
          return null;
        }

        // Don't retry if this was the last attempt
        if (attempt == maxAttempts) {
          break;
        }

        // Calculate delay with exponential backoff and jitter
        final baseDelay = initialDelay * pow(2, attempt - 1);
        final jitter = Duration(
          milliseconds: Random().nextInt(baseDelay.inMilliseconds ~/ 2),
        );
        final delay = Duration(
          milliseconds: min(
            (baseDelay + jitter).inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );

        // Notify about retry
        onRetry?.call(attempt, e, delay);

        developer.log(
          'Retry attempt $attempt/$maxAttempts after ${delay.inMilliseconds}ms',
          name: 'RetryHelper',
          error: e,
        );

        await Future.delayed(delay);
      }
    }

    developer.log(
      'All retry attempts failed',
      name: 'RetryHelper',
      error: lastException,
    );
    return null;
  }

  /// Check if an exception is typically retryable (network errors, timeouts, etc.)
  static bool isRetryableException(Exception e) {
    final message = e.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('unavailable') ||
        message.contains('socket') ||
        message.contains('deadline exceeded') ||
        message.contains('internal error');
  }
}

/// Extension to make retry easier to use with Futures
extension RetryableFuture<T> on Future<T> Function() {
  /// Retry this future-returning function with exponential backoff
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) {
    return RetryHelper.withRetry(
      this,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
    );
  }
}
