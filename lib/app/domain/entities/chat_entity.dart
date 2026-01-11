// ARCH-005 FIX: Domain Layer Entities
// Pure domain entities decoupled from Firebase/data layer

import 'package:equatable/equatable.dart';

/// Domain entity representing a chat room
/// Independent of Firebase structure
class ChatEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isGroupChat;
  final List<MemberEntity> members;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageTime;
  final bool isRead;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final List<String> blockedUserIds;
  final DateTime? createdAt;
  final String? createdBy;

  const ChatEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isGroupChat,
    required this.members,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageTime,
    this.isRead = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.blockedUserIds = const [],
    this.createdAt,
    this.createdBy,
  });

  /// Get member IDs
  List<String> get memberIds => members.map((m) => m.id).toList();

  /// Get member count
  int get memberCount => members.length;

  /// Check if user is member
  bool hasMember(String userId) => memberIds.contains(userId);

  /// Check if user is blocked
  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  /// Get other member (for 1-on-1 chats)
  MemberEntity? getOtherMember(String currentUserId) {
    if (isGroupChat) return null;
    return members.firstWhere(
      (m) => m.id != currentUserId,
      orElse: () => members.first,
    );
  }

  /// Create a copy with updated fields
  ChatEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isGroupChat,
    List<MemberEntity>? members,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastMessageTime,
    bool? isRead,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    List<String>? blockedUserIds,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isRead: isRead ?? this.isRead,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        isGroupChat,
        members,
        lastMessage,
        lastSenderId,
        lastMessageTime,
        isRead,
        isMuted,
        isPinned,
        isArchived,
        isFavorite,
        blockedUserIds,
        createdAt,
        createdBy,
      ];
}

/// Domain entity representing a chat member
class MemberEntity extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final bool isOnline;
  final DateTime? lastSeen;
  final MemberRole role;

  const MemberEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.email,
    this.phone,
    this.isOnline = false,
    this.lastSeen,
    this.role = MemberRole.member,
  });

  bool get isAdmin => role == MemberRole.admin || role == MemberRole.owner;
  bool get isOwner => role == MemberRole.owner;

  MemberEntity copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? email,
    String? phone,
    bool? isOnline,
    DateTime? lastSeen,
    MemberRole? role,
  }) {
    return MemberEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, email, phone, isOnline, lastSeen, role];
}

/// Member roles in a chat
enum MemberRole {
  owner,
  admin,
  member,
}
