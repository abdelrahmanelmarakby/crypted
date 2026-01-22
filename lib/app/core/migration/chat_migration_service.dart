// ARCH-011 FIX: Chat Migration Service
// Handles migration from legacy 'Chats' collection to 'chat_rooms' collection
// This service should be run once during app initialization for users with legacy data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to migrate chat data from legacy collection to new collection
class ChatMigrationService {
  static const String _migrationKey = 'chat_migration_v1_completed';
  static const String _legacyCollection = FirebaseCollections.chatsLegacyCapital;
  static const String _newCollection = FirebaseCollections.chats;

  final FirebaseFirestore _firestore;

  ChatMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool(_migrationKey) ?? false;

    if (migrationCompleted) {
      return false;
    }

    // Check if legacy collection has any documents
    try {
      final legacyDocs = await _firestore
          .collection(_legacyCollection)
          .limit(1)
          .get();
      return legacyDocs.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatMigration] Error checking legacy collection: $e');
      }
      return false;
    }
  }

  /// Run the migration process
  Future<MigrationResult> runMigration({
    String? userId,
    void Function(double progress, String message)? onProgress,
  }) async {
    final result = MigrationResult();

    try {
      onProgress?.call(0.0, 'Checking for legacy data...');

      // Get all legacy chat rooms for the user
      Query query = _firestore.collection(_legacyCollection);
      if (userId != null) {
        query = query.where('membersIds', arrayContains: userId);
      }

      final legacyRooms = await query.get();

      if (legacyRooms.docs.isEmpty) {
        onProgress?.call(1.0, 'No legacy data found.');
        await _markMigrationComplete();
        return result;
      }

      result.totalRooms = legacyRooms.docs.length;
      onProgress?.call(0.1, 'Found ${result.totalRooms} chat rooms to migrate...');

      // Process each chat room
      for (int i = 0; i < legacyRooms.docs.length; i++) {
        final legacyDoc = legacyRooms.docs[i];
        final roomId = legacyDoc.id;
        final progress = 0.1 + (0.8 * (i / legacyRooms.docs.length));

        onProgress?.call(progress, 'Migrating room ${i + 1}/${result.totalRooms}...');

        try {
          // Check if room already exists in new collection
          final existingRoom = await _firestore
              .collection(_newCollection)
              .doc(roomId)
              .get();

          if (!existingRoom.exists) {
            // Migrate room document
            await _migrateRoom(legacyDoc);
            result.migratedRooms++;
          } else {
            result.skippedRooms++;
          }

          // Migrate messages
          final messagesResult = await _migrateMessages(roomId);
          result.migratedMessages += messagesResult.migrated;
          result.skippedMessages += messagesResult.skipped;

        } catch (e) {
          result.errors.add('Room $roomId: $e');
          if (kDebugMode) {
            print('[ChatMigration] Error migrating room $roomId: $e');
          }
        }
      }

      onProgress?.call(0.95, 'Cleaning up legacy data...');

      // Optionally clean up legacy data after successful migration
      if (result.errors.isEmpty) {
        await _cleanupLegacyData(userId);
      }

      await _markMigrationComplete();
      onProgress?.call(1.0, 'Migration complete!');

    } catch (e) {
      result.errors.add('Migration failed: $e');
      if (kDebugMode) {
        print('[ChatMigration] Migration failed: $e');
      }
    }

    return result;
  }

  /// Migrate a single room document
  Future<void> _migrateRoom(DocumentSnapshot legacyDoc) async {
    final data = legacyDoc.data() as Map<String, dynamic>?;
    if (data == null) return;

    // Transform data if needed (field name changes, etc.)
    final migratedData = _transformRoomData(data);

    // Write to new collection
    await _firestore
        .collection(_newCollection)
        .doc(legacyDoc.id)
        .set(migratedData);
  }

  /// Transform room data from legacy format to new format
  Map<String, dynamic> _transformRoomData(Map<String, dynamic> data) {
    // Apply any transformations needed
    final transformed = Map<String, dynamic>.from(data);

    // Ensure required fields exist
    transformed['isGroupChat'] ??= false;
    transformed['createdAt'] ??= FieldValue.serverTimestamp();

    // Normalize field names
    if (transformed.containsKey('members') &&
        !transformed.containsKey('membersIds')) {
      // Extract member IDs from members list
      final members = transformed['members'] as List?;
      if (members != null) {
        transformed['membersIds'] = members
            .map((m) => m is Map ? m['uid'] : m?.toString())
            .where((id) => id != null)
            .toList();
      }
    }

    return transformed;
  }

  /// Migrate messages for a room
  Future<_MessageMigrationResult> _migrateMessages(String roomId) async {
    final result = _MessageMigrationResult();

    try {
      // Get legacy messages
      final legacyMessages = await _firestore
          .collection(_legacyCollection)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .get();

      if (legacyMessages.docs.isEmpty) {
        return result;
      }

      // Check which messages already exist
      final newMessagesRef = _firestore
          .collection(_newCollection)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages);

      // Batch write for efficiency
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const batchLimit = 400; // Firestore limit is 500

      for (final legacyMsg in legacyMessages.docs) {
        final existingMsg = await newMessagesRef.doc(legacyMsg.id).get();

        if (!existingMsg.exists) {
          final data = legacyMsg.data();
          batch.set(newMessagesRef.doc(legacyMsg.id), data);
          result.migrated++;
          batchCount++;

          // Commit batch if reaching limit
          if (batchCount >= batchLimit) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        } else {
          result.skipped++;
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

    } catch (e) {
      if (kDebugMode) {
        print('[ChatMigration] Error migrating messages for room $roomId: $e');
      }
    }

    return result;
  }

  /// Clean up legacy collection after successful migration
  Future<void> _cleanupLegacyData(String? userId) async {
    // Note: In production, you might want to keep legacy data for a period
    // or move to an archive collection instead of deleting

    if (kDebugMode) {
      print('[ChatMigration] Legacy data cleanup skipped (keeping for safety)');
    }

    // Uncomment to actually delete legacy data:
    // try {
    //   Query query = _firestore.collection(_legacyCollection);
    //   if (userId != null) {
    //     query = query.where('membersIds', arrayContains: userId);
    //   }
    //
    //   final docs = await query.get();
    //   for (final doc in docs.docs) {
    //     // Delete subcollections first
    //     final messages = await doc.reference.collection('chat').get();
    //     for (final msg in messages.docs) {
    //       await msg.reference.delete();
    //     }
    //     await doc.reference.delete();
    //   }
    // } catch (e) {
    //   print('[ChatMigration] Cleanup error: $e');
    // }
  }

  /// Mark migration as complete
  Future<void> _markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Reset migration status (for testing)
  Future<void> resetMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
  }
}

