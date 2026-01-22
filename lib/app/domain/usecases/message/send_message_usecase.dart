import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

/// Parameters for SendMessageUseCase
class SendMessageParams extends UseCaseParams {
  final String roomId;
  final Message message;
  final List<String> memberIds;

  SendMessageParams({
    required this.roomId,
    required this.message,
    required this.memberIds,
  });

  @override
  String? validate() {
    if (roomId.isEmpty) {
      return 'Room ID is required';
    }
    if (message.senderId.isEmpty) {
      return 'Sender ID is required';
    }
    if (memberIds.isEmpty) {
      return 'At least one member is required';
    }

    // Validate message content based on type
    final map = message.toMap();
    final type = map['type'] as String?;

    switch (type) {
      case 'text':
        final text = map['text'] as String? ?? '';
        if (text.trim().isEmpty) {
          return 'Message text cannot be empty';
        }
        if (text.length > 10000) {
          return 'Message is too long (max 10000 characters)';
        }
        break;
      case 'photo':
        final imageUrl = map['imageUrl'] as String? ?? '';
        if (imageUrl.isEmpty) {
          return 'Image URL is required';
        }
        break;
      case 'video':
        final videoUrl = map['videoUrl'] as String? ?? map['video'] as String? ?? '';
        if (videoUrl.isEmpty) {
          return 'Video URL is required';
        }
        break;
      case 'audio':
        final audioUrl = map['audioUrl'] as String? ?? '';
        if (audioUrl.isEmpty) {
          return 'Audio URL is required';
        }
        break;
      case 'file':
        final fileUrl = map['fileUrl'] as String? ?? map['file'] as String? ?? '';
        if (fileUrl.isEmpty) {
          return 'File URL is required';
        }
        break;
      case 'location':
        final lat = map['latitude'];
        final lng = map['longitude'];
        if (lat == null || lng == null) {
          return 'Location coordinates are required';
        }
        break;
      case 'poll':
        final question = map['question'] as String? ?? '';
        final options = map['options'] as List? ?? [];
        if (question.isEmpty) {
          return 'Poll question is required';
        }
        if (options.length < 2) {
          return 'Poll must have at least 2 options';
        }
        break;
    }

    return null;
  }
}

/// Use case for sending messages
///
/// Responsibilities:
/// - Validate message content
/// - Check rate limits
/// - Delegate to repository
class SendMessageUseCase implements UseCase<String, SendMessageParams> {
  final IMessageRepository _repository;
  final RateLimiter? _rateLimiter;

  SendMessageUseCase({
    required IMessageRepository repository,
    RateLimiter? rateLimiter,
  })  : _repository = repository,
        _rateLimiter = rateLimiter;

  @override
  Future<Result<String, RepositoryError>> call(SendMessageParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check rate limit (if rate limiter provided)
    final rateLimiter = _rateLimiter;
    if (rateLimiter != null) {
      final rateLimitResult = rateLimiter.checkAndRecord();
      if (!rateLimitResult.allowed) {
        return Result.failure(
          RepositoryError.rateLimit(Duration(milliseconds: rateLimitResult.resetInMs)),
        );
      }
    }

    // 3. Delegate to repository
    return _repository.sendMessage(
      roomId: params.roomId,
      message: params.message,
      memberIds: params.memberIds,
    );
  }
}
