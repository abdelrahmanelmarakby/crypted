// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/message_model.dart';

class LocationMessage extends Message {
  final double latitude;
  final double longitude;

  LocationMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.latitude,
    required this.longitude,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'location',
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationMessage.fromMap(Map<String, dynamic> map) => LocationMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        latitude: map['latitude'],
        longitude: map['longitude'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  LocationMessage copyWith({
    double? latitude,
    double? longitude,
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return LocationMessage(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