/// Result of message migration for a single room
class _MessageMigrationResult {
  int migrated = 0;
  int skipped = 0;
}

/// Result of the full migration process
class MigrationResult {
  int totalRooms = 0;
  int migratedRooms = 0;
  int skippedRooms = 0;
  int migratedMessages = 0;
  int skippedMessages = 0;
  List<String> errors = [];

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errors.isEmpty && totalRooms > 0;

  @override
  String toString() {
    return '''
MigrationResult:
  Total Rooms: $totalRooms
  Migrated Rooms: $migratedRooms
  Skipped Rooms: $skippedRooms
  Migrated Messages: $migratedMessages
  Skipped Messages: $skippedMessages
  Errors: ${errors.length}
''';
  }
}

/// Collection name constants for the chat module
/// Use these constants instead of hardcoded strings
class ChatCollections {
  /// The current/active chat rooms collection
  static const String rooms = FirebaseCollections.chats;

  /// Messages subcollection within a room
  static const String messages = FirebaseCollections.chatMessages;

  /// Legacy collection (deprecated, use rooms instead)
  @Deprecated('Use ChatCollections.rooms instead')
  static const String legacyRooms = FirebaseCollections.chatsLegacyCapital;

  /// Get chat room reference
  static DocumentReference roomRef(String roomId) {
    return FirebaseFirestore.instance.collection(rooms).doc(roomId);
  }

  /// Get messages collection reference
  static CollectionReference messagesRef(String roomId) {
    return roomRef(roomId).collection(messages);
  }
}
