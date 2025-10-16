import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/call_model.dart';

class CallMessage extends Message {
  final CallModel callModel;

  CallMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.callModel,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'call',
        'callModel': callModel.toMap(),
      };

  factory CallMessage.fromMap(Map<String, dynamic> map) => CallMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        callModel: CallModel.fromMap(map['callModel']),
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  CallMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    CallModel? callModel,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return CallMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      callModel: callModel ?? this.callModel,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
