// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/message_model.dart';

class TextMessage extends Message {
  final String text;

  TextMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.text,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'text',
        'text': text,
      };

  factory TextMessage.fromMap(Map<String, dynamic> map) => TextMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        text: map['text'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  TextMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    String? text,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return TextMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
