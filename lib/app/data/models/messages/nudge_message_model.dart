import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// A "Nudge" / "Thinking of You" message.
///
/// Lightweight special message type that shows an animated nudge card
/// in the chat. The nudge can carry a short preset text
/// (e.g. "Thinking of you", "Hey! I miss chatting with you").
class NudgeMessage extends Message {
  final String nudgeText;
  final String nudgeEmoji;

  NudgeMessage({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.timestamp,
    this.nudgeText = 'Thinking of you',
    this.nudgeEmoji = '💭',
    super.reactions,
    super.replyTo,
    super.isPinned,
    super.isFavorite,
    super.isDeleted,
    super.isForwarded,
    super.forwardedFrom,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...baseMap(),
      'type': 'nudge',
      'nudgeText': nudgeText,
      'nudgeEmoji': nudgeEmoji,
    };
  }

  factory NudgeMessage.fromMap(Map<String, dynamic> map) {
    return NudgeMessage(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: Message.parseTimestamp(map['timestamp']),
      nudgeText: map['nudgeText'] as String? ?? 'Thinking of you',
      nudgeEmoji: map['nudgeEmoji'] as String? ?? '💭',
      reactions: Message.parseReactions(map['reactions']),
      isPinned: map['isPinned'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isForwarded: map['isForwarded'] as bool? ?? false,
      forwardedFrom: map['forwardedFrom'] as String?,
    );
  }
}
