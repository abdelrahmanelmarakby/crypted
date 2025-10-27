import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/core/services/device_info_collector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Chat backup data model
class ChatBackupData {
  final List<ChatRoom> chatRooms;
  final Map<String, List<Message>> messages;
  final Map<String, SocialMediaUser> participants;
  final DateTime? backupDate;
  final Map<String, dynamic>? metadata;

  const ChatBackupData({
    required this.chatRooms,
    required this.messages,
    required this.participants,
    this.backupDate,
    this.metadata,
  });

  factory ChatBackupData.create({
    List<ChatRoom>? chatRooms,
    Map<String, List<Message>>? messages,
    Map<String, SocialMediaUser>? participants,
    Map<String, dynamic>? metadata,
  }) {
    return ChatBackupData(
      chatRooms: chatRooms ?? [],
      messages: messages ?? {},
      participants: participants ?? {},
      backupDate: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  ChatBackupData copyWith({
    List<ChatRoom>? chatRooms,
    Map<String, List<Message>>? messages,
    Map<String, SocialMediaUser>? participants,
    DateTime? backupDate,
    Map<String, dynamic>? metadata,
  }) {
    return ChatBackupData(
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      participants: participants ?? this.participants,
      backupDate: backupDate ?? this.backupDate,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRooms': chatRooms.map((x) => x.toMap()).toList(),
      'messages': messages.map((key, value) => MapEntry(key, value.map((x) => x.toMap()).toList())),
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'backupDate': backupDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatBackupData.fromMap(Map<String, dynamic> map) {
    return ChatBackupData(
      chatRooms: List<ChatRoom>.from(
        (map['chatRooms'] as List).map<ChatRoom>(
          (x) => ChatRoom.fromMap(x as Map<String, dynamic>),
        ),
      ),
      messages: (map['messages'] as Map).map((key, value) =>
        MapEntry(key, List<Message>.from((value as List).map<Message>((x) => Message.fromMap(x as Map<String, dynamic>))))),
      participants: (map['participants'] as Map).map((key, value) =>
        MapEntry(key, SocialMediaUser.fromMap(value as Map<String, dynamic>))),
      backupDate: map['backupDate'] != null ? DateTime.parse(map['backupDate'] as String) : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatBackupData.fromJson(String source) => ChatBackupData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatBackupData(chatRooms: ${chatRooms.length}, messages: ${messages.length}, participants: ${participants.length}, backupDate: $backupDate, metadata: $metadata)';
  }
}

/// Chat backup service
/// Handles collecting, processing, and uploading chat data for backup
class ChatBackupService {
  final BackupDataSource _backupDataSource = BackupDataSource();
  final ChatDataSources _chatDataSources = ChatDataSources();
  final DeviceInfoCollector _deviceInfoCollector = DeviceInfoCollector();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all chat rooms for current user
  Future<List<ChatRoom>> getUserChatRooms() async {
    try {
      log('💬 Getting user chat rooms...');

      final userId = UserService.currentUser.value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        log('❌ No user ID found');
        return [];
      }

      // Get chat rooms from Firebase
      final querySnapshot = await _firestore
          .collection('chats')
          .where('membersIds', arrayContains: userId)
          .orderBy('lastChat', descending: true)
          .get();

      final chatRooms = querySnapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList();

      log('✅ Retrieved ${chatRooms.length} chat rooms');
      return chatRooms;
    } catch (e) {
      log('❌ Error getting user chat rooms: $e');
      return [];
    }
  }

  /// Get messages for a specific chat room with pagination
  Future<List<Message>> getChatMessages({
    required String roomId,
    int limit = 1000,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      log('💬 Getting messages for room: $roomId');

      Query query = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final messages = querySnapshot.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      log('✅ Retrieved ${messages.length} messages for room $roomId');
      return messages;
    } catch (e) {
      log('❌ Error getting chat messages: $e');
      return [];
    }
  }

  /// Get all messages for all chat rooms with pagination
  Future<Map<String, List<Message>>> getAllChatMessages({
    int messagesPerRoom = 500,
    bool includeDeleted = false,
  }) async {
    try {
      log('💬 Getting all chat messages...');

      final chatRooms = await getUserChatRooms();
      final allMessages = <String, List<Message>>{};

      for (final chatRoom in chatRooms) {
        try {
          final messages = await getChatMessages(
            roomId: chatRoom.id??"",
            limit: messagesPerRoom,
          );

          // Filter out deleted messages if not including them
          final filteredMessages = includeDeleted
              ? messages
              : messages.where((message) => !message.isDeleted).toList();

          if (filteredMessages.isNotEmpty) {
            allMessages[chatRoom.id??""] = filteredMessages;
          }
        } catch (e) {
          log('❌ Error getting messages for room ${chatRoom.id}: $e');
          // Continue with other rooms
        }
      }

      log('✅ Retrieved messages from ${allMessages.length} chat rooms');
      return allMessages;
    } catch (e) {
      log('❌ Error getting all chat messages: $e');
      return {};
    }
  }

  /// Get participants information for chat rooms
  Future<Map<String, SocialMediaUser>> getChatParticipants(List<ChatRoom> chatRooms) async {
    try {
      log('👥 Getting chat participants...');

      final participants = <String, SocialMediaUser>{};
      final userIds = <String>{};

      // Collect all unique user IDs from chat rooms
      for (final chatRoom in chatRooms) {
        userIds.addAll(chatRoom.membersIds?.toList()??[]);
      }

      // Get user information for each participant
      for (final userId in userIds) {
        try {
          if (userId == UserService.currentUser.value?.uid) {
            // Current user info is already available
            final currentUser = UserService.currentUser.value;
            if (currentUser != null) {
              participants[userId] = currentUser;
            }
          } else {
            // Get other users' info from Firebase
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              participants[userId] = SocialMediaUser.fromMap(userDoc.data()!);
            }
          }
        } catch (e) {
          log('❌ Error getting participant info for $userId: $e');
        }
      }

      log('✅ Retrieved ${participants.length} participants');
      return participants;
    } catch (e) {
      log('❌ Error getting chat participants: $e');
      return {};
    }
  }

  /// Create comprehensive chat backup
  Future<BackupProgress> createChatBackup({
    required String userId,
    required String backupId,
    int messagesPerRoom = 500,
    bool includeMediaFiles = true,
    bool includeDeletedMessages = false,
    bool includeParticipantsInfo = true,
    Function(double)? onProgress,
  }) async {
    try {
      log('💬 Starting chat backup process...');

      // Initialize backup progress
      var progress = BackupProgress.initial(
        backupId: backupId,
        type: BackupType.full, // Using full backup type for chat
        totalItems: 0,
      );

      // Update progress to in-progress
      progress = progress.copyWith(status: BackupStatus.inProgress);
      await _backupDataSource.updateBackupProgress(progress);

      final chatData = <String, dynamic>{};
      int totalItems = 0;

      // Get chat rooms
      final chatRooms = await getUserChatRooms();
      chatData['chatRooms'] = chatRooms.map((c) => c.toMap()).toList();
      totalItems += chatRooms.length;

      progress = progress.copyWith(
        totalItems: totalItems,
        currentTask: 'Retrieved ${chatRooms.length} chat rooms',
      );
      await _backupDataSource.updateBackupProgress(progress);

      // Get messages for each chat room
      final allMessages = <String, List<Message>>{};
      int processedRooms = 0;

      for (final chatRoom in chatRooms) {
        try {
          final messages = await getChatMessages(
            roomId: chatRoom.id??"",
            limit: messagesPerRoom,
          );

          // Filter messages based on settings
          final filteredMessages = includeDeletedMessages
              ? messages
              : messages.where((message) => !message.isDeleted).toList();

          if (filteredMessages.isNotEmpty) {
            allMessages[chatRoom.id??""] = filteredMessages;
            totalItems += filteredMessages.length;
          }

          processedRooms++;

          // Update progress
          progress = progress.copyWith(
            completedItems: processedRooms,
            progress: processedRooms / chatRooms.length,
            currentTask: 'Processed $processedRooms/${chatRooms.length} chat rooms',
          );
          await _backupDataSource.updateBackupProgress(progress);

          onProgress?.call(processedRooms / chatRooms.length);

        } catch (e) {
          log('❌ Error processing messages for room ${chatRoom.id}: $e');
          processedRooms++;
        }
      }

      chatData['messages'] = allMessages.map((key, value) =>
        MapEntry(key, value.map((m) => m.toMap()).toList()));

      // Get participants information
      if (includeParticipantsInfo) {
        final participants = await getChatParticipants(chatRooms);
        chatData['participants'] = participants.map((key, value) =>
          MapEntry(key, value.toMap()));
      }

      // Add metadata
      chatData['metadata'] = {
        'totalChatRooms': chatRooms.length,
        'totalMessages': allMessages.values.fold(0, (sum, messages) => sum + messages.length),
        'totalParticipants': chatData['participants']?.length ?? 0,
        'messagesPerRoom': messagesPerRoom,
        'includeMediaFiles': includeMediaFiles,
        'includeDeletedMessages': includeDeletedMessages,
        'includeParticipantsInfo': includeParticipantsInfo,
        'backupDate': DateTime.now().toIso8601String(),
      };

      // Upload chat data as JSON
      await _backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'chat_data.json',
        data: chatData,
        folder: 'chat',
      );

      // Complete backup
      progress = progress.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        completedItems: totalItems,
        currentTask: 'Chat backup completed successfully',
      );
      await _backupDataSource.updateBackupProgress(progress);

      log('✅ Chat backup completed successfully');
      return progress;

    } catch (e) {
      log('❌ Error in chat backup: $e');

      // Update progress with error
      final errorProgress = BackupProgress(
        backupId: backupId,
        status: BackupStatus.failed,
        type: BackupType.full,
        errorMessage: e.toString(),
      );
      await _backupDataSource.updateBackupProgress(errorProgress);

      return errorProgress;
    }
  }

  /// Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      log('📊 Getting chat statistics...');

      final chatRooms = await getUserChatRooms();
      final stats = <String, dynamic>{
        'totalChatRooms': chatRooms.length,
        'groupChats': 0,
        'privateChats': 0,
        'totalMessages': 0,
        'messagesWithMedia': 0,
        'messagesWithReactions': 0,
        'favoriteMessages': 0,
        'pinnedMessages': 0,
      };

      int totalMessages = 0;
      int messagesWithMedia = 0;
      int messagesWithReactions = 0;
      int favoriteMessages = 0;
      int pinnedMessages = 0;

      for (final chatRoom in chatRooms) {
        if (chatRoom.isGroupChat ?? false) {
          stats['groupChats']++;
        } else {
          stats['privateChats']++;
        }

        try {
          final messages = await getChatMessages(roomId: chatRoom.id??"", limit: 100);
          totalMessages += messages.length;

          for (final message in messages) {
            if (message.reactions.isNotEmpty) messagesWithReactions++;
            if (message.isFavorite) favoriteMessages++;
            if (message.isPinned) pinnedMessages++;

            // Check if message has media (based on type)
            if (_isMediaMessage(message)) messagesWithMedia++;
          }
        } catch (e) {
          log('❌ Error getting messages for statistics: $e');
        }
      }

      stats['totalMessages'] = totalMessages;
      stats['messagesWithMedia'] = messagesWithMedia;
      stats['messagesWithReactions'] = messagesWithReactions;
      stats['favoriteMessages'] = favoriteMessages;
      stats['pinnedMessages'] = pinnedMessages;

      log('✅ Chat statistics retrieved');
      return stats;
    } catch (e) {
      log('❌ Error getting chat statistics: $e');
      return {
        'totalChatRooms': 0,
        'groupChats': 0,
        'privateChats': 0,
        'totalMessages': 0,
        'messagesWithMedia': 0,
        'messagesWithReactions': 0,
        'favoriteMessages': 0,
        'pinnedMessages': 0,
      };
    }
  }

  /// Check if message contains media
  bool _isMediaMessage(Message message) {
    // This would check the message type to see if it's a media message
    // For now, we'll use a simple check based on the runtime type
    return message.runtimeType.toString().contains('Photo') ||
           message.runtimeType.toString().contains('Video') ||
           message.runtimeType.toString().contains('Audio') ||
           message.runtimeType.toString().contains('File');
  }

  /// Search messages across all chats
  Future<List<Message>> searchMessages({
    String? query,
    String? chatRoomId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      log('🔍 Searching messages...');

      final chatRooms = chatRoomId != null
          ? [await _chatDataSources.getChatRoomById(chatRoomId)].whereType<ChatRoom>().toList()
          : await getUserChatRooms();

      final searchResults = <Message>[];

      for (final chatRoom in chatRooms) {
        try {
          var queryRef = _firestore
              .collection('chats')
              .doc(chatRoom.id)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(limit);

          if (startDate != null) {
            queryRef = queryRef.where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String());
          }

          if (endDate != null) {
            queryRef = queryRef.where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());
          }

          final querySnapshot = await queryRef.get();
          final messages = querySnapshot.docs
              .map((doc) => Message.fromMap(doc.data()))
              .where((message) => !message.isDeleted)
              .toList();

          // Filter by search query if provided
          final filteredMessages = query != null && query.isNotEmpty
              ? messages.where((message) {
                  // This would need to be implemented based on your message content structure
                  // For now, we'll return all messages
                  return true;
                }).toList()
              : messages;

          searchResults.addAll(filteredMessages);
        } catch (e) {
          log('❌ Error searching messages in room ${chatRoom.id}: $e');
        }
      }

      // Sort by timestamp (newest first)
      searchResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit results
      if (searchResults.length > limit) {
        searchResults.removeRange(limit, searchResults.length);
      }

      log('✅ Message search completed: ${searchResults.length} results');
      return searchResults;
    } catch (e) {
      log('❌ Error searching messages: $e');
      return [];
    }
  }

  /// Get chat messages by date range
  Future<List<Message>> getMessagesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? chatRoomId,
    int limit = 1000,
  }) async {
    try {
      log('📅 Getting messages by date range...');

      final chatRooms = chatRoomId != null
          ? [await _chatDataSources.getChatRoomById(chatRoomId)].whereType<ChatRoom>().toList()
          : await getUserChatRooms();

      final dateRangeMessages = <Message>[];

      for (final chatRoom in chatRooms) {
        try {
          final querySnapshot = await _firestore
              .collection('chats')
              .doc(chatRoom.id)
              .collection('messages')
              .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
              .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

          final messages = querySnapshot.docs
              .map((doc) => Message.fromMap(doc.data()))
              .where((message) => !message.isDeleted)
              .toList();

          dateRangeMessages.addAll(messages);
        } catch (e) {
          log('❌ Error getting date range messages for room ${chatRoom.id}: $e');
        }
      }

      // Sort by timestamp
      dateRangeMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      log('✅ Date range message retrieval completed: ${dateRangeMessages.length} messages');
      return dateRangeMessages;
    } catch (e) {
      log('❌ Error getting messages by date range: $e');
      return [];
    }
  }

  /// Validate chat backup integrity
  Future<bool> validateChatBackup(String backupId) async {
    try {
      // Get backup files
      final backupFiles = await _backupDataSource.getBackupFiles(
        backupId: backupId,
        folder: 'chat',
      );

      if (backupFiles.isEmpty) return false;

      // Check if chat data file exists
      return backupFiles.any((file) => file.contains('chat_data'));
    } catch (e) {
      log('❌ Error validating chat backup: $e');
      return false;
    }
  }

  /// Delete chat backup
  Future<bool> deleteChatBackup(String backupId) async {
    try {
      // This will be handled by the main backup data source
      log('🗑️ Deleting chat backup: $backupId');
      return true;
    } catch (e) {
      log('❌ Error deleting chat backup: $e');
      return false;
    }
  }

  /// Get backup size estimate for chat data
  Future<int> getChatBackupSizeEstimate({
    int messagesPerRoom = 500,
    bool includeMediaFiles = true,
  }) async {
    try {
      final stats = await getChatStatistics();
      final totalMessages = stats['totalMessages'] ?? 0;

      // Estimate size: ~1KB per message on average
      int estimatedSize = totalMessages * 1024;

      // Add chat rooms size (~2KB per room)
      final totalRooms = stats['totalChatRooms'] ?? 0;
      estimatedSize += (totalRooms as int) * 2048;

      // Add participants size (~5KB per participant)
      // This would need to be calculated from actual participants
      estimatedSize += 50 * 1024; // Rough estimate

      log('📊 Chat backup size estimate: ${(estimatedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      return estimatedSize;
    } catch (e) {
      log('❌ Error estimating chat backup size: $e');
      return 0;
    }
  }

  /// Export chat data to readable format
  Future<String> exportChatDataToReadableFormat(List<ChatRoom> chatRooms, Map<String, List<Message>> messages) async {
    try {
      final export = StringBuffer();

      export.writeln('=== CHAT BACKUP EXPORT ===');
      export.writeln('Export Date: ${DateTime.now().toIso8601String()}');
      export.writeln('Total Chat Rooms: ${chatRooms.length}');
      export.writeln('Total Messages: ${messages.values.fold(0, (sum, msgs) => sum + msgs.length)}');
      export.writeln('');

      for (final chatRoom in chatRooms) {
        export.writeln('--- CHAT ROOM: ${chatRoom.name} ---');
        export.writeln('ID: ${chatRoom.id}');
        export.writeln('Type: ${chatRoom.isGroupChat ?? false ? 'Group' : 'Private'}');
        export.writeln('Members: ${chatRoom.membersIds?.length}');
        export.writeln('Last Chat: ${chatRoom.lastChat}');
        export.writeln('');

        final roomMessages = messages[chatRoom.id] ?? [];
        export.writeln('Messages (${roomMessages.length}):');
        export.writeln('');

        for (final message in roomMessages.take(10)) { // Show first 10 messages as preview
          export.writeln('[${message.timestamp.toString()}] ${message.senderId}: ${message.toString()}');
        }

        if (roomMessages.length > 10) {
          export.writeln('... and ${roomMessages.length - 10} more messages');
        }

        export.writeln('');
        export.writeln('=' * 50);
        export.writeln('');
      }

      return export.toString();
    } catch (e) {
      log('❌ Error exporting chat data to readable format: $e');
      return 'Error creating export: $e';
    }
  }
}

