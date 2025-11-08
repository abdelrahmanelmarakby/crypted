// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/message_model.dart';

class TextMessage extends Message {
  final String text;
  final bool isEdited;
  final DateTime? editedAt;
  final String? originalText;

  TextMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    required this.text,
    this.isEdited = false,
    this.editedAt,
    this.originalText,
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
        'type': 'text',
        'text': text,
        'isEdited': isEdited,
        'editedAt': editedAt?.toIso8601String(),
        'originalText': originalText,
      };

  factory TextMessage.fromMap(Map<String, dynamic> map) => TextMessage(
        id: map['id'],
        roomId: map['roomId'],
        senderId: map['senderId'],
        timestamp: DateTime.parse(map['timestamp']),
        text: map['text'],
        isEdited: map['isEdited'] ?? false,
        editedAt: map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
        originalText: map['originalText'],
        reactions: Message.parseReactions(map['reactions']),
        replyTo: Message.parseReplyTo(map['replyTo']),
        isPinned: map['isPinned'] ?? false,
        isFavorite: map['isFavorite'] ?? false,
        isDeleted: map['isDeleted'] ?? false,
        isForwarded: map['isForwarded'] ?? false,
        forwardedFrom: map['forwardedFrom'],
      );

  @override
  TextMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    String? text,
    bool? isEdited,
    DateTime? editedAt,
    String? originalText,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
  }) {
    return TextMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      originalText: originalText ?? this.originalText,
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
