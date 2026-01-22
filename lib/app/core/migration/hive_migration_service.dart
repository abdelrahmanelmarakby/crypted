// Hive Migration Service
// Handles migration of data from Firestore to local Hive storage for existing users

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypted_app/app/core/services/local_database_service.dart';
import 'package:crypted_app/app/data/models/hive/hive_models.dart';

/// Migration progress callback
typedef MigrationProgressCallback = void Function(
  double progress,
  String message,
);

/// Migration result
class HiveMigrationResult {
  final bool success;
  final int migratedRooms;
  final int migratedMessages;
  final List<String> errors;
  final Duration duration;

  HiveMigrationResult({
    required this.success,
    this.migratedRooms = 0,
    this.migratedMessages = 0,
    this.errors = const [],
    this.duration = Duration.zero,
  });

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    return 'HiveMigrationResult(success: $success, rooms: $migratedRooms, messages: $migratedMessages, errors: ${errors.length})';
  }
}

/// HiveMigrationService - Migrates existing Firestore data to Hive
class HiveMigrationService {
  static const String _migrationVersionKey = 'hive_migration_version';
  static const int _currentMigrationVersion = 1;

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getInt(_migrationVersionKey) ?? 0;

    // Check if local database is empty (new install doesn't need migration)
    final stats = _localDb.getStats();
    final isEmpty = stats['chatRooms'] == 0 && stats['messages'] == 0;

    // Migration needed if:
    // 1. Version is outdated AND
    // 2. We have a logged-in user (existing user)
    final hasUser = FirebaseAuth.instance.currentUser != null;

    if (kDebugMode) {
      print('[HiveMigrationService] Last version: $lastVersion, current: $_currentMigrationVersion');
      print('[HiveMigrationService] Is empty: $isEmpty, has user: $hasUser');
    }

    return lastVersion < _currentMigrationVersion && hasUser && isEmpty;
  }

  /// Run the migration
  Future<HiveMigrationResult> runMigration({
    MigrationProgressCallback? onProgress,
    int messagesPerRoomLimit = 100,
  }) async {
    final stopwatch = Stopwatch()..start();
    final errors = <String>[];
    int migratedRooms = 0;
    int migratedMessages = 0;

    try {
      onProgress?.call(0.0, 'Starting migration...');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return HiveMigrationResult(
          success: false,
          errors: ['No user logged in'],
          duration: stopwatch.elapsed,
        );
      }

      // Step 1: Migrate chat rooms
      onProgress?.call(0.1, 'Fetching chat rooms...');

      final roomsSnapshot = await _firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: userId)
          .get();

      final totalRooms = roomsSnapshot.docs.length;

      if (kDebugMode) {
        print('[HiveMigrationService] Found $totalRooms rooms to migrate');
      }

      if (totalRooms == 0) {
        // No rooms to migrate
        await _markMigrationComplete();
        return HiveMigrationResult(
          success: true,
          migratedRooms: 0,
          migratedMessages: 0,
          duration: stopwatch.elapsed,
        );
      }

      // Step 2: Process each room
      for (var i = 0; i < totalRooms; i++) {
        final doc = roomsSnapshot.docs[i];
        final progress = 0.1 + (0.8 * (i / totalRooms));

        try {
          onProgress?.call(progress, 'Migrating room ${i + 1} of $totalRooms...');

          // Migrate room
          final roomData = doc.data();
          roomData['id'] = doc.id;

          final hiveRoom = HiveChatRoom.fromMap(roomData, isSynced: true);
          await _localDb.saveChatRoom(hiveRoom);
          migratedRooms++;

          // Migrate messages for this room
          final messagesSnapshot = await _firestore
              .collection(FirebaseCollections.chats)
              .doc(doc.id)
              .collection(FirebaseCollections.chatMessages)
              .orderBy('timestamp', descending: true)
              .limit(messagesPerRoomLimit)
              .get();

          final messages = <HiveMessage>[];
          for (final msgDoc in messagesSnapshot.docs) {
            try {
              final msgData = msgDoc.data();
              msgData['id'] = msgDoc.id;
              msgData['roomId'] = doc.id;

              final hiveMessage = HiveMessage.fromMap(msgData, isSynced: true);
              messages.add(hiveMessage);
            } catch (e) {
              errors.add('Error parsing message ${msgDoc.id}: $e');
            }
          }

          if (messages.isNotEmpty) {
            await _localDb.saveMessages(messages);
            migratedMessages += messages.length;
          }

          // Update sync metadata
          await _localDb.completeRoomSync(
            doc.id,
            lastMessageId: messages.isNotEmpty ? messages.first.id : null,
            lastMessageTimestamp: messages.isNotEmpty ? messages.first.timestamp : null,
          );
        } catch (e) {
          errors.add('Error migrating room ${doc.id}: $e');
          if (kDebugMode) {
            print('[HiveMigrationService] Error migrating room ${doc.id}: $e');
          }
        }
      }

      // Step 3: Mark migration complete
      onProgress?.call(0.95, 'Finalizing migration...');
      await _markMigrationComplete();

      stopwatch.stop();
      onProgress?.call(1.0, 'Migration complete!');

      if (kDebugMode) {
        print('[HiveMigrationService] Migration complete:');
        print('  Rooms: $migratedRooms');
        print('  Messages: $migratedMessages');
        print('  Errors: ${errors.length}');
        print('  Duration: ${stopwatch.elapsed.inSeconds}s');
      }

      return HiveMigrationResult(
        success: errors.isEmpty,
        migratedRooms: migratedRooms,
        migratedMessages: migratedMessages,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      errors.add('Migration failed: $e');

      if (kDebugMode) {
        print('[HiveMigrationService] Migration failed: $e');
      }

      return HiveMigrationResult(
        success: false,
        migratedRooms: migratedRooms,
        migratedMessages: migratedMessages,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Mark migration as complete
  Future<void> _markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);

    if (kDebugMode) {
      print('[HiveMigrationService] Migration marked complete (v$_currentMigrationVersion)');
    }
  }

  /// Reset migration status (useful for testing)
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationVersionKey);

    if (kDebugMode) {
      print('[HiveMigrationService] Migration status reset');
    }
  }

  /// Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_migrationVersionKey) ?? 0;
    final stats = _localDb.getStats();

    return {
      'currentVersion': _currentMigrationVersion,
      'lastMigratedVersion': version,
      'isUpToDate': version >= _currentMigrationVersion,
      'localStats': stats,
    };
  }

  /// Force re-migration (clears local data first)
  Future<HiveMigrationResult> forceMigration({
    MigrationProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.0, 'Clearing local data...');

    // Clear local data
    await _localDb.clearAll();

    // Reset migration status
    await resetMigration();

    // Run migration
    return runMigration(onProgress: onProgress);
  }
}
