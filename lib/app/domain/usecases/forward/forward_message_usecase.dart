import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

/// Parameters for ForwardMessageUseCase
class ForwardMessageParams extends UseCaseParams {
  final String sourceRoomId;
  final Message message;
  final String currentUserId;
  final String? targetRoomId;
  final String? targetUserId;
  final ForwardOptions options;

  ForwardMessageParams({
    required this.sourceRoomId,
    required this.message,
    required this.currentUserId,
    this.targetRoomId,
    this.targetUserId,
    this.options = ForwardOptions.defaultOptions,
  });

  @override
  String? validate() {
    if (sourceRoomId.isEmpty) {
      return 'Source room ID is required';
    }

    if (message.id.isEmpty) {
      return 'Message ID is required';
    }

    if (message.id.startsWith('pending_')) {
      return 'Cannot forward pending message';
    }

    if (currentUserId.isEmpty) {
      return 'Current user ID is required';
    }

    // Must have either target room or target user
    if (targetRoomId == null && targetUserId == null) {
      return 'Either target room or target user is required';
    }

    // Cannot have both
    if (targetRoomId != null && targetUserId != null) {
      return 'Cannot specify both target room and target user';
    }

    // Validate message type is forwardable
    final messageType = message.toMap()['type'] as String? ?? 'unknown';
    if (kNonForwardableMessageTypes.contains(messageType)) {
      return 'Message type "$messageType" cannot be forwarded';
    }

    return null;
  }
}

/// Use case for forwarding a single message
///
/// Responsibilities:
/// - Validate forward parameters
/// - Check rate limits
/// - Verify privacy settings allow forwarding
/// - Delegate to repository
class ForwardMessageUseCase
    implements UseCase<ForwardResult, ForwardMessageParams> {
  final IForwardRepository _repository;
  final RateLimiter? _rateLimiter;

  ForwardMessageUseCase({
    required IForwardRepository repository,
    RateLimiter? rateLimiter,
  })  : _repository = repository,
        _rateLimiter = rateLimiter;

  @override
  Future<Result<ForwardResult, RepositoryError>> call(
    ForwardMessageParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check rate limit
    final rateLimiter = _rateLimiter;
    if (rateLimiter != null) {
      final rateLimitResult = rateLimiter.checkAndRecord();
      if (!rateLimitResult.allowed) {
        return Result.failure(
          RepositoryError.rateLimit(
            Duration(milliseconds: rateLimitResult.resetInMs),
          ),
        );
      }
    }

    // 3. Check if message can be forwarded (privacy settings)
    final canForward = await _repository.canForwardMessage(
      roomId: params.sourceRoomId,
      messageId: params.message.id,
      currentUserId: params.currentUserId,
    );

    if (canForward.isFailure) {
      return Result.failure(canForward.errorOrNull!);
    }

    if (canForward.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('forward this message'),
      );
    }

    // 4. Check if can forward to target
    final canForwardToTarget = await _repository.canForwardToTarget(
      currentUserId: params.currentUserId,
      targetRoomId: params.targetRoomId,
      targetUserId: params.targetUserId,
    );

    if (canForwardToTarget.isFailure) {
      return Result.failure(canForwardToTarget.errorOrNull!);
    }

    if (canForwardToTarget.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('send to this chat'),
      );
    }

    // 5. Delegate to repository
    return _repository.forwardMessage(
      sourceRoomId: params.sourceRoomId,
      message: params.message,
      currentUserId: params.currentUserId,
      targetRoomId: params.targetRoomId,
      targetUserId: params.targetUserId,
      options: params.options,
    );
  }
}

/// Parameters for batch forward use case
class BatchForwardParams extends UseCaseParams {
  final String sourceRoomId;
  final List<Message> messages;
  final String currentUserId;
  final String? targetRoomId;
  final String? targetUserId;
  final ForwardOptions options;

  BatchForwardParams({
    required this.sourceRoomId,
    required this.messages,
    required this.currentUserId,
    this.targetRoomId,
    this.targetUserId,
    this.options = ForwardOptions.defaultOptions,
  });

  @override
  String? validate() {
    if (sourceRoomId.isEmpty) {
      return 'Source room ID is required';
    }

    if (messages.isEmpty) {
      return 'At least one message is required';
    }

    if (messages.length > 10) {
      return 'Cannot forward more than 10 messages at once';
    }

    if (currentUserId.isEmpty) {
      return 'Current user ID is required';
    }

    if (targetRoomId == null && targetUserId == null) {
      return 'Either target room or target user is required';
    }

    // Validate all messages are forwardable
    for (final message in messages) {
      if (message.id.startsWith('pending_')) {
        return 'Cannot forward pending messages';
      }
      final messageType = message.toMap()['type'] as String? ?? 'unknown';
      if (kNonForwardableMessageTypes.contains(messageType)) {
        return 'Message type "$messageType" cannot be forwarded';
      }
    }

    return null;
  }
}

