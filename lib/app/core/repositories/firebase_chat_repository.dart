// ARCH-003 & ARCH-006 FIX: Firebase implementation of Chat Repository
// This encapsulates all Firebase-specific code in one place

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// Firebase implementation of IChatRepository
/// Wraps ChatDataSources and provides error handling
class FirebaseChatRepository implements IChatRepository {
  late ChatDataSources _dataSource;
  final FirebaseFirestore _firestore;

  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    List<SocialMediaUser>? members,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _dataSource = ChatDataSources(
      chatConfiguration: ChatConfiguration(members: members ?? []),
    );
  }

  /// Update the members configuration
  void updateMembers(List<SocialMediaUser> members) {
    _dataSource = ChatDataSources(
      chatConfiguration: ChatConfiguration(members: members),
    );
  }

  // =================== CHAT ROOM QUERIES ===================

  @override
  Stream<List<ChatRoom>> getChatRooms({
    bool groupOnly = false,
    bool privateOnly = false,
  }) {
    return _dataSource.getChats(
      getGroupChatOnly: groupOnly,
      getPrivateChatOnly: privateOnly,
    );
  }

  @override
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      return await _dataSource.getChatRoomById(roomId);
    } catch (e) {
      _logError('getChatRoomById', e);
      return null;
    }
  }

  @override
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    try {
      return await _dataSource.findExistingChatRoom(memberIds);
    } catch (e) {
      _logError('findExistingChatRoom', e);
      return null;
    }
  }

  @override
  Future<bool> chatRoomExists(String roomId) async {
    try {
      final room = await getChatRoomById(roomId);
      return room != null;
    } catch (e) {
      _logError('chatRoomExists', e);
      return false;
    }
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
    updateMembers(members);
    return await _dataSource.createNewChatRoom(
      members: members,
      isGroupChat: isGroupChat,
      groupName: groupName,
      groupDescription: groupDescription,
      roomId: roomId,
    );
  }

  @override
  Future<bool> addMember({
    required String roomId,
    required SocialMediaUser member,
  }) async {
    try {
      return await _dataSource.addMemberToChat(
        roomId: roomId,
        newMember: member,
      );
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
      return await _dataSource.removeMemberFromChat(
        roomId: roomId,
        memberIdToRemove: memberId,
      );
    } catch (e) {
      _logError('removeMember', e);
      return false;
    }
  }

  @override
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      return await _dataSource.updateChatRoomInfo(
        roomId: roomId,
        groupName: name,
        groupDescription: description,
        groupImageUrl: imageUrl,
      );
    } catch (e) {
      _logError('updateChatRoom', e);
      return false;
    }
  }

  @override
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      return await _dataSource.deleteRoom(roomId);
    } catch (e) {
      _logError('deleteChatRoom', e);
      return false;
    }
  }

  // =================== MESSAGE OPERATIONS ===================

  @override
  Stream<List<Message>> getMessages(String roomId) {
    return _dataSource.getLivePrivateMessage(roomId);
  }

  @override
  Future<void> sendMessage({
    required Message message,
    required String roomId,
    required List<SocialMediaUser> members,
  }) async {
    updateMembers(members);
    await _dataSource.sendMessage(
      privateMessage: message,
      roomId: roomId,
      members: members,
    );
  }

  @override
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String senderId,
  }) async {
    await _dataSource.editMessage(
      roomId: roomId,
      messageId: messageId,
      newText: newText,
      senderId: senderId,
    );
  }

  @override
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await _dataSource.deletePrivateMessage(messageId, roomId);
  }

  @override
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  }) async {
    await _dataSource.updateMessage(
      roomId: roomId,
      messageId: messageId,
      updates: updates,
    );
  }

  // =================== REACTIONS ===================

  @override
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    await _dataSource.toggleReaction(
      roomId: roomId,
      messageId: messageId,
      emoji: emoji,
      userId: userId,
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
    await _dataSource.votePoll(
      roomId: roomId,
      messageId: messageId,
      optionIndex: optionIndex,
      userId: userId,
      allowMultipleVotes: allowMultipleVotes,
    );
  }

  // =================== CHAT ROOM ACTIONS ===================

  @override
  Future<void> toggleMute(String roomId) async {
    await _dataSource.toggleMuteChat(roomId);
  }

  @override
  Future<void> togglePin(String roomId) async {
    await _dataSource.togglePinChat(roomId);
  }

  @override
  Future<void> toggleArchive(String roomId) async {
    await _dataSource.toggleArchiveChat(roomId);
  }

  @override
  Future<void> toggleFavorite(String roomId) async {
    await _dataSource.toggleFavoriteChat(roomId);
  }

  @override
  Future<void> blockUser(String roomId, String userId) async {
    await _dataSource.blockUser(roomId, userId);
  }

  @override
  Future<void> unblockUser(String roomId, String userId) async {
    await _dataSource.unblockUser(roomId, userId);
  }

  @override
  Future<void> clearChat(String roomId) async {
    await _dataSource.clearChat(roomId);
  }

  @override
  Future<void> exitGroup(String roomId, String userId) async {
    await _dataSource.exitGroup(roomId, userId);
  }

  // =================== MEDIA & SEARCH ===================

  @override
  Future<List<Message>> getMediaMessages(String roomId, {String? mediaType}) async {
    try {
      return await _dataSource.getMediaMessages(roomId, mediaType: mediaType);
    } catch (e) {
      _logError('getMediaMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> getPinnedMessages(String roomId) async {
    try {
      return await _dataSource.getPinnedMessages(roomId);
    } catch (e) {
      _logError('getPinnedMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> getFavoriteMessages(String roomId) async {
    try {
      return await _dataSource.getFavoriteMessages(roomId);
    } catch (e) {
      _logError('getFavoriteMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> searchMessages(String roomId, String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();

      // Firestore doesn't support full-text search, so we fetch messages
      // and filter client-side. For better performance at scale,
      // consider using Algolia, Typesense, or ElasticSearch.
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .orderBy('timestamp', descending: true)
          .limit(500) // Limit to recent messages for performance
          .get();

      final results = <Message>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          data['roomId'] = roomId;

          final text = (data['text'] as String?)?.toLowerCase() ?? '';
          final content = (data['content'] as String?)?.toLowerCase() ?? '';
          final fileName = (data['fileName'] as String?)?.toLowerCase() ?? '';

          // Check if any searchable field contains the query
          if (text.contains(queryLower) ||
              content.contains(queryLower) ||
              fileName.contains(queryLower)) {
            final message = Message.fromMap(data);
            results.add(message);
          }
        } catch (e) {
          // Skip malformed messages
          continue;
        }
      }

      return results;
    } catch (e) {
      _logError('searchMessages', e);
      return [];
    }
  }

  // =================== HELPERS ===================

  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('FirebaseChatRepository.$operation error: $error');
    }
  }

  /// Get the underlying data source for advanced operations
  /// Note: Try to avoid using this - prefer repository methods
  ChatDataSources get dataSource => _dataSource;
}
