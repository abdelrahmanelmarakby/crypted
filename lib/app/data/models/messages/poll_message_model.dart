// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:crypted_app/app/data/models/messages/message_model.dart';

class PollMessage extends Message {
  final String question;
  final List<String> options;

  PollMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.question,
    required this.options,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'poll',
        'question': question,
        'options': options,
      };

  factory PollMessage.fromMap(Map<String, dynamic> map) => PollMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        question: map['question'],
        options: List<String>.from(map['options']),
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  PollMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    String? question,
    List<String>? options,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return PollMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      question: question ?? this.question,
      options: options ?? this.options,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
