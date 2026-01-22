import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Backup data source for handling all backup operations
/// This includes Firebase Firestore for metadata and Firebase Storage for files
class BackupDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GetStorage _storageBox = GetStorage();
  final Uuid _uuid = const Uuid();

  // Collection names
  static const String _backupsCollection = 'backups';
  static const String _backupProgressCollection = 'backup_progress';

  /// Stream for monitoring backup progress
  Stream<BackupProgress> getBackupProgressStream(String userId, String backupId) {
    return _firestore
        .collection(_backupProgressCollection)
        .doc(backupId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return BackupProgress.fromMap(snapshot.data()!);
      }
      return BackupProgress(backupId: backupId, status: BackupStatus.pending);
    });
  }

  /// Get all backups for a user
  Future<List<BackupMetadata>> getUserBackups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BackupMetadata.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log('Error getting user backups: $e');
      return [];
    }
  }

  /// Create a new backup metadata record
  Future<BackupMetadata> createBackup({
    required String userId,
    required BackupType type,
    String? name,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final backupId = _uuid.v4();
      final metadata = BackupMetadata.create(
        backupId: backupId,
        userId: userId,
        type: type,
        name: name,
        description: description,
        additionalData: additionalData,
      );

      await _firestore
          .collection(_backupsCollection)
          .doc(backupId)
          .set(metadata.toMap());

      // Create initial progress record
      await _createProgressRecord(
        backupId: backupId,
        type: type,
        totalItems: 0,
      );

      log('✅ Backup metadata created: ${metadata.name}');
      return metadata;
    } catch (e) {
      log('❌ Error creating backup: $e');
      rethrow;
    }
  }

  /// Update backup metadata
  Future<void> updateBackupMetadata(BackupMetadata metadata) async {
    try {
      await _firestore
          .collection(_backupsCollection)
          .doc(metadata.backupId)
          .update({
        ...metadata.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      log('❌ Error updating backup metadata: $e');
      rethrow;
    }
  }

  /// Update backup progress
  Future<void> updateBackupProgress(BackupProgress progress) async {
    try {
      await _firestore
          .collection(_backupProgressCollection)
          .doc(progress.backupId)
          .set(progress.toMap());
    } catch (e) {
      log('❌ Error updating backup progress: $e');
      rethrow;
    }
  }

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required String backupId,
    required String fileName,
    required File file,
    required String folder,
    Function(double)? onProgress,
  }) async {
    try {
      final storageRef = _storage.ref().child('$folder/$backupId/$fileName');
      final uploadTask = storageRef.putFile(file);

      // Monitor upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log('✅ File uploaded successfully: $fileName');
      return downloadUrl;
    } catch (e) {
      log('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload multiple files in batch
  Future<List<String>> uploadMultipleFiles({
    required String backupId,
    required List<File> files,
    required String folder,
    Function(double)? onProgress,
  }) async {
    final uploadUrls = <String>[];
    final totalFiles = files.length;

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final url = await uploadFile(
          backupId: backupId,
          fileName: fileName,
          file: file,
          folder: folder,
        );
        uploadUrls.add(url);

        // Update progress
        if (onProgress != null) {
          onProgress((i + 1) / totalFiles);
        }
      } catch (e) {
        log('❌ Error uploading file ${files[i].path}: $e');
        // Continue with other files
      }
    }

    return uploadUrls;
  }

  /// Upload JSON data as file
  Future<String> uploadJsonData({
    required String backupId,
    required String fileName,
    required Map<String, dynamic> data,
    required String folder,
  }) async {
    try {
      final jsonString = json.encode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      return await uploadFile(
        backupId: backupId,
        fileName: fileName,
        file: file,
        folder: folder,
      );
    } catch (e) {
      log('❌ Error uploading JSON data: $e');
      rethrow;
    }
  }

  /// Download backup file from Firebase Storage
  Future<File> downloadBackupFile({
    required String backupId,
    required String fileName,
    required String folder,
  }) async {
    try {
      final storageRef = _storage.ref().child('$folder/$backupId/$fileName');
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/$fileName');

      await storageRef.writeToFile(localFile);
      return localFile;
    } catch (e) {
      log('❌ Error downloading backup file: $e');
      rethrow;
    }
  }

  /// Get backup files list from Firebase Storage
  Future<List<String>> getBackupFiles({
    required String backupId,
    required String folder,
  }) async {
    try {
      final storageRef = _storage.ref().child('$folder/$backupId');
      final result = await storageRef.listAll();

      return result.items.map((item) => item.name).toList();
    } catch (e) {
      log('❌ Error getting backup files: $e');
      return [];
    }
  }

  /// Delete backup completely (metadata + files)
  Future<void> deleteBackup(String backupId) async {
    try {
      // Delete metadata
      await _firestore.collection(_backupsCollection).doc(backupId).delete();

      // Delete progress
      await _firestore.collection(_backupProgressCollection).doc(backupId).delete();

      // Delete files from storage
      await _deleteBackupFiles(backupId);

      log('✅ Backup deleted successfully: $backupId');
    } catch (e) {
      log('❌ Error deleting backup: $e');
      rethrow;
    }
  }

  /// Delete backup files from Firebase Storage
  Future<void> _deleteBackupFiles(String backupId) async {
    try {
      const folders = ['images', 'contacts', 'device_info', 'settings'];

      for (final folder in folders) {
        final storageRef = _storage.ref().child('$folder/$backupId');
        final result = await storageRef.listAll();

        for (final item in result.items) {
          await item.delete();
        }

        // Delete empty folder
        try {
          await storageRef.delete();
        } catch (e) {
          // Folder might not be empty or doesn't exist, ignore
        }
      }
    } catch (e) {
      log('❌ Error deleting backup files: $e');
    }
  }

  /// Update user device information
  Future<void> updateUserDeviceInfo({
    required String userId,
    required List<String> deviceImages,
    required List<Contact> contacts,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(userId).update({
        'deviceImages': deviceImages,
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'deviceInfo': deviceInfo,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      log('✅ User device info updated successfully');
    } catch (e) {
      log('❌ Error updating user device info: $e');
      rethrow;
    }
  }

  /// Get backup statistics for a user
  Future<Map<String, dynamic>> getBackupStatistics(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final backups = querySnapshot.docs
          .map((doc) => BackupMetadata.fromMap(doc.data()))
          .toList();

      final totalBackups = backups.length;
      final totalSize = backups.fold<int>(0, (sum, backup) => sum + (backup.totalSize ?? 0));
      final completedBackups = backups.where((b) => b.createdAt != null).length;

      final typeStats = <String, int>{};
      for (final backup in backups) {
        final type = backup.type?.name ?? 'unknown';
        typeStats[type] = (typeStats[type] ?? 0) + 1;
      }

      return {
        'totalBackups': totalBackups,
        'completedBackups': completedBackups,
        'totalSize': totalSize,
        'typeStats': typeStats,
        'lastBackup': backups.isNotEmpty ? backups.first.createdAt : null,
      };
    } catch (e) {
      log('❌ Error getting backup statistics: $e');
      return {};
    }
  }

  /// Create initial progress record
  Future<void> _createProgressRecord({
    required String backupId,
    required BackupType type,
    int? totalItems,
  }) async {
    final progress = BackupProgress.initial(
      backupId: backupId,
      type: type,
      totalItems: totalItems,
    );

    await _firestore
        .collection(_backupProgressCollection)
        .doc(backupId)
        .set(progress.toMap());
  }

  /// Cache backup preferences locally
  Future<void> cacheBackupPreferences({
    required bool autoBackup,
    required BackupType backupType,
    required int maxBackups,
    required bool includeImages,
    required bool includeContacts,
    required bool includeDeviceInfo,
  }) async {
    await _storageBox.write('backup_preferences', {
      'autoBackup': autoBackup,
      'backupType': backupType.name,
      'maxBackups': maxBackups,
      'includeImages': includeImages,
      'includeContacts': includeContacts,
      'includeDeviceInfo': includeDeviceInfo,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get cached backup preferences
  Map<String, dynamic>? getCachedBackupPreferences() {
    return _storageBox.read('backup_preferences');
  }

  /// Clear all backup data for a user (for logout/reset)
  Future<void> clearUserBackupData(String userId) async {
    try {
      // Get all user backups
      final querySnapshot = await _firestore
          .collection(_backupsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final backupIds = querySnapshot.docs.map((doc) => doc.id).toList();

      // Delete each backup
      for (final backupId in backupIds) {
        await deleteBackup(backupId);
      }

      // Clear local cache
      await _storageBox.remove('backup_preferences');

      log('✅ User backup data cleared successfully');
    } catch (e) {
      log('❌ Error clearing user backup data: $e');
      rethrow;
    }
  }

  /// Validate backup integrity
  Future<bool> validateBackupIntegrity(String backupId) async {
    try {
      final backupDoc = await _firestore.collection(_backupsCollection).doc(backupId).get();
      if (!backupDoc.exists) return false;

      final metadata = BackupMetadata.fromMap(backupDoc.data()!);

      // Check if files exist in storage
      const folders = ['images', 'contacts', 'device_info', 'settings'];
      for (final folder in folders) {
        if (metadata.additionalData?[folder] != null) {
          final files = await getBackupFiles(backupId: backupId, folder: folder);
          if (files.isEmpty) return false;
        }
      }

      return true;
    } catch (e) {
      log('❌ Error validating backup integrity: $e');
      return false;
    }
  }
}
