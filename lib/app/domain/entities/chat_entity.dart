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
  final List<String> memberIds;
  final String? lastMessage;
  final String? lastSenderId;
  final String? lastSenderName;
  final DateTime? lastMessageTime;
  final bool isRead;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final List<String> blockedUserIds;
  final List<String> adminIds;
  final String? blockingUserId;
  final List<String> keywords;
  final DateTime? createdAt;
  final String? createdBy;

  const ChatEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isGroupChat,
    required this.members,
    this.memberIds = const [],
    this.lastMessage,
    this.lastSenderId,
    this.lastSenderName,
    this.lastMessageTime,
    this.isRead = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.blockedUserIds = const [],
    this.adminIds = const [],
    this.blockingUserId,
    this.keywords = const [],
    this.createdAt,
    this.createdBy,
  });

  /// Get member count
  int get memberCount => members.isNotEmpty ? members.length : memberIds.length;

  /// Check if user is member
  bool hasMember(String userId) {
    if (members.isNotEmpty) {
      return members.any((m) => m.id == userId);
    }
    return memberIds.contains(userId);
  }

  /// Check if user is blocked
  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  /// Check if user is admin
  bool isUserAdmin(String userId) {
    // Check adminIds list first
    if (adminIds.contains(userId)) return true;
    // Fallback: check if user is the creator
    if (createdBy == userId) return true;
    // Fallback for legacy data: first member is admin
    if (adminIds.isEmpty && memberIds.isNotEmpty) {
      return memberIds.first == userId;
    }
    return false;
  }

  /// Get other member (for 1-on-1 chats)
  /// FIX: Returns null safely if members list is empty instead of crashing
  MemberEntity? getOtherMember(String currentUserId) {
    if (isGroupChat || members.isEmpty) return null;
    try {
      return members.firstWhere((m) => m.id != currentUserId);
    } catch (e) {
      // If no other member found, return the first member (could be the current user)
      return members.isNotEmpty ? members.first : null;
    }
  }

  /// Create a copy with updated fields
  ChatEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isGroupChat,
    List<MemberEntity>? members,
    List<String>? memberIds,
    String? lastMessage,
    String? lastSenderId,
    String? lastSenderName,
    DateTime? lastMessageTime,
    bool? isRead,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    List<String>? blockedUserIds,
    List<String>? adminIds,
    String? blockingUserId,
    List<String>? keywords,
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
      memberIds: memberIds ?? this.memberIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isRead: isRead ?? this.isRead,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      adminIds: adminIds ?? this.adminIds,
      blockingUserId: blockingUserId ?? this.blockingUserId,
      keywords: keywords ?? this.keywords,
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
        memberIds,
        lastMessage,
        lastSenderId,
        lastSenderName,
        lastMessageTime,
        isRead,
        isMuted,
        isPinned,
        isArchived,
        isFavorite,
        blockedUserIds,
        adminIds,
        blockingUserId,
        keywords,
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
