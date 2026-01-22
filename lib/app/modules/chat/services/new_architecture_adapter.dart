import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/di/chat_architecture_bindings.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/domain/usecases/message/send_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/edit_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/delete_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/reaction/toggle_reaction_usecase.dart';
import 'package:crypted_app/app/modules/chat/services/message_orchestration_service.dart';
import 'package:crypted_app/app/modules/chat/services/optimistic_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Adapter to integrate new architecture with existing ChatController
///
/// This adapter provides a bridge between the legacy ChatController
/// and the new clean architecture components. It:
/// 1. Wraps MessageOrchestrationService
/// 2. Provides the same interface for message operations
/// 3. Uses feature flag to enable/disable new architecture
///
/// Usage:
/// ```dart
/// // In ChatController._initializeNewArchitecture()
/// _newArchitectureAdapter = NewArchitectureAdapter(messages: messages);
/// _newArchitectureAdapter.initialize(roomId);
///
/// // When sending messages
/// if (_newArchitectureAdapter.isEnabled) {
///   await _newArchitectureAdapter.sendMessage(message, memberIds);
/// } else {
///   await chatDataSource.sendMessage(...); // Legacy path
/// }
/// ```
class NewArchitectureAdapter {
  /// The reactive messages list (shared with UI)
  final RxList<Message> messages;

  /// Internal services (initialized lazily)
  MessageOrchestrationService? _orchestrationService;
  OptimisticUpdateService? _optimisticService;

  /// Room ID for current chat
  String? _roomId;

  /// Whether the adapter has been initialized
  bool _isInitialized = false;

  NewArchitectureAdapter({required this.messages});

  // =================== Configuration ===================

  /// Whether the new architecture is enabled
  bool get isEnabled => ChatArchitectureConfig.shouldUseNewArchitecture && _isInitialized;

  /// Check if adapter is ready for use
  bool get isReady => _isInitialized && _orchestrationService != null;

  // =================== Initialization ===================

  /// Initialize the adapter for a specific room
  ///
  /// This should be called from ChatController._initializeNewArchitecture()
  /// after global bindings are registered.
  void initialize(String roomId) {
    if (_isInitialized && _roomId == roomId) {
      if (kDebugMode) {
        print('🔧 NewArchitectureAdapter already initialized for room: $roomId');
      }
      return;
    }

    _roomId = roomId;

    try {
      // Ensure bindings are registered
      NewArchitectureBindings().dependencies();

      // Create OptimisticUpdateService with shared messages list
      _optimisticService = OptimisticUpdateService(messages: messages);

      // Get dependencies from GetX
      final sendMessageUseCase = Get.find<SendMessageUseCase>();
      final editMessageUseCase = Get.find<EditMessageUseCase>();
      final deleteMessageUseCase = Get.find<DeleteMessageUseCase>();
      final toggleReactionUseCase = Get.find<ToggleReactionUseCase>();
      final eventBus = Get.find<EventBus>();
      final connectivity = Get.find<ConnectivityService>();

      // Create orchestration service
      _orchestrationService = MessageOrchestrationService(
        sendMessageUseCase: sendMessageUseCase,
        editMessageUseCase: editMessageUseCase,
        deleteMessageUseCase: deleteMessageUseCase,
        toggleReactionUseCase: toggleReactionUseCase,
        optimisticService: _optimisticService!,
        eventBus: eventBus,
        connectivity: connectivity,
        offlineQueue: _getOfflineQueue(),
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ NewArchitectureAdapter initialized for room: $roomId');
        print('   - Feature flag enabled: ${ChatArchitectureConfig.shouldUseNewArchitecture}');
        print('   - OrchestrationService: ${_orchestrationService != null}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Failed to initialize NewArchitectureAdapter: $e');
        print(stackTrace);
      }
      _isInitialized = false;
    }
  }

  /// Try to get offline queue if registered
  OfflineQueue? _getOfflineQueue() {
    try {
      return Get.find<OfflineQueue>();
    } catch (_) {
      return null;
    }
  }

  // =================== Message Operations ===================

