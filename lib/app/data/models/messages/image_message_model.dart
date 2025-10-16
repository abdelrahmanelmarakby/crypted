// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:crypted_app/app/data/models/messages/message_model.dart';

class PhotoMessage extends Message {
  final String imageUrl;

  PhotoMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.imageUrl,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'photo',
        'imageUrl': imageUrl,
      };

  factory PhotoMessage.fromMap(Map<String, dynamic> map) => PhotoMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        imageUrl: map['imageUrl'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  PhotoMessage copyWith({
    String? imageUrl,
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return PhotoMessage(
      imageUrl: imageUrl ?? this.imageUrl,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
