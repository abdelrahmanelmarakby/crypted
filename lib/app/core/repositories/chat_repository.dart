// ARCH-003 FIX: Repository Pattern for Chat Operations
// This abstracts Firebase operations and provides a clean interface for data access

import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

/// Abstract repository interface for chat operations
/// This allows for easy testing and backend switching
abstract class IChatRepository {
  // =================== CHAT ROOM QUERIES ===================

  /// Get all chat rooms for the current user
  Stream<List<ChatRoom>> getChatRooms({
    bool groupOnly = false,
    bool privateOnly = false,
  });

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoomById(String roomId);

  /// Find existing chat room between specific members
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds);

  /// Check if a chat room exists
  Future<bool> chatRoomExists(String roomId);

  // =================== CHAT ROOM MANAGEMENT ===================

  /// Create a new chat room
  Future<ChatRoom> createChatRoom({
    required List<SocialMediaUser> members,
    bool isGroupChat = false,
    String? groupName,
    String? groupDescription,
    String? roomId,
  });

  /// Add member to chat room
  Future<bool> addMember({
    required String roomId,
    required SocialMediaUser member,
  });

  /// Remove member from chat room
  Future<bool> removeMember({
    required String roomId,
    required String memberId,
  });

  /// Update chat room info
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  });

  /// Delete chat room
  Future<bool> deleteChatRoom(String roomId);

  // =================== MESSAGE OPERATIONS ===================

  /// Get live message stream for a chat room
  Stream<List<Message>> getMessages(String roomId);

  /// Send a message
  /// Returns the Firestore document ID of the created message
  Future<String> sendMessage({
    required Message message,
    required String roomId,
    required List<SocialMediaUser> members,
  });

  /// Edit a message
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String senderId,
  });

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  });

  /// Update message properties
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  });

  // =================== REACTIONS ===================

  /// Toggle reaction on a message
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  // =================== POLLS ===================

  /// Vote on a poll
  Future<void> votePoll({
    required String roomId,
    required String messageId,
    required int optionIndex,
    required String userId,
    required bool allowMultipleVotes,
  });

  // =================== CHAT ROOM ACTIONS ===================

  /// Toggle mute status
  Future<void> toggleMute(String roomId);

  /// Toggle pin status
  Future<void> togglePin(String roomId);

  /// Toggle archive status
  Future<void> toggleArchive(String roomId);

  /// Toggle favorite status
  Future<void> toggleFavorite(String roomId);

  /// Block a user in the chat
  Future<void> blockUser(String roomId, String userId);

  /// Unblock a user in the chat
  Future<void> unblockUser(String roomId, String userId);

  /// Clear all messages in chat
  Future<void> clearChat(String roomId);

  /// Exit from a group chat
  Future<void> exitGroup(String roomId, String userId);

  // =================== MEDIA & SEARCH ===================

  /// Get media messages from chat
  Future<List<Message>> getMediaMessages(String roomId, {String? mediaType});

  /// Get pinned messages
  Future<List<Message>> getPinnedMessages(String roomId);

  /// Get favorite messages
  Future<List<Message>> getFavoriteMessages(String roomId);

  /// Search messages
  Future<List<Message>> searchMessages(String roomId, String query);
}

/// Result wrapper for repository operations
class RepositoryResult<T> {
  final T? data;
  final RepositoryError? error;
  final bool isSuccess;

  RepositoryResult.success(this.data)
      : error = null,
        isSuccess = true;

  RepositoryResult.failure(this.error)
      : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Repository error types
class RepositoryError {
  final String message;
  final String code;
  final dynamic originalError;

  RepositoryError({
    required this.message,
    required this.code,
    this.originalError,
  });

  factory RepositoryError.notFound(String entity) => RepositoryError(
        message: '$entity not found',
        code: 'NOT_FOUND',
      );

  factory RepositoryError.unauthorized(String action) => RepositoryError(
        message: 'Unauthorized to $action',
        code: 'UNAUTHORIZED',
      );

  factory RepositoryError.network(dynamic error) => RepositoryError(
        message: 'Network error occurred',
        code: 'NETWORK_ERROR',
        originalError: error,
      );

  factory RepositoryError.validation(String message) => RepositoryError(
        message: message,
        code: 'VALIDATION_ERROR',
      );

  factory RepositoryError.unknown(dynamic error) => RepositoryError(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
        originalError: error,
      );

  @override
  String toString() => 'RepositoryError(code: $code, message: $message)';
}
