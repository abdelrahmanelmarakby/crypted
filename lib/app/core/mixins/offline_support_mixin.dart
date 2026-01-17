// ARCH-010 FIX: Offline Support Mixin
// Integrates OfflineQueue with controllers for seamless offline support

import 'dart:async';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mixin providing offline support for chat controllers
mixin OfflineSupportMixin on GetxController {
  final OfflineQueue _offlineQueue = OfflineQueue();
  final EventBus _eventBus = EventBus();

  /// Reactive pending operations count
  final RxInt pendingOperationsCount = 0.obs;

  /// Reactive sync status
  final RxBool isSyncing = false.obs;

  /// Reactive online status
  final RxBool isOnline = true.obs;

  StreamSubscription? _syncStatusSubscription;
  StreamSubscription? _connectivitySubscription;

  /// Initialize offline support
  Future<void> initializeOfflineSupport() async {
    await _offlineQueue.initialize();

    // Listen to sync status
    _syncStatusSubscription = _eventBus.on<SyncStatusEvent>((event) {
      isSyncing.value = event.isSyncing;
      pendingOperationsCount.value = event.pendingCount;
    });

    // Listen to connectivity changes
    _connectivitySubscription = _eventBus.on<ConnectivityChangedEvent>((event) {
      isOnline.value = event.isOnline;
    });

    // Register operation handlers
    _registerHandlers();

    // Update initial state
    pendingOperationsCount.value = _offlineQueue.pendingCount;
    isOnline.value = _offlineQueue.isOnline;

    if (kDebugMode) {
      print('[OfflineSupportMixin] Initialized with ${pendingOperationsCount.value} pending operations');
    }
  }

  /// Register operation handlers with the queue
  void _registerHandlers() {
    _offlineQueue.registerHandlers(
      sendMessage: _handleSendMessage,
      deleteMessage: _handleDeleteMessage,
      editMessage: _handleEditMessage,
      markAsRead: _handleMarkAsRead,
      toggleReaction: _handleToggleReaction,
    );
  }

  /// Queue a message for sending (when offline)
  Future<String> queueMessage(Message message, String roomId) async {
    return await _offlineQueue.enqueue(
      OperationType.sendMessage,
      {
        'roomId': roomId,
        'message': message.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Queue a message deletion
  Future<String> queueDeleteMessage(String messageId, String roomId) async {
    return await _offlineQueue.enqueue(
      OperationType.deleteMessage,
      {
        'roomId': roomId,
        'messageId': messageId,
      },
    );
  }

  /// Queue a message edit
  Future<String> queueEditMessage(
    String messageId,
    String roomId,
    String newText,
  ) async {
    return await _offlineQueue.enqueue(
      OperationType.editMessage,
      {
        'roomId': roomId,
        'messageId': messageId,
        'newText': newText,
      },
    );
  }

  /// Queue marking messages as read
  Future<String> queueMarkAsRead(
    List<String> messageIds,
    String roomId,
    String userId,
  ) async {
    return await _offlineQueue.enqueue(
      OperationType.markAsRead,
      {
        'roomId': roomId,
        'messageIds': messageIds,
        'userId': userId,
      },
    );
  }

  /// Queue a reaction toggle
  Future<String> queueToggleReaction(
    String messageId,
    String roomId,
    String emoji,
    String userId,
  ) async {
    return await _offlineQueue.enqueue(
      OperationType.toggleReaction,
      {
        'roomId': roomId,
        'messageId': messageId,
        'emoji': emoji,
        'userId': userId,
      },
    );
  }

  /// Get pending operations for current room
  List<PendingOperation> getPendingOperations(String roomId) {
    return _offlineQueue.getOperationsForRoom(roomId);
  }

  /// Manually trigger sync
  Future<void> triggerSync() async {
    await _offlineQueue.syncPendingOperations();
  }

  /// Check if there are pending operations
  bool hasPendingOperations(String roomId) {
    return _offlineQueue.getOperationsForRoom(roomId).isNotEmpty;
  }

  // Handler implementations - these should be overridden in the controller
  Future<void> _handleSendMessage(Map<String, dynamic> data) async {
    throw UnimplementedError('Override _handleSendMessage in your controller');
  }

  Future<void> _handleDeleteMessage(Map<String, dynamic> data) async {
    throw UnimplementedError('Override _handleDeleteMessage in your controller');
  }

  Future<void> _handleEditMessage(Map<String, dynamic> data) async {
    throw UnimplementedError('Override _handleEditMessage in your controller');
  }

  Future<void> _handleMarkAsRead(Map<String, dynamic> data) async {
    throw UnimplementedError('Override _handleMarkAsRead in your controller');
  }

  Future<void> _handleToggleReaction(Map<String, dynamic> data) async {
    throw UnimplementedError('Override _handleToggleReaction in your controller');
  }

  /// Dispose offline support resources
  void disposeOfflineSupport() {
    _syncStatusSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }
}

/// Extension to check connectivity before operations
extension ConnectivityCheck on OfflineSupportMixin {
  /// Execute operation if online, queue if offline
  Future<T?> executeOrQueue<T>({
    required Future<T> Function() onlineOperation,
    required Future<String> Function() queueOperation,
    bool showOfflineMessage = true,
  }) async {
    if (ConnectivityService().isOnline) {
      return await onlineOperation();
    } else {
      await queueOperation();
      if (showOfflineMessage && kDebugMode) {
        print('[OfflineSupportMixin] Operation queued for offline sync');
      }
      return null;
    }
  }
}

/// Widget to display offline/sync status
class OfflineStatusIndicator extends StatelessWidget {
  final RxBool isOnline;
  final RxBool isSyncing;
  final RxInt pendingCount;

  const OfflineStatusIndicator({
    super.key,
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isOnline.value && pendingCount.value == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline.value ? Colors.orange : Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing.value)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                isOnline.value ? Icons.sync : Icons.cloud_off,
                size: 14,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getStatusText() {
    if (!isOnline.value) {
      return 'Offline${pendingCount.value > 0 ? ' (${pendingCount.value} pending)' : ''}';
    }
    if (isSyncing.value) {
      return 'Syncing...';
    }
    return '${pendingCount.value} pending';
  }
}
