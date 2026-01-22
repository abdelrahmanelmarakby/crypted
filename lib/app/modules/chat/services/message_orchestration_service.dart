import 'dart:async';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/domain/usecases/message/send_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/edit_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/delete_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/reaction/toggle_reaction_usecase.dart';
import 'package:crypted_app/app/modules/chat/services/optimistic_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// SINGLE SOURCE OF TRUTH for all message operations
///
/// This service replaces the dual paths that existed in:
/// - ChatController.sendMessage() (lines 914-1010)
/// - MessageController._sendMessage() (lines 741-781)
///
/// All message operations MUST go through this service to ensure:
/// 1. Consistent optimistic updates
/// 2. Proper event emission
/// 3. Uniform error handling
/// 4. Offline support coordination
class MessageOrchestrationService {
  final SendMessageUseCase _sendMessageUseCase;
  final EditMessageUseCase _editMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final ToggleReactionUseCase _toggleReactionUseCase;
  final OptimisticUpdateService _optimisticService;
  final EventBus _eventBus;
  final ConnectivityService _connectivity;
  final OfflineQueue? _offlineQueue;

  /// Subscriptions to event bus
  final List<StreamSubscription> _subscriptions = [];

  MessageOrchestrationService({
    required SendMessageUseCase sendMessageUseCase,
    required EditMessageUseCase editMessageUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required ToggleReactionUseCase toggleReactionUseCase,
    required OptimisticUpdateService optimisticService,
    required EventBus eventBus,
    required ConnectivityService connectivity,
    OfflineQueue? offlineQueue,
  })  : _sendMessageUseCase = sendMessageUseCase,
        _editMessageUseCase = editMessageUseCase,
        _deleteMessageUseCase = deleteMessageUseCase,
        _toggleReactionUseCase = toggleReactionUseCase,
        _optimisticService = optimisticService,
        _eventBus = eventBus,
        _connectivity = connectivity,
        _offlineQueue = offlineQueue {
    _setupEventListeners();
  }

  /// Setup event listeners
  void _setupEventListeners() {
    // Listen for message sent events to update optimistic state
    _subscriptions.add(
      _eventBus.on<MessageSentEvent>((event) {
        if (event.localId != null) {
          _optimisticService.registerConfirmed(event.localId!, event.messageId);
        }
      }),
    );

    // Listen for message send failed events to rollback
    _subscriptions.add(
      _eventBus.on<MessageSendFailedEvent>((event) {
        _optimisticService.rollback(event.localId);
      }),
    );
  }

  // =================== Message Sending ===================

  /// Send a message with full orchestration
  ///
  /// Flow:
  /// 1. Generate temp ID
  /// 2. Add optimistic message to UI
  /// 3. Execute use case (validates, rate limits, sends)
  /// 4. Handle success (register mapping) or failure (rollback)
  Future<Result<String, RepositoryError>> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
    VoidCallback? onOptimisticUpdate,
  }) async {
    // 1. Generate temp ID for optimistic update
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';

    // Create message with temp ID
    final localMessage = message.copyWith(id: tempId) as Message;

    // 2. OPTIMISTIC UPDATE: Show in UI immediately
    _optimisticService.addLocalMessage(localMessage);
    onOptimisticUpdate?.call();

    if (kDebugMode) {
      print('🎯 Optimistic message added: $tempId');
    }

    // 3. Check offline - queue if needed
    final offlineQueue = _offlineQueue;
    if (!_connectivity.isOnline && offlineQueue != null) {
      await offlineQueue.enqueue(
        OperationType.sendMessage,
        {
          'roomId': roomId,
          'message': localMessage.toMap(),
          'memberIds': memberIds,
        },
      );

      if (kDebugMode) {
        print('📤 Message queued for offline sync: $tempId');
      }

      return Result.success(tempId);
    }

    // 4. Execute use case
    final result = await _sendMessageUseCase.call(SendMessageParams(
      roomId: roomId,
      message: localMessage,
      memberIds: memberIds,
    ));

    // 5. Handle result
    return result.fold(
      onSuccess: (actualId) {
        // Register mapping for deduplication
        _optimisticService.registerConfirmed(tempId, actualId);

        if (kDebugMode) {
          print('✅ Message sent: $tempId -> $actualId');
        }

        return Result<String, RepositoryError>.success(actualId);
      },
      onFailure: (error) {
        // ROLLBACK: Remove optimistic message
        _optimisticService.rollback(tempId);

        if (kDebugMode) {
          print('❌ Message failed, rolled back: $tempId');
        }

        return Result<String, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Message Editing ===================

  /// Edit a message with optimistic update
  Future<Result<void, RepositoryError>> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String userId,
    DateTime? originalTimestamp,
  }) async {
    // 1. Optimistic update
    _optimisticService.updateMessageText(messageId, newText);

    // 2. Execute use case
    final result = await _editMessageUseCase.call(EditMessageParams(
      roomId: roomId,
      messageId: messageId,
      newText: newText,
      userId: userId,
      originalTimestamp: originalTimestamp,
    ));

    // 3. Handle failure (rollback)
    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Message edited: $messageId');
        }
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        // Rollback edit
        _optimisticService.rollbackEdit(messageId);

        if (kDebugMode) {
          print('❌ Edit failed, rolled back: $messageId');
        }

        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Message Deletion ===================

  /// Delete a message with optimistic update
  Future<Result<void, RepositoryError>> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
    bool permanent = false,
  }) async {
    // 1. Optimistic update
    _optimisticService.updateMessageProperty(messageId, 'isDeleted', true);

    // 2. Execute use case
    final result = await _deleteMessageUseCase.call(DeleteMessageParams(
      roomId: roomId,
      messageId: messageId,
      userId: userId,
      permanent: permanent,
    ));

    // 3. Handle failure (rollback)
    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Message deleted: $messageId');
        }
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        // Rollback delete
        _optimisticService.updateMessageProperty(messageId, 'isDeleted', false);

        if (kDebugMode) {
          print('❌ Delete failed, rolled back: $messageId');
        }

        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Reactions ===================

  /// Toggle a reaction on a message
  Future<Result<ReactionResult, RepositoryError>> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    // Execute use case (no optimistic update for reactions - they're fast)
    return _toggleReactionUseCase.call(ToggleReactionParams(
      roomId: roomId,
      messageId: messageId,
      emoji: emoji,
      userId: userId,
    ));
  }

  // =================== Message Properties ===================

  /// Toggle pin status
  Future<Result<void, RepositoryError>> togglePin({
    required String roomId,
    required String messageId,
    required IMessageRepository repository,
  }) async {
    // Optimistic update
    _optimisticService.updateMessageProperty(messageId, 'isPinned', true);

    // This delegates to repository directly since there's no use case
    // (toggle operations are simple enough)
    return repository.togglePin(roomId: roomId, messageId: messageId);
  }

  /// Toggle favorite status
  Future<Result<void, RepositoryError>> toggleFavorite({
    required String roomId,
    required String messageId,
    required IMessageRepository repository,
  }) async {
    // Optimistic update
    _optimisticService.updateMessageProperty(messageId, 'isFavorite', true);

    return repository.toggleFavorite(roomId: roomId, messageId: messageId);
  }

  // =================== Stream Integration ===================

  /// Merge messages from Firestore stream with local state
  List<Message> mergeWithStream(List<Message> remoteMessages) {
    return _optimisticService.mergeWithStream(remoteMessages);
  }

  // =================== Cleanup ===================

  /// Dispose resources
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _optimisticService.clear();
  }
}
