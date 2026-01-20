// Hive Message Model
// Stores message data locally for offline-first architecture

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// HiveMessage - Local storage model for messages
/// Uses Map serialization to support all message types without complex adapters
class HiveMessage extends HiveObject {
  /// Unique message ID (from Firestore or generated locally)
  String id;

  /// Room ID this message belongs to
  String roomId;

  /// Sender user ID
  String senderId;

  /// Message type (text, photo, video, audio, file, poll, location, contact, call, event)
  String type;

  /// Message timestamp
  DateTime timestamp;

  /// Whether the message has been sent to the server
  bool isSent;

  /// Whether the message has been synced/confirmed by the server
  bool isSynced;

  /// Local ID for correlation (UUID generated locally before server assigns ID)
  String? localId;

  /// Version for conflict resolution (increments on each edit)
  int version;

  /// Serialized message data as JSON string
  /// Contains all message-specific fields (text, urls, metadata, etc.)
  String dataJson;

  HiveMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.timestamp,
    this.isSent = false,
    this.isSynced = false,
    this.localId,
    this.version = 1,
    required this.dataJson,
  });

  /// Create from a Message object
  factory HiveMessage.fromMessage(Message message, {
    bool isSent = true,
    bool isSynced = true,
    String? localId,
    int version = 1,
  }) {
    final map = message.toMap();
    return HiveMessage(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      type: map['type'] ?? 'text',
      timestamp: message.timestamp,
      isSent: isSent,
      isSynced: isSynced,
      localId: localId,
      version: version,
      dataJson: jsonEncode(map),
    );
  }

  /// Create from a Map (e.g., from Firestore)
  factory HiveMessage.fromMap(Map<String, dynamic> map, {
    bool isSent = true,
    bool isSynced = true,
    String? localId,
    int version = 1,
  }) {
    return HiveMessage(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: Message.parseTimestamp(map['timestamp']),
      isSent: isSent,
      isSynced: isSynced,
      localId: localId ?? map['localId'],
      version: version,
      dataJson: jsonEncode(map),
    );
  }

  /// Convert back to a Message object
  Message toMessage() {
    final map = jsonDecode(dataJson) as Map<String, dynamic>;
    return Message.fromMap(map);
  }

  /// Get the raw data map
  Map<String, dynamic> toDataMap() {
    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  /// Get preview text for display (last message preview)
  String get previewText {
    final map = toDataMap();
    switch (type) {
      case 'photo':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      case 'file':
        final fileName = map['fileName'] as String? ?? 'File';
        return '📄 $fileName';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'poll':
        return '📊 Poll';
      case 'call':
        return '📞 Call';
      default:
        return map['text'] as String? ?? '';
    }
  }

  /// Create a copy with updated fields
  HiveMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? type,
    DateTime? timestamp,
    bool? isSent,
    bool? isSynced,
    String? localId,
    int? version,
    String? dataJson,
  }) {
    return HiveMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSent: isSent ?? this.isSent,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      version: version ?? this.version,
      dataJson: dataJson ?? this.dataJson,
    );
  }

  @override
  String toString() {
    return 'HiveMessage(id: $id, roomId: $roomId, type: $type, isSynced: $isSynced)';
  }
}

/// Type adapter for HiveMessage
/// TypeId 0 - Reserved for HiveMessage
class HiveMessageAdapter extends TypeAdapter<HiveMessage> {
  @override
  final int typeId = 0;

  @override
  HiveMessage read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }
    return HiveMessage(
      id: fields[0] as String,
      roomId: fields[1] as String,
      senderId: fields[2] as String,
      type: fields[3] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      isSent: fields[5] as bool,
      isSynced: fields[6] as bool,
      localId: fields[7] as String?,
      version: fields[8] as int,
      dataJson: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveMessage obj) {
    writer.writeByte(10); // Number of fields
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.roomId);
    writer.writeByte(2);
    writer.write(obj.senderId);
    writer.writeByte(3);
    writer.write(obj.type);
    writer.writeByte(4);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.writeByte(5);
    writer.write(obj.isSent);
    writer.writeByte(6);
    writer.write(obj.isSynced);
    writer.writeByte(7);
    writer.write(obj.localId);
    writer.writeByte(8);
    writer.write(obj.version);
    writer.writeByte(9);
    writer.write(obj.dataJson);
  }
}
