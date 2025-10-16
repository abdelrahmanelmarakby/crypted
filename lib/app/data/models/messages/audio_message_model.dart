// ignore_for_file: public_member_api_docs, sort_constructors_first

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
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'audio',
        'audioUrl': audioUrl,
        'duration': duration,
      };

  factory AudioMessage.fromMap(Map<String, dynamic> map) => AudioMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        audioUrl: map['audioUrl'],
        duration: map['duration'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

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
    );
  }
}
