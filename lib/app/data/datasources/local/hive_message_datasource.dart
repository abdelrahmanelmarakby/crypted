import 'dart:async';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Interface for local message storage
abstract class ILocalMessageDataSource {
  /// Save a message locally
  Future<void> saveMessage(String roomId, Message message);

  /// Save multiple messages
  Future<void> saveMessages(String roomId, List<Message> messages);

  /// Get cached messages for a room
  Future<List<Message>> getMessages(String roomId, {int limit = 30});

  /// Get a specific message
  Future<Message?> getMessage(String roomId, String messageId);

  /// Update message ID (when server confirms)
  Future<void> updateMessageId(
    String roomId,
    String localId,
    String actualId,
  );

  /// Delete a message locally
  Future<void> deleteMessage(String roomId, String messageId);

  /// Clear all messages for a room
  Future<void> clearRoom(String roomId);

  /// Queue message for sync
  Future<void> queueForSync(String roomId, Message message);

  /// Get pending (unsynced) messages
  Future<List<Message>> getPendingMessages(String roomId);

  /// Mark message as synced
  Future<void> markAsSynced(String roomId, String messageId);

  /// Search messages locally
  Future<List<Message>> searchMessages(String query, {String? roomId});
}

/// Hive implementation of local message storage
class HiveMessageDataSource implements ILocalMessageDataSource {
  static const String _messagesBoxPrefix = 'messages_';
  static const String _pendingBoxName = 'pending_messages';
  static const String _syncQueueBoxName = 'sync_queue';

  final Map<String, Box<Map>> _openBoxes = {};
  Box<Map>? _pendingBox;
  Box<Map>? _syncQueueBox;

  /// Get or open a messages box for a room
  Future<Box<Map>> _getMessagesBox(String roomId) async {
    final boxName = '$_messagesBoxPrefix$roomId';
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]!;
    }

    final box = await Hive.openBox<Map>(boxName);
    _openBoxes[boxName] = box;
    return box;
  }

  /// Get or open the pending messages box
  Future<Box<Map>> _getPendingBox() async {
    _pendingBox ??= await Hive.openBox<Map>(_pendingBoxName);
    return _pendingBox!;
  }

  /// Get or open the sync queue box
  Future<Box<Map>> _getSyncQueueBox() async {
    _syncQueueBox ??= await Hive.openBox<Map>(_syncQueueBoxName);
    return _syncQueueBox!;
  }

  @override
  Future<void> saveMessage(String roomId, Message message) async {
    final box = await _getMessagesBox(roomId);
    final data = message.toMap();
    data['_localTimestamp'] = DateTime.now().millisecondsSinceEpoch;
    await box.put(message.id, data);

    if (kDebugMode) {
      print('💾 Saved message locally: ${message.id}');
    }
  }

  @override
  Future<void> saveMessages(String roomId, List<Message> messages) async {
    final box = await _getMessagesBox(roomId);
    final entries = <String, Map>{};

    for (final message in messages) {
      final data = message.toMap();
      data['_localTimestamp'] = DateTime.now().millisecondsSinceEpoch;
      entries[message.id] = data;
    }

    await box.putAll(entries);

    if (kDebugMode) {
      print('💾 Saved ${messages.length} messages locally for room $roomId');
    }
  }

  @override
  Future<List<Message>> getMessages(String roomId, {int limit = 30}) async {
    final box = await _getMessagesBox(roomId);
    final messages = <Message>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          final map = Map<String, dynamic>.from(data);
          messages.add(Message.fromMap(map));
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing cached message: $e');
          }
        }
      }
    }

    // Sort by timestamp descending
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return messages.take(limit).toList();
  }

  @override
  Future<Message?> getMessage(String roomId, String messageId) async {
    final box = await _getMessagesBox(roomId);
    final data = box.get(messageId);

    if (data == null) return null;

    try {
      return Message.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateMessageId(
    String roomId,
    String localId,
    String actualId,
  ) async {
    final box = await _getMessagesBox(roomId);
    final data = box.get(localId);

    if (data != null) {
      // Delete old entry
      await box.delete(localId);

      // Save with new ID
      final map = Map<String, dynamic>.from(data);
      map['id'] = actualId;
      map['_synced'] = true;
      await box.put(actualId, map);

      if (kDebugMode) {
        print('💾 Updated message ID: $localId -> $actualId');
      }
    }
  }

  @override
  Future<void> deleteMessage(String roomId, String messageId) async {
    final box = await _getMessagesBox(roomId);
    await box.delete(messageId);
  }

  @override
  Future<void> clearRoom(String roomId) async {
    final box = await _getMessagesBox(roomId);
    await box.clear();

    if (kDebugMode) {
      print('🗑️ Cleared local messages for room $roomId');
    }
  }

  @override
  Future<void> queueForSync(String roomId, Message message) async {
    final box = await _getSyncQueueBox();
    final key = '${roomId}_${message.id}';

    await box.put(key, {
      'roomId': roomId,
      'message': message.toMap(),
      'queuedAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('📤 Queued message for sync: ${message.id}');
    }
  }

  @override
  Future<List<Message>> getPendingMessages(String roomId) async {
    final box = await _getSyncQueueBox();
    final messages = <Message>[];

    for (final key in box.keys) {
      if ((key as String).startsWith('${roomId}_')) {
        final data = box.get(key);
        if (data != null) {
          try {
            final messageData = Map<String, dynamic>.from(data['message']);
            messages.add(Message.fromMap(messageData));
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error parsing pending message: $e');
            }
          }
        }
      }
    }

    return messages;
  }

  @override
  Future<void> markAsSynced(String roomId, String messageId) async {
    final box = await _getSyncQueueBox();
    final key = '${roomId}_$messageId';
    await box.delete(key);

    // Also update in messages box
    final messagesBox = await _getMessagesBox(roomId);
    final data = messagesBox.get(messageId);
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      map['_synced'] = true;
      await messagesBox.put(messageId, map);
    }

    if (kDebugMode) {
      print('✅ Marked message as synced: $messageId');
    }
  }

  @override
  Future<List<Message>> searchMessages(String query, {String? roomId}) async {
    final results = <Message>[];
    final lowerQuery = query.toLowerCase();

    if (roomId != null) {
      // Search in specific room
      final messages = await getMessages(roomId, limit: 1000);
      for (final message in messages) {
        if (_messageMatchesQuery(message, lowerQuery)) {
          results.add(message);
        }
      }
    } else {
      // Search across all rooms
      for (final boxName in _openBoxes.keys) {
        final roomMessages = await getMessages(
          boxName.replaceFirst(_messagesBoxPrefix, ''),
          limit: 1000,
        );
        for (final message in roomMessages) {
          if (_messageMatchesQuery(message, lowerQuery)) {
            results.add(message);
          }
        }
      }
    }

    return results;
  }

  bool _messageMatchesQuery(Message message, String lowerQuery) {
    final map = message.toMap();
    final text = (map['text'] as String?)?.toLowerCase() ?? '';
    final fileName = (map['fileName'] as String?)?.toLowerCase() ?? '';

    return text.contains(lowerQuery) || fileName.contains(lowerQuery);
  }

  /// Close all open boxes
  Future<void> dispose() async {
    for (final box in _openBoxes.values) {
      await box.close();
    }
    _openBoxes.clear();

    await _pendingBox?.close();
    await _syncQueueBox?.close();
  }
}
