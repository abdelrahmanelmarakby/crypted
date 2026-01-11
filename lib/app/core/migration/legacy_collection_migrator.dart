import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:flutter/foundation.dart';

/// ARCH-011: Legacy Collection Migration Helper
/// Helps migrate from legacy 'Chats' collection to new 'chats' collection
/// and provides utilities for removing legacy collection support
class LegacyCollectionMigrator {
  static final LegacyCollectionMigrator instance = LegacyCollectionMigrator._();
  LegacyCollectionMigrator._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = LoggerService.instance;

  // Collection names
  static const String legacyCollection = 'Chats';
  static const String currentCollection = 'chats';

  /// Check if there are any documents in the legacy collection
  Future<bool> hasLegacyData() async {
    try {
      final snapshot = await _firestore
          .collection(legacyCollection)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.warning('Error checking legacy data', context: 'Migration', data: {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Get count of documents in legacy collection
  Future<int> getLegacyDocumentCount() async {
    try {
      final snapshot = await _firestore.collection(legacyCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Migrate all data from legacy collection to current collection
  Future<MigrationResult> migrateAllData({
    Function(int, int)? onProgress,
  }) async {
    _logger.info('Starting legacy data migration', context: 'Migration');

    try {
      final legacyDocs = await _firestore.collection(legacyCollection).get();
      final totalDocs = legacyDocs.docs.length;

      if (totalDocs == 0) {
        return MigrationResult(
          success: true,
          migratedCount: 0,
          failedCount: 0,
          message: 'No legacy data to migrate',
        );
      }

      int migratedCount = 0;
      int failedCount = 0;
      List<String> failedRoomIds = [];

      for (int i = 0; i < legacyDocs.docs.length; i++) {
        final doc = legacyDocs.docs[i];
        try {
          await _migrateRoom(doc.id);
          migratedCount++;
        } catch (e) {
          failedCount++;
          failedRoomIds.add(doc.id);
          _logger.logError('Failed to migrate room', error: e, context: 'Migration', data: {
            'roomId': doc.id,
          });
        }

        onProgress?.call(i + 1, totalDocs);
      }

      return MigrationResult(
        success: failedCount == 0,
        migratedCount: migratedCount,
        failedCount: failedCount,
        failedRoomIds: failedRoomIds,
        message: 'Migrated $migratedCount/$totalDocs rooms',
      );
    } catch (e) {
      _logger.logError('Migration failed', error: e, context: 'Migration');
      return MigrationResult(
        success: false,
        migratedCount: 0,
        failedCount: 0,
        message: 'Migration failed: $e',
      );
    }
  }

  /// Migrate a single room from legacy to current collection
  Future<void> _migrateRoom(String roomId) async {
    final legacyRoomRef = _firestore.collection(legacyCollection).doc(roomId);
    final currentRoomRef = _firestore.collection(currentCollection).doc(roomId);

    // Check if already exists in current collection
    final currentDoc = await currentRoomRef.get();
    if (currentDoc.exists) {
      _logger.debug('Room already exists in current collection', context: 'Migration', data: {
        'roomId': roomId,
      });
      return;
    }

    // Get legacy room data
    final legacyDoc = await legacyRoomRef.get();
    if (!legacyDoc.exists) return;

    final roomData = legacyDoc.data()!;

    // Migrate room document
    await currentRoomRef.set(roomData);

    // Migrate messages subcollection
    final legacyMessages = await legacyRoomRef.collection('chat').get();

    final batch = _firestore.batch();
    for (final messageDoc in legacyMessages.docs) {
      final newMessageRef = currentRoomRef.collection('chat').doc(messageDoc.id);
      batch.set(newMessageRef, messageDoc.data());
    }

    await batch.commit();

    _logger.debug('Room migrated successfully', context: 'Migration', data: {
      'roomId': roomId,
      'messageCount': legacyMessages.docs.length,
    });
  }

  /// Delete all legacy data (use after confirming migration success)
  Future<bool> deleteLegacyData({
    bool dryRun = true,
    Function(int, int)? onProgress,
  }) async {
    if (dryRun) {
      _logger.info('Dry run: would delete legacy data', context: 'Migration');
      final count = await getLegacyDocumentCount();
      return count >= 0;
    }

    try {
      final legacyDocs = await _firestore.collection(legacyCollection).get();
      final totalDocs = legacyDocs.docs.length;

      for (int i = 0; i < legacyDocs.docs.length; i++) {
        final doc = legacyDocs.docs[i];

        // Delete messages subcollection first
        final messages = await _firestore
            .collection(legacyCollection)
            .doc(doc.id)
            .collection('chat')
            .get();

        for (final messageDoc in messages.docs) {
          await messageDoc.reference.delete();
        }

        // Delete room document
        await doc.reference.delete();

        onProgress?.call(i + 1, totalDocs);
      }

      _logger.info('Legacy data deleted', context: 'Migration', data: {
        'count': totalDocs,
      });

      return true;
    } catch (e) {
      _logger.logError('Failed to delete legacy data', error: e, context: 'Migration');
      return false;
    }
  }

  /// Verify migration integrity
  Future<VerificationResult> verifyMigration() async {
    try {
      final legacyDocs = await _firestore.collection(legacyCollection).get();
      final currentDocs = await _firestore.collection(currentCollection).get();

      final legacyIds = legacyDocs.docs.map((d) => d.id).toSet();
      final currentIds = currentDocs.docs.map((d) => d.id).toSet();

      final missingInCurrent = legacyIds.difference(currentIds);
      final onlyInCurrent = currentIds.difference(legacyIds);

      return VerificationResult(
        legacyCount: legacyDocs.docs.length,
        currentCount: currentDocs.docs.length,
        missingInCurrent: missingInCurrent.toList(),
        onlyInCurrent: onlyInCurrent.toList(),
        isComplete: missingInCurrent.isEmpty,
      );
    } catch (e) {
      return VerificationResult(
        legacyCount: 0,
        currentCount: 0,
        missingInCurrent: [],
        onlyInCurrent: [],
        isComplete: false,
        error: e.toString(),
      );
    }
  }
}

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final int migratedCount;
  final int failedCount;
  final List<String> failedRoomIds;
  final String message;

  MigrationResult({
    required this.success,
    required this.migratedCount,
    required this.failedCount,
    this.failedRoomIds = const [],
    required this.message,
  });
}

/// Result of verification operation
class VerificationResult {
  final int legacyCount;
  final int currentCount;
  final List<String> missingInCurrent;
  final List<String> onlyInCurrent;
  final bool isComplete;
  final String? error;

  VerificationResult({
    required this.legacyCount,
    required this.currentCount,
    required this.missingInCurrent,
    required this.onlyInCurrent,
    required this.isComplete,
    this.error,
  });

  @override
  String toString() {
    return 'VerificationResult(legacy: $legacyCount, current: $currentCount, '
        'missing: ${missingInCurrent.length}, complete: $isComplete)';
  }
}

/// Unified collection accessor that handles both legacy and current collections
/// ARCH-011: This provides backward compatibility during migration
class UnifiedChatCollection {
  static final UnifiedChatCollection instance = UnifiedChatCollection._();
  UnifiedChatCollection._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the correct collection reference for a room
  /// Checks current collection first, falls back to legacy if not found
  Future<CollectionReference<Map<String, dynamic>>> getMessagesCollection(
    String roomId,
  ) async {
    // Check current collection first
    final currentRoom = await _firestore
        .collection(LegacyCollectionMigrator.currentCollection)
        .doc(roomId)
        .get();

    if (currentRoom.exists) {
      return _firestore
          .collection(LegacyCollectionMigrator.currentCollection)
          .doc(roomId)
          .collection('chat');
    }

    // Fall back to legacy collection
    return _firestore
        .collection(LegacyCollectionMigrator.legacyCollection)
        .doc(roomId)
        .collection('chat');
  }

  /// Get chat room document reference
  Future<DocumentReference<Map<String, dynamic>>> getRoomReference(
    String roomId,
  ) async {
    final currentRoom = await _firestore
        .collection(LegacyCollectionMigrator.currentCollection)
        .doc(roomId)
        .get();

    if (currentRoom.exists) {
      return _firestore
          .collection(LegacyCollectionMigrator.currentCollection)
          .doc(roomId);
    }

    return _firestore
        .collection(LegacyCollectionMigrator.legacyCollection)
        .doc(roomId);
  }

  /// Always use the current collection for new rooms
  CollectionReference<Map<String, dynamic>> get currentCollection {
    return _firestore.collection(LegacyCollectionMigrator.currentCollection);
  }
}
