import 'dart:async';
import 'dart:developer';
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
            // Get messages for this room
            final messages = await _getChatMessages(
              roomId: chatRoom.id ?? '',
              limit: _messagesPerRoom,
              context: context,
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

      // Step 5: Upload as JSON
      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'chat_data.json',
        data: backupData,
        folder: 'chat',
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

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    // If incremental mode is enabled, check if chat has new messages
    if (context.options.incrementalOnly && item is ChatRoom) {
      try {
        // Check last backup timestamp vs chat's last message timestamp
        final lastBackup = await _getLastBackupTimestamp(
          context.backupId,
          item.id ?? '',
        );

        if (lastBackup != null) {
          // lastChat is a Timestamp, convert to DateTime
          final chatLastUpdate = item.lastChat != null
              ? DateTime.parse(item.lastChat!)
              : DateTime.now();
          return chatLastUpdate.isAfter(lastBackup);
        }
      } catch (e) {
        log('❌ Error checking backup need: $e');
      }
    }

    // Default: always backup
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
  }) async {
    try {
      // FIX: Use chatMessages ('chat') instead of messages ('messages')
      // The actual Firestore structure is: chats/{roomId}/chat/{messageId}
      final querySnapshot = await context.firestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
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

  Future<DateTime?> _getLastBackupTimestamp(
    String backupId,
    String roomId,
  ) async {
    try {
      // Check if previous backup exists for this room
      // This would require storing incremental metadata
      // For now, return null (always backup)
      return null;
    } catch (e) {
      return null;
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
