// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:crypted_app/app/data/models/messages/message_model.dart';

class EventMessage extends Message {
  final String? title;
  final String? description;
  final DateTime? eventDate;

  EventMessage({
    this.description,
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    this.title,
    this.eventDate,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'event',
        'title': title ?? 'No Title',
        'description': description ?? 'No Description',
        'eventDate': eventDate?.toIso8601String(),
      };

  factory EventMessage.fromMap(Map<String, dynamic> map) => EventMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        title: map['title'],
        description: map['description'],
        eventDate: DateTime.parse(map['eventDate']),
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  EventMessage copyWith({
    String? title,
    String? description,
    DateTime? eventDate,
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return EventMessage(
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
