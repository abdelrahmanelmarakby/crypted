import 'package:crypted_app/app/core/di/chat_architecture_bindings.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:crypted_app/app/domain/usecases/forward/forward_message_usecase.dart';
import 'package:crypted_app/app/modules/chat/services/forward_orchestration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Mixin to add forward architecture support to ChatController
///
/// This mixin provides:
/// 1. ForwardOrchestrationService integration
/// 2. Methods for single, batch, and multi-target forwarding
/// 3. Feature flag support for gradual migration
///
/// Usage:
/// ```dart
/// class ChatController extends GetxController with ForwardArchitectureMixin {
///   @override
///   void onInit() {
///     super.onInit();
///     initializeForwardMixin(roomId, currentUserId);
///   }
/// }
/// ```
mixin ForwardArchitectureMixin on GetxController {
  /// The forward orchestration service
  ForwardOrchestrationService? _forwardService;

  /// Current room ID
  String? _forwardRoomId;

  /// Current user ID
  String? _forwardUserId;

  /// Whether forward architecture is enabled and ready
  bool get isForwardArchitectureEnabled =>
      ChatArchitectureConfig.shouldUseNewArchitecture && _forwardService != null;

  /// Forward operation in progress
  final RxBool isForwarding = false.obs;

  /// Last forward error
  final RxnString lastForwardError = RxnString(null);

  // =================== Initialization ===================

  /// Initialize the forward architecture mixin
  ///
  /// Call this from onInit() after roomId and currentUserId are available.
  void initializeForwardMixin(String roomId, String currentUserId) {
    _forwardRoomId = roomId;
    _forwardUserId = currentUserId;

    // Ensure bindings are registered
    NewArchitectureBindings().dependencies();

    // Create orchestration service
    _forwardService = ForwardOrchestrationService(
      forwardMessageUseCase: Get.find<ForwardMessageUseCase>(),
      batchForwardUseCase: Get.find<BatchForwardUseCase>(),
      forwardToMultipleUseCase: Get.find<ForwardToMultipleUseCase>(),
      eventBus: Get.find<EventBus>(),
    );

    if (kDebugMode) {
      print('🔧 ForwardArchitectureMixin initialized');
      print('   - Room ID: $roomId');
      print('   - Feature enabled: ${ChatArchitectureConfig.shouldUseNewArchitecture}');
    }
  }

  // =================== Forward Operations ===================

  /// Forward a single message to a target room
  ///
  /// [message] - The message to forward
  /// [targetRoomId] - Target room ID (mutually exclusive with targetUserId)
  /// [targetUserId] - Target user ID for private chat
  /// [options] - Forward options
  /// [onSuccess] - Called with ForwardResult on success
  /// [onError] - Called with error message on failure
  Future<ForwardResult?> forwardMessageWithNewArchitecture({
    required Message message,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(ForwardResult result)? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isForwardArchitectureEnabled) {
      onError?.call('Forward architecture not initialized');
      return null;
    }

    isForwarding.value = true;
    lastForwardError.value = null;

    final result = await _forwardService!.forwardMessage(
      message: message,
      sourceRoomId: _forwardRoomId!,
      currentUserId: _forwardUserId!,
      targetRoomId: targetRoomId,
      targetUserId: targetUserId,
      options: options,
      onSuccess: onSuccess,
      onError: (error) {
        lastForwardError.value = error;
        onError?.call(error);
      },
    );

    isForwarding.value = false;

    return result.fold(
      onSuccess: (forwardResult) {
        if (kDebugMode) {
          print('✅ Message forwarded: ${forwardResult.messageId}');
        }
        return forwardResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Forward failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Forward multiple messages to a single target
  ///
  /// Messages are forwarded in chronological order.
  Future<BatchForwardResult?> forwardMessagesWithNewArchitecture({
    required List<Message> messages,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(BatchForwardResult result)? onComplete,
    void Function(int current, int total)? onProgress,
  }) async {
    if (!isForwardArchitectureEnabled) {
      return null;
    }

    isForwarding.value = true;
    lastForwardError.value = null;

    final result = await _forwardService!.forwardMessages(
      messages: messages,
      sourceRoomId: _forwardRoomId!,
      currentUserId: _forwardUserId!,
      targetRoomId: targetRoomId,
      targetUserId: targetUserId,
      options: options,
      onComplete: onComplete,
      onProgress: onProgress,
    );

    isForwarding.value = false;

    return result.fold(
      onSuccess: (batchResult) {
        if (kDebugMode) {
          print('✅ Batch forward: ${batchResult.successful.length}/${batchResult.totalAttempted}');
        }
        return batchResult;
      },
      onFailure: (error) {
        lastForwardError.value = error.message;
        if (kDebugMode) {
          print('❌ Batch forward failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Forward a message to multiple targets
  ///
  /// Useful for "share to multiple chats" feature.
  Future<BatchForwardResult?> forwardToMultipleWithNewArchitecture({
    required Message message,
    required List<String> targetRoomIds,
    ForwardOptions options = ForwardOptions.defaultOptions,
    void Function(BatchForwardResult result)? onComplete,
  }) async {
    if (!isForwardArchitectureEnabled) {
      return null;
    }

    isForwarding.value = true;
    lastForwardError.value = null;

    final result = await _forwardService!.forwardToMultiple(
      message: message,
      sourceRoomId: _forwardRoomId!,
      currentUserId: _forwardUserId!,
      targetRoomIds: targetRoomIds,
      options: options,
      onComplete: onComplete,
    );

    isForwarding.value = false;

    return result.fold(
      onSuccess: (batchResult) {
        if (kDebugMode) {
          print('✅ Multi-forward: ${batchResult.successful.length}/${batchResult.totalAttempted}');
        }
        return batchResult;
      },
      onFailure: (error) {
        lastForwardError.value = error.message;
        if (kDebugMode) {
          print('❌ Multi-forward failed: ${error.message}');
        }
        return null;
      },
    );
  }

  // =================== Helper Methods ===================

  /// Check if a message can be forwarded
  bool canForwardMessage(Message message) {
    // Cannot forward pending messages
    if (message.id.startsWith('pending_')) return false;

    // Check message type
    final messageType = message.toMap()['type'] as String? ?? 'unknown';
    return kForwardableMessageTypes.contains(messageType);
  }

  /// Get forward statistics
  Map<String, int> get forwardStats => _forwardService?.stats ?? {};

  /// Reset forward statistics
  void resetForwardStats() {
    _forwardService?.resetStats();
  }

  // =================== Cleanup ===================

  /// Dispose the forward architecture resources
  void disposeForwardMixin() {
    _forwardService?.dispose();
    _forwardService = null;
    _forwardRoomId = null;
    _forwardUserId = null;

    if (kDebugMode) {
      print('🧹 ForwardArchitectureMixin disposed');
    }
  }
}
