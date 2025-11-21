import 'dart:convert';
import 'dart:developer' as dev;
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Service to queue messages when offline and send when back online
class OfflineMessageQueue {
  static final OfflineMessageQueue instance = OfflineMessageQueue._();
  OfflineMessageQueue._();

  static const String _queueKey = 'offline_message_queue';

  final RxList<QueuedMessage> _queue = <QueuedMessage>[].obs;
  final RxBool _isSending = false.obs;

  List<QueuedMessage> get queue => _queue;
  bool get isSending => _isSending.value;

  /// Initialize the queue from storage
  Future<void> initialize() async {
    try {
      final stored = await GetStorage().read(_queueKey);
      if (stored != null && stored is String) {
        final List<dynamic> jsonList = jsonDecode(stored);
        _queue.value = jsonList
            .map((json) => QueuedMessage.fromJson(json))
            .toList();

        if (kDebugMode) {
          dev.log('📦 Loaded ${_queue.length} queued messages from storage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error loading queued messages: $e');
      }
    }
  }

  /// Add a message to the queue
  Future<void> enqueue(Message message, String roomId) async {
    try {
      final queuedMessage = QueuedMessage(
        message: message,
        roomId: roomId,
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      _queue.add(queuedMessage);
      await _saveQueue();

      if (kDebugMode) {
        dev.log('➕ Added message to offline queue: ${message.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error enqueueing message: $e');
      }
    }
  }

  /// Remove a message from the queue
  Future<void> dequeue(String messageId) async {
    try {
      _queue.removeWhere((qm) => qm.message.id == messageId);
      await _saveQueue();

      if (kDebugMode) {
        dev.log('➖ Removed message from queue: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error dequeuing message: $e');
      }
    }
  }

  /// Process the queue and send messages
  Future<void> processQueue(
    Future<void> Function(Message message, String roomId) sendFunction,
  ) async {
    if (_isSending.value || _queue.isEmpty) return;

    _isSending.value = true;

    try {
      final messagesToSend = List<QueuedMessage>.from(_queue);

      for (final queuedMessage in messagesToSend) {
        try {
          await sendFunction(queuedMessage.message, queuedMessage.roomId);
          await dequeue(queuedMessage.message.id);

          if (kDebugMode) {
            dev.log('✅ Sent queued message: ${queuedMessage.message.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('❌ Failed to send queued message: $e');
          }

          // Increment retry count
          queuedMessage.retryCount++;

          // Remove if too many retries
          if (queuedMessage.retryCount > 5) {
            await dequeue(queuedMessage.message.id);
            if (kDebugMode) {
              dev.log('⚠️ Removed message after 5 failed attempts');
            }
          }
        }
      }
    } finally {
      _isSending.value = false;
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final jsonList = _queue.map((qm) => qm.toJson()).toList();
      await GetStorage().write(_queueKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error saving queue: $e');
      }
    }
  }

  /// Clear the entire queue
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
  }
}

/// Model for queued messages
class QueuedMessage {
  final Message message;
  final String roomId;
  final DateTime timestamp;
  int retryCount;

  QueuedMessage({
    required this.message,
    required this.roomId,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'message': message.toMap(),
        'roomId': roomId,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
        message: Message.fromMap(json['message']),
        roomId: json['roomId'],
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'] ?? 0,
      );
}
