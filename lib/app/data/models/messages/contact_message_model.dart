// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/message_model.dart';

class ContactMessage extends Message {
  final String name;
  final String phoneNumber;

  ContactMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.name,
    required this.phoneNumber,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'contact',
        'name': name,
        'phoneNumber': phoneNumber,
      };

  factory ContactMessage.fromMap(Map<String, dynamic> map) => ContactMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        name: map['name'],
        phoneNumber: map['phoneNumber'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  ContactMessage copyWith({
    String? name,
    String? phoneNumber,
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return ContactMessage(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
