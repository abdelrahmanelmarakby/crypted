import 'package:crypted_app/app/domain/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with data', () {
        final result = Result<String, String>.success('data');
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('should extract data via fold', () {
        final result = Result<String, String>.success('data');
        final extracted = result.fold(
          onSuccess: (data) => data,
          onFailure: (error) => 'error',
        );
        expect(extracted, 'data');
      });

      test('should transform data via map', () {
        final result = Result<int, String>.success(42);
        final mapped = result.map((data) => data * 2);
        expect(mapped.isSuccess, isTrue);
        mapped.fold(
          onSuccess: (data) => expect(data, 84),
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('should chain async operations via flatMap', () async {
        final result = Result<int, String>.success(42);
        final chained = await result.flatMap((data) async => Result.success(data.toString()));
        expect(chained.isSuccess, isTrue);
        chained.fold(
          onSuccess: (data) => expect(data, '42'),
          onFailure: (_) => fail('Should not fail'),
        );
      });
    });

    group('Failure', () {
      test('should create failure result with error', () {
        final result = Result<String, String>.failure('error');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('should extract error via fold', () {
        final result = Result<String, String>.failure('error');
        final extracted = result.fold(
          onSuccess: (data) => 'data',
          onFailure: (error) => error,
        );
        expect(extracted, 'error');
      });

      test('should not transform data via map', () {
        final result = Result<int, String>.failure('error');
        final mapped = result.map((data) => data * 2);
        expect(mapped.isFailure, isTrue);
        mapped.fold(
          onSuccess: (_) => fail('Should not succeed'),
          onFailure: (error) => expect(error, 'error'),
        );
      });

      test('should not chain via flatMap', () async {
        final result = Result<int, String>.failure('error');
        final chained = await result.flatMap((data) async => Result.success(data.toString()));
        expect(chained.isFailure, isTrue);
      });
    });

    group('mapError', () {
      test('should transform error in failure', () {
        final result = Result<int, String>.failure('error');
        final mapped = result.mapError((error) => error.toUpperCase());
        mapped.fold(
          onSuccess: (_) => fail('Should not succeed'),
          onFailure: (error) => expect(error, 'ERROR'),
        );
      });

      test('should not transform success', () {
        final result = Result<int, String>.success(42);
        final mapped = result.mapError((error) => error.toUpperCase());
        expect(mapped.isSuccess, isTrue);
      });
    });

    group('getOrElse', () {
      test('should return data for success', () {
        final result = Result<int, String>.success(42);
        expect(result.getOrElse(0), 42);
      });

      test('should return default for failure', () {
        final result = Result<int, String>.failure('error');
        expect(result.getOrElse(0), 0);
      });
    });

    group('dataOrNull', () {
      test('should return data for success', () {
        final result = Result<int, String>.success(42);
        expect(result.dataOrNull, 42);
      });

      test('should return null for failure', () {
        final result = Result<int, String>.failure('error');
        expect(result.dataOrNull, isNull);
      });
    });

    group('errorOrNull', () {
      test('should return null for success', () {
        final result = Result<int, String>.success(42);
        expect(result.errorOrNull, isNull);
      });

      test('should return error for failure', () {
        final result = Result<int, String>.failure('error');
        expect(result.errorOrNull, 'error');
      });
    });

    group('onSuccess/onFailure side effects', () {
      test('should execute onSuccess callback for success', () {
        var called = false;
        final result = Result<int, String>.success(42);
        result.onSuccess((data) => called = true);
        expect(called, isTrue);
      });

      test('should not execute onSuccess callback for failure', () {
        var called = false;
        final result = Result<int, String>.failure('error');
        result.onSuccess((data) => called = true);
        expect(called, isFalse);
      });

      test('should execute onFailure callback for failure', () {
        var called = false;
        final result = Result<int, String>.failure('error');
        result.onFailure((error) => called = true);
        expect(called, isTrue);
      });

      test('should not execute onFailure callback for success', () {
        var called = false;
        final result = Result<int, String>.success(42);
        result.onFailure((error) => called = true);
        expect(called, isFalse);
      });
    });
  });

  group('RepositoryError', () {
    test('should create validation error', () {
      final error = RepositoryError.validation('Field is required');
      expect(error.code, 'VALIDATION');
      expect(error.message, 'Field is required');
    });

    test('should create not found error', () {
      final error = RepositoryError.notFound('User');
      expect(error.code, 'NOT_FOUND');
      expect(error.message, contains('User'));
    });

    test('should create unauthorized error', () {
      final error = RepositoryError.unauthorized('delete message');
      expect(error.code, 'UNAUTHORIZED');
      expect(error.message, contains('delete message'));
    });

    test('should create network error', () {
      final error = RepositoryError.network('No connection');
      expect(error.code, 'NETWORK');
      expect(error.message, 'No connection');
    });

    test('should create rate limit error', () {
      final error = RepositoryError.rateLimit(const Duration(seconds: 5));
      expect(error.code, 'RATE_LIMIT');
      expect(error.message, contains('5'));
    });

    test('should create from exception', () {
      final error = RepositoryError.fromException(
        Exception('Something went wrong'),
        StackTrace.current,
      );
      expect(error.code, 'UNKNOWN');
      expect(error.message, contains('Something went wrong'));
      expect(error.stackTrace, isNotNull);
    });

    test('should detect permission denied error from exception', () {
      final error = RepositoryError.fromException(
        Exception('permission-denied: Missing permissions'),
      );
      expect(error.code, 'PERMISSION_DENIED');
    });

    test('should detect network error from exception', () {
      final error = RepositoryError.fromException(
        Exception('Network is unavailable'),
      );
      expect(error.code, 'NETWORK');
    });

    test('should have correct string representation', () {
      final error = RepositoryError.validation('Field required');
      expect(error.toString(), contains('VALIDATION'));
      expect(error.toString(), contains('Field required'));
    });

    test('should identify retryable errors', () {
      expect(RepositoryError.network().isRetryable, isTrue);
      expect(RepositoryError.timeout().isRetryable, isTrue);
      expect(RepositoryError.server().isRetryable, isTrue);
      expect(RepositoryError.validation('test').isRetryable, isFalse);
    });

    test('should identify errors that should notify user', () {
      expect(RepositoryError.validation('test').shouldNotifyUser, isTrue);
      expect(RepositoryError.unauthorized('test').shouldNotifyUser, isTrue);
      expect(RepositoryError.network().shouldNotifyUser, isFalse);
    });
  });
}
