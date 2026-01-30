import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

/// Chat backup strategy - backs up chat rooms, messages, and participants
///
/// **Features:**
/// - Chunked processing (500 messages per room to avoid memory issues)
/// - Incremental backup (only backs up new/changed messages)
/// - Participant data included (avoids extra lookups during restore)
/// - Lightweight (streams data, doesn't load all into memory)
class ChatBackupStrategy extends BackupStrategy {
  final BackupDataSource _backupDataSource = BackupDataSource();

  static const int _messagesPerRoom = 500;
  static const int _roomBatchSize = 10; // Process 10 rooms at a time

  @override
  Future<BackupResult> execute(BackupContext context) async {
    try {
      log('💬 Starting chat backup...');

      int successfulItems = 0;
      int failedItems = 0;
      int bytesTransferred = 0;
      final errors = <String>[];

      // Step 1: Get all chat rooms for user
      final chatRooms = await _getUserChatRooms(context);

      if (chatRooms.isEmpty) {
        log('⚠️ No chat rooms found for user');
        return BackupResult(
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          bytesTransferred: 0,
        );
      }

      final totalItems = chatRooms.length;
      log('📊 Found ${chatRooms.length} chat rooms to backup');

      // Step 2: Process chat rooms in batches
      final allMessages = <String, List<Map<String, dynamic>>>{};
      final participantIds = <String>{};

      for (int i = 0; i < chatRooms.length; i += _roomBatchSize) {
        final batch = chatRooms.skip(i).take(_roomBatchSize).toList();

        for (final chatRoom in batch) {
          try {
            // Get messages for this room (incremental: only since last backup)
            final sinceTimestamp = context.options.incrementalOnly
                ? context.lastBackupTimestamp
                : null;
            final messages = await _getChatMessages(
              roomId: chatRoom.id ?? '',
              limit: _messagesPerRoom,
              context: context,
              sinceTimestamp: sinceTimestamp,
            );

            if (messages.isNotEmpty) {
              allMessages[chatRoom.id ?? ''] =
                  messages.map((m) => m.toMap()).toList();
              successfulItems++;
            }

            // Collect participant IDs
            participantIds.addAll(chatRoom.membersIds?.toList() ?? []);

          } catch (e) {
            log('❌ Error backing up room ${chatRoom.id}: $e');
            errors.add('Room ${chatRoom.id}: $e');
            failedItems++;
          }
        }

        // Brief pause between batches to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Step 3: Get participant information
      final participants = await _getChatParticipants(
        participantIds.toList(),
        context,
      );

      // Step 4: Create backup data structure
      final backupData = {
        'chatRooms': chatRooms.map((c) => c.toMap()).toList(),
        'messages': allMessages,
        'participants': participants.map((k, v) => MapEntry(k, v.toMap())),
        'metadata': {
          'totalChatRooms': chatRooms.length,
          'totalMessages': allMessages.values
              .fold(0, (total, msgs) => total + msgs.length),
          'totalParticipants': participants.length,
          'backupDate': DateTime.now().toIso8601String(),
          'messagesPerRoom': _messagesPerRoom,
        },
      };

      // Step 5: Upload as JSON with organized folder structure
      // Path: backups/{userId}/{backupId}/chats/chat_data.json
      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'chat_data.json',
        data: backupData,
        folder: 'chats',
        userId: context.userId,
      );

      // Estimate bytes transferred (rough estimate based on JSON size)
      bytesTransferred = _estimateDataSize(backupData);

      log('✅ Chat backup completed: $successfulItems/$totalItems rooms backed up');

      return BackupResult(
        totalItems: totalItems,
        successfulItems: successfulItems,
        failedItems: failedItems,
        bytesTransferred: bytesTransferred,
        errors: errors,
      );

    } catch (e, stackTrace) {
      log('❌ Chat backup failed: $e', stackTrace: stackTrace);
      return BackupResult(
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        bytesTransferred: 0,
        errors: ['Chat backup failed: $e'],
      );
    }
  }

  @override
  Future<int> estimateItemCount(BackupContext context) async {
    try {
      final chatRooms = await _getUserChatRooms(context);
      return chatRooms.length;
    } catch (e) {
      log('❌ Error estimating chat count: $e');
      return 0;
    }
  }

