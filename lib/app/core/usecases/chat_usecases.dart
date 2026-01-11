// ARCH-005 FIX: Use Cases Layer (Clean Architecture)
// Business logic abstraction independent of UI and data layers

import 'package:crypted_app/app/core/repositories/message_repository.dart';
import 'package:crypted_app/app/core/repositories/chat_room_repository.dart';
import 'package:crypted_app/app/core/security/input_sanitizer.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}

/// Result wrapper for use case execution
class UseCaseResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const UseCaseResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory UseCaseResult.success(T data) => UseCaseResult._(
        data: data,
        isSuccess: true,
      );

  factory UseCaseResult.failure(String error) => UseCaseResult._(
        error: error,
        isSuccess: false,
      );
}

// =================== MESSAGE USE CASES ===================

/// Parameters for sending a message
class SendMessageParams {
  final String roomId;
  final Message message;

  const SendMessageParams({
    required this.roomId,
    required this.message,
  });
}

/// Use case for sending messages with validation
class SendMessageUseCase implements UseCase<UseCaseResult<void>, SendMessageParams> {
  final IMessageRepository _messageRepository;
  final InputSanitizer _sanitizer;

  SendMessageUseCase({
    required IMessageRepository messageRepository,
    InputSanitizer? sanitizer,
  })  : _messageRepository = messageRepository,
        _sanitizer = sanitizer ?? InputSanitizer();