/// Use case for forwarding multiple messages
class BatchForwardUseCase
    implements UseCase<BatchForwardResult, BatchForwardParams> {
  final IForwardRepository _repository;
  final RateLimiter? _rateLimiter;

  BatchForwardUseCase({
    required IForwardRepository repository,
    RateLimiter? rateLimiter,
  })  : _repository = repository,
        _rateLimiter = rateLimiter;

  @override
  Future<Result<BatchForwardResult, RepositoryError>> call(
    BatchForwardParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check rate limit (check once for batch, not per message)
    final rateLimiter = _rateLimiter;
    if (rateLimiter != null) {
      final rateLimitResult = rateLimiter.checkAndRecord();
      if (!rateLimitResult.allowed) {
        return Result.failure(
          RepositoryError.rateLimit(
            Duration(milliseconds: rateLimitResult.resetInMs),
          ),
        );
      }
    }

    // 3. Check if can forward to target
    final canForwardToTarget = await _repository.canForwardToTarget(
      currentUserId: params.currentUserId,
      targetRoomId: params.targetRoomId,
      targetUserId: params.targetUserId,
    );

    if (canForwardToTarget.isFailure) {
      return Result.failure(canForwardToTarget.errorOrNull!);
    }

    if (canForwardToTarget.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('send to this chat'),
      );
    }

    // 4. Delegate to repository
    return _repository.forwardMessages(
      sourceRoomId: params.sourceRoomId,
      messages: params.messages,
      currentUserId: params.currentUserId,
      targetRoomId: params.targetRoomId,
      targetUserId: params.targetUserId,
      options: params.options,
    );
  }
}

/// Parameters for forward to multiple targets
class ForwardToMultipleParams extends UseCaseParams {
  final String sourceRoomId;
  final Message message;
  final String currentUserId;
  final List<String> targetRoomIds;
  final ForwardOptions options;

  ForwardToMultipleParams({
    required this.sourceRoomId,
    required this.message,
    required this.currentUserId,
    required this.targetRoomIds,
    this.options = ForwardOptions.defaultOptions,
  });

  @override
  String? validate() {
    if (sourceRoomId.isEmpty) {
      return 'Source room ID is required';
    }

    if (message.id.isEmpty) {
      return 'Message ID is required';
    }

    if (message.id.startsWith('pending_')) {
      return 'Cannot forward pending message';
    }

    if (currentUserId.isEmpty) {
      return 'Current user ID is required';
    }

    if (targetRoomIds.isEmpty) {
      return 'At least one target room is required';
    }

    if (targetRoomIds.length > 5) {
      return 'Cannot forward to more than 5 chats at once';
    }

    // Validate message type
    final messageType = message.toMap()['type'] as String? ?? 'unknown';
    if (kNonForwardableMessageTypes.contains(messageType)) {
      return 'Message type "$messageType" cannot be forwarded';
    }

    return null;
  }
}

/// Use case for forwarding a message to multiple targets
class ForwardToMultipleUseCase
    implements UseCase<BatchForwardResult, ForwardToMultipleParams> {
  final IForwardRepository _repository;
  final RateLimiter? _rateLimiter;

  ForwardToMultipleUseCase({
    required IForwardRepository repository,
    RateLimiter? rateLimiter,
  })  : _repository = repository,
        _rateLimiter = rateLimiter;

  @override
  Future<Result<BatchForwardResult, RepositoryError>> call(
    ForwardToMultipleParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check rate limit
    final rateLimiter = _rateLimiter;
    if (rateLimiter != null) {
      final rateLimitResult = rateLimiter.checkAndRecord();
      if (!rateLimitResult.allowed) {
        return Result.failure(
          RepositoryError.rateLimit(
            Duration(milliseconds: rateLimitResult.resetInMs),
          ),
        );
      }
    }

    // 3. Check if message can be forwarded (privacy settings)
    final canForward = await _repository.canForwardMessage(
      roomId: params.sourceRoomId,
      messageId: params.message.id,
      currentUserId: params.currentUserId,
    );

    if (canForward.isFailure) {
      return Result.failure(canForward.errorOrNull!);
    }

    if (canForward.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('forward this message'),
      );
    }

    // 4. Delegate to repository
    return _repository.forwardToMultiple(
      sourceRoomId: params.sourceRoomId,
      message: params.message,
      currentUserId: params.currentUserId,
      targetRoomIds: params.targetRoomIds,
      options: params.options,
    );
  }
}