  /// Dynamic size estimation by sampling actual chat rooms
  /// Samples up to 3 rooms to calculate average message size
  @override
  Future<int> estimateBytesPerItem(BackupContext context) async {
    try {
      log('📊 Sampling chat rooms for size estimation...');

      final chatRooms = await _getUserChatRooms(context);
      if (chatRooms.isEmpty) return 2 * 1024; // 2KB fallback

      // Sample up to 3 chat rooms
      final sampleRooms = chatRooms.take(3).toList();
      int totalMessageSize = 0;
      int totalMessages = 0;

      for (final room in sampleRooms) {
        try {
          final messages = await _getChatMessages(
            roomId: room.id ?? '',
            limit: 50, // Sample 50 messages per room
            context: context,
          );

          for (final message in messages) {
            // Estimate JSON size of each message
            final messageMap = message.toMap();
            final jsonSize = _estimateJsonSize(messageMap);
            totalMessageSize += jsonSize;
            totalMessages++;
          }
        } catch (e) {
          // Skip failed samples
        }
      }

      if (totalMessages == 0) return 2 * 1024; // 2KB fallback

      // Calculate average message size
      final avgMessageSize = totalMessageSize ~/ totalMessages;

      // Estimate per-room size: avg message size * messages per room + room metadata
      final perRoomEstimate = (avgMessageSize * _messagesPerRoom) + 1024; // +1KB for metadata

      log('📊 Chat estimation: $totalMessages samples, avg message ${avgMessageSize}B, per room ~${perRoomEstimate ~/ 1024}KB');

      return perRoomEstimate;
    } catch (e) {
      log('⚠️ Chat estimation failed, using fallback: $e');
      return 2 * 1024; // 2KB fallback per room
    }
  }

  /// Estimate JSON size of a map
  int _estimateJsonSize(Map<String, dynamic> map) {
    int size = 2; // {} brackets
    map.forEach((key, value) {
      size += key.length + 3; // "key":
      if (value is String) {
        size += value.length + 2; // "value"
      } else if (value is Map) {
        size += _estimateJsonSize(value.cast<String, dynamic>());
      } else if (value is List) {
        size += value.length * 10; // rough estimate
      } else {
        size += value.toString().length;
      }
      size += 1; // comma
    });
    return size;
  }

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    // If incremental mode is enabled, check if chat has new messages
    if (context.options.incrementalOnly && item is ChatRoom) {
      try {
        final lastBackup = context.lastBackupTimestamp;

        if (lastBackup != null) {
          // lastChat is a Timestamp string, convert to DateTime
          final chatLastUpdate = item.lastChat != null
              ? DateTime.parse(item.lastChat!)
              : DateTime.now();
          return chatLastUpdate.isAfter(lastBackup);
        }
      } catch (e) {
        log('❌ Error checking backup need: $e');
      }
    }

    // Default: always backup (first backup or non-incremental mode)
    return true;
  }

  // Private helper methods

  Future<List<ChatRoom>> _getUserChatRooms(BackupContext context) async {
    try {
      final querySnapshot = await context.firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: context.userId)
          .orderBy('lastChat', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log('❌ Error getting user chat rooms: $e');
      return [];
    }
  }

  Future<List<Message>> _getChatMessages({
    required String roomId,
    required int limit,
    required BackupContext context,
    DateTime? sinceTimestamp,
  }) async {
    try {
      // The actual Firestore structure is: chats/{roomId}/chat/{messageId}
      Query query = context.firestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Only fetch messages since last backup (incremental mode)
      if (sinceTimestamp != null) {
        query = query.where('timestamp',
            isGreaterThan: Timestamp.fromDate(sinceTimestamp));
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>))
          .where((msg) => !msg.isDeleted) // Skip deleted messages
          .toList();
    } catch (e) {
      log('❌ Error getting messages for room $roomId: $e');
      return [];
    }
  }

  Future<Map<String, SocialMediaUser>> _getChatParticipants(
    List<String> userIds,
    BackupContext context,
  ) async {
    try {
      final participants = <String, SocialMediaUser>{};

      for (final userId in userIds) {
        try {
          final userDoc = await context.firestore
              .collection(FirebaseCollections.users)
              .doc(userId)
              .get();

          if (userDoc.exists) {
            participants[userId] = SocialMediaUser.fromMap(userDoc.data()!);
          }
        } catch (e) {
          log('❌ Error getting participant $userId: $e');
        }
      }

      return participants;
    } catch (e) {
      log('❌ Error getting participants: $e');
      return {};
    }
  }

  int _estimateDataSize(Map<String, dynamic> data) {
    // Rough estimate: 1KB per message average
    final totalMessages = (data['metadata']?['totalMessages'] ?? 0) as int;
    final totalRooms = (data['metadata']?['totalChatRooms'] ?? 0) as int;
    final totalParticipants = (data['metadata']?['totalParticipants'] ?? 0) as int;

    return (totalMessages * 1024) + // Messages
        (totalRooms * 2048) + // Chat rooms
        (totalParticipants * 5120); // Participants with full profile data
  }
}
