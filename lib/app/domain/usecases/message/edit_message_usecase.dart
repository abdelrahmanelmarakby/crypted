import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

/// Parameters for EditMessageUseCase
class EditMessageParams extends UseCaseParams {
  final String roomId;
  final String messageId;
  final String newText;
  final String userId;
  final DateTime? originalTimestamp;

  /// Edit time limit in minutes
  static const int editTimeLimitMinutes = 15;

  EditMessageParams({
    required this.roomId,
    required this.messageId,
    required this.newText,
    required this.userId,
    this.originalTimestamp,
  });

  @override
  String? validate() {
    if (roomId.isEmpty) {
      return 'Room ID is required';
    }
    if (messageId.isEmpty) {
      return 'Message ID is required';
    }
    if (newText.trim().isEmpty) {
      return 'New text cannot be empty';
    }
    if (newText.length > 10000) {
      return 'Message is too long (max 10000 characters)';
    }
    if (userId.isEmpty) {
      return 'User ID is required';
    }

    // Check edit time limit if original timestamp provided
    if (originalTimestamp != null) {
      final difference = DateTime.now().difference(originalTimestamp!);
      if (difference.inMinutes > editTimeLimitMinutes) {
        return 'Edit time limit exceeded ($editTimeLimitMinutes minutes)';
      }
    }

    return null;
  }
}

/// Use case for editing messages
///
/// Responsibilities:
/// - Validate edit permissions
/// - Check edit time limit
/// - Validate new content
/// - Delegate to repository
class EditMessageUseCase implements UseCase<void, EditMessageParams> {
  final IMessageRepository _repository;

  EditMessageUseCase({
    required IMessageRepository repository,
  }) : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(EditMessageParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Delegate to repository (repository handles sender validation)
    return _repository.editMessage(
      roomId: params.roomId,
      messageId: params.messageId,
      newText: params.newText,
      userId: params.userId,
    );
  }
}
