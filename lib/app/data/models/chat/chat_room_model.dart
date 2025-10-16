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
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'blockingUserId': blockingUserId,
      'membersIds': membersIds, // Use membersIds instead of members
      'lastMsg': lastMsg,
      'lastSender': lastSender, // Remove unnecessary enum conversion
      'lastChat': lastChat,
      'keywords': keywords,
      'read': read,
      'isGroupChat': isGroupChat,
      'description': description,
    };
  }

  List<ChatRoom> fromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      return ChatRoom(
        blockingUserId: _safeGet(data, "blockingUserId"),
        id: _safeGet(data, 'id'),
        membersIds: _safeGetStringList(data, 'membersIds'),
        // Only try to get members if the field exists
        members: data.containsKey('members') && data['members'] != null
            ? (data['members'] as List<dynamic>?)
                ?.map((e) => SocialMediaUser.fromMap(e as Map<String, dynamic>))
                .toList()
            : null,
        lastMsg: _safeGet(data, 'lastMsg'),
        lastSender: _safeGet(data, 'lastSender'),
        lastChat: _safeGet(data, 'lastChat'),
        keywords: _safeGetStringList(data, 'keywords'),
        read: data['read'] as bool?,
        isGroupChat: data['isGroupChat'] as bool?,
        description: _safeGet(data, 'description'),
      );
    })
        .where((chatRoom) => chatRoom != null)
        .cast<ChatRoom>()
        .toList();
  }

  // Helper method to safely get string values
  String? _safeGet(Map<String, dynamic> data, String key) {
    return data.containsKey(key) ? data[key] as String? : null;
  }

  // Helper method to safely get string lists
  List<String>? _safeGetStringList(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key) || data[key] == null) return null;
    return (data[key] as List<dynamic>?)?.map((e) => e.toString()).toList();
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      blockingUserId: map['blockingUserId'] as String?,
      id: map['id'] as String?,
      name: map['name'] as String?,
      membersIds: map['membersIds'] != null
          ? (map['membersIds'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      members: map['members'] != null
          ? (map['members'] as List<dynamic>)
              .map((e) => SocialMediaUser.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      lastMsg: map['lastMsg'] as String?,
      lastSender: map['lastSender'] as String?,
      lastChat: map['lastChat'] as String?,
      keywords: map['keywords'] != null
          ? (map['keywords'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      read: map['read'] as bool?,
      isGroupChat: map['isGroupChat'] as bool?,
    );
  }

  @override
  String toString() {
    return 'ChatRoom(blockingUserId: $blockingUserId, id: $id, membersIds: $membersIds, lastMsg: $lastMsg, lastSender: $lastSender, lastChat: $lastChat, keywords: $keywords, read: $read)';
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
        other.isGroupChat == isGroupChat;
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
        isGroupChat.hashCode;
  }
}