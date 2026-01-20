// Hive Sync Metadata Model
// Tracks synchronization state for each chat room

import 'package:hive/hive.dart';

/// Sync state enum values
class SyncState {
  static const int idle = 0;
  static const int syncing = 1;
  static const int error = 2;
  static const int paused = 3;
}

/// HiveSyncMetadata - Tracks sync state for a chat room
/// Used to resume sync after app restart and track what's been synced
class HiveSyncMetadata extends HiveObject {
  /// Room ID this metadata is for
  String roomId;

  /// Last successful sync timestamp
  DateTime? lastSyncTime;

  /// ID of the last synced message (for pagination)
  String? lastMessageId;

  /// Timestamp of the last synced message (for querying newer messages)
  DateTime? lastMessageTimestamp;

  /// Current sync state (0=idle, 1=syncing, 2=error, 3=paused)
  int syncState;

  /// Number of pending operations for this room
  int pendingOperations;

  /// Last error message (if syncState == error)
  String? lastError;

  /// Number of consecutive sync failures
  int failureCount;

  /// Whether full initial sync has been completed
  bool initialSyncComplete;

  HiveSyncMetadata({
    required this.roomId,
    this.lastSyncTime,
    this.lastMessageId,
    this.lastMessageTimestamp,
    this.syncState = SyncState.idle,
    this.pendingOperations = 0,
    this.lastError,
    this.failureCount = 0,
    this.initialSyncComplete = false,
  });

  /// Check if sync is currently in progress
  bool get isSyncing => syncState == SyncState.syncing;

  /// Check if there was an error
  bool get hasError => syncState == SyncState.error;

  /// Check if sync is idle
  bool get isIdle => syncState == SyncState.idle;

  /// Check if sync needs to be resumed
  bool get needsSync => !initialSyncComplete || pendingOperations > 0;

  /// Mark sync as started
  void startSync() {
    syncState = SyncState.syncing;
    lastError = null;
  }

  /// Mark sync as completed successfully
  void completeSync({
    required DateTime syncTime,
    String? lastMsgId,
    DateTime? lastMsgTimestamp,
  }) {
    syncState = SyncState.idle;
    lastSyncTime = syncTime;
    lastMessageId = lastMsgId ?? lastMessageId;
    lastMessageTimestamp = lastMsgTimestamp ?? lastMessageTimestamp;
    lastError = null;
    failureCount = 0;
    initialSyncComplete = true;
  }

  /// Mark sync as failed
  void failSync(String error) {
    syncState = SyncState.error;
    lastError = error;
    failureCount++;
  }

  /// Reset failure count and error
  void resetError() {
    syncState = SyncState.idle;
    lastError = null;
    failureCount = 0;
  }

  /// Increment pending operations count
  void addPendingOperation() {
    pendingOperations++;
  }

  /// Decrement pending operations count
  void completePendingOperation() {
    if (pendingOperations > 0) {
      pendingOperations--;
    }
  }

  /// Create a copy with updated fields
  HiveSyncMetadata copyWith({
    String? roomId,
    DateTime? lastSyncTime,
    String? lastMessageId,
    DateTime? lastMessageTimestamp,
    int? syncState,
    int? pendingOperations,
    String? lastError,
    int? failureCount,
    bool? initialSyncComplete,
  }) {
    return HiveSyncMetadata(
      roomId: roomId ?? this.roomId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      syncState: syncState ?? this.syncState,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastError: lastError ?? this.lastError,
      failureCount: failureCount ?? this.failureCount,
      initialSyncComplete: initialSyncComplete ?? this.initialSyncComplete,
    );
  }

  @override
  String toString() {
    return 'HiveSyncMetadata(roomId: $roomId, state: $syncState, pending: $pendingOperations, lastSync: $lastSyncTime)';
  }
}

/// Type adapter for HiveSyncMetadata
/// TypeId 2 - Reserved for HiveSyncMetadata
class HiveSyncMetadataAdapter extends TypeAdapter<HiveSyncMetadata> {
  @override
  final int typeId = 2;

  @override
  HiveSyncMetadata read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    DateTime? lastSyncTime;
    if (fields[1] != null) {
      lastSyncTime = DateTime.fromMillisecondsSinceEpoch(fields[1] as int);
    }

    DateTime? lastMsgTimestamp;
    if (fields[3] != null) {
      lastMsgTimestamp = DateTime.fromMillisecondsSinceEpoch(fields[3] as int);
    }

    return HiveSyncMetadata(
      roomId: fields[0] as String,
      lastSyncTime: lastSyncTime,
      lastMessageId: fields[2] as String?,
      lastMessageTimestamp: lastMsgTimestamp,
      syncState: fields[4] as int,
      pendingOperations: fields[5] as int,
      lastError: fields[6] as String?,
      failureCount: fields[7] as int,
      initialSyncComplete: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSyncMetadata obj) {
    writer.writeByte(9); // Number of fields
    writer.writeByte(0);
    writer.write(obj.roomId);
    writer.writeByte(1);
    writer.write(obj.lastSyncTime?.millisecondsSinceEpoch);
    writer.writeByte(2);
    writer.write(obj.lastMessageId);
    writer.writeByte(3);
    writer.write(obj.lastMessageTimestamp?.millisecondsSinceEpoch);
    writer.writeByte(4);
    writer.write(obj.syncState);
    writer.writeByte(5);
    writer.write(obj.pendingOperations);
    writer.writeByte(6);
    writer.write(obj.lastError);
    writer.writeByte(7);
    writer.write(obj.failureCount);
    writer.writeByte(8);
    writer.write(obj.initialSyncComplete);
  }
}
