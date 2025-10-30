// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';

class AudioMessage extends Message {
  final String audioUrl;
  final String? duration;

  AudioMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.audioUrl,
    this.duration,
    super.reactions,
    super.replyTo,
    super.isPinned,
    super.isFavorite,
    super.isDeleted,
    super.isForwarded,
    super.forwardedFrom,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'audio',
        'audioUrl': audioUrl,
        'duration': duration,
      };

  factory AudioMessage.fromMap(Map<String, dynamic> map) {
    // Handle both Firestore Timestamp and ISO string
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          print('Error parsing timestamp string: $e');
          return DateTime.now();
        }
      }
      // Handle Firestore Timestamp as Map (from JSON)
      if (timestamp is Map) {
        try {
          final seconds = timestamp['_seconds'] ?? timestamp['seconds'] ?? 0;
          final nanoseconds = timestamp['_nanoseconds'] ?? timestamp['nanoseconds'] ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        } catch (e) {
          print('Error parsing timestamp map: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return AudioMessage(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      audioUrl: map['audioUrl'] ?? '',
      duration: map['duration'],
      reactions: Message.parseReactions(map['reactions']),
      replyTo: Message.parseReplyTo(map['replyTo']),
      isPinned: map['isPinned'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      isForwarded: map['isForwarded'] ?? false,
      forwardedFrom: map['forwardedFrom'],
    );
  }

  @override
  AudioMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    String? audioUrl,
    String? duration,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
  }) {
    return AudioMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
    );
  }
}
