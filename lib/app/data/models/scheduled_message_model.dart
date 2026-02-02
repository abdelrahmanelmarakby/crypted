import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// Status of a scheduled message.
enum ScheduledMessageStatus { pending, sent, cancelled, failed }

/// Model for a message scheduled to be sent at a future time.
///
/// Stored in Firestore `scheduled_messages/{id}`.
/// A Cloud Function runs every minute, picks up `pending` messages
/// whose `scheduledFor` <= now, writes them to the chat room, and
/// marks them `sent`.
class ScheduledMessage {
  final String? id;
  final String chatRoomId;
  final String senderId;
  final String? senderName;
  final String? senderImageUrl;
  final Map<String, dynamic> messageData;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final ScheduledMessageStatus status;
  final List<Map<String, dynamic>> members;
  final String? errorMessage;

  const ScheduledMessage({
    this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderName,
    this.senderImageUrl,
    required this.messageData,
    required this.scheduledFor,
    required this.createdAt,
    this.status = ScheduledMessageStatus.pending,
    this.members = const [],
    this.errorMessage,
  });

  /// Human-readable message preview (first 80 chars of text content).
  String get preview {
    final text = messageData['text'] as String? ??
        messageData['caption'] as String? ??
        _typeLabel;
    return text.length > 80 ? '${text.substring(0, 80)}...' : text;
  }

  String get _typeLabel {
    switch (messageData['type']) {
      case 'photo':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      case 'file':
        return 'File';
      case 'location':
        return 'Location';
      case 'contact':
        return 'Contact';
      case 'poll':
        return 'Poll';
      case 'sticker':
        return 'Sticker';
      case 'gif':
        return 'GIF';
      default:
        return 'Message';
    }
  }

  /// Whether this message can still be cancelled.
  bool get isCancellable => status == ScheduledMessageStatus.pending;

  /// Time remaining until the message is sent.
  Duration get timeUntilSend => scheduledFor.difference(DateTime.now());

  ScheduledMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    Map<String, dynamic>? messageData,
    DateTime? scheduledFor,
    DateTime? createdAt,
    ScheduledMessageStatus? status,
    List<Map<String, dynamic>>? members,
    String? errorMessage,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      messageData: messageData ?? this.messageData,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'messageData': messageData,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'members': members,
      'errorMessage': errorMessage,
    };
  }

  factory ScheduledMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ScheduledMessage(
      id: docId ?? map['id'] as String?,
      chatRoomId: map['chatRoomId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String?,
      senderImageUrl: map['senderImageUrl'] as String?,
      messageData: Map<String, dynamic>.from(map['messageData'] as Map? ?? {}),
      scheduledFor: _parseDateTime(map['scheduledFor']),
      createdAt: _parseDateTime(map['createdAt']),
      status: _parseStatus(map['status']),
      members: (map['members'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      errorMessage: map['errorMessage'] as String?,
    );
  }

  factory ScheduledMessage.fromQuery(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return ScheduledMessage.fromMap(doc.data() ?? {}, docId: doc.id);
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static ScheduledMessageStatus _parseStatus(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'pending':
          return ScheduledMessageStatus.pending;
        case 'sent':
          return ScheduledMessageStatus.sent;
        case 'cancelled':
          return ScheduledMessageStatus.cancelled;
        case 'failed':
          return ScheduledMessageStatus.failed;
      }
    }
    return ScheduledMessageStatus.pending;
  }
}
