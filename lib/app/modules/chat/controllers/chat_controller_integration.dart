// ARCH-017 FIX: Chat Controller Integration Layer
// Provides integration between new architecture and existing ChatController
// This enables gradual migration without breaking existing functionality

import 'dart:async';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_state_manager.dart';
import 'package:crypted_app/app/modules/chat/controllers/group_management_controller.dart';
import 'package:crypted_app/app/modules/chat/controllers/message_actions_controller.dart';
import 'package:get/get.dart';

/// Mixin that adds new architecture integration to ChatController
/// Usage: class ChatController extends GetxController with ChatControllerIntegration
mixin ChatControllerIntegration on GetxController {
  // =================== LAZY GETTERS FOR NEW ARCHITECTURE ===================

  /// State manager for reactive state
  ChatStateManager get stateManager {
    if (!Get.isRegistered<ChatStateManager>()) {
      Get.lazyPut(() => ChatStateManager());
    }
    return Get.find<ChatStateManager>();
  }

  /// Message actions controller
  MessageActionsController? get messageActionsController {
    if (Get.isRegistered<MessageActionsController>()) {
      return Get.find<MessageActionsController>();
    }
    return null;
  }

  /// Group management controller
  GroupManagementController? get groupController {
    if (Get.isRegistered<GroupManagementController>()) {
      return Get.find<GroupManagementController>();
    }
    return null;
  }

  /// Error handler
  ErrorHandler get errorHandler {
    if (!Get.isRegistered<ErrorHandler>()) {
      Get.put(ErrorHandler(), permanent: true);
    }
    return Get.find<ErrorHandler>();
  }

  /// Chat repository
  IChatRepository? get chatRepository {
    if (Get.isRegistered<IChatRepository>()) {
      return Get.find<IChatRepository>();
    }
    return null;
  }

  /// Event bus for decoupled communication
  EventBus get eventBus => EventBus();

  /// Offline queue for pending operations
  OfflineQueue get offlineQueue => OfflineQueue();

  // =================== EVENT SUBSCRIPTIONS ===================

  final List<StreamSubscription> _architectureSubscriptions = [];

  /// Initialize new architecture components
  void initializeArchitecture({
    required String roomId,
    required RxList<Message> messages,
  }) {
    // Initialize state manager
    stateManager.roomId.value = roomId;

    // Initialize message actions controller if available
    messageActionsController?.initialize(
      roomId: roomId,
      messagesRef: messages,
    );

    // Subscribe to events
    _subscribeToEvents(roomId);

    // Initialize offline queue
    _initializeOfflineQueue();
  }

  /// Subscribe to architecture events
  void _subscribeToEvents(String roomId) {
    // Listen for message events
    _architectureSubscriptions.add(
      eventBus.on<MessageReceivedEvent>((event) {
        if (event.roomId == roomId) {
          _onMessageReceived(event);
        }
      }),
    );

    _architectureSubscriptions.add(
      eventBus.on<MessageSentEvent>((event) {
        if (event.roomId == roomId) {
          _onMessageSent(event);
        }
      }),
    );

    _architectureSubscriptions.add(
      eventBus.on<MessageSendFailedEvent>((event) {
        if (event.roomId == roomId) {
          _onMessageSendFailed(event);
        }
      }),
    );

    // Listen for connectivity changes
    _architectureSubscriptions.add(
      eventBus.on<ConnectivityChangedEvent>((event) {
        _onConnectivityChanged(event);
      }),
    );

    // Listen for sync status
    _architectureSubscriptions.add(
      eventBus.on<SyncStatusEvent>((event) {
        _onSyncStatusChanged(event);
      }),
    );
  }

  /// Initialize offline queue handlers
  void _initializeOfflineQueue() {
    offlineQueue.registerHandlers(
      sendMessage: _handleOfflineSendMessage,
      deleteMessage: _handleOfflineDeleteMessage,
      editMessage: _handleOfflineEditMessage,
      toggleReaction: _handleOfflineToggleReaction,
    );
  }

  // =================== EVENT HANDLERS ===================

  void _onMessageReceived(MessageReceivedEvent event) {
    // Override in controller if needed
  }

  void _onMessageSent(MessageSentEvent event) {
    // Override in controller if needed
  }

  void _onMessageSendFailed(MessageSendFailedEvent event) {
    errorHandler.showWarning('Message failed to send. Will retry when online.');
  }

  void _onConnectivityChanged(ConnectivityChangedEvent event) {
    if (event.isOnline) {
      // Trigger sync of pending operations
      offlineQueue.syncPendingOperations();
    }
  }

  void _onSyncStatusChanged(SyncStatusEvent event) {
    // Override in controller if needed
  }

  // =================== OFFLINE HANDLERS ===================

  Future<void> _handleOfflineSendMessage(Map<String, dynamic> data) async {
    final repository = chatRepository;
    if (repository == null) {
      throw Exception('Chat repository not available');
    }

    // Reconstruct message and send
    // This is a placeholder - actual implementation depends on message serialization
    throw UnimplementedError('Implement message reconstruction and send');
  }

  Future<void> _handleOfflineDeleteMessage(Map<String, dynamic> data) async {
    final repository = chatRepository;
    if (repository == null) {
      throw Exception('Chat repository not available');
    }

    await repository.deleteMessage(
      roomId: data['roomId'],
      messageId: data['messageId'],
    );
  }

  Future<void> _handleOfflineEditMessage(Map<String, dynamic> data) async {
    final repository = chatRepository;
    if (repository == null) {
      throw Exception('Chat repository not available');
    }

    await repository.editMessage(
      roomId: data['roomId'],
      messageId: data['messageId'],
      newText: data['newText'],
      senderId: data['senderId'],
    );
  }

  Future<void> _handleOfflineToggleReaction(Map<String, dynamic> data) async {
    final repository = chatRepository;
    if (repository == null) {
      throw Exception('Chat repository not available');
    }

    await repository.toggleReaction(
      roomId: data['roomId'],
      messageId: data['messageId'],
      emoji: data['emoji'],
      userId: data['userId'],
    );
  }

  // =================== DELEGATED OPERATIONS ===================

  /// Pin a message using the new architecture
  Future<void> pinMessage(Message message) async {
    final controller = messageActionsController;
    if (controller != null) {
      await controller.togglePinMessage(message);
    } else {
      // Fallback to direct implementation
      errorHandler.showWarning('Message actions not available');
    }
  }

  /// Favorite a message using the new architecture
  Future<void> favoriteMessage(Message message) async {
    final controller = messageActionsController;
    if (controller != null) {
      await controller.toggleFavoriteMessage(message);
    } else {
      errorHandler.showWarning('Message actions not available');
    }
  }

  /// Delete a message using the new architecture
  Future<void> deleteMessageNew(Message message) async {
    final controller = messageActionsController;
    if (controller != null) {
      await controller.deleteMessage(message);
    } else {
      errorHandler.showWarning('Message actions not available');
    }
  }

  /// Copy message text using the new architecture
  void copyMessage(Message message) {
    messageActionsController?.copyMessageText(message);
  }

  /// Add reaction using the new architecture
  Future<void> addReaction(Message message, String emoji, String userId) async {
    final controller = messageActionsController;
    if (controller != null) {
      await controller.toggleReaction(message, emoji, userId);
    }
  }

  // =================== CLEANUP ===================

  /// Dispose architecture resources
  void disposeArchitecture() {
    for (final subscription in _architectureSubscriptions) {
      subscription.cancel();
    }
    _architectureSubscriptions.clear();

    stateManager.reset();
  }
}

/// Extension to add architecture features to any controller
extension ChatControllerArchitectureExtension on GetxController {
  /// Check if offline queue has pending operations
  bool get hasPendingOperations => OfflineQueue().pendingCount > 0;

  /// Get pending operations count
  int get pendingOperationsCount => OfflineQueue().pendingCount;

  /// Emit an event through the event bus
  void emitEvent(AppEvent event) => EventBus().emit(event);

  /// Check if the app is online
  bool get isOnline => OfflineQueue().isOnline;
}

/// Widget helpers for architecture integration
class ArchitectureHelpers {
  /// Show sync status indicator if needed
  static bool shouldShowSyncIndicator() {
    return OfflineQueue().pendingCount > 0 || OfflineQueue().isSyncing;
  }

  /// Get sync status text
  static String getSyncStatusText() {
    final queue = OfflineQueue();
    if (queue.isSyncing) {
      return 'Syncing...';
    }
    if (queue.pendingCount > 0) {
      return '${queue.pendingCount} pending';
    }
    return 'Synced';
  }
}
