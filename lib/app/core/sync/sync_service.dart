// Sync Service
// Handles bidirectional synchronization between Hive and Firestore

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/services/local_database_service.dart';
import 'package:crypted_app/app/core/sync/conflict_resolver.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/hive/hive_models.dart';

/// Sync result containing statistics
class SyncResult {
  final int pulledMessages;
  final int pushedMessages;
  final int conflicts;
  final List<String> errors;
  final Duration duration;

  SyncResult({
    this.pulledMessages = 0,
    this.pushedMessages = 0,
    this.conflicts = 0,
    this.errors = const [],
    this.duration = Duration.zero,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => errors.isEmpty;

  @override
  String toString() {
    return 'SyncResult(pulled: $pulledMessages, pushed: $pushedMessages, conflicts: $conflicts, errors: ${errors.length})';
  }
}

/// SyncService - Manages bidirectional sync between Hive and Firestore
/// Uses RoomSyncStatusEvent from event_bus.dart for status updates
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventBus _eventBus = EventBus();

  // Active listeners for real-time sync
  final Map<String, StreamSubscription> _roomListeners = {};

  // Sync state
  bool _isSyncing = false;
  final Set<String> _syncingRooms = {};

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Check if a specific room is syncing
  bool isRoomSyncing(String roomId) => _syncingRooms.contains(roomId);

  // =================== PULL OPERATIONS (Firestore → Hive) ===================

  /// Pull messages for a room from Firestore
  Future<int> pullMessages(
    String roomId, {
    DateTime? since,
    int limit = 100,
  }) async {
    if (!ConnectivityService().isOnline) {
      if (kDebugMode) print('[SyncService] Offline, skipping pull');
      return 0;
    }

    try {
      Query query = _firestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return 0;

      final messages = <HiveMessage>[];
      DateTime? latestTimestamp;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        final message = HiveMessage.fromMap(data, isSynced: true);
        messages.add(message);

        // Track latest timestamp
        if (latestTimestamp == null || message.timestamp.isAfter(latestTimestamp)) {
          latestTimestamp = message.timestamp;
        }
      }

      // Save to local database
      await _localDb.saveMessages(messages);

      // Update sync metadata
      if (latestTimestamp != null) {
        await _localDb.completeRoomSync(
          roomId,
          lastMessageId: messages.first.id,
          lastMessageTimestamp: latestTimestamp,
        );
      }

      if (kDebugMode) {
        print('[SyncService] Pulled ${messages.length} messages for room: $roomId');
      }

      return messages.length;
    } catch (e) {
      if (kDebugMode) {
        print('[SyncService] Error pulling messages: $e');
      }
      await _localDb.failRoomSync(roomId, e.toString());
      return 0;
    }
  }

