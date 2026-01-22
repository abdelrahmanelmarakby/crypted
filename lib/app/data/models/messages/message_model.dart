// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:flutter/foundation.dart';

import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';

abstract class Message {
  final String id;
  final String roomId;
  final String senderId;
  final DateTime timestamp;
  final List<Reaction> reactions;
  final ReplyToMessage? replyTo;
  final bool isPinned;
  final bool isFavorite;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFrom;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.timestamp,
    this.reactions = const [],
    this.replyTo,
    this.isPinned = false,
    this.isFavorite = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFrom,
  });

  Map<String, dynamic> toMap();

  static Message fromMap(Map<String, dynamic> map) {
    switch (map['type']) {
      case 'text':
        return TextMessage.fromMap(map);
      case 'photo':
        return PhotoMessage.fromMap(map);
      case 'audio':
        return AudioMessage.fromMap(map);
      case 'contact':
        return ContactMessage.fromMap(map);
      case 'location':
        return LocationMessage.fromMap(map);
      case 'poll':
        return PollMessage.fromMap(map);
      case 'event':
        return EventMessage.fromMap(map);
      case 'file':
        return FileMessage.fromMap(map);
      case 'video':
        return VideoMessage.fromMap(map);
      case 'call':
        return CallMessage.fromMap(map);
      default:
        throw Exception('Unknown message type');
    }
  }

  /// FIX: Updated to use safe parsing that filters out invalid reactions
  static List<Reaction> parseReactions(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((r) => Reaction.fromMapSafe(r as Map<String, dynamic>?))
        .where((r) => r != null)
        .cast<Reaction>()
        .toList();
  }

  static ReplyToMessage? parseReplyTo(dynamic data) {
    if (data == null) return null;
    return ReplyToMessage.fromMap(Map<String, dynamic>.from(data));
  }

  // BUG-008 FIX: Centralized timestamp parsing to handle multiple formats
  /// Parses timestamp from various formats (Firestore Timestamp, ISO string, Map, DateTime)
  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;

    // Handle Firestore Timestamp directly
    try {
      // Using dynamic to avoid import issues - Timestamp has toDate() method
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        return (timestamp as dynamic).toDate();
      }
    } catch (_) {}

    // Handle ISO 8601 string
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp as Map (from JSON serialization)
    if (timestamp is Map) {
      try {
        final seconds = timestamp['_seconds'] ?? timestamp['seconds'] ?? 0;
        final nanoseconds = timestamp['_nanoseconds'] ?? timestamp['nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as int) * 1000 + ((nanoseconds as int) ~/ 1000000),
        );
      } catch (e) {
        print('Error parsing timestamp map: $e');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> baseMap() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
        'reactions': reactions.map((r) => r.toMap()).toList(),
        'replyTo': replyTo?.toMap(),
        'isPinned': isPinned,
        'isFavorite': isFavorite,
        'isDeleted': isDeleted,
        'isForwarded': isForwarded,
        'forwardedFrom': forwardedFrom,
      };

  @override
  String toString() {
    return 'Message(id: $id, roomId: $roomId, senderId: $senderId, timestamp: $timestamp, reactions: $reactions, replyTo: $replyTo, isPinned: $isPinned, isFavorite: $isFavorite, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.timestamp == timestamp &&
        listEquals(other.reactions, reactions) &&
        other.replyTo == replyTo &&
        other.isPinned == isPinned &&
        other.isFavorite == isFavorite &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roomId.hashCode ^
        senderId.hashCode ^
        timestamp.hashCode ^
        reactions.hashCode ^
        replyTo.hashCode ^
        isPinned.hashCode ^
        isFavorite.hashCode ^
        isDeleted.hashCode;
  }

  copyWith({
    String? id,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    List<Reaction>? reactions,
    ReplyToMessage? replyTo,
    bool? isPinned,
    bool? isFavorite,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFrom,
  }) {
    // This is an abstract method, implementation in subclasses
    throw UnimplementedError('copyWith must be implemented by subclasses');
  }
}

class Reaction {
  final String emoji;
  final String userId;

  Reaction({required this.emoji, required this.userId});

  Map<String, dynamic> toMap() => {
        'emoji': emoji,
        'userId': userId,
      };

