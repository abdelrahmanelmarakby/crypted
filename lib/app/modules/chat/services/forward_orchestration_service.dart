import 'dart:async';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:crypted_app/app/domain/usecases/forward/forward_message_usecase.dart';
import 'package:flutter/foundation.dart';

/// Orchestration service for message forwarding operations
///
/// This service provides:
/// 1. Unified interface for all forwarding operations
/// 2. UI feedback coordination (loading states, success/error)
/// 3. Event subscription for real-time updates
/// 4. Analytics tracking
class ForwardOrchestrationService {
  final ForwardMessageUseCase _forwardMessageUseCase;
  final BatchForwardUseCase _batchForwardUseCase;
  final ForwardToMultipleUseCase _forwardToMultipleUseCase;
  final EventBus _eventBus;

  /// Subscriptions to event bus
  final List<StreamSubscription> _subscriptions = [];

  /// Track forward operations for analytics
  int _totalForwards = 0;
  int _successfulForwards = 0;
  int _failedForwards = 0;

  ForwardOrchestrationService({
    required ForwardMessageUseCase forwardMessageUseCase,
    required BatchForwardUseCase batchForwardUseCase,
    required ForwardToMultipleUseCase forwardToMultipleUseCase,
    required EventBus eventBus,
  })  : _forwardMessageUseCase = forwardMessageUseCase,
        _batchForwardUseCase = batchForwardUseCase,
        _forwardToMultipleUseCase = forwardToMultipleUseCase,
        _eventBus = eventBus {
    _setupEventListeners();
  }

  /// Setup event listeners for analytics
  void _setupEventListeners() {
    _subscriptions.add(
      _eventBus.on<MessageForwardedEvent>((event) {
        _successfulForwards++;
        if (kDebugMode) {
          print('📊 Forward stats: $_successfulForwards/$_totalForwards successful');
        }
      }),
    );

    _subscriptions.add(
      _eventBus.on<BatchForwardCompletedEvent>((event) {
        if (kDebugMode) {
          print('📊 Batch forward: ${event.successCount} success, ${event.failedCount} failed');
        }
      }),
    );
  }

  // =================== Single Message Forward ===================

  /// Forward a single message to a target room or user
  ///
  /// [message] - The message to forward
  /// [sourceRoomId] - The room where the message originated
  /// [currentUserId] - The user performing the forward
  /// [targetRoomId] - Target room ID (mutually exclusive with targetUserId)
  /// [targetUserId] - Target user ID for private chat
  /// [options] - Forward options
  /// [onSuccess] - Called with ForwardResult on success
  /// [onError] - Called with error message on failure
  Future<Result<ForwardResult, RepositoryError>> forwardMessage({
    required Message message,
    required String sourceRoomId,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(ForwardResult result)? onSuccess,
    void Function(String error)? onError,
  }) async {
    _totalForwards++;

    final result = await _forwardMessageUseCase.call(ForwardMessageParams(
      sourceRoomId: sourceRoomId,
      message: message,
      currentUserId: currentUserId,
      targetRoomId: targetRoomId,
      targetUserId: targetUserId,
      options: options,
    ));

    return result.fold(
      onSuccess: (forwardResult) {
        onSuccess?.call(forwardResult);
        return Result<ForwardResult, RepositoryError>.success(forwardResult);
      },
      onFailure: (error) {
        _failedForwards++;
        onError?.call(error.message);
        return Result<ForwardResult, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Batch Forward ===================

  /// Forward multiple messages to a single target
  ///
  /// Messages are forwarded in chronological order.
  /// Operation continues on individual failures.
  Future<Result<BatchForwardResult, RepositoryError>> forwardMessages({
    required List<Message> messages,
    required String sourceRoomId,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(BatchForwardResult result)? onComplete,
    void Function(int current, int total)? onProgress,
  }) async {
    _totalForwards += messages.length;

    final result = await _batchForwardUseCase.call(BatchForwardParams(
      sourceRoomId: sourceRoomId,
      messages: messages,
      currentUserId: currentUserId,
      targetRoomId: targetRoomId,
      targetUserId: targetUserId,
      options: options,
    ));

    return result.fold(
      onSuccess: (batchResult) {
        _failedForwards += batchResult.failed.length;
        onComplete?.call(batchResult);
        return Result<BatchForwardResult, RepositoryError>.success(batchResult);
      },
      onFailure: (error) {
        _failedForwards += messages.length;
        return Result<BatchForwardResult, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Multi-Target Forward ===================

  /// Forward a single message to multiple targets
  ///
  /// Useful for "share to multiple chats" feature.
  Future<Result<BatchForwardResult, RepositoryError>> forwardToMultiple({
    required Message message,
    required String sourceRoomId,
    required String currentUserId,
    required List<String> targetRoomIds,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(BatchForwardResult result)? onComplete,
  }) async {
    _totalForwards += targetRoomIds.length;

    final result = await _forwardToMultipleUseCase.call(ForwardToMultipleParams(
      sourceRoomId: sourceRoomId,
      message: message,
      currentUserId: currentUserId,
      targetRoomIds: targetRoomIds,
      options: options,
    ));

    return result.fold(
      onSuccess: (batchResult) {
        _failedForwards += batchResult.failed.length;
        onComplete?.call(batchResult);
        return Result<BatchForwardResult, RepositoryError>.success(batchResult);
      },
      onFailure: (error) {
        _failedForwards += targetRoomIds.length;
        return Result<BatchForwardResult, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Analytics ===================

  /// Get forward statistics
  Map<String, int> get stats => {
        'totalForwards': _totalForwards,
        'successfulForwards': _successfulForwards,
        'failedForwards': _failedForwards,
      };

  /// Reset statistics
  void resetStats() {
    _totalForwards = 0;
    _successfulForwards = 0;
    _failedForwards = 0;
  }

  // =================== Cleanup ===================

  /// Dispose resources
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    if (kDebugMode) {
      print('🧹 ForwardOrchestrationService disposed');
      print('   Final stats: $_successfulForwards/$_totalForwards successful');
    }
  }
}
