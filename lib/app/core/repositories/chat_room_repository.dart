// ARCH-002 FIX: Dedicated Chat Room Repository
// Separates room management from message operations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/entities/chat_entity.dart';
import 'package:crypted_app/app/domain/mappers/chat_mapper.dart';
import 'package:flutter/foundation.dart';

/// Abstract interface for chat room operations
abstract class IChatRoomRepository {
  /// Get all chat rooms for current user
  Stream<List<ChatRoom>> getChatRooms({
    bool groupOnly = false,
    bool privateOnly = false,
    bool archivedOnly = false,
  });

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoomById(String roomId);

  /// Find existing chat room between members
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds);

  /// Create a new chat room
  Future<ChatRoom> createChatRoom({
    required List<SocialMediaUser> members,
    bool isGroupChat = false,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
  });

  /// Update chat room details
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  });

  /// Delete a chat room
  Future<bool> deleteChatRoom(String roomId);

  /// Add a member to a chat room
  Future<bool> addMember({
    required String roomId,
    required SocialMediaUser member,
  });

  /// Remove a member from a chat room
  Future<bool> removeMember({
    required String roomId,
    required String memberId,
  });

  /// Toggle mute status
  Future<void> toggleMute(String roomId, String userId);

  /// Toggle pin status
  Future<void> togglePin(String roomId, String userId);

  /// Toggle archive status
  Future<void> toggleArchive(String roomId, String userId);

  /// Get archived chat rooms
  Future<List<ChatRoom>> getArchivedRooms(String userId);

  /// Update last message info
  Future<void> updateLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime timestamp,
    required String senderId,
  });

  // ========== DOMAIN LAYER METHODS (ChatEntity) ==========

  /// Get all chat rooms as domain entities
  Stream<List<ChatEntity>> getChatEntities({
    bool groupOnly = false,
    bool privateOnly = false,
    bool archivedOnly = false,
  });

  /// Get a specific chat room as domain entity
  Future<ChatEntity?> getChatEntityById(String roomId);

  /// Find existing chat room as domain entity
  Future<ChatEntity?> findExistingChatEntity(List<String> memberIds);
}

/// Firebase implementation of IChatRoomRepository
class FirebaseChatRoomRepository implements IChatRoomRepository {
  final FirebaseFirestore _firestore;
  final String _currentUserId;

  FirebaseChatRoomRepository({
    FirebaseFirestore? firestore,
    required String currentUserId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _currentUserId = currentUserId;

  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection(FirebaseCollections.chats);

  @override
  Stream<List<ChatRoom>> getChatRooms({
    bool groupOnly = false,
    bool privateOnly = false,
    bool archivedOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _chatsCollection
        .where('membersIds', arrayContains: _currentUserId)
        .orderBy('lastMessageTime', descending: true);

    if (groupOnly) {
      query = query.where('isGroupChat', isEqualTo: true);
    } else if (privateOnly) {
      query = query.where('isGroupChat', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return ChatRoom.fromMap(data);
            } catch (e) {
              _logError('getChatRooms', e);
              return null;
            }
          })
          .where((room) => room != null)
          .cast<ChatRoom>()
          .where((room) {
            // Filter by archive status client-side
            final isArchived = room.isArchived ?? false;
            return archivedOnly ? isArchived : !isArchived;
          })
          .toList();
    });
  }