  /// FIX: Added null safety handling for Reaction.fromMap()
  /// Returns null if required fields are missing
  static Reaction? fromMapSafe(Map<String, dynamic>? map) {
    if (map == null) return null;

    final emoji = map['emoji'] as String?;
    final userId = map['userId'] as String?;

    // Skip invalid reactions with missing fields
    if (emoji == null || emoji.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }

    return Reaction(emoji: emoji, userId: userId);
  }

  /// Legacy factory - kept for backwards compatibility but with null handling
  factory Reaction.fromMap(Map<String, dynamic> map) => Reaction(
        emoji: map['emoji'] ?? '',
        userId: map['userId'] ?? '',
      );

  /// Parse a list of reactions from Firestore data with null safety
  static List<Reaction> fromMapList(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((item) => Reaction.fromMapSafe(item as Map<String, dynamic>?))
        .where((r) => r != null && r.emoji.isNotEmpty && r.userId.isNotEmpty)
        .cast<Reaction>()
        .toList();
  }
}

class ReplyToMessage {
  final String id;
  final String senderId;
  final String previewText;

  ReplyToMessage({
    required this.id,
    required this.senderId,
    required this.previewText,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'previewText': previewText,
      };

  /// FIX: Added null safety handling
  factory ReplyToMessage.fromMap(Map<String, dynamic> map) => ReplyToMessage(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        previewText: map['previewText'] ?? '',
      );

  /// Safe parsing that returns null if required fields are missing
  static ReplyToMessage? fromMapSafe(Map<String, dynamic>? map) {
    if (map == null) return null;
    final id = map['id'] as String?;
    final senderId = map['senderId'] as String?;
    if (id == null || senderId == null) return null;
    return ReplyToMessage(
      id: id,
      senderId: senderId,
      previewText: map['previewText'] ?? '',
    );
  }
}

/// MessageModel - A simplified model for media gallery and other UI components
/// that need quick access to message data without the full Message hierarchy
class MessageModel {
  final String? messageId;
  final String? senderId;
  final String? type;
  final String? text;
  final DateTime? timestamp;

  // Media URLs
  final String? photoUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? fileUrl;

  // File metadata
  final String? fileName;
  final String? fileSize;
  final String? audioDuration;

  // Thumbnail for videos
  final String? thumbnailUrl;

  MessageModel({
    this.messageId,
    this.senderId,
    this.type,
    this.text,
    this.timestamp,
    this.photoUrl,
    this.videoUrl,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.audioDuration,
    this.thumbnailUrl,
  });

  /// Create MessageModel from a Firestore DocumentSnapshot
  factory MessageModel.fromQuery(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return MessageModel(messageId: doc.id);
    }

    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] as String?,
      type: data['type'] as String?,
      text: data['text'] as String? ?? data['content'] as String?,
      timestamp: Message.parseTimestamp(data['timestamp']),
      photoUrl: data['photoUrl'] as String? ?? data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      fileUrl: data['fileUrl'] as String? ?? data['url'] as String?,
      fileName: data['fileName'] as String? ?? data['name'] as String?,
      fileSize: _formatFileSize(data['fileSize']),
      audioDuration: _formatDuration(data['audioDuration'] ?? data['duration']),
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }

  /// Create MessageModel from a Map
  factory MessageModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MessageModel(
      messageId: id ?? map['id'] as String?,
      senderId: map['senderId'] as String?,
      type: map['type'] as String?,
      text: map['text'] as String? ?? map['content'] as String?,
      timestamp: Message.parseTimestamp(map['timestamp']),
      photoUrl: map['photoUrl'] as String? ?? map['imageUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      fileUrl: map['fileUrl'] as String? ?? map['url'] as String?,
      fileName: map['fileName'] as String? ?? map['name'] as String?,
      fileSize: _formatFileSize(map['fileSize']),
      audioDuration: _formatDuration(map['audioDuration'] ?? map['duration']),
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  /// Format file size to human-readable string
  static String? _formatFileSize(dynamic size) {
    if (size == null) return null;
    if (size is String) return size;

    final bytes = size is int ? size : (size as num).toInt();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format duration to human-readable string
  static String? _formatDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is String) return duration;

    final seconds = duration is int ? duration : (duration as num).toInt();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