  /// Send a message using the new architecture
  ///
  /// Returns the message ID on success, or throws on failure.
  /// If new architecture is disabled, returns null (caller should use legacy path).
  Future<String?> sendMessage({
    required Message message,
    required List<SocialMediaUser> members,
    VoidCallback? onOptimisticUpdate,
  }) async {
    if (!isEnabled || _roomId == null) {
      if (kDebugMode) {
        print('⚠️ New architecture not enabled, returning null');
      }
      return null;
    }

    final memberIds = members.map((m) => m.uid ?? '').where((id) => id.isNotEmpty).toList();

    final result = await _orchestrationService!.sendMessage(
      roomId: _roomId!,
      message: message,
      memberIds: memberIds,
      onOptimisticUpdate: onOptimisticUpdate,
    );

    return result.fold(
      onSuccess: (messageId) => messageId,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Edit a message using the new architecture
  ///
  /// Returns true on success, throws on failure.
  /// If new architecture is disabled, returns null (caller should use legacy path).
  Future<bool?> editMessage({
    required String messageId,
    required String newText,
    required String userId,
    DateTime? originalTimestamp,
  }) async {
    if (!isEnabled || _roomId == null) {
      return null;
    }

    final result = await _orchestrationService!.editMessage(
      roomId: _roomId!,
      messageId: messageId,
      newText: newText,
      userId: userId,
      originalTimestamp: originalTimestamp,
    );

    return result.fold(
      onSuccess: (_) => true,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Delete a message using the new architecture
  ///
  /// Returns true on success, throws on failure.
  /// If new architecture is disabled, returns null (caller should use legacy path).
  Future<bool?> deleteMessage({
    required String messageId,
    required String userId,
    bool permanent = false,
  }) async {
    if (!isEnabled || _roomId == null) {
      return null;
    }

    final result = await _orchestrationService!.deleteMessage(
      roomId: _roomId!,
      messageId: messageId,
      userId: userId,
      permanent: permanent,
    );

    return result.fold(
      onSuccess: (_) => true,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  /// Toggle a reaction using the new architecture
  ///
  /// Returns the reaction result on success, throws on failure.
  /// If new architecture is disabled, returns null (caller should use legacy path).
  Future<ReactionResult?> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    if (!isEnabled || _roomId == null) {
      return null;
    }

    final result = await _orchestrationService!.toggleReaction(
      roomId: _roomId!,
      messageId: messageId,
      emoji: emoji,
      userId: userId,
    );

    return result.fold(
      onSuccess: (reactionResult) => reactionResult,
      onFailure: (error) => throw Exception(error.message),
    );
  }

  // =================== Optimistic Updates ===================

  /// Add a local message optimistically
  void addLocalMessage(Message message) {
    _optimisticService?.addLocalMessage(message);
  }

  /// Register that a temp ID has been confirmed with actual ID
  void registerConfirmed(String tempId, String actualId) {
    _optimisticService?.registerConfirmed(tempId, actualId);
  }

  /// Register a pending upload
  void registerPendingUpload(String uploadId, String actualMessageId) {
    _optimisticService?.registerPendingUpload(uploadId, actualMessageId);
  }

  /// Rollback a failed message
  void rollback(String tempId) {
    _optimisticService?.rollback(tempId);
  }

  /// Merge local messages with Firestore stream
  List<Message> mergeWithStream(List<Message> remoteMessages) {
    return _optimisticService?.mergeWithStream(remoteMessages) ?? remoteMessages;
  }

  // =================== Cleanup ===================

  /// Dispose resources
  void dispose() {
    _orchestrationService?.dispose();
    _optimisticService?.clear();
    _isInitialized = false;
    _roomId = null;

    if (kDebugMode) {
      print('🧹 NewArchitectureAdapter disposed');
    }
  }
}

/// Extension to make integration with ChatController easier
extension ChatControllerNewArchitectureExtension on NewArchitectureAdapter {
  /// Execute an operation with fallback to legacy path
  ///
  /// Usage:
  /// ```dart
  /// await adapter.withFallback(
  ///   newPath: () => adapter.sendMessage(...),
  ///   legacyPath: () => chatDataSource.sendMessage(...),
  /// );
  /// ```
  Future<T> withFallback<T>({
    required Future<T?> Function() newPath,
    required Future<T> Function() legacyPath,
  }) async {
    if (!isEnabled) {
      return legacyPath();
    }

    try {
      final result = await newPath();
      if (result != null) {
        return result;
      }
      // New path returned null, fall back to legacy
      return legacyPath();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ New architecture failed, falling back to legacy: $e');
      }
      // On error, fall back to legacy
      return legacyPath();
    }
  }
}
