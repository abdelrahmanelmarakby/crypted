import 'package:crypted_app/app/data/models/messages/message_model.dart';

class FileMessage extends Message {
  final String file;
  final String fileName;

  FileMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.file,
    required this.fileName,
    super.reactions,
    super.replyTo,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...baseMap(),
        'type': 'file',
        'file': file,
        'fileName': fileName,
      };

  factory FileMessage.fromMap(Map<String, dynamic> map) => FileMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        file: map['file'],
        fileName: map['fileName'] ?? '',
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
      );

  @override
  FileMessage copyWith({
    String? file,
    String? fileName,
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
  }) {
    return FileMessage(
      file: file ?? this.file,
      fileName: fileName ?? this.fileName,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
