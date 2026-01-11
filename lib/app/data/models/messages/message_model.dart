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
  final bool isPinned;
  final bool isFavorite;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFrom;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.timestamp,
    this.reactions = const [],
    this.replyTo,
    this.isPinned = false,
    this.isFavorite = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFrom,
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

  // BUG-008 FIX: Centralized timestamp parsing to handle multiple formats
  /// Parses timestamp from various formats (Firestore Timestamp, ISO string, Map, DateTime)
  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;

    // Handle Firestore Timestamp directly
    try {
      // Using dynamic to avoid import issues - Timestamp has toDate() method
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        return (timestamp as dynamic).toDate();
      }
    } catch (_) {}

    // Handle ISO 8601 string
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp as Map (from JSON serialization)
    if (timestamp is Map) {
      try {
        final seconds = timestamp['_seconds'] ?? timestamp['seconds'] ?? 0;
        final nanoseconds = timestamp['_nanoseconds'] ?? timestamp['nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as int) * 1000 + ((nanoseconds as int) ~/ 1000000),
        );
      } catch (e) {
        print('Error parsing timestamp map: $e');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> baseMap() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
        'reactions': reactions.map((r) => r.toMap()).toList(),
        'replyTo': replyTo?.toMap(),
        'isPinned': isPinned,
        'isFavorite': isFavorite,
        'isDeleted': isDeleted,
        'isForwarded': isForwarded,
        'forwardedFrom': forwardedFrom,
      };

  @override
  String toString() {
    return 'Message(id: $id, roomId: $roomId, senderId: $senderId, timestamp: $timestamp, reactions: $reactions, replyTo: $replyTo, isPinned: $isPinned, isFavorite: $isFavorite, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.timestamp == timestamp &&
        listEquals(other.reactions, reactions) &&
        other.replyTo == replyTo &&
        other.isPinned == isPinned &&
        other.isFavorite == isFavorite &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roomId.hashCode ^
        senderId.hashCode ^
        timestamp.hashCode ^
        reactions.hashCode ^
        replyTo.hashCode ^
        isPinned.hashCode ^
        isFavorite.hashCode ^
        isDeleted.hashCode;
  }

  copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
  }) {
    // This is an abstract method, implementation in subclasses
    throw UnimplementedError('copyWith must be implemented by subclasses');
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
