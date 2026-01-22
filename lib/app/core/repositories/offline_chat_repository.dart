// Offline-First Chat Repository
// Implements IChatRepository with local Hive storage and background sync

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/core/services/local_database_service.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/models/hive/hive_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// OfflineChatRepository - Offline-first implementation of IChatRepository
/// Reads from Hive first, syncs with Firestore in background
class OfflineChatRepository implements IChatRepository {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final OfflineQueue _offlineQueue = OfflineQueue();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Stream controllers for reactive updates
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final StreamController<List<ChatRoom>> _chatRoomsController =
      StreamController<List<ChatRoom>>.broadcast();

  // Firestore subscriptions for real-time updates
  final Map<String, StreamSubscription> _firestoreSubscriptions = {};

  /// Get the current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // =================== CHAT ROOM QUERIES ===================

  @override
  Stream<List<ChatRoom>> getChatRooms({
    bool groupOnly = false,
    bool privateOnly = false,
  }) async* {
    final userId = _currentUserId;
    if (userId == null) {
      yield [];
      return;
    }

    // First emit from local cache
    final localRooms = await _localDb.getChatRooms();
    final filteredRooms = _filterRooms(localRooms, groupOnly, privateOnly);
    yield filteredRooms.map((h) => h.toChatRoom()).toList();

    // Then sync with Firestore and listen for updates
    if (ConnectivityService().isOnline) {
      yield* _firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: userId)
          .snapshots()
          .asyncMap((snapshot) async {
        final rooms = <HiveChatRoom>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;

          final room = HiveChatRoom.fromMap(data, isSynced: true);
          rooms.add(room);
        }

        // Update local cache
        await _localDb.saveChatRooms(rooms);

        final filtered = _filterRooms(rooms, groupOnly, privateOnly);
        return filtered.map((h) => h.toChatRoom()).toList();
      });
    }
  }

  List<HiveChatRoom> _filterRooms(
    List<HiveChatRoom> rooms,
    bool groupOnly,
    bool privateOnly,
  ) {
    if (groupOnly) {
      return rooms.where((r) => r.isGroup).toList();
    } else if (privateOnly) {
      return rooms.where((r) => !r.isGroup).toList();
    }
    return rooms;
  }

  @override
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    // Check local first
    final local = await _localDb.getChatRoom(roomId);
    if (local != null) return local.toChatRoom();

    // Fall back to Firestore if online
    if (ConnectivityService().isOnline) {
      try {
        final doc = await _firestore.collection(FirebaseCollections.chats).doc(roomId).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;

          final room = HiveChatRoom.fromMap(data, isSynced: true);
          await _localDb.saveChatRoom(room);
          return room.toChatRoom();
        }
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error fetching room: $e');
      }
    }

    return null;
  }

  @override
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    // Check local cache first
    final localRooms = await _localDb.getChatRooms();
    for (final room in localRooms) {
      if (!room.isGroup &&
          room.memberIds.length == memberIds.length &&
          room.memberIds.toSet().containsAll(memberIds)) {
        return room.toChatRoom();
      }
    }

    // Fall back to Firestore
    if (ConnectivityService().isOnline) {
      try {
        final sortedIds = List<String>.from(memberIds)..sort();
        final query = await _firestore
            .collection(FirebaseCollections.chats)
            .where('membersIds', arrayContains: sortedIds.first)
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          final roomMemberIds = (data['membersIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final sortedRoomIds = List<String>.from(roomMemberIds)..sort();

          if (data['isGroupChat'] != true &&
              sortedRoomIds.length == sortedIds.length &&
              sortedRoomIds.join() == sortedIds.join()) {
            data['id'] = doc.id;
            final room = HiveChatRoom.fromMap(data, isSynced: true);
            await _localDb.saveChatRoom(room);
            return room.toChatRoom();
          }
        }
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error finding room: $e');
      }
    }

    return null;
  }

  @override
  Future<bool> chatRoomExists(String roomId) async {
    final room = await getChatRoomById(roomId);
    return room != null;
  }

  // =================== CHAT ROOM MANAGEMENT ===================

  @override
  Future<ChatRoom> createChatRoom({
    required List<SocialMediaUser> members,
    bool isGroupChat = false,
    String? groupName,
    String? groupDescription,
    String? roomId,
  }) async {
    final id = roomId ?? _uuid.v4();
    final userId = _currentUserId;

    final memberIds = members.map((m) => m.uid ?? '').toList();

    final room = ChatRoom(
      id: id,
      name: groupName,
      description: groupDescription,
      isGroupChat: isGroupChat,
      members: members,
      membersIds: memberIds,
      adminIds: userId != null ? [userId] : [],
      createdBy: userId,
      lastMsg: '',
      read: true,
      isMuted: false,
      isPinned: false,
      isArchived: false,
      isFavorite: false,
    );

    // Save locally first
    final hiveRoom = HiveChatRoom.fromChatRoom(room, isSynced: false);
    await _localDb.saveChatRoom(hiveRoom);

    // Queue for Firestore sync
    if (ConnectivityService().isOnline) {
      try {
        await _firestore.collection(FirebaseCollections.chats).doc(id).set(room.toMap());
        await _localDb.saveChatRoom(hiveRoom.copyWith(isSynced: true));
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error creating room: $e');
        // Will be synced later
      }
    }

    return room;
  }

  @override
  Future<bool> addMember({
    required String roomId,
    required SocialMediaUser member,
  }) async {
    // Update local
    await _localDb.updateChatRoom(roomId, (room) {
      final members = List<String>.from(room.memberIds);
      if (member.uid != null && !members.contains(member.uid)) {
        members.add(member.uid!);
      }
      return room.copyWith(memberIds: members, isSynced: false);
    });

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.addMember,
      {'roomId': roomId, 'memberData': member.toMap()},
    );

    return true;
  }

  @override
  Future<bool> removeMember({
    required String roomId,
    required String memberId,
  }) async {
    // Update local
    await _localDb.updateChatRoom(roomId, (room) {
      final members = List<String>.from(room.memberIds);
      members.remove(memberId);
      return room.copyWith(memberIds: members, isSynced: false);
    });

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.removeMember,
      {'roomId': roomId, 'memberId': memberId},
    );

    return true;
  }

  @override
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    // Update local
    await _localDb.updateChatRoom(roomId, (room) {
      return room.copyWith(
        name: name ?? room.name,
        groupImageUrl: imageUrl ?? room.groupImageUrl,
        isSynced: false,
      );
    });

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.updateChatRoom,
      {
        'roomId': roomId,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
      },
    );

    return true;
  }

  @override
  Future<bool> deleteChatRoom(String roomId) async {
    await _localDb.deleteChatRoom(roomId);

    if (ConnectivityService().isOnline) {
      try {
        await _firestore.collection(FirebaseCollections.chats).doc(roomId).delete();
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error deleting room: $e');
      }
    }

    return true;
  }

  // =================== MESSAGE OPERATIONS ===================

  @override
  Stream<List<Message>> getMessages(String roomId) {
    // Get or create stream controller
    _messageControllers.putIfAbsent(
      roomId,
      () => StreamController<List<Message>>.broadcast(),
    );

    // Emit local messages immediately
    _emitLocalMessages(roomId);

    // Start real-time sync if online
    if (ConnectivityService().isOnline) {
      _startMessageListener(roomId);
    }

    return _messageControllers[roomId]!.stream;
  }

  Future<void> _emitLocalMessages(String roomId) async {
    final localMessages = await _localDb.getMessages(roomId, limit: 100);
    final messages = localMessages.map((h) => h.toMessage()).toList();

    // Sort by timestamp (oldest first for chat display)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (_messageControllers[roomId]?.isClosed == false) {
      _messageControllers[roomId]!.add(messages);
    }
  }

  void _startMessageListener(String roomId) {
    if (_firestoreSubscriptions.containsKey(roomId)) return;

    final subscription = _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          data['id'] = change.doc.id;
          data['roomId'] = roomId;

          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              final message = HiveMessage.fromMap(data, isSynced: true);
              await _localDb.saveMessage(message);
              break;

            case DocumentChangeType.removed:
              await _localDb.deleteMessage(roomId, change.doc.id);
              break;
          }
        }

        // Re-emit updated messages
        await _emitLocalMessages(roomId);
      },
      onError: (error) {
        if (kDebugMode) {
          print('[OfflineChatRepository] Message listener error: $error');
        }
      },
    );

    _firestoreSubscriptions[roomId] = subscription;
  }

  @override
  Future<void> sendMessage({
    required Message message,
    required String roomId,
    required List<SocialMediaUser> members,
  }) async {
    // Generate local ID if needed
    final localId = _uuid.v4();
    final messageData = message.toMap();
    messageData['roomId'] = roomId;
    messageData['localId'] = localId;

    // Save locally with isSynced = false (optimistic UI)
    final hiveMessage = HiveMessage.fromMap(
      messageData,
      isSynced: false,
      localId: localId,
    );
    await _localDb.saveMessage(hiveMessage);

    // Update room's last message
    await _localDb.updateRoomLastMessage(
      roomId,
      lastMessage: hiveMessage.previewText,
      lastMessageTime: hiveMessage.timestamp,
      lastSenderId: hiveMessage.senderId,
    );

    // Emit updated messages immediately (optimistic UI)
    await _emitLocalMessages(roomId);

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.sendMessage,
      {'roomId': roomId, 'message': messageData},
    );
  }

  @override
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String senderId,
  }) async {
    // Update local
    final message = await _localDb.getMessage(roomId, messageId);
    if (message != null) {
      final data = message.toDataMap();
      data['text'] = newText;
      data['isEdited'] = true;
      data['editedAt'] = DateTime.now().toIso8601String();

      final updated = HiveMessage.fromMap(data, isSynced: false);
      await _localDb.saveMessage(updated);
      await _emitLocalMessages(roomId);
    }

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.editMessage,
      {'roomId': roomId, 'messageId': messageId, 'newText': newText},
    );
  }

  @override
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    // Mark as deleted locally (soft delete)
    final message = await _localDb.getMessage(roomId, messageId);
    if (message != null) {
      final data = message.toDataMap();
      data['isDeleted'] = true;

      final updated = HiveMessage.fromMap(data, isSynced: false);
      await _localDb.saveMessage(updated);
      await _emitLocalMessages(roomId);
    }

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.deleteMessage,
      {'roomId': roomId, 'messageId': messageId},
    );
  }

  @override
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  }) async {
    // Update local
    final message = await _localDb.getMessage(roomId, messageId);
    if (message != null) {
      final data = message.toDataMap();
      data.addAll(updates);

      final updated = HiveMessage.fromMap(data, isSynced: false);
      await _localDb.saveMessage(updated);
      await _emitLocalMessages(roomId);
    }

    // Direct Firestore update if online
    if (ConnectivityService().isOnline) {
      try {
        await _firestore
            .collection(FirebaseCollections.chats)
            .doc(roomId)
            .collection(FirebaseCollections.chatMessages)
            .doc(messageId)
            .update(updates);

        await _localDb.updateMessageSyncStatus(roomId, messageId, true);
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error updating message: $e');
      }
    }
  }

  // =================== REACTIONS ===================

  @override
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    // Update local
    final message = await _localDb.getMessage(roomId, messageId);
    if (message != null) {
      final data = message.toDataMap();
      final reactions = List<dynamic>.from(data['reactions'] ?? []);

      // Check if reaction exists
      final existingIndex = reactions.indexWhere(
        (r) => r['emoji'] == emoji && r['userId'] == userId,
      );

      if (existingIndex >= 0) {
        reactions.removeAt(existingIndex);
      } else {
        reactions.add({'emoji': emoji, 'userId': userId});
      }

      data['reactions'] = reactions;
      final updated = HiveMessage.fromMap(data, isSynced: false);
      await _localDb.saveMessage(updated);
      await _emitLocalMessages(roomId);
    }

    // Queue for sync
    await _offlineQueue.enqueue(
      OperationType.toggleReaction,
      {
        'roomId': roomId,
        'messageId': messageId,
        'emoji': emoji,
        'userId': userId,
      },
    );
  }

  // =================== POLLS ===================

  @override
  Future<void> votePoll({
    required String roomId,
    required String messageId,
    required int optionIndex,
    required String userId,
    required bool allowMultipleVotes,
  }) async {
    // Update local
    final message = await _localDb.getMessage(roomId, messageId);
    if (message != null) {
      final data = message.toDataMap();
      final votes = Map<String, List<dynamic>>.from(data['votes'] ?? {});
      final key = optionIndex.toString();

      if (!allowMultipleVotes) {
        // Remove previous votes
        for (final voteList in votes.values) {
          voteList.remove(userId);
        }
      }

      votes.putIfAbsent(key, () => []);
      if (votes[key]!.contains(userId)) {
        votes[key]!.remove(userId);
      } else {
        votes[key]!.add(userId);
      }

      data['votes'] = votes;
      final updated = HiveMessage.fromMap(data, isSynced: false);
      await _localDb.saveMessage(updated);
      await _emitLocalMessages(roomId);
    }

    // Sync to Firestore if online
    if (ConnectivityService().isOnline) {
      try {
        await _firestore.runTransaction((transaction) async {
          final docRef = _firestore
              .collection(FirebaseCollections.chats)
              .doc(roomId)
              .collection(FirebaseCollections.chatMessages)
              .doc(messageId);

          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) return;

          final currentData = snapshot.data() ?? {};
          final currentVotes =
              Map<String, List<dynamic>>.from(currentData['votes'] ?? {});
          final key = optionIndex.toString();

          if (!allowMultipleVotes) {
            for (final voteList in currentVotes.values) {
              voteList.remove(userId);
            }
          }

          currentVotes.putIfAbsent(key, () => []);
          if (currentVotes[key]!.contains(userId)) {
            currentVotes[key]!.remove(userId);
          } else {
            currentVotes[key]!.add(userId);
          }

          transaction.update(docRef, {'votes': currentVotes});
        });

        await _localDb.updateMessageSyncStatus(roomId, messageId, true);
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error voting: $e');
      }
    }
  }

  // =================== CHAT ROOM ACTIONS ===================

  Future<void> _updateRoomProperty(
    String roomId,
    String property,
    bool Function(bool current) toggle,
  ) async {
    // Update local
    await _localDb.updateChatRoom(roomId, (room) {
      switch (property) {
        case 'isMuted':
          return room.copyWith(isMuted: toggle(room.isMuted));
        case 'isPinned':
          return room.copyWith(isPinned: toggle(room.isPinned));
        case 'isArchived':
          return room.copyWith(isArchived: toggle(room.isArchived));
        case 'isFavorite':
          return room.copyWith(isFavorite: toggle(room.isFavorite));
        default:
          return room;
      }
    });

    // Sync to Firestore
    if (ConnectivityService().isOnline) {
      final room = await _localDb.getChatRoom(roomId);
      if (room != null) {
        final value = switch (property) {
          'isMuted' => room.isMuted,
          'isPinned' => room.isPinned,
          'isArchived' => room.isArchived,
          'isFavorite' => room.isFavorite,
          _ => false,
        };

        try {
          await _firestore
              .collection(FirebaseCollections.chats)
              .doc(roomId)
              .update({property: value});
        } catch (e) {
          if (kDebugMode) print('[OfflineChatRepository] Error updating $property: $e');
        }
      }
    }
  }

  @override
  Future<void> toggleMute(String roomId) =>
      _updateRoomProperty(roomId, 'isMuted', (current) => !current);

  @override
  Future<void> togglePin(String roomId) =>
      _updateRoomProperty(roomId, 'isPinned', (current) => !current);

  @override
  Future<void> toggleArchive(String roomId) =>
      _updateRoomProperty(roomId, 'isArchived', (current) => !current);

  @override
  Future<void> toggleFavorite(String roomId) =>
      _updateRoomProperty(roomId, 'isFavorite', (current) => !current);

  @override
  Future<void> blockUser(String roomId, String userId) async {
    if (ConnectivityService().isOnline) {
      try {
        await _firestore.collection(FirebaseCollections.chats).doc(roomId).update({
          'blockedUsers': FieldValue.arrayUnion([userId]),
        });
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error blocking user: $e');
      }
    }
  }

  @override
  Future<void> unblockUser(String roomId, String userId) async {
    if (ConnectivityService().isOnline) {
      try {
        await _firestore.collection(FirebaseCollections.chats).doc(roomId).update({
          'blockedUsers': FieldValue.arrayRemove([userId]),
        });
      } catch (e) {
        if (kDebugMode) print('[OfflineChatRepository] Error unblocking user: $e');
      }
    }
  }

  @override
  Future<void> clearChat(String roomId) async {
    await _localDb.deleteMessagesForRoom(roomId);
    await _emitLocalMessages(roomId);

    // Note: Usually don't clear remote messages, just local
  }

  @override
  Future<void> exitGroup(String roomId, String userId) async {
    await removeMember(roomId: roomId, memberId: userId);
    await _localDb.deleteChatRoom(roomId);
  }

  // =================== MEDIA & SEARCH ===================

  @override
  Future<List<Message>> getMediaMessages(String roomId, {String? mediaType}) async {
    final messages = await _localDb.getMessages(roomId, limit: 500);

    return messages
        .where((m) {
          final type = m.type;
          if (mediaType != null) return type == mediaType;
          return ['photo', 'video', 'audio', 'file'].contains(type);
        })
        .map((h) => h.toMessage())
        .toList();
  }

  @override
  Future<List<Message>> getPinnedMessages(String roomId) async {
    final messages = await _localDb.getMessages(roomId, limit: 500);

    return messages
        .where((m) {
          final data = m.toDataMap();
          return data['isPinned'] == true;
        })
        .map((h) => h.toMessage())
        .toList();
  }

  @override
  Future<List<Message>> getFavoriteMessages(String roomId) async {
    final messages = await _localDb.getMessages(roomId, limit: 500);

    return messages
        .where((m) {
          final data = m.toDataMap();
          return data['isFavorite'] == true;
        })
        .map((h) => h.toMessage())
        .toList();
  }

  @override
  Future<List<Message>> searchMessages(String roomId, String query) async {
    final results = await _localDb.searchMessages(query, roomId: roomId);
    return results.map((h) => h.toMessage()).toList();
  }

  // =================== CLEANUP ===================

  /// Dispose resources
  void dispose() {
    // Close all message controllers
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();

    // Cancel Firestore subscriptions
    for (final subscription in _firestoreSubscriptions.values) {
      subscription.cancel();
    }
    _firestoreSubscriptions.clear();

    // Close rooms controller
    _chatRoomsController.close();
  }

  /// Stop listening to a specific room
  void stopListening(String roomId) {
    _messageControllers[roomId]?.close();
    _messageControllers.remove(roomId);

    _firestoreSubscriptions[roomId]?.cancel();
    _firestoreSubscriptions.remove(roomId);
  }
}
