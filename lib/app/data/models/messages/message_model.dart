// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:flutter/foundation.dart';

import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';

abstract class Message {
  final String id;
  final String roomId;
  final String senderId;
  final DateTime timestamp;
  final List<Reaction> reactions;
  final ReplyToMessage? replyTo;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.timestamp,
    this.reactions = const [],
    this.replyTo,
  });

  Map<String, dynamic> toMap();

  static Message fromMap(Map<String, dynamic> map) {
    switch (map['type']) {
      case 'text':
        return TextMessage.fromMap(map);
      case 'photo':
        return PhotoMessage.fromMap(map);
      case 'audio':
        return AudioMessage.fromMap(map);
      case 'contact':
        return ContactMessage.fromMap(map);
      case 'location':
        return LocationMessage.fromMap(map);
      case 'poll':
        return PollMessage.fromMap(map);
      case 'event':
        return EventMessage.fromMap(map);
      case 'file':
        return FileMessage.fromMap(map);
      case 'video':
        return VideoMessage.fromMap(map);
      case 'call':
        return CallMessage.fromMap(map);
      default:
        throw Exception('Unknown message type');
    }
  }

  static List<Reaction> parseReactions(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((r) => Reaction.fromMap(r)).toList();
  }

  static ReplyToMessage? parseReplyTo(dynamic data) {
    if (data == null) return null;
    return ReplyToMessage.fromMap(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> baseMap() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
        'reactions': reactions.map((r) => r.toMap()).toList(),
        'replyTo': replyTo?.toMap(),
      };

  @override
  String toString() {
    return 'Message(id: $id, roomId: $roomId, senderId: $senderId, timestamp: $timestamp, reactions: $reactions, replyTo: $replyTo)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.timestamp == timestamp &&
        listEquals(other.reactions, reactions) &&
        other.replyTo == replyTo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roomId.hashCode ^
        senderId.hashCode ^
        timestamp.hashCode ^
        reactions.hashCode ^
        replyTo.hashCode;
  }

  copyWith({required String id, required String roomId}) {
    return copyWith(
      id: id,
      roomId: roomId,
    );
  }
}

class Reaction {
  final String emoji;
  final String userId;

  Reaction({required this.emoji, required this.userId});

  Map<String, dynamic> toMap() => {
        'emoji': emoji,
        'userId': userId,
      };

  factory Reaction.fromMap(Map<String, dynamic> map) => Reaction(
        emoji: map['emoji'],
        userId: map['userId'],
      );
}

class ReplyToMessage {
  final String id;
  final String senderId;
  final String previewText;

  ReplyToMessage({
    required this.id,
    required this.senderId,
    required this.previewText,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'previewText': previewText,
      };

  factory ReplyToMessage.fromMap(Map<String, dynamic> map) => ReplyToMessage(
        id: map['id'],
        senderId: map['senderId'],
        previewText: map['previewText'],
      );
}