  @override
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      final doc = await _chatsCollection.doc(roomId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return ChatRoom.fromMap(data);
    } catch (e) {
      _logError('getChatRoomById', e);
      return null;
    }
  }

  @override
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    try {
      // Sort member IDs for consistent matching
      final sortedIds = List<String>.from(memberIds)..sort();

      // Query for private chats with exact member match
      final snapshot = await _chatsCollection
          .where('isGroupChat', isEqualTo: false)
          .where('membersIds', isEqualTo: sortedIds)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return ChatRoom.fromMap(data);
    } catch (e) {
      _logError('findExistingChatRoom', e);
      return null;
    }
  }

  @override
  Future<ChatRoom> createChatRoom({
    required List<SocialMediaUser> members,
    bool isGroupChat = false,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
  }) async {
    final memberIds = members.map((m) => m.uid ?? '').where((id) => id.isNotEmpty).toList()..sort();

    final roomId = _generateRoomId(memberIds, isGroupChat);

    final roomData = {
      'id': roomId,
      'isGroupChat': isGroupChat,
      'membersIds': memberIds,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'userSettings': {},
      if (isGroupChat) ...{
        'groupName': groupName ?? 'New Group',
        'groupDescription': groupDescription ?? '',
        'groupImageUrl': groupImageUrl ?? '',
        'adminIds': [_currentUserId],
      },
    };

    await _chatsCollection.doc(roomId).set(roomData);

    final doc = await _chatsCollection.doc(roomId).get();
    final data = doc.data()!;
    data['id'] = doc.id;
    return ChatRoom.fromMap(data);
  }

  @override
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['groupName'] = name;
      if (description != null) updates['groupDescription'] = description;
      if (imageUrl != null) updates['groupImageUrl'] = imageUrl;

      if (updates.isEmpty) return true;

      await _chatsCollection.doc(roomId).update(updates);
      return true;
    } catch (e) {
      _logError('updateChatRoom', e);
      return false;
    }
  }

  @override
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      // Delete all messages in the room first
      final messagesSnapshot = await _chatsCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the room itself
      batch.delete(_chatsCollection.doc(roomId));

      await batch.commit();
      return true;
    } catch (e) {
      _logError('deleteChatRoom', e);
      return false;
    }
  }

  @override
  Future<bool> addMember({
    required String roomId,
    required SocialMediaUser member,
  }) async {
    try {
      await _chatsCollection.doc(roomId).update({
        'membersIds': FieldValue.arrayUnion([member.uid]),
        'members': FieldValue.arrayUnion([member.toMap()]),
      });
      return true;
    } catch (e) {
      _logError('addMember', e);
      return false;
    }
  }

  @override
  Future<bool> removeMember({
    required String roomId,
    required String memberId,
  }) async {
    try {
      // Get current room data to find the member object
      final room = await getChatRoomById(roomId);
      if (room == null) return false;

      final memberToRemove = room.members?.firstWhere(
        (m) => m.uid == memberId,
        orElse: () => SocialMediaUser(),
      );

      await _chatsCollection.doc(roomId).update({
        'membersIds': FieldValue.arrayRemove([memberId]),
        if (memberToRemove != null)
          'members': FieldValue.arrayRemove([memberToRemove.toMap()]),
      });
      return true;
    } catch (e) {
      _logError('removeMember', e);
      return false;
    }
  }

  @override
  Future<void> toggleMute(String roomId, String userId) async {
    await _toggleUserSetting(roomId, userId, 'muted');
  }

  @override
  Future<void> togglePin(String roomId, String userId) async {
    await _toggleUserSetting(roomId, userId, 'pinned');
  }

  @override
  Future<void> toggleArchive(String roomId, String userId) async {
    await _toggleUserSetting(roomId, userId, 'archived');
  }

  Future<void> _toggleUserSetting(
    String roomId,
    String userId,
    String setting,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _chatsCollection.doc(roomId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final userSettings = Map<String, dynamic>.from(data['userSettings'] ?? {});
      final currentUserSettings = Map<String, dynamic>.from(userSettings[userId] ?? {});

      currentUserSettings[setting] = !(currentUserSettings[setting] ?? false);
      userSettings[userId] = currentUserSettings;

      transaction.update(docRef, {'userSettings': userSettings});
    });
  }

  @override
  Future<List<ChatRoom>> getArchivedRooms(String userId) async {
    try {
      final snapshot = await _chatsCollection
          .where('membersIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return ChatRoom.fromMap(data);
            } catch (e) {
              return null;
            }
          })
          .where((room) => room != null)
          .cast<ChatRoom>()
          .where((room) {
            return room.isArchived ?? false;
          })
          .toList();
    } catch (e) {
      _logError('getArchivedRooms', e);
      return [];
    }
  }

  @override
  Future<void> updateLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime timestamp,
    required String senderId,
  }) async {
    await _chatsCollection.doc(roomId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(timestamp),
      'lastMessageSenderId': senderId,
    });
  }

  String _generateRoomId(List<String> memberIds, bool isGroupChat) {
    if (isGroupChat) {
      return 'group_${DateTime.now().millisecondsSinceEpoch}';
    }
    return memberIds.join('_');
  }

  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('FirebaseChatRoomRepository.$operation error: $error');
    }
  }

  // ========== DOMAIN LAYER METHODS (ChatEntity) ==========

  @override
  Stream<List<ChatEntity>> getChatEntities({
    bool groupOnly = false,
    bool privateOnly = false,
    bool archivedOnly = false,
  }) {
    return getChatRooms(
      groupOnly: groupOnly,
      privateOnly: privateOnly,
      archivedOnly: archivedOnly,
    ).map((rooms) => ChatMapper.toEntityList(rooms));
  }

  @override
  Future<ChatEntity?> getChatEntityById(String roomId) async {
    final room = await getChatRoomById(roomId);
    if (room == null) return null;
    return ChatMapper.toEntity(room);
  }

  @override
  Future<ChatEntity?> findExistingChatEntity(List<String> memberIds) async {
    final room = await findExistingChatRoom(memberIds);
    if (room == null) return null;
    return ChatMapper.toEntity(room);
  }
}
