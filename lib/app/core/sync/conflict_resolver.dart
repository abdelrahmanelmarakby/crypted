// Conflict Resolver
// Handles conflicts when syncing local and remote data

import 'package:crypted_app/app/data/models/hive/hive_models.dart';

/// Conflict resolution strategies
enum ConflictStrategy {
  /// Remote data wins (server is source of truth)
  remoteWins,

  /// Local data wins (preserve offline changes)
  localWins,

  /// Last write wins based on timestamp
  lastWriteWins,

  /// Merge both versions (for reactions, members, etc.)
  merge,
}

/// Result of conflict resolution
class ConflictResult<T> {
  final T resolved;
  final bool hadConflict;
  final String? conflictDescription;

  ConflictResult({
    required this.resolved,
    this.hadConflict = false,
    this.conflictDescription,
  });
}

/// ConflictResolver - Handles sync conflicts between local and remote data
class ConflictResolver {
  /// Default strategy for messages
  static const ConflictStrategy defaultMessageStrategy = ConflictStrategy.lastWriteWins;

  /// Default strategy for chat rooms
  static const ConflictStrategy defaultRoomStrategy = ConflictStrategy.remoteWins;

  // =================== MESSAGE CONFLICT RESOLUTION ===================

  /// Resolve conflict between local and remote message
  static ConflictResult<HiveMessage> resolveMessage(
    HiveMessage local,
    HiveMessage remote, {
    ConflictStrategy strategy = defaultMessageStrategy,
  }) {
    // If IDs don't match, this isn't a conflict
    if (local.id != remote.id) {
      return ConflictResult(resolved: remote, hadConflict: false);
    }

    // Check if there's actually a conflict
    final localData = local.toDataMap();
    final remoteData = remote.toDataMap();

    // Simple case: if data is identical, no conflict
    if (_mapsEqual(localData, remoteData)) {
      return ConflictResult(
        resolved: remote.copyWith(isSynced: true),
        hadConflict: false,
      );
    }

    // Apply strategy
    switch (strategy) {
      case ConflictStrategy.remoteWins:
        return ConflictResult(
          resolved: HiveMessage.fromMap(remoteData, isSynced: true),
          hadConflict: true,
          conflictDescription: 'Remote data preserved',
        );

      case ConflictStrategy.localWins:
        return ConflictResult(
          resolved: local.copyWith(isSynced: false),
          hadConflict: true,
          conflictDescription: 'Local data preserved, needs re-sync',
        );

      case ConflictStrategy.lastWriteWins:
        if (local.timestamp.isAfter(remote.timestamp)) {
          return ConflictResult(
            resolved: local.copyWith(isSynced: false),
            hadConflict: true,
            conflictDescription: 'Local is newer, needs re-sync',
          );
        } else {
          return ConflictResult(
            resolved: HiveMessage.fromMap(remoteData, isSynced: true),
            hadConflict: true,
            conflictDescription: 'Remote is newer, updated locally',
          );
        }

      case ConflictStrategy.merge:
        // For messages, merge reactions but keep remote text
        final mergedData = _mergeMessageData(localData, remoteData);
        return ConflictResult(
          resolved: HiveMessage.fromMap(mergedData, isSynced: true),
          hadConflict: true,
          conflictDescription: 'Data merged',
        );
    }
  }

  /// Merge message data (for reactions, read receipts, etc.)
  static Map<String, dynamic> _mergeMessageData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Start with remote data
    final merged = Map<String, dynamic>.from(remote);

    // Merge reactions (union)
    final localReactions = local['reactions'] as List<dynamic>? ?? [];
    final remoteReactions = remote['reactions'] as List<dynamic>? ?? [];
    merged['reactions'] = _mergeReactionLists(localReactions, remoteReactions);

    // Merge readBy (union)
    final localReadBy = local['readBy'] as List<dynamic>? ?? [];
    final remoteReadBy = remote['readBy'] as List<dynamic>? ?? [];
    merged['readBy'] = {...localReadBy, ...remoteReadBy}.toList();

