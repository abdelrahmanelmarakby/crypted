// Domain layer mapper for ChatEntity
// Converts between Firebase data models and domain entities

import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/entities/chat_entity.dart';

/// Mapper for converting between ChatRoom (data layer) and ChatEntity (domain layer)
class ChatMapper {
  /// Convert ChatRoom to ChatEntity
  static ChatEntity toEntity(ChatRoom chatRoom) {
    return ChatEntity(
      id: chatRoom.id ?? '',
      name: chatRoom.name ?? '',
      description: chatRoom.description,
      imageUrl: chatRoom.groupImageUrl,
      isGroupChat: chatRoom.isGroupChat ?? false,
      members: chatRoom.members?.map((m) => MemberMapper.toEntity(m, chatRoom.adminIds, chatRoom.createdBy)).toList() ?? [],
      memberIds: chatRoom.membersIds ?? [],
      lastMessage: chatRoom.lastMsg,
      lastSenderId: chatRoom.lastSender,
      lastSenderName: chatRoom.lastChat,
      lastMessageTime: null, // ChatRoom doesn't store timestamp directly
      isRead: chatRoom.read ?? false,
      isMuted: chatRoom.isMuted ?? false,
      isPinned: chatRoom.isPinned ?? false,
      isArchived: chatRoom.isArchived ?? false,
      isFavorite: chatRoom.isFavorite ?? false,
      blockedUserIds: chatRoom.blockedUsers ?? [],
      adminIds: chatRoom.adminIds ?? [],
      blockingUserId: chatRoom.blockingUserId,
      keywords: chatRoom.keywords ?? [],
      createdBy: chatRoom.createdBy,
    );
  }

  /// Convert ChatEntity back to ChatRoom (for persistence)
  static ChatRoom toModel(ChatEntity entity) {
    return ChatRoom(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      groupImageUrl: entity.imageUrl,
      isGroupChat: entity.isGroupChat,
      members: entity.members.map((m) => MemberMapper.toModel(m)).toList(),
      membersIds: entity.memberIds,
      lastMsg: entity.lastMessage,
      lastSender: entity.lastSenderId,
      lastChat: entity.lastSenderName,
      read: entity.isRead,
      isMuted: entity.isMuted,
      isPinned: entity.isPinned,
      isArchived: entity.isArchived,
      isFavorite: entity.isFavorite,
      blockedUsers: entity.blockedUserIds,
      adminIds: entity.adminIds,
      blockingUserId: entity.blockingUserId,
      keywords: entity.keywords,
      createdBy: entity.createdBy,
    );
  }

  /// Convert list of ChatRoom to list of ChatEntity
  static List<ChatEntity> toEntityList(List<ChatRoom> chatRooms) {
    return chatRooms.map((room) => toEntity(room)).toList();
  }

  /// Convert list of ChatEntity to list of ChatRoom
  static List<ChatRoom> toModelList(List<ChatEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}

/// Mapper for converting between SocialMediaUser and MemberEntity
class MemberMapper {
  /// Convert SocialMediaUser to MemberEntity
  /// Note: isOnline/lastSeen are not stored in SocialMediaUser - these are tracked
  /// separately by PresenceService. Pass them explicitly if available.
  static MemberEntity toEntity(
    SocialMediaUser user,
    List<String>? adminIds,
    String? createdBy, {
    bool isOnline = false,
    DateTime? lastSeen,
  }) {
    // Determine member role
    MemberRole role = MemberRole.member;
    if (user.uid != null) {
      if (createdBy == user.uid) {
        role = MemberRole.owner;
      } else if (adminIds?.contains(user.uid) == true) {
        role = MemberRole.admin;
      }
    }

    return MemberEntity(
      id: user.uid ?? '',
      name: user.fullName ?? '',
      imageUrl: user.imageUrl,
      email: user.email,
      phone: user.phoneNumber,
      isOnline: isOnline,
      lastSeen: lastSeen,
      role: role,
    );
  }

  /// Convert MemberEntity back to SocialMediaUser
  /// Note: isOnline/lastSeen are not stored in SocialMediaUser
  static SocialMediaUser toModel(MemberEntity entity) {
    return SocialMediaUser(
      uid: entity.id,
      fullName: entity.name,
      imageUrl: entity.imageUrl,
      email: entity.email,
      phoneNumber: entity.phone,
    );
  }

  /// Convert list of SocialMediaUser to list of MemberEntity
  static List<MemberEntity> toEntityList(
    List<SocialMediaUser> users,
    List<String>? adminIds,
    String? createdBy,
  ) {
    return users.map((user) => toEntity(user, adminIds, createdBy)).toList();
  }

  /// Convert list of MemberEntity to list of SocialMediaUser
  static List<SocialMediaUser> toModelList(List<MemberEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}
