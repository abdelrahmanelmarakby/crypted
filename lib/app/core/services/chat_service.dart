import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

/// Service layer for chat-related business logic
/// Handles all chat operations and data management
class ChatService {
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();

  ChatService._();

  late ChatDataSources _chatDataSource;

  /// Initialize chat data source with members
  void initializeChatDataSource(List<SocialMediaUser> members) {
    _chatDataSource = ChatDataSources(
      chatConfiguration: ChatConfiguration(members: members),
    );
  }

  /// Create a new chat room
  Future<ChatRoom?> createChatRoom({
    required List<SocialMediaUser> members,
    required bool isGroupChat,
    String? groupName,
    String? groupDescription,
    String? customRoomId,
  }) async {
    try {
      return await _chatDataSource.createNewChatRoom(
        members: members,
        isGroupChat: isGroupChat,
        groupName: groupName,
        groupDescription: groupDescription,
        roomId: customRoomId,
      );
    } catch (e) {
      print('❌ Error creating chat room: $e');
      rethrow;
    }
  }

  /// Send a message to a chat room
  Future<void> sendMessage({
    required Message message,
    required String roomId,
    required List<SocialMediaUser> members,
  }) async {
    try {
      await _chatDataSource.sendMessage(
        privateMessage: message,
        roomId: roomId,
        members: members,
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Post a message to chat (alternative method)
  Future<void> postMessageToChat(Message message, String roomId) async {
    try {
      await _chatDataSource.postMessageToChat(message, roomId);
    } catch (e) {
      print('❌ Error posting message to chat: $e');
      rethrow;
    }
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      return await _chatDataSource.getChatRoomById(roomId);
    } catch (e) {
      print('❌ Error getting chat room: $e');
      return null;
    }
  }

  /// Get all chats for current user
  Stream<List<ChatRoom>> getChats({
    bool getGroupChatOnly = false,
    bool getPrivateChatOnly = false,
  }) {
    try {
      return _chatDataSource.getChats(
        getGroupChatOnly: getGroupChatOnly,
        getPrivateChatOnly: getPrivateChatOnly,
      );
    } catch (e) {
      print('❌ Error getting chats: $e');
      return Stream.value([]);
    }
  }

  /// Find existing chat room between specific members
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    try {
      return await _chatDataSource.findExistingChatRoom(memberIds);
    } catch (e) {
      print('❌ Error finding existing chat room: $e');
      return null;
    }
  }

  /// Update chat room information
  Future<bool> updateChatRoomInfo({
    required String roomId,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
  }) async {
    try {
      return await _chatDataSource.updateChatRoomInfo(
        roomId: roomId,
        groupName: groupName,
        groupDescription: groupDescription,
        groupImageUrl: groupImageUrl,
      );
    } catch (e) {
      print('❌ Error updating chat room info: $e');
      return false;
    }
  }

  /// Add member to group chat
  Future<bool> addMemberToGroup({
    required String roomId,
    required SocialMediaUser newMember,
  }) async {
    try {
      return await _chatDataSource.addMemberToChat(
        roomId: roomId,
        newMember: newMember,
      );
    } catch (e) {
      print('❌ Error adding member to group: $e');
      return false;
    }
  }

  /// Remove member from group chat
  Future<bool> removeMemberFromGroup({
    required String roomId,
    required String memberId,
  }) async {
    try {
      return await _chatDataSource.removeMemberFromChat(
        roomId: roomId,
        memberIdToRemove: memberId,
      );
    } catch (e) {
      print('❌ Error removing member from group: $e');
      return false;
    }
  }

  /// Delete entire chat room
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      return await _chatDataSource.deleteRoom(roomId);
    } catch (e) {
      print('❌ Error deleting chat room: $e');
      return false;
    }
  }

  /// Get live messages for a chat room
  Stream<List<Message>> getLiveMessages(String roomId) {
    try {
      return _chatDataSource.getLivePrivateMessage(roomId);
    } catch (e) {
      print('❌ Error getting live messages: $e');
      return Stream.value([]);
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId, String roomId) async {
    try {
      await _chatDataSource.deletePrivateMessage(messageId, roomId);
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  /// Get member count for a chat room
  Future<int> getMemberCount(String roomId) async {
    try {
      return await _chatDataSource.getMemberCount(roomId);
    } catch (e) {
      print('❌ Error getting member count: $e');
      return 0;
    }
  }

  /// Check if chat room exists
  Future<bool> chatRoomExists() async {
    try {
      return await _chatDataSource.chatRoomExists();
    } catch (e) {
      print('❌ Error checking chat room existence: $e');
      return false;
    }
  }

  /// Validate chat room exists and user has access
  Future<bool> validateChatAccess(String roomId) async {
    try {
      final chatRoom = await getChatRoom(roomId);
      return chatRoom != null;
    } catch (e) {
      print('❌ Error validating chat access: $e');
      return false;
    }
  }

  /// Check if user can perform admin actions on chat
  Future<bool> canPerformAdminActions(String roomId) async {
    try {
      final chatRoom = await getChatRoom(roomId);
      if (chatRoom == null) return false;

      // For now, assume group chat creators are admins
      // This logic can be enhanced based on your requirements
      // You can add a 'createdBy' or 'adminIds' field to ChatRoom model if needed
      return chatRoom.isGroupChat ?? false;
    } catch (e) {
      print('❌ Error checking admin permissions: $e');
      return false;
    }
  }
}
