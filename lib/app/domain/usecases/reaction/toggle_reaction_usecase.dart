import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

/// Parameters for ToggleReactionUseCase
class ToggleReactionParams extends UseCaseParams {
  final String roomId;
  final String messageId;
  final String emoji;
  final String userId;

  ToggleReactionParams({
    required this.roomId,
    required this.messageId,
    required this.emoji,
    required this.userId,
  });

  @override
  String? validate() {
    if (roomId.isEmpty) {
      return 'Room ID is required';
    }
    if (messageId.isEmpty) {
      return 'Message ID is required';
    }
    if (messageId.startsWith('pending_')) {
      return 'Cannot react to pending message';
    }
    if (emoji.isEmpty) {
      return 'Emoji is required';
    }
    if (userId.isEmpty) {
      return 'User ID is required';
    }
    return null;
  }
}

/// Use case for toggling reactions on messages
///
/// Responsibilities:
/// - Validate input parameters
/// - Validate emoji is allowed
/// - Delegate to repository
class ToggleReactionUseCase implements UseCase<ReactionResult, ToggleReactionParams> {
  final IReactionRepository _repository;

  ToggleReactionUseCase({
    required IReactionRepository repository,
  }) : _repository = repository;

  @override
  Future<Result<ReactionResult, RepositoryError>> call(
    ToggleReactionParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Validate emoji
    if (!_repository.isValidEmoji(params.emoji)) {
      return Result.failure(RepositoryError.validation('Invalid emoji'));
    }

    // 3. Delegate to repository
    return _repository.toggleReaction(
      roomId: params.roomId,
      messageId: params.messageId,
      emoji: params.emoji,
      userId: params.userId,
    );
  }
}
