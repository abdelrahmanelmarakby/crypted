import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../user_model.dart';

class ChatRoom {
  String? id;
  String? name;
  String? lastMsg;
  String? lastSender;
  String? lastChat;
  String? blockingUserId;
  List<String>? keywords;
  List<SocialMediaUser>? members;
  List<String>? membersIds;
  bool? read;
  bool? isGroupChat;
  String? description;
  String? groupImageUrl;
  bool? isMuted;
  bool? isPinned;
  bool? isArchived;
  bool? isFavorite;
  List<String>? blockedUsers;
  List<String>? adminIds;
  String? createdBy;
  Map<String, int>? unreadCounts;

  ChatRoom({
    this.id,
    this.name,
    this.membersIds,
    this.members,
    this.lastMsg,
    this.lastSender,
    this.lastChat,
    this.keywords,
    this.read,
    this.blockingUserId,
    this.isGroupChat,
    this.description,
    this.groupImageUrl,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.blockedUsers,
    this.adminIds,
    this.createdBy,
    this.unreadCounts,
  });

  /// Get unread count for a specific user
  int unreadCountFor(String userId) {
    return unreadCounts?[userId] ?? 0;
  }

  /// Check if a user is an admin of this chat room
  bool isUserAdmin(String userId) {
    // First check adminIds list
    if (adminIds != null && adminIds!.contains(userId)) {
      return true;
    }
    // Fallback: check if user is the creator
    if (createdBy != null && createdBy == userId) {
      return true;
    }
    // Fallback for legacy data: first member is admin
    if (adminIds == null && membersIds != null && membersIds!.isNotEmpty) {
      return membersIds!.first == userId;
    }
    return false;
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    List<String>? membersIds,
    List<SocialMediaUser>? members,
    String? lastMsg,
    String? lastSender,
    String? lastChat,
    List<String>? keywords,
    String? blockingUserId,
    bool? read,
    bool? isGroupChat,
    String? description,
    String? groupImageUrl,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    List<String>? blockedUsers,
    List<String>? adminIds,
    String? createdBy,
    Map<String, int>? unreadCounts,
  }) {
    return ChatRoom(
      blockingUserId: blockingUserId ?? this.blockingUserId,
      id: id ?? this.id,
      name: name ?? this.name,
      membersIds: membersIds ?? this.membersIds,
      members: members ?? this.members,
      lastMsg: lastMsg ?? this.lastMsg,
      lastSender: lastSender ?? this.lastSender,
      lastChat: lastChat ?? this.lastChat,
      keywords: keywords ?? this.keywords,
      read: read ?? this.read,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      description: description ?? this.description,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      adminIds: adminIds ?? this.adminIds,
      createdBy: createdBy ?? this.createdBy,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'blockingUserId': blockingUserId,
      'membersIds': membersIds,
      'members': members
          ?.map((member) => member.toMap())
          .toList(), // Include members in saved data
      'lastMsg': lastMsg,
      'lastSender': lastSender,
      'lastChat': lastChat,
      'keywords': keywords,
      'read': read,
      'isGroupChat': isGroupChat,
      'description': description,
      'groupImageUrl': groupImageUrl,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'blockedUsers': blockedUsers,
      'adminIds': adminIds,
      'createdBy': createdBy,
      'unreadCounts': unreadCounts,
    };
  }

  List<ChatRoom> fromQuery(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return null;

          return ChatRoom(
            blockingUserId: _safeGet(data, "blockingUserId"),
            id: _safeGet(data, 'id'),
            membersIds: _safeGetStringList(data, 'membersIds'),
            // Only try to get members if the field exists
            members: data.containsKey('members') && data['members'] != null
                ? (data['members'] as List<dynamic>?)
                    ?.map((e) =>
                        SocialMediaUser.fromMap(e as Map<String, dynamic>))
                    .toList()
                : null,
            lastMsg: _safeGet(data, 'lastMsg'),
            lastSender: _safeGet(data, 'lastSender'),
            lastChat: _safeGet(data, 'lastChat'),
            keywords: _safeGetStringList(data, 'keywords'),
            read: data['read'] as bool?,
            isGroupChat: data['isGroupChat'] as bool?,
            description: _safeGet(data, 'description'),
            groupImageUrl: _safeGet(data, 'groupImageUrl'),
            isMuted: data['isMuted'] as bool?,
            isPinned: data['isPinned'] as bool?,
            isArchived: data['isArchived'] as bool?,
            isFavorite: data['isFavorite'] as bool?,
            blockedUsers: data['blockedUsers'] != null
                ? (data['blockedUsers'] as List<dynamic>)
                    .map((e) => e.toString())
                    .toList()
                : null,
            adminIds: data['adminIds'] != null
                ? (data['adminIds'] as List<dynamic>)
                    .map((e) => e.toString())
                    .toList()
                : null,
            createdBy: _safeGet(data, 'createdBy'),
            unreadCounts: data['unreadCounts'] != null
                ? (data['unreadCounts'] as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0))
                : null,
          );
        })
        .where((chatRoom) => chatRoom != null)
        .cast<ChatRoom>()
        .toList();
  }

  // Helper method to safely get string values
  String? _safeGet(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key) || data[key] == null) return null;
    final value = data[key];
    // Handle Timestamp fields that should be converted to ISO string
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value as String?;
  }

  // Helper method to safely get string lists
  List<String>? _safeGetStringList(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key) || data[key] == null) return null;
    return (data[key] as List<dynamic>?)?.map((e) => e.toString()).toList();
  }

  // Static helper to parse lastChat which can be Timestamp, DateTime, or String
  static String? _parseLastChat(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      blockingUserId: map['blockingUserId'] as String?,
      id: map['id'] as String?,
      name: map['name'] as String?,
      membersIds: map['membersIds'] != null
          ? (map['membersIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      members: map['members'] != null
          ? (map['members'] as List<dynamic>)
              .map((e) => SocialMediaUser.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      lastMsg: map['lastMsg'] as String?,
      lastSender: map['lastSender'] as String?,
      lastChat: _parseLastChat(map['lastChat']),
      keywords: map['keywords'] != null
          ? (map['keywords'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      read: map['read'] as bool?,
      isGroupChat: map['isGroupChat'] as bool?,
      isMuted: map['isMuted'] as bool?,
      isPinned: map['isPinned'] as bool?,
      isArchived: map['isArchived'] as bool?,
      isFavorite: map['isFavorite'] as bool?,
      description: map['description'] as String?,
      groupImageUrl: map['groupImageUrl'] as String?,
      blockedUsers: map['blockedUsers'] != null
          ? (map['blockedUsers'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      adminIds: map['adminIds'] != null
          ? (map['adminIds'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      createdBy: map['createdBy'] as String?,
      unreadCounts: map['unreadCounts'] != null
          ? (map['unreadCounts'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0))
          : null,
    );
  }

  /// Factory constructor from JSON string
  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      ChatRoom.fromMap(json);

  @override
  String toString() {
    return 'ChatRoom(blockingUserId: $blockingUserId, id: $id, membersIds: $membersIds, lastMsg: $lastMsg, lastSender: $lastSender, lastChat: $lastChat, keywords: $keywords, read: $read, isMuted: $isMuted, isPinned: $isPinned, isArchived: $isArchived, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(covariant ChatRoom other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.blockingUserId == blockingUserId &&
        listEquals(other.membersIds, membersIds) &&
        listEquals(other.members, members) &&
        other.lastMsg == lastMsg &&
        other.lastSender == lastSender &&
        other.lastChat == lastChat &&
        listEquals(other.keywords, keywords) &&
        other.read == read &&
        other.isGroupChat == isGroupChat &&
        other.isMuted == isMuted &&
        other.isPinned == isPinned &&
        other.isArchived == isArchived &&
        other.isFavorite == isFavorite &&
        listEquals(other.blockedUsers, blockedUsers);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        blockingUserId.hashCode ^
        membersIds.hashCode ^
        members.hashCode ^
        lastMsg.hashCode ^
        lastSender.hashCode ^
        lastChat.hashCode ^
        keywords.hashCode ^
        read.hashCode ^
        isGroupChat.hashCode ^
        isMuted.hashCode ^
        isPinned.hashCode ^
        isArchived.hashCode ^
        isFavorite.hashCode ^
        blockedUsers.hashCode;
  }
}
