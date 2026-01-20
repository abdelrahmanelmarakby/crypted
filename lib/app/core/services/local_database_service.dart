// Local Database Service
// Provides Hive CRUD operations for offline-first architecture

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypted_app/app/data/models/hive/hive_models.dart';

/// LocalDatabaseService - Manages all Hive database operations
/// Singleton pattern for consistent access across the app
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  // Box names
  static const String messagesBoxName = 'messages';
  static const String chatRoomsBoxName = 'chat_rooms';
  static const String syncMetadataBoxName = 'sync_metadata';
  static const String messageIndexBoxName = 'message_index'; // Room -> Message IDs

  // Boxes
  Box<HiveMessage>? _messagesBox;
  Box<HiveChatRoom>? _chatRoomsBox;
  Box<HiveSyncMetadata>? _syncMetadataBox;
  Box<List<String>>? _messageIndexBox;

  bool _isInitialized = false;

  /// Check if the database is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive with Flutter
      await Hive.initFlutter();

      // Register type adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HiveMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(HiveChatRoomAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(HiveSyncMetadataAdapter());
      }

      // Open boxes
      _messagesBox = await Hive.openBox<HiveMessage>(messagesBoxName);
      _chatRoomsBox = await Hive.openBox<HiveChatRoom>(chatRoomsBoxName);
      _syncMetadataBox = await Hive.openBox<HiveSyncMetadata>(syncMetadataBoxName);
      _messageIndexBox = await Hive.openBox<List<String>>(messageIndexBoxName);

      _isInitialized = true;

      if (kDebugMode) {
        print('[LocalDatabaseService] Initialized successfully');
        print('  Messages: ${_messagesBox!.length}');
        print('  Chat Rooms: ${_chatRoomsBox!.length}');
        print('  Sync Metadata: ${_syncMetadataBox!.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalDatabaseService] Initialization error: $e');
      }
      rethrow;
    }
  }

  /// Ensure boxes are initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('LocalDatabaseService not initialized. Call initialize() first.');
    }
  }

  // =================== MESSAGE OPERATIONS ===================

  /// Generate a composite key for a message
  String _messageKey(String roomId, String messageId) => '${roomId}_$messageId';

  /// Save a single message
  Future<void> saveMessage(HiveMessage message) async {
    _ensureInitialized();
    final key = _messageKey(message.roomId, message.id);
    await _messagesBox!.put(key, message);

    // Update message index
    await _addToMessageIndex(message.roomId, message.id);

    if (kDebugMode) {
      print('[LocalDatabaseService] Saved message: ${message.id} to room: ${message.roomId}');
    }
  }

  /// Save multiple messages in a batch
  Future<void> saveMessages(List<HiveMessage> messages) async {
    _ensureInitialized();
    if (messages.isEmpty) return;

    final entries = <String, HiveMessage>{};
    final indexUpdates = <String, Set<String>>{};

    for (final message in messages) {
      final key = _messageKey(message.roomId, message.id);
      entries[key] = message;

      // Collect index updates
      indexUpdates.putIfAbsent(message.roomId, () => <String>{});
      indexUpdates[message.roomId]!.add(message.id);
    }

    // Batch save messages
    await _messagesBox!.putAll(entries);

    // Update message indexes
    for (final entry in indexUpdates.entries) {
      await _addToMessageIndex(entry.key, entry.value.toList());
    }

    if (kDebugMode) {
      print('[LocalDatabaseService] Saved ${messages.length} messages');
    }
  }

  /// Get messages for a room with pagination
  Future<List<HiveMessage>> getMessages(
    String roomId, {
    int limit = 50,
    String? beforeId,
    DateTime? beforeTimestamp,
  }) async {
    _ensureInitialized();

    // Get message IDs from index
    final messageIds = _messageIndexBox!.get(roomId) ?? [];
    if (messageIds.isEmpty) return [];

    // Get all messages for this room
    final messages = <HiveMessage>[];
    for (final id in messageIds) {
      final key = _messageKey(roomId, id);
      final message = _messagesBox!.get(key);
      if (message != null) {
        messages.add(message);
      }
    }

    // Sort by timestamp descending (newest first)
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    var result = messages;

    if (beforeId != null || beforeTimestamp != null) {
      final beforeTime = beforeTimestamp ??
          messages.firstWhere(
            (m) => m.id == beforeId,
            orElse: () => messages.first,
          ).timestamp;

      result = messages.where((m) => m.timestamp.isBefore(beforeTime)).toList();
    }

    // Apply limit
    if (result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  /// Get a single message by ID
  Future<HiveMessage?> getMessage(String roomId, String messageId) async {
    _ensureInitialized();
    final key = _messageKey(roomId, messageId);
    return _messagesBox!.get(key);
  }

  /// Update a message's sync status
  Future<void> updateMessageSyncStatus(
    String roomId,
    String messageId,
    bool isSynced,
  ) async {
    _ensureInitialized();
    final key = _messageKey(roomId, messageId);
    final message = _messagesBox!.get(key);
    if (message != null) {
      final updated = message.copyWith(isSynced: isSynced);
      await _messagesBox!.put(key, updated);
    }
  }

  /// Get all unsynced messages
  Future<List<HiveMessage>> getUnsyncedMessages() async {
    _ensureInitialized();
    return _messagesBox!.values.where((m) => !m.isSynced).toList();
  }

  /// Get unsynced messages for a specific room
  Future<List<HiveMessage>> getUnsyncedMessagesForRoom(String roomId) async {
    _ensureInitialized();
    final messageIds = _messageIndexBox!.get(roomId) ?? [];
    final messages = <HiveMessage>[];

    for (final id in messageIds) {
      final key = _messageKey(roomId, id);
      final message = _messagesBox!.get(key);
      if (message != null && !message.isSynced) {
        messages.add(message);
      }
    }

    return messages;
  }

  /// Delete a message
  Future<void> deleteMessage(String roomId, String messageId) async {
    _ensureInitialized();
    final key = _messageKey(roomId, messageId);
    await _messagesBox!.delete(key);
    await _removeFromMessageIndex(roomId, messageId);
  }

  /// Delete all messages for a room
  Future<void> deleteMessagesForRoom(String roomId) async {
    _ensureInitialized();
    final messageIds = _messageIndexBox!.get(roomId) ?? [];

    for (final id in messageIds) {
      final key = _messageKey(roomId, id);
      await _messagesBox!.delete(key);
    }

    await _messageIndexBox!.delete(roomId);

    if (kDebugMode) {
      print('[LocalDatabaseService] Deleted ${messageIds.length} messages for room: $roomId');
    }
  }

  /// Search messages by text content
  Future<List<HiveMessage>> searchMessages(String query, {String? roomId}) async {
    _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    final results = <HiveMessage>[];

    if (roomId != null) {
      // Search in specific room
      final messageIds = _messageIndexBox!.get(roomId) ?? [];
      for (final id in messageIds) {
        final key = _messageKey(roomId, id);
        final message = _messagesBox!.get(key);
        if (message != null && _messageMatchesQuery(message, lowerQuery)) {
          results.add(message);
        }
      }
    } else {
      // Search all messages
      for (final message in _messagesBox!.values) {
        if (_messageMatchesQuery(message, lowerQuery)) {
          results.add(message);
        }
      }
    }

    // Sort by timestamp descending
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  bool _messageMatchesQuery(HiveMessage message, String query) {
    final dataMap = message.toDataMap();
    final text = (dataMap['text'] as String? ?? '').toLowerCase();
    return text.contains(query);
  }

  // =================== MESSAGE INDEX OPERATIONS ===================

  Future<void> _addToMessageIndex(String roomId, dynamic messageIdOrIds) async {
    final currentIds = List<String>.from(_messageIndexBox!.get(roomId) ?? []);

    if (messageIdOrIds is String) {
      if (!currentIds.contains(messageIdOrIds)) {
        currentIds.add(messageIdOrIds);
      }
    } else if (messageIdOrIds is List<String>) {
      for (final id in messageIdOrIds) {
        if (!currentIds.contains(id)) {
          currentIds.add(id);
        }
      }
    }

    await _messageIndexBox!.put(roomId, currentIds);
  }

  Future<void> _removeFromMessageIndex(String roomId, String messageId) async {
    final currentIds = List<String>.from(_messageIndexBox!.get(roomId) ?? []);
    currentIds.remove(messageId);
    await _messageIndexBox!.put(roomId, currentIds);
  }

  // =================== CHAT ROOM OPERATIONS ===================

  /// Save a chat room
  Future<void> saveChatRoom(HiveChatRoom room) async {
    _ensureInitialized();
    await _chatRoomsBox!.put(room.id, room);

    if (kDebugMode) {
      print('[LocalDatabaseService] Saved chat room: ${room.id}');
    }
  }

  /// Save multiple chat rooms
  Future<void> saveChatRooms(List<HiveChatRoom> rooms) async {
    _ensureInitialized();
    final entries = {for (var room in rooms) room.id: room};
    await _chatRoomsBox!.putAll(entries);

    if (kDebugMode) {
      print('[LocalDatabaseService] Saved ${rooms.length} chat rooms');
    }
  }

  /// Get all chat rooms
  Future<List<HiveChatRoom>> getChatRooms() async {
    _ensureInitialized();
    final rooms = _chatRoomsBox!.values.toList();

    // Sort by last message time (newest first)
    rooms.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime(1970);
      final bTime = b.lastMessageTime ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return rooms;
  }

  /// Get a single chat room by ID
  Future<HiveChatRoom?> getChatRoom(String id) async {
    _ensureInitialized();
    return _chatRoomsBox!.get(id);
  }

  /// Update a chat room
  Future<void> updateChatRoom(String id, HiveChatRoom Function(HiveChatRoom) updater) async {
    _ensureInitialized();
    final room = _chatRoomsBox!.get(id);
    if (room != null) {
      final updated = updater(room);
      await _chatRoomsBox!.put(id, updated);
    }
  }

  /// Update last message for a room
  Future<void> updateRoomLastMessage(
    String roomId, {
    required String lastMessage,
    required DateTime lastMessageTime,
    required String lastSenderId,
  }) async {
    _ensureInitialized();
    final room = _chatRoomsBox!.get(roomId);
    if (room != null) {
      final updated = room.copyWith(
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        lastSenderId: lastSenderId,
      );
      await _chatRoomsBox!.put(roomId, updated);
    }
  }

  /// Delete a chat room and its messages
  Future<void> deleteChatRoom(String id) async {
    _ensureInitialized();
    await _chatRoomsBox!.delete(id);
    await deleteMessagesForRoom(id);
    await _syncMetadataBox!.delete(id);

    if (kDebugMode) {
      print('[LocalDatabaseService] Deleted chat room and messages: $id');
    }
  }

  /// Get rooms for a specific user (filtering by memberIds)
  Future<List<HiveChatRoom>> getRoomsForUser(String userId) async {
    _ensureInitialized();
    return _chatRoomsBox!.values
        .where((room) => room.memberIds.contains(userId))
        .toList();
  }

  // =================== SYNC METADATA OPERATIONS ===================

  /// Get sync metadata for a room
  Future<HiveSyncMetadata?> getSyncMetadata(String roomId) async {
    _ensureInitialized();
    return _syncMetadataBox!.get(roomId);
  }

  /// Update or create sync metadata
  Future<void> updateSyncMetadata(
    String roomId,
    HiveSyncMetadata Function(HiveSyncMetadata?) updater,
  ) async {
    _ensureInitialized();
    final current = _syncMetadataBox!.get(roomId);
    final updated = updater(current);
    await _syncMetadataBox!.put(roomId, updated);
  }

  /// Mark room sync as started
  Future<void> startRoomSync(String roomId) async {
    await updateSyncMetadata(roomId, (current) {
      final metadata = current ?? HiveSyncMetadata(roomId: roomId);
      metadata.startSync();
      return metadata;
    });
  }

  /// Mark room sync as completed
  Future<void> completeRoomSync(
    String roomId, {
    String? lastMessageId,
    DateTime? lastMessageTimestamp,
  }) async {
    await updateSyncMetadata(roomId, (current) {
      final metadata = current ?? HiveSyncMetadata(roomId: roomId);
      metadata.completeSync(
        syncTime: DateTime.now(),
        lastMsgId: lastMessageId,
        lastMsgTimestamp: lastMessageTimestamp,
      );
      return metadata;
    });
  }

  /// Mark room sync as failed
  Future<void> failRoomSync(String roomId, String error) async {
    await updateSyncMetadata(roomId, (current) {
      final metadata = current ?? HiveSyncMetadata(roomId: roomId);
      metadata.failSync(error);
      return metadata;
    });
  }

  /// Get all rooms that need syncing
  Future<List<HiveSyncMetadata>> getRoomsNeedingSync() async {
    _ensureInitialized();
    return _syncMetadataBox!.values
        .where((m) => m.needsSync || m.hasError)
        .toList();
  }

  // =================== UTILITY OPERATIONS ===================

  /// Get database statistics
  Map<String, int> getStats() {
    _ensureInitialized();
    return {
      'messages': _messagesBox!.length,
      'chatRooms': _chatRoomsBox!.length,
      'syncMetadata': _syncMetadataBox!.length,
      'messageIndexes': _messageIndexBox!.length,
    };
  }

  /// Clear all data (use with caution)
  Future<void> clearAll() async {
    _ensureInitialized();
    await _messagesBox!.clear();
    await _chatRoomsBox!.clear();
    await _syncMetadataBox!.clear();
    await _messageIndexBox!.clear();

    if (kDebugMode) {
      print('[LocalDatabaseService] Cleared all data');
    }
  }

  /// Clear data for a specific user (on logout)
  Future<void> clearUserData(String userId) async {
    _ensureInitialized();

    // Get rooms for this user
    final rooms = await getRoomsForUser(userId);

    // Delete each room's data
    for (final room in rooms) {
      await deleteChatRoom(room.id);
    }

    if (kDebugMode) {
      print('[LocalDatabaseService] Cleared data for user: $userId');
    }
  }

  /// Compact databases to reclaim space
  Future<void> compact() async {
    _ensureInitialized();
    await _messagesBox!.compact();
    await _chatRoomsBox!.compact();
    await _syncMetadataBox!.compact();
    await _messageIndexBox!.compact();

    if (kDebugMode) {
      print('[LocalDatabaseService] Compacted all boxes');
    }
  }

  /// Close all boxes
  Future<void> close() async {
    if (!_isInitialized) return;

    await _messagesBox?.close();
    await _chatRoomsBox?.close();
    await _syncMetadataBox?.close();
    await _messageIndexBox?.close();

    _messagesBox = null;
    _chatRoomsBox = null;
    _syncMetadataBox = null;
    _messageIndexBox = null;
    _isInitialized = false;

    if (kDebugMode) {
      print('[LocalDatabaseService] Closed all boxes');
    }
  }

  /// Dispose resources
  void dispose() {
    close();
  }
}
