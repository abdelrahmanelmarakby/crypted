// Hive Chat Room Model
// Stores chat room data locally for offline-first architecture

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';

/// HiveChatRoom - Local storage model for chat rooms
class HiveChatRoom extends HiveObject {
  /// Unique room ID
  String id;

  /// Room name (for groups) or null (for 1-on-1)
  String? name;

  /// Whether this is a group chat
  bool isGroup;

  /// List of member user IDs
  List<String> memberIds;

  /// Last message preview text
  String? lastMessage;

  /// Timestamp of last message
  DateTime? lastMessageTime;

  /// Last message sender ID
  String? lastSenderId;

  /// Unread message count for current user
  int unreadCount;

  /// Whether the room data is synced with server
  bool isSynced;

  /// Version for conflict resolution
  int version;

  /// Group image URL
  String? groupImageUrl;

  /// Whether this room is muted
  bool isMuted;

  /// Whether this room is pinned
  bool isPinned;

  /// Whether this room is archived
  bool isArchived;

  /// Whether this room is marked as favorite
  bool isFavorite;

  /// Serialized full room data as JSON string
  /// Contains all room-specific fields (members, blocked users, etc.)
  String dataJson;

  HiveChatRoom({
    required this.id,
    this.name,
    required this.isGroup,
    required this.memberIds,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    this.unreadCount = 0,
    this.isSynced = false,
    this.version = 1,
    this.groupImageUrl,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    required this.dataJson,
  });

  /// Create from a ChatRoom object
  factory HiveChatRoom.fromChatRoom(ChatRoom room, {
    bool isSynced = true,
    int version = 1,
    int unreadCount = 0,
  }) {
    final map = room.toMap();
    return HiveChatRoom(
      id: room.id ?? '',
      name: room.name,
      isGroup: room.isGroupChat ?? false,
      memberIds: room.membersIds ?? [],
      lastMessage: room.lastMsg,
      lastMessageTime: null, // Will be set from last message
      lastSenderId: room.lastSender,
      unreadCount: unreadCount,
      isSynced: isSynced,
      version: version,
      groupImageUrl: room.groupImageUrl,
      isMuted: room.isMuted ?? false,
      isPinned: room.isPinned ?? false,
      isArchived: room.isArchived ?? false,
      isFavorite: room.isFavorite ?? false,
      dataJson: jsonEncode(map),
    );
  }

  /// Create from a Map (e.g., from Firestore)
  factory HiveChatRoom.fromMap(Map<String, dynamic> map, {
    bool isSynced = true,
    int version = 1,
    int unreadCount = 0,
  }) {
    final memberIds = map['membersIds'] != null
        ? (map['membersIds'] as List<dynamic>).map((e) => e.toString()).toList()
        : <String>[];

    DateTime? lastMsgTime;
    if (map['lastMessageTimestamp'] != null) {
      try {
        if (map['lastMessageTimestamp'] is DateTime) {
          lastMsgTime = map['lastMessageTimestamp'];
        } else if (map['lastMessageTimestamp'].runtimeType.toString().contains('Timestamp')) {
          lastMsgTime = (map['lastMessageTimestamp'] as dynamic).toDate();
        }
      } catch (_) {}
    }

    return HiveChatRoom(
      id: map['id'] ?? '',
      name: map['name'],
      isGroup: map['isGroupChat'] ?? false,
      memberIds: memberIds,
      lastMessage: map['lastMsg'] ?? map['lastMessage'],
      lastMessageTime: lastMsgTime,
      lastSenderId: map['lastSender'] ?? map['lastMessageSenderId'],
      unreadCount: unreadCount,
      isSynced: isSynced,
      version: version,
      groupImageUrl: map['groupImageUrl'],
      isMuted: map['isMuted'] ?? false,
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      dataJson: jsonEncode(map),
    );
  }

  /// Convert back to a ChatRoom object
  ChatRoom toChatRoom() {
    final map = jsonDecode(dataJson) as Map<String, dynamic>;
    return ChatRoom.fromMap(map);
  }

  /// Get the raw data map
  Map<String, dynamic> toDataMap() {
    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  /// Get display name for the room
  /// For groups: use room name
  /// For 1-on-1: should use other user's name (handled by controller)
  String get displayName => name ?? 'Chat';

  /// Create a copy with updated fields
  HiveChatRoom copyWith({
    String? id,
    String? name,
    bool? isGroup,
    List<String>? memberIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastSenderId,
    int? unreadCount,
    bool? isSynced,
    int? version,
    String? groupImageUrl,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    String? dataJson,
  }) {
    return HiveChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      memberIds: memberIds ?? this.memberIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isSynced: isSynced ?? this.isSynced,
      version: version ?? this.version,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      dataJson: dataJson ?? this.dataJson,
    );
  }

  @override
  String toString() {
    return 'HiveChatRoom(id: $id, name: $name, isGroup: $isGroup, unread: $unreadCount, isSynced: $isSynced)';
  }
}

/// Type adapter for HiveChatRoom
/// TypeId 1 - Reserved for HiveChatRoom
class HiveChatRoomAdapter extends TypeAdapter<HiveChatRoom> {
  @override
  final int typeId = 1;

  @override
  HiveChatRoom read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    DateTime? lastMsgTime;
    if (fields[5] != null) {
      lastMsgTime = DateTime.fromMillisecondsSinceEpoch(fields[5] as int);
    }

    return HiveChatRoom(
      id: fields[0] as String,
      name: fields[1] as String?,
      isGroup: fields[2] as bool,
      memberIds: (fields[3] as List).cast<String>(),
      lastMessage: fields[4] as String?,
      lastMessageTime: lastMsgTime,
      lastSenderId: fields[6] as String?,
      unreadCount: fields[7] as int,
      isSynced: fields[8] as bool,
      version: fields[9] as int,
      groupImageUrl: fields[10] as String?,
      isMuted: fields[11] as bool,
      isPinned: fields[12] as bool,
      isArchived: fields[13] as bool,
      isFavorite: fields[14] as bool,
      dataJson: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveChatRoom obj) {
    writer.writeByte(16); // Number of fields
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.isGroup);
    writer.writeByte(3);
    writer.write(obj.memberIds);
    writer.writeByte(4);
    writer.write(obj.lastMessage);
    writer.writeByte(5);
    writer.write(obj.lastMessageTime?.millisecondsSinceEpoch);
    writer.writeByte(6);
    writer.write(obj.lastSenderId);
    writer.writeByte(7);
    writer.write(obj.unreadCount);
    writer.writeByte(8);
    writer.write(obj.isSynced);
    writer.writeByte(9);
    writer.write(obj.version);
    writer.writeByte(10);
    writer.write(obj.groupImageUrl);
    writer.writeByte(11);
    writer.write(obj.isMuted);
    writer.writeByte(12);
    writer.write(obj.isPinned);
    writer.writeByte(13);
    writer.write(obj.isArchived);
    writer.writeByte(14);
    writer.write(obj.isFavorite);
    writer.writeByte(15);
    writer.write(obj.dataJson);
  }
}
