import 'package:crypted_app/app/domain/core/result.dart';

/// Base interface for all use cases
///
/// Use cases encapsulate a single business operation.
/// They contain validation logic and coordinate between repositories.
///
/// Example:
/// ```dart
/// class SendMessageUseCase implements UseCase<String, SendMessageParams> {
///   @override
///   Future<Result<String, RepositoryError>> call(SendMessageParams params) async {
///     // Validate
///     if (!params.isValid) return Result.failure(RepositoryError.validation('...'));
///     // Execute
///     return repository.sendMessage(...);
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Result<Type, RepositoryError>> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Type> {
  Future<Result<Type, RepositoryError>> call();
}

/// Use case parameters base class
/// Provides common validation interface
abstract class UseCaseParams {
  /// Validate the parameters
  /// Returns null if valid, error message if invalid
  String? validate();

  /// Check if parameters are valid
  bool get isValid => validate() == null;
}
