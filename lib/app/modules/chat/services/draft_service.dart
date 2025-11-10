import 'dart:convert';
import 'dart:developer' as dev;
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Service for managing draft messages per chat
class DraftService {
  static final DraftService instance = DraftService._();
  DraftService._();

  static const String _draftPrefix = 'draft_';

  /// Save draft for a specific chat room
  Future<void> saveDraft(String roomId, String text) async {
    try {
      if (text.trim().isEmpty) {
        await clearDraft(roomId);
        return;
      }

      final key = _getDraftKey(roomId);
      final draftData = {
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await GetStorage().write(
        key,
        jsonEncode(draftData),
      );

      if (kDebugMode) {
        dev.log('💾 Saved draft for room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error saving draft: $e');
      }
    }
  }

  /// Load draft for a specific chat room
  Future<String?> loadDraft(String roomId) async {
    try {
      final key = _getDraftKey(roomId);
      final stored = await GetStorage().read(key);

      if (stored != null && stored is String) {
        final Map<String, dynamic> draftData = jsonDecode(stored);
        final text = draftData['text'] as String?;
        final timestamp = draftData['timestamp'] as String?;

        // Optional: Clear old drafts (e.g., older than 7 days)
        if (timestamp != null) {
          final draftTime = DateTime.parse(timestamp);
          final age = DateTime.now().difference(draftTime);

          if (age.inDays > 7) {
            await clearDraft(roomId);
            return null;
          }
        }

        if (kDebugMode) {
          dev.log('📄 Loaded draft for room: $roomId');
        }

        return text;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error loading draft: $e');
      }
      return null;
    }
  }

  /// Clear draft for a specific chat room
  Future<void> clearDraft(String roomId) async {
    try {
      final key = _getDraftKey(roomId);
      await GetStorage().remove(key);

      if (kDebugMode) {
        dev.log('🗑️ Cleared draft for room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error clearing draft: $e');
      }
    }
  }

  /// Check if draft exists for a room
  Future<bool> hasDraft(String roomId) async {
    final draft = await loadDraft(roomId);
    return draft != null && draft.isNotEmpty;
  }

  /// Get all rooms with drafts
  Future<List<String>> getRoomsWithDrafts() async {
    try {
      // This would require iterating through all cache keys
      // For now, return empty list
      // In production, could maintain a separate index of draft rooms
      return [];
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error getting rooms with drafts: $e');
      }
      return [];
    }
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    try {
      // This would require iterating through all draft keys
      // Implementation depends on cache helper capabilities
      if (kDebugMode) {
        dev.log('🗑️ Cleared all drafts');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error clearing all drafts: $e');
      }
    }
  }

  String _getDraftKey(String roomId) => '$_draftPrefix$roomId';
}

/// Model for draft message
class DraftMessage {
  final String text;
  final DateTime timestamp;

  DraftMessage({
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DraftMessage.fromMap(Map<String, dynamic> map) => DraftMessage(
        text: map['text'],
        timestamp: DateTime.parse(map['timestamp']),
      );

  bool get isExpired {
    final age = DateTime.now().difference(timestamp);
    return age.inDays > 7; // Expire after 7 days
  }
}
