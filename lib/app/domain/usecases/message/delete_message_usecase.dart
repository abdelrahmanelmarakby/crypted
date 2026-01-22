import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

/// Parameters for DeleteMessageUseCase
class DeleteMessageParams extends UseCaseParams {
  final String roomId;
  final String messageId;
  final String userId;
  final bool permanent;

  DeleteMessageParams({
    required this.roomId,
    required this.messageId,
    required this.userId,
    this.permanent = false,
  });

  @override
  String? validate() {
    if (roomId.isEmpty) {
      return 'Room ID is required';
    }
    if (messageId.isEmpty) {
      return 'Message ID is required';
    }
    if (userId.isEmpty) {
      return 'User ID is required';
    }
    return null;
  }
}

/// Use case for deleting messages
///
/// Responsibilities:
/// - Validate delete permissions
/// - Support soft delete (default) and permanent delete
/// - Delegate to repository
class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final IMessageRepository _repository;

  DeleteMessageUseCase({
    required IMessageRepository repository,
  }) : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(DeleteMessageParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Delegate to repository
    if (params.permanent) {
      return _repository.permanentlyDeleteMessage(
        roomId: params.roomId,
        messageId: params.messageId,
        userId: params.userId,
      );
    }

    return _repository.deleteMessage(
      roomId: params.roomId,
      messageId: params.messageId,
      userId: params.userId,
    );
  }
}
