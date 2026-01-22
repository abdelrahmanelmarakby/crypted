import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// Service for managing optimistic updates in the chat UI
///
/// Optimistic updates show the user immediate feedback while the actual
/// operation is in progress. This service:
/// 1. Adds local messages with temp IDs
/// 2. Tracks pending message mappings (tempId -> actualId)
/// 3. Handles rollback on failure
/// 4. Merges local state with Firestore stream
class OptimisticUpdateService {
  /// The reactive message list (shared with UI)
  final RxList<Message> messages;

  /// Maps temp IDs to actual Firestore IDs
  /// When Firestore stream delivers a message, we can identify if it's
  /// one we sent (and avoid duplicates)
  final Map<String, String> _pendingIdMap = {};

  /// Tracks original state for rollback
  final Map<String, Message> _originalMessages = {};

  /// Tracks upload IDs to message IDs
  final Map<String, String> _pendingUploads = {};

  OptimisticUpdateService({required this.messages});

  // =================== Add/Remove Local Messages ===================

  /// Add a message optimistically (shows immediately in UI)
  void addLocalMessage(Message message) {
    // Insert at the beginning (newest first)
    messages.insert(0, message);
    messages.refresh();

    if (kDebugMode) {
      print('🎯 Added optimistic message: ${message.id}');
    }
  }

  /// Remove a local message (used for rollback)
  void removeLocalMessage(String messageId) {
    messages.removeWhere((m) => m.id == messageId);
    messages.refresh();

    if (kDebugMode) {
      print('🔄 Removed optimistic message: $messageId');
    }
  }

  // =================== ID Mapping ===================

  /// Register that a temp ID has been confirmed with an actual ID
  void registerConfirmed(String tempId, String actualId) {
    _pendingIdMap[tempId] = actualId;

    if (kDebugMode) {
      print('✅ Registered mapping: $tempId -> $actualId');
    }
  }

  /// Register a pending upload
  void registerPendingUpload(String uploadId, String actualMessageId) {
    _pendingUploads[uploadId] = actualMessageId;

    if (kDebugMode) {
      print('📤 Registered upload: $uploadId -> $actualMessageId');
    }
  }

  /// Get actual ID for a temp ID (if confirmed)
  String? getActualId(String tempId) => _pendingIdMap[tempId];

  /// Check if a message ID is pending
  bool isPending(String messageId) =>
      messageId.startsWith('pending_') || _pendingIdMap.containsKey(messageId);

  // =================== Stream Merging ===================

  /// Replace temp message with confirmed one from Firestore stream
  void replaceWithConfirmed(String tempId, Message confirmedMessage) {
    final index = messages.indexWhere((m) => m.id == tempId);
    if (index != -1) {
      messages[index] = confirmedMessage;
      messages.refresh();

      if (kDebugMode) {
        print('✅ Replaced optimistic with confirmed: $tempId -> ${confirmedMessage.id}');
      }
    }

    // Clean up mapping
    _pendingIdMap.remove(tempId);
  }

  /// Smart merge of local messages with Firestore stream
  ///
  /// This is the key method that prevents duplicates and maintains
  /// optimistic messages while syncing with the server.
  List<Message> mergeWithStream(List<Message> remoteMessages) {
    // 1. Keep pending local messages that haven't been confirmed yet
    final pendingLocal = messages
        .where((m) => m.id.startsWith('pending_'))
        .where((m) => !_pendingIdMap.containsKey(m.id))
        .toList();

    // 2. Keep uploading messages
    final uploading = messages
        .where((m) => m.runtimeType.toString().contains('Uploading'))
        .where((m) => !_pendingUploads.containsKey(m.id))
        .toList();

    // 3. Filter out duplicates from remote
    // (messages where the actual ID matches a pending mapping)
    final confirmedIds = _pendingIdMap.values.toSet();
    final uploadedIds = _pendingUploads.values.toSet();

    final filteredRemote = remoteMessages.where((m) {
      // Keep if not a confirmed pending message (we'll swap it)
      if (confirmedIds.contains(m.id)) {
        // Find and replace the pending message
        final tempId = _pendingIdMap.entries
            .firstWhere(
              (e) => e.value == m.id,
              orElse: () => const MapEntry('', ''),
            )
            .key;
        if (tempId.isNotEmpty) {
          replaceWithConfirmed(tempId, m);
          return false; // Don't add to filtered, we replaced it
        }
      }

      // Keep if not a confirmed upload
      if (uploadedIds.contains(m.id)) {
        final uploadId = _pendingUploads.entries
            .firstWhere(
              (e) => e.value == m.id,
              orElse: () => const MapEntry('', ''),
            )
            .key;
        if (uploadId.isNotEmpty) {
          // Remove the uploading message and add the real one
          messages.removeWhere((msg) => msg.id == uploadId);
          _pendingUploads.remove(uploadId);
        }
      }

      return true;
    }).toList();

    // 4. Merge all sources
    final merged = <Message>[
      ...uploading,
      ...pendingLocal,
      ...filteredRemote,
    ];

    // 5. Remove duplicates by ID (keep first occurrence)
    final seen = <String>{};
    final deduplicated = merged.where((m) {
      if (seen.contains(m.id)) return false;
      seen.add(m.id);
      return true;
    }).toList();

    // 6. Sort by timestamp (newest first)
    deduplicated.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return deduplicated;
  }

  // =================== Rollback ===================

  /// Rollback a failed message send
  void rollback(String tempId) {
    removeLocalMessage(tempId);
    _pendingIdMap.remove(tempId);

    if (kDebugMode) {
      print('🔄 Rolled back message: $tempId');
    }
  }

  /// Save original message state for potential rollback
  void saveForRollback(String messageId, Message originalMessage) {
    _originalMessages[messageId] = originalMessage;
  }

  /// Rollback an edit
  void rollbackEdit(String messageId) {
    final original = _originalMessages[messageId];
    if (original != null) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = original;
        messages.refresh();
      }
      _originalMessages.remove(messageId);
    }
  }

  // =================== State Updates ===================

  /// Update a message's text optimistically
  void updateMessageText(String messageId, String newText) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = messages[index];
      // Save original for rollback
      saveForRollback(messageId, message);

      // Update with new text
      try {
        final updated = message.copyWith(id: messageId);
        final map = updated.toMap();
        map['text'] = newText;
        map['isEdited'] = true;
        messages[index] = Message.fromMap(map);
        messages.refresh();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not update message text: $e');
        }
      }
    }
  }

  /// Update a message property optimistically
  void updateMessageProperty(
    String messageId,
    String property,
    dynamic value,
  ) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = messages[index];
      saveForRollback(messageId, message);

      try {
        final map = message.toMap();
        map[property] = value;
        messages[index] = Message.fromMap(map);
        messages.refresh();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not update message property: $e');
        }
      }
    }
  }

  // =================== Cleanup ===================

  /// Clear all pending state
  void clear() {
    _pendingIdMap.clear();
    _originalMessages.clear();
    _pendingUploads.clear();
  }

  /// Get statistics about pending operations
  Map<String, int> get stats => {
        'pendingMessages': _pendingIdMap.length,
        'pendingUploads': _pendingUploads.length,
        'savedForRollback': _originalMessages.length,
      };
}
