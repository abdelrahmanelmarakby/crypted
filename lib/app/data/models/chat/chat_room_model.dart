import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../user_model.dart';

class ChatRoom {
  String? id;
  SocialMediaUser? sender;
  SocialMediaUser? receiver;
  String? lastMsg;
  String? lastSender;
  String? lastChat;
  String? blockingUserId;
  List? keywords;
  bool? read;
  ChatRoom({
    this.id,
    this.sender,
    this.receiver,
    this.lastMsg,
    this.lastSender,
    this.lastChat,
    this.keywords,
    this.read,
    this.blockingUserId,
  });

  ChatRoom copyWith({
    String? id,
    SocialMediaUser? sender,
    SocialMediaUser? receiver,
    String? lastMsg,
    String? lastSender,
    String? lastChat,
    List<String>? keywords,
    String? blockingUserId,
    bool? read,
  }) {
    return ChatRoom(
      blockingUserId: blockingUserId ?? this.blockingUserId,
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      lastMsg: lastMsg ?? this.lastMsg,
      lastSender: lastSender ?? this.lastSender,
      lastChat: lastChat ?? this.lastChat,
      keywords: keywords ?? this.keywords,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      "blockingUserId": blockingUserId,
      'sender': sender?.toMap(),
      'receiver': receiver?.toMap(),
      'lastMsg': lastMsg,
      'lastSender': lastSender?.toString().split('.').last,
      'lastChat': lastChat,
      'keywords': keywords,
      'read': read,
    };
  }

  List<ChatRoom> fromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map(
      (doc) {
        return ChatRoom(
          blockingUserId: doc.get("blockingUserId"),
          id: doc.get('id'),
          sender: SocialMediaUser.fromMap(doc.get('sender')),
          receiver: SocialMediaUser.fromMap(doc.get('receiver')),
          lastMsg: doc.get('lastMsg'),
          lastSender: doc.get('lastSender'),
          lastChat: doc.get('lastChat'),
          keywords: doc.get('keywords'),
          read: doc.get('read'),
        );
      },
    ).toList();
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      blockingUserId: map['blockingUserId'] != null
          ? map['blockingUserId'] as String
          : null,
      id: map['id'] != null ? map['id'] as String : null,
      sender: map['sender'] != null
          ? SocialMediaUser.fromMap(map['sender'] as Map<String, dynamic>)
          : null,
      receiver: map['receiver'] != null
          ? SocialMediaUser.fromMap(map['receiver'] as Map<String, dynamic>)
          : null,
      lastMsg: map['lastMsg'] != null ? map['lastMsg'] as String : null,
      lastSender:
          map['lastSender'] != null ? map['lastSender'] as String : null,
      lastChat: map['lastChat'],
      keywords: map['keywords'] != null ? List.from((map['keywords'])) : null,
      read: map['read'] != null ? map['read'] as bool : null,
    );
  }
  @override
  String toString() {
    return 'ChatRoom( blockingUserId: $blockingUserId, id: $id, sender: $sender, receiver: $receiver, lastMsg: $lastMsg, lastSender: $lastSender, lastChat: $lastChat, keywords: $keywords, read: $read)';
  }

  @override
  bool operator ==(covariant ChatRoom other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.sender == sender &&
        other.blockingUserId == blockingUserId &&
        other.receiver == receiver &&
        other.lastMsg == lastMsg &&
        other.lastSender == lastSender &&
        other.lastChat == lastChat &&
        listEquals(other.keywords, keywords) &&
        other.read == read;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sender.hashCode ^
        receiver.hashCode ^
        blockingUserId.hashCode ^
        lastMsg.hashCode ^
        lastSender.hashCode ^
        lastChat.hashCode ^
        keywords.hashCode ^
        read.hashCode;
  }
}
