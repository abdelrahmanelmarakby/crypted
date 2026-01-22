// Offline Queue Service
// Provides concrete implementations for offline operation handlers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:flutter/foundation.dart';

/// Service to initialize and manage offline queue handlers
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  final OfflineQueue _queue = OfflineQueue();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initialize the offline queue service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _queue.initialize();

    // Register all handlers with concrete implementations
    _queue.registerHandlers(
      sendMessage: _handleSendMessage,
      deleteMessage: _handleDeleteMessage,
      editMessage: _handleEditMessage,
      markAsRead: _handleMarkAsRead,
      toggleReaction: _handleToggleReaction,
      updateChatRoom: _handleUpdateChatRoom,
      addMember: _handleAddMember,
      removeMember: _handleRemoveMember,
    );

    _isInitialized = true;

    if (kDebugMode) {
      print('[OfflineQueueService] Initialized with handlers registered');
    }
  }

  /// Get the queue instance
  OfflineQueue get queue => _queue;

  // =================== HANDLER IMPLEMENTATIONS ===================

  /// Send a message to Firestore
  Future<void> _handleSendMessage(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final messageData = data['message'] as Map<String, dynamic>?;

    if (roomId == null || messageData == null) {
      throw ArgumentError('Missing roomId or message data');
    }

    // Remove local-only fields before sending
    final cleanedData = Map<String, dynamic>.from(messageData);
    cleanedData.remove('isLocal');
    cleanedData.remove('localId');

    // Ensure timestamp is a server timestamp for consistency
    cleanedData['timestamp'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .add(cleanedData);

    // Update last message in chat room
    final lastMessagePreview = _getMessagePreview(messageData);
    await _firestore.collection(FirebaseCollections.chats).doc(roomId).update({
      'lastMessage': lastMessagePreview,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': messageData['senderId'],
    });

    if (kDebugMode) {
      print('[OfflineQueueService] Message sent to room: $roomId');
    }
  }

  /// Delete a message from Firestore
  Future<void> _handleDeleteMessage(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final messageId = data['messageId'] as String?;

    if (roomId == null || messageId == null) {
      throw ArgumentError('Missing roomId or messageId');
    }

    await _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .doc(messageId)
        .delete();

    if (kDebugMode) {
      print('[OfflineQueueService] Message deleted: $messageId from room: $roomId');
    }
  }

  /// Edit a message in Firestore
  Future<void> _handleEditMessage(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final messageId = data['messageId'] as String?;
    final newText = data['newText'] as String?;

    if (roomId == null || messageId == null || newText == null) {
      throw ArgumentError('Missing roomId, messageId, or newText');
    }

    await _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      print('[OfflineQueueService] Message edited: $messageId in room: $roomId');
    }
  }

  /// Mark messages as read in Firestore
  Future<void> _handleMarkAsRead(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final messageIds = (data['messageIds'] as List<dynamic>?)?.cast<String>();
    final userId = data['userId'] as String?;

    if (roomId == null || messageIds == null || userId == null) {
      throw ArgumentError('Missing roomId, messageIds, or userId');
    }

    // Batch update for efficiency
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      final docRef = _firestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      batch.update(docRef, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();

    if (kDebugMode) {
      print('[OfflineQueueService] Marked ${messageIds.length} messages as read in room: $roomId');
    }
  }

  /// Toggle a reaction on a message in Firestore
  Future<void> _handleToggleReaction(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final messageId = data['messageId'] as String?;
    final emoji = data['emoji'] as String?;
    final userId = data['userId'] as String?;

    if (roomId == null || messageId == null || emoji == null || userId == null) {
      throw ArgumentError('Missing roomId, messageId, emoji, or userId');
    }

    final docRef = _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .doc(messageId);

    // Use transaction to safely toggle reaction
    // Reactions are stored as a List of {emoji, userId} maps
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentData = snapshot.data() ?? {};
      final reactions = List<dynamic>.from(currentData['reactions'] ?? []);

      // Check if user already reacted with this emoji
      final existingIndex = reactions.indexWhere(
        (r) => r is Map && r['emoji'] == emoji && r['userId'] == userId,
      );

      if (existingIndex != -1) {
        // Remove existing reaction
        reactions.removeAt(existingIndex);
      } else {
        // Add new reaction
        reactions.add({'emoji': emoji, 'userId': userId});
      }

      transaction.update(docRef, {'reactions': reactions});
    });

    if (kDebugMode) {
      print('[OfflineQueueService] Toggled reaction $emoji on message: $messageId');
    }
  }

  /// Update chat room info in Firestore
  Future<void> _handleUpdateChatRoom(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;

    if (roomId == null) {
      throw ArgumentError('Missing roomId');
    }

    final updates = <String, dynamic>{};

    if (data['name'] != null) {
      updates['name'] = data['name'];
    }
    if (data['description'] != null) {
      updates['description'] = data['description'];
    }
    if (data['imageUrl'] != null) {
      updates['groupImageUrl'] = data['imageUrl'];
    }

    if (updates.isEmpty) {
      if (kDebugMode) {
        print('[OfflineQueueService] No updates to apply for room: $roomId');
      }
      return;
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(FirebaseCollections.chats).doc(roomId).update(updates);

    if (kDebugMode) {
      print('[OfflineQueueService] Updated chat room: $roomId with ${updates.keys}');
    }
  }

  /// Add a member to a chat room in Firestore
  Future<void> _handleAddMember(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final memberData = data['memberData'] as Map<String, dynamic>?;

    if (roomId == null || memberData == null) {
      throw ArgumentError('Missing roomId or memberData');
    }

    final memberId = memberData['uid'] as String?;
    if (memberId == null) {
      throw ArgumentError('Member data missing uid');
    }

    await _firestore.collection(FirebaseCollections.chats).doc(roomId).update({
      'members': FieldValue.arrayUnion([memberData]),
      'membersIds': FieldValue.arrayUnion([memberId]),
    });

    if (kDebugMode) {
      print('[OfflineQueueService] Added member $memberId to room: $roomId');
    }
  }

  /// Remove a member from a chat room in Firestore
  Future<void> _handleRemoveMember(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String?;
    final memberId = data['memberId'] as String?;

    if (roomId == null || memberId == null) {
      throw ArgumentError('Missing roomId or memberId');
    }

    // Need to get current member data to remove the full object
    final roomDoc = await _firestore.collection(FirebaseCollections.chats).doc(roomId).get();
    if (!roomDoc.exists) return;

    final roomData = roomDoc.data() ?? {};
    final members = List<Map<String, dynamic>>.from(roomData['members'] ?? []);
    final memberToRemove = members.firstWhere(
      (m) => m['uid'] == memberId,
      orElse: () => {},
    );

    if (memberToRemove.isEmpty) {
      if (kDebugMode) {
        print('[OfflineQueueService] Member $memberId not found in room: $roomId');
      }
      return;
    }

    await _firestore.collection(FirebaseCollections.chats).doc(roomId).update({
      'members': FieldValue.arrayRemove([memberToRemove]),
      'membersIds': FieldValue.arrayRemove([memberId]),
    });

    if (kDebugMode) {
      print('[OfflineQueueService] Removed member $memberId from room: $roomId');
    }
  }

  // =================== HELPERS ===================

  /// Get a preview string for the last message
  String _getMessagePreview(Map<String, dynamic> messageData) {
    final type = messageData['type'] as String? ?? 'text';

    switch (type) {
      case 'photo':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      case 'file':
        final fileName = messageData['fileName'] as String? ?? 'File';
        return '📄 $fileName';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'poll':
        return '📊 Poll';
      default:
        return messageData['text'] as String? ?? '';
    }
  }

  /// Dispose resources
  void dispose() {
    _queue.dispose();
  }
}