  /// Pull chat rooms from Firestore for a user
  Future<int> pullChatRooms(String userId) async {
    if (!ConnectivityService().isOnline) {
      if (kDebugMode) print('[SyncService] Offline, skipping room pull');
      return 0;
    }

    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: userId)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final rooms = <HiveChatRoom>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final room = HiveChatRoom.fromMap(data, isSynced: true);
        rooms.add(room);
      }

      // Save to local database
      await _localDb.saveChatRooms(rooms);

      if (kDebugMode) {
        print('[SyncService] Pulled ${rooms.length} chat rooms for user: $userId');
      }

      return rooms.length;
    } catch (e) {
      if (kDebugMode) {
        print('[SyncService] Error pulling chat rooms: $e');
      }
      return 0;
    }
  }

  // =================== PUSH OPERATIONS (Hive → Firestore) ===================

  /// Push pending messages to Firestore
  Future<int> pushPendingMessages() async {
    if (!ConnectivityService().isOnline) {
      if (kDebugMode) print('[SyncService] Offline, skipping push');
      return 0;
    }

    try {
      final unsyncedMessages = await _localDb.getUnsyncedMessages();
      if (unsyncedMessages.isEmpty) return 0;

      int pushed = 0;

      for (final message in unsyncedMessages) {
        try {
          // Use the offline queue to ensure proper handling
          final data = message.toDataMap();
          await _firestore
              .collection(FirebaseCollections.chats)
              .doc(message.roomId)
              .collection(FirebaseCollections.chatMessages)
              .doc(message.id)
              .set(data, SetOptions(merge: true));

          // Mark as synced
          await _localDb.updateMessageSyncStatus(message.roomId, message.id, true);
          pushed++;
        } catch (e) {
          if (kDebugMode) {
            print('[SyncService] Error pushing message ${message.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('[SyncService] Pushed $pushed of ${unsyncedMessages.length} messages');
      }

      return pushed;
    } catch (e) {
      if (kDebugMode) {
        print('[SyncService] Error pushing messages: $e');
      }
      return 0;
    }
  }

  // =================== FULL SYNC OPERATIONS ===================

  /// Sync a single room (pull then push)
  Future<SyncResult> syncRoom(String roomId) async {
    if (_syncingRooms.contains(roomId)) {
      if (kDebugMode) print('[SyncService] Room $roomId already syncing');
      return SyncResult(errors: ['Already syncing']);
    }

    final stopwatch = Stopwatch()..start();
    _syncingRooms.add(roomId);

    _eventBus.emit(RoomSyncStatusEvent(
      roomId: roomId,
      isSyncing: true,
      message: 'Syncing...',
    ));

    try {
      await _localDb.startRoomSync(roomId);

      // Get last sync time for incremental sync
      final metadata = await _localDb.getSyncMetadata(roomId);
      final since = metadata?.lastMessageTimestamp;

      // Pull remote changes first
      final pulled = await pullMessages(roomId, since: since);

      // Push local changes
      final unsynced = await _localDb.getUnsyncedMessagesForRoom(roomId);
      int pushed = 0;
      int conflicts = 0;

      for (final message in unsynced) {
        try {
          // Check if message exists remotely
          final remoteDoc = await _firestore
              .collection(FirebaseCollections.chats)
              .doc(roomId)
              .collection(FirebaseCollections.chatMessages)
              .doc(message.id)
              .get();

          if (remoteDoc.exists) {
            // Resolve conflict
            final remoteData = remoteDoc.data()!;
            remoteData['id'] = remoteDoc.id;
            final remote = HiveMessage.fromMap(remoteData, isSynced: true);
            final result = ConflictResolver.resolveMessage(message, remote);

            await _localDb.saveMessage(result.resolved);
            if (result.hadConflict) conflicts++;
          } else {
            // Push new message
            final data = message.toDataMap();
            await _firestore
                .collection(FirebaseCollections.chats)
                .doc(roomId)
                .collection(FirebaseCollections.chatMessages)
                .doc(message.id)
                .set(data);

            await _localDb.updateMessageSyncStatus(roomId, message.id, true);
            pushed++;
          }
        } catch (e) {
          if (kDebugMode) {
            print('[SyncService] Error syncing message ${message.id}: $e');
          }
        }
      }

      stopwatch.stop();

      final result = SyncResult(
        pulledMessages: pulled,
        pushedMessages: pushed,
        conflicts: conflicts,
        duration: stopwatch.elapsed,
      );

      if (kDebugMode) {
        print('[SyncService] Room sync complete: $result');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await _localDb.failRoomSync(roomId, e.toString());

      return SyncResult(
        errors: [e.toString()],
        duration: stopwatch.elapsed,
      );
    } finally {
      _syncingRooms.remove(roomId);
      _eventBus.emit(RoomSyncStatusEvent(
        roomId: roomId,
        isSyncing: false,
      ));
    }
  }

  /// Sync all rooms for a user
  Future<SyncResult> syncAll(String userId) async {
    if (_isSyncing) {
      if (kDebugMode) print('[SyncService] Already syncing');
      return SyncResult(errors: ['Already syncing']);
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    int totalPulled = 0;
    int totalPushed = 0;
    int totalConflicts = 0;
    final errors = <String>[];

    try {
      // First, sync chat rooms list
      await pullChatRooms(userId);

      // Get all local rooms
      final rooms = await _localDb.getChatRooms();

      for (final room in rooms) {
        final result = await syncRoom(room.id);
        totalPulled += result.pulledMessages;
        totalPushed += result.pushedMessages;
        totalConflicts += result.conflicts;
        errors.addAll(result.errors);
      }

      stopwatch.stop();

      final result = SyncResult(
        pulledMessages: totalPulled,
        pushedMessages: totalPushed,
        conflicts: totalConflicts,
        errors: errors,
        duration: stopwatch.elapsed,
      );

      if (kDebugMode) {
        print('[SyncService] Full sync complete: $result');
      }

      return result;
    } finally {
      _isSyncing = false;
    }
  }

  // =================== REAL-TIME SYNC ===================

  /// Start real-time sync for a room
  void startRealtimeSync(String roomId) {
    if (_roomListeners.containsKey(roomId)) {
      if (kDebugMode) print('[SyncService] Real-time sync already active for: $roomId');
      return;
    }

    final subscription = _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          data['id'] = change.doc.id;

          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              final message = HiveMessage.fromMap(data, isSynced: true);

              // Check for conflicts
              final existing = await _localDb.getMessage(roomId, message.id);
              if (existing != null && !existing.isSynced) {
                final result = ConflictResolver.resolveMessage(existing, message);
                await _localDb.saveMessage(result.resolved);
              } else {
                await _localDb.saveMessage(message);
              }
              break;

            case DocumentChangeType.removed:
              await _localDb.deleteMessage(roomId, change.doc.id);
              break;
          }
        }

        // Fire event for UI update
        _eventBus.emit(RoomSyncStatusEvent(
          roomId: roomId,
          isSyncing: false,
          message: 'Updated',
        ));
      },
      onError: (error) {
        if (kDebugMode) {
          print('[SyncService] Real-time sync error for $roomId: $error');
        }
      },
    );

    _roomListeners[roomId] = subscription;

    if (kDebugMode) {
      print('[SyncService] Started real-time sync for: $roomId');
    }
  }

  /// Stop real-time sync for a room
  void stopRealtimeSync(String roomId) {
    final subscription = _roomListeners.remove(roomId);
    subscription?.cancel();

    if (kDebugMode) {
      print('[SyncService] Stopped real-time sync for: $roomId');
    }
  }

  /// Stop all real-time syncs
  void stopAllRealtimeSyncs() {
    for (final subscription in _roomListeners.values) {
      subscription.cancel();
    }
    _roomListeners.clear();

    if (kDebugMode) {
      print('[SyncService] Stopped all real-time syncs');
    }
  }

  // =================== INITIAL SYNC ===================

  /// Perform initial sync for a room (full history)
  Future<SyncResult> initialSync(String roomId, {int messageLimit = 100}) async {
    if (kDebugMode) {
      print('[SyncService] Starting initial sync for: $roomId');
    }

    // Pull full history
    final pulled = await pullMessages(roomId, limit: messageLimit);

    // Mark as initially synced
    await _localDb.completeRoomSync(roomId);

    return SyncResult(pulledMessages: pulled);
  }

  // =================== UTILITY ===================

  /// Check if a room has been initially synced
  Future<bool> isRoomSynced(String roomId) async {
    final metadata = await _localDb.getSyncMetadata(roomId);
    return metadata?.initialSyncComplete ?? false;
  }

  /// Get sync status for a room
  Future<HiveSyncMetadata?> getRoomSyncStatus(String roomId) async {
    return await _localDb.getSyncMetadata(roomId);
  }

  /// Dispose resources
  void dispose() {
    stopAllRealtimeSyncs();
  }
}