  @override
  Future<UseCaseResult<void>> call(SendMessageParams params) async {
    try {
      // Validate message content if it's a text message
      final messageMap = params.message.toMap();
      if (messageMap['type'] == 'text' && messageMap['text'] != null) {
        final validation = _sanitizer.validateMessage(messageMap['text']);
        if (!validation.isValid) {
          return UseCaseResult.failure(
            validation.errors.isNotEmpty ? validation.errors.first : 'Invalid message content',
          );
        }
      }

      await _messageRepository.sendMessage(
        roomId: params.roomId,
        message: params.message,
      );

      return UseCaseResult.success(null);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

/// Parameters for getting messages
class GetMessagesParams {
  final String roomId;
  final int limit;

  const GetMessagesParams({
    required this.roomId,
    this.limit = 30,
  });
}

/// Use case for getting paginated messages
class GetMessagesUseCase implements UseCase<Stream<List<Message>>, GetMessagesParams> {
  final IMessageRepository _messageRepository;

  GetMessagesUseCase({required IMessageRepository messageRepository})
      : _messageRepository = messageRepository;

  @override
  Future<Stream<List<Message>>> call(GetMessagesParams params) async {
    return _messageRepository.getMessages(
      params.roomId,
      limit: params.limit,
    );
  }
}

/// Parameters for deleting a message
class DeleteMessageParams {
  final String roomId;
  final String messageId;
  final String userId;

  const DeleteMessageParams({
    required this.roomId,
    required this.messageId,
    required this.userId,
  });
}

/// Use case for deleting messages with authorization
class DeleteMessageUseCase implements UseCase<UseCaseResult<void>, DeleteMessageParams> {
  final IMessageRepository _messageRepository;

  DeleteMessageUseCase({required IMessageRepository messageRepository})
      : _messageRepository = messageRepository;

  @override
  Future<UseCaseResult<void>> call(DeleteMessageParams params) async {
    try {
      // Get the message to verify ownership
      final message = await _messageRepository.getMessageById(
        params.roomId,
        params.messageId,
      );

      if (message == null) {
        return UseCaseResult.failure('Message not found');
      }

      if (message.senderId != params.userId) {
        return UseCaseResult.failure('You can only delete your own messages');
      }

      await _messageRepository.deleteMessage(
        roomId: params.roomId,
        messageId: params.messageId,
      );

      return UseCaseResult.success(null);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

/// Parameters for toggling reactions
class ToggleReactionParams {
  final String roomId;
  final String messageId;
  final String emoji;
  final String userId;

  const ToggleReactionParams({
    required this.roomId,
    required this.messageId,
    required this.emoji,
    required this.userId,
  });
}

/// Use case for toggling reactions
class ToggleReactionUseCase implements UseCase<UseCaseResult<void>, ToggleReactionParams> {
  final IMessageRepository _messageRepository;

  ToggleReactionUseCase({required IMessageRepository messageRepository})
      : _messageRepository = messageRepository;

  @override
  Future<UseCaseResult<void>> call(ToggleReactionParams params) async {
    try {
      await _messageRepository.toggleReaction(
        roomId: params.roomId,
        messageId: params.messageId,
        emoji: params.emoji,
        userId: params.userId,
      );

      return UseCaseResult.success(null);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

/// Parameters for searching messages
class SearchMessagesParams {
  final String roomId;
  final String query;
  final int limit;

  const SearchMessagesParams({
    required this.roomId,
    required this.query,
    this.limit = 50,
  });
}

/// Use case for searching messages
class SearchMessagesUseCase implements UseCase<UseCaseResult<List<Message>>, SearchMessagesParams> {
  final IMessageRepository _messageRepository;

  SearchMessagesUseCase({required IMessageRepository messageRepository})
      : _messageRepository = messageRepository;

  @override
  Future<UseCaseResult<List<Message>>> call(SearchMessagesParams params) async {
    try {
      if (params.query.trim().isEmpty) {
        return UseCaseResult.success([]);
      }

      final messages = await _messageRepository.searchMessages(
        roomId: params.roomId,
        query: params.query,
        limit: params.limit,
      );

      return UseCaseResult.success(messages);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

// =================== CHAT ROOM USE CASES ===================

/// Parameters for creating a chat room
class CreateChatRoomParams {
  final List<SocialMediaUser> members;
  final bool isGroupChat;
  final String? groupName;
  final String? groupDescription;
  final String? groupImageUrl;

  const CreateChatRoomParams({
    required this.members,
    this.isGroupChat = false,
    this.groupName,
    this.groupDescription,
    this.groupImageUrl,
  });
}

/// Use case for creating chat rooms with validation
class CreateChatRoomUseCase implements UseCase<UseCaseResult<dynamic>, CreateChatRoomParams> {
  final IChatRoomRepository _chatRoomRepository;
  final InputSanitizer _sanitizer;

  CreateChatRoomUseCase({
    required IChatRoomRepository chatRoomRepository,
    InputSanitizer? sanitizer,
  })  : _chatRoomRepository = chatRoomRepository,
        _sanitizer = sanitizer ?? InputSanitizer();

  @override
  Future<UseCaseResult<dynamic>> call(CreateChatRoomParams params) async {
    try {
      // Validate members
      if (params.members.isEmpty) {
        return UseCaseResult.failure('At least one member is required');
      }

      if (params.members.length < 2 && !params.isGroupChat) {
        return UseCaseResult.failure('Private chat requires at least 2 members');
      }

      // Validate group name if it's a group chat
      if (params.isGroupChat && params.groupName != null) {
        final validation = _sanitizer.validateGroupName(params.groupName!);
        if (!validation.isValid) {
          return UseCaseResult.failure(
            validation.errors.isNotEmpty ? validation.errors.first : 'Invalid group name',
          );
        }
      }

      // Check for existing chat room (for private chats)
      if (!params.isGroupChat) {
        final memberIds = params.members.map((m) => m.uid ?? '').toList();
        final existingRoom = await _chatRoomRepository.findExistingChatRoom(memberIds);
        if (existingRoom != null) {
          return UseCaseResult.success(existingRoom);
        }
      }

      final chatRoom = await _chatRoomRepository.createChatRoom(
        members: params.members,
        isGroupChat: params.isGroupChat,
        groupName: params.groupName,
        groupDescription: params.groupDescription,
        groupImageUrl: params.groupImageUrl,
      );

      return UseCaseResult.success(chatRoom);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

/// Parameters for adding a member to a chat room
class AddMemberParams {
  final String roomId;
  final SocialMediaUser member;
  final String requesterId;

  const AddMemberParams({
    required this.roomId,
    required this.member,
    required this.requesterId,
  });
}

/// Use case for adding members with authorization
class AddMemberUseCase implements UseCase<UseCaseResult<void>, AddMemberParams> {
  final IChatRoomRepository _chatRoomRepository;

  AddMemberUseCase({required IChatRoomRepository chatRoomRepository})
      : _chatRoomRepository = chatRoomRepository;

  @override
  Future<UseCaseResult<void>> call(AddMemberParams params) async {
    try {
      // Get the chat room to verify it exists and check permissions
      final room = await _chatRoomRepository.getChatRoomById(params.roomId);
      if (room == null) {
        return UseCaseResult.failure('Chat room not found');
      }

      // Check if it's a group chat
      if (!room.isGroupChat) {
        return UseCaseResult.failure('Cannot add members to a private chat');
      }

      // Check if requester is an admin (simplified check)
      final isAdmin = room.adminIds?.contains(params.requesterId) ?? false;
      if (!isAdmin) {
        return UseCaseResult.failure('Only admins can add members');
      }

      // Check if member is already in the room
      if (room.membersIds.contains(params.member.uid)) {
        return UseCaseResult.failure('User is already a member');
      }

      final success = await _chatRoomRepository.addMember(
        roomId: params.roomId,
        member: params.member,
      );

      if (!success) {
        return UseCaseResult.failure('Failed to add member');
      }

      return UseCaseResult.success(null);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}

/// Parameters for removing a member
class RemoveMemberParams {
  final String roomId;
  final String memberId;
  final String requesterId;

  const RemoveMemberParams({
    required this.roomId,
    required this.memberId,
    required this.requesterId,
  });
}

/// Use case for removing members with authorization
class RemoveMemberUseCase implements UseCase<UseCaseResult<void>, RemoveMemberParams> {
  final IChatRoomRepository _chatRoomRepository;

  RemoveMemberUseCase({required IChatRoomRepository chatRoomRepository})
      : _chatRoomRepository = chatRoomRepository;

  @override
  Future<UseCaseResult<void>> call(RemoveMemberParams params) async {
    try {
      final room = await _chatRoomRepository.getChatRoomById(params.roomId);
      if (room == null) {
        return UseCaseResult.failure('Chat room not found');
      }

      if (!room.isGroupChat) {
        return UseCaseResult.failure('Cannot remove members from a private chat');
      }

      // Check if requester is an admin or is removing themselves
      final isAdmin = room.adminIds?.contains(params.requesterId) ?? false;
      final isSelfRemoval = params.memberId == params.requesterId;

      if (!isAdmin && !isSelfRemoval) {
        return UseCaseResult.failure('Only admins can remove other members');
      }

      final success = await _chatRoomRepository.removeMember(
        roomId: params.roomId,
        memberId: params.memberId,
      );

      if (!success) {
        return UseCaseResult.failure('Failed to remove member');
      }

      return UseCaseResult.success(null);
    } catch (e) {
      return UseCaseResult.failure(e.toString());
    }
  }
}