    return merged;
  }

  /// Merge reaction lists
  static List<dynamic> _mergeReactionLists(
    List<dynamic> local,
    List<dynamic> remote,
  ) {
    // Create a map of emoji -> userIds
    final reactionMap = <String, Set<String>>{};

    for (final reaction in [...local, ...remote]) {
      if (reaction is Map) {
        final emoji = reaction['emoji'] as String?;
        final userId = reaction['userId'] as String?;
        if (emoji != null && userId != null) {
          reactionMap.putIfAbsent(emoji, () => <String>{});
          reactionMap[emoji]!.add(userId);
        }
      }
    }

    // Convert back to list format
    final result = <Map<String, dynamic>>[];
    for (final entry in reactionMap.entries) {
      for (final userId in entry.value) {
        result.add({'emoji': entry.key, 'userId': userId});
      }
    }

    return result;
  }

  // =================== CHAT ROOM CONFLICT RESOLUTION ===================

  /// Resolve conflict between local and remote chat room
  static ConflictResult<HiveChatRoom> resolveRoom(
    HiveChatRoom local,
    HiveChatRoom remote, {
    ConflictStrategy strategy = defaultRoomStrategy,
  }) {
    // If IDs don't match, this isn't a conflict
    if (local.id != remote.id) {
      return ConflictResult(resolved: remote, hadConflict: false);
    }

    // Check if there's actually a conflict
    final localData = local.toDataMap();
    final remoteData = remote.toDataMap();

    if (_mapsEqual(localData, remoteData)) {
      return ConflictResult(
        resolved: remote.copyWith(isSynced: true),
        hadConflict: false,
      );
    }

    // For chat rooms, merge is usually the best strategy
    switch (strategy) {
      case ConflictStrategy.remoteWins:
        // Preserve local UI preferences
        return ConflictResult(
          resolved: HiveChatRoom.fromMap(
            remoteData,
            isSynced: true,
          ).copyWith(
            isMuted: local.isMuted,
            isPinned: local.isPinned,
            isArchived: local.isArchived,
            isFavorite: local.isFavorite,
          ),
          hadConflict: true,
          conflictDescription: 'Remote data with local preferences',
        );

      case ConflictStrategy.localWins:
        return ConflictResult(
          resolved: local.copyWith(isSynced: false),
          hadConflict: true,
          conflictDescription: 'Local data preserved, needs re-sync',
        );

      case ConflictStrategy.lastWriteWins:
        final localTime = local.lastMessageTime ?? DateTime(1970);
        final remoteTime = remote.lastMessageTime ?? DateTime(1970);
        if (localTime.isAfter(remoteTime)) {
          return ConflictResult(
            resolved: local.copyWith(isSynced: false),
            hadConflict: true,
            conflictDescription: 'Local is newer',
          );
        } else {
          return ConflictResult(
            resolved: remote.copyWith(isSynced: true),
            hadConflict: true,
            conflictDescription: 'Remote is newer',
          );
        }

      case ConflictStrategy.merge:
        final mergedData = _mergeRoomData(localData, remoteData);
        return ConflictResult(
          resolved: HiveChatRoom.fromMap(mergedData, isSynced: true).copyWith(
            isMuted: local.isMuted,
            isPinned: local.isPinned,
            isArchived: local.isArchived,
            isFavorite: local.isFavorite,
          ),
          hadConflict: true,
          conflictDescription: 'Data merged',
        );
    }
  }

  /// Merge chat room data
  static Map<String, dynamic> _mergeRoomData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Start with remote data (source of truth for members, settings)
    final merged = Map<String, dynamic>.from(remote);

    // Keep local UI preferences
    merged['isMuted'] = local['isMuted'] ?? remote['isMuted'];
    merged['isPinned'] = local['isPinned'] ?? remote['isPinned'];
    merged['isArchived'] = local['isArchived'] ?? remote['isArchived'];
    merged['isFavorite'] = local['isFavorite'] ?? remote['isFavorite'];

    return merged;
  }

  // =================== BATCH OPERATIONS ===================

  /// Resolve conflicts for a list of messages
  static List<HiveMessage> resolveMessageBatch(
    List<HiveMessage> localMessages,
    List<HiveMessage> remoteMessages,
  ) {
    final localMap = {for (var m in localMessages) m.id: m};
    final resolved = <HiveMessage>[];

    for (final remote in remoteMessages) {
      final local = localMap[remote.id];
      if (local != null) {
        final result = resolveMessage(local, remote);
        resolved.add(result.resolved);
        localMap.remove(remote.id);
      } else {
        // New message from remote
        resolved.add(remote.copyWith(isSynced: true));
      }
    }

    // Add remaining local messages that aren't synced
    for (final local in localMap.values) {
      if (!local.isSynced) {
        resolved.add(local);
      }
    }

    return resolved;
  }

  // =================== HELPERS ===================

  /// Deep compare two maps
  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;

      final valueA = a[key];
      final valueB = b[key];

      if (valueA is Map && valueB is Map) {
        if (!_mapsEqual(
          Map<String, dynamic>.from(valueA),
          Map<String, dynamic>.from(valueB),
        )) {
          return false;
        }
      } else if (valueA is List && valueB is List) {
        if (!_listsEqual(valueA, valueB)) return false;
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }

  /// Deep compare two lists
  static bool _listsEqual(List a, List b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] is Map && b[i] is Map) {
        if (!_mapsEqual(
          Map<String, dynamic>.from(a[i]),
          Map<String, dynamic>.from(b[i]),
        )) {
          return false;
        }
      } else if (a[i] is List && b[i] is List) {
        if (!_listsEqual(a[i], b[i])) return false;
      } else if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }
}
