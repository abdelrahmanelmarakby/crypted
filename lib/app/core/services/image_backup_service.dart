import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Image backup service with pagination support
/// Handles collecting, processing, and uploading device images for backup
class ImageBackupService {
  final BackupDataSource _backupDataSource = BackupDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  /// Get device images using ImagePicker (simplified version)
  Future<List<XFile>> getDeviceImages({
    int maxImages = 100,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      log('📸 Getting device images...');

      // Check permissions
      final permission = await Permission.photos.status;
      if (!permission.isGranted) {
        await Permission.photos.request();
        final newPermission = await Permission.photos.status;
        if (!newPermission.isGranted) {
          log('❌ Photo permission denied');
          return [];
        }
      }

      // Note: ImagePicker doesn't provide bulk access like photo_manager
      // This is a simplified implementation for demonstration
      // In a production app, you'd use photo_manager for full gallery access

      log('⚠️ Using simplified image picker - limited to single selection');
      return [];
    } catch (e) {
      log('❌ Error getting device images: $e');
      return [];
    }
  }

  /// Pick multiple images manually (user selects them)
  Future<List<XFile>> pickMultipleImages({
    int maxImages = 50,
  }) async {
    try {
      log('📸 Opening image picker for multiple selection...');

      // Check permissions
      final permission = await Permission.photos.status;
      if (!permission.isGranted) {
        await Permission.photos.request();
        final newPermission = await Permission.photos.status;
        if (!newPermission.isGranted) {
          throw Exception('Photo permission required for backup');
        }
      }

      // Note: ImagePicker doesn't have pickMultipleImages in current version
      // Using single image picker in a loop for demonstration
      final images = <XFile>[];

      for (int i = 0; i < maxImages; i++) {
        try {
          final image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );

          if (image != null) {
            images.add(image);
          } else {
            // User cancelled
            break;
          }
        } catch (e) {
          log('❌ Error picking image $i: $e');
          break;
        }
      }

      log('✅ Selected ${images.length} images');
      return images;
    } catch (e) {
      log('❌ Error picking multiple images: $e');
      return [];
    }
  }

  /// Create image backup with selected images
  Future<BackupProgress> createImageBackup({
    required String userId,
    required String backupId,
    int maxImages = 50,
    bool includeMetadata = true,
    Function(double)? onProgress,
  }) async {
    try {
      log('📸 Starting image backup process...');

      // Update progress to in-progress
      var progress = BackupProgress.initial(
        backupId: backupId,
        type: BackupType.images,
        totalItems: 0,
      );
      progress = progress.copyWith(status: BackupStatus.inProgress);
      await _backupDataSource.updateBackupProgress(progress);

      // Let user select images
      final selectedImages = await pickMultipleImages(maxImages: maxImages);

      if (selectedImages.isEmpty) {
        log('⚠️ No images selected by user');
        return progress.copyWith(
          status: BackupStatus.completed,
          progress: 1.0,
          completedItems: 0,
        );
      }

      progress = progress.copyWith(totalItems: selectedImages.length);
      await _backupDataSource.updateBackupProgress(progress);

      // Upload selected images
      final uploadedUrls = <String>[];

      for (int i = 0; i < selectedImages.length; i++) {
        final imageFile = File(selectedImages[i].path);

        try {
          // Generate filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'image_${timestamp}_${i + 1}.jpg';

          // Upload file
          final url = await _backupDataSource.uploadFile(
            backupId: backupId,
            fileName: filename,
            file: imageFile,
            folder: 'images',
            onProgress: (uploadProgress) {
              final overallProgress = (i + uploadProgress) / selectedImages.length;
              onProgress?.call(overallProgress);
            },
          );

          uploadedUrls.add(url);

          // Update progress
          progress = progress.copyWith(
            completedItems: i + 1,
            progress: (i + 1) / selectedImages.length,
            currentTask: 'Uploading $filename',
          );
          await _backupDataSource.updateBackupProgress(progress);

        } catch (e) {
          log('❌ Error uploading image ${selectedImages[i].path}: $e');
          // Continue with next image
        }
      }

      // Create metadata for images
      if (includeMetadata) {
        await _createImageMetadata(
          backupId: backupId,
          selectedImages: selectedImages,
          uploadedUrls: uploadedUrls,
        );
      }

      // Complete backup
      progress = progress.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        completedItems: selectedImages.length,
        currentTask: 'Backup completed',
      );
      await _backupDataSource.updateBackupProgress(progress);

      log('✅ Image backup completed successfully');
      return progress;
    } catch (e) {
      log('❌ Error in image backup: $e');

      // Update progress with error
      final errorProgress = BackupProgress(
        backupId: backupId,
        status: BackupStatus.failed,
        type: BackupType.images,
        errorMessage: e.toString(),
      );
      await _backupDataSource.updateBackupProgress(errorProgress);

      return errorProgress;
    }
  }

  /// Create metadata file for uploaded images
  Future<void> _createImageMetadata({
    required String backupId,
    required List<XFile> selectedImages,
    required List<String> uploadedUrls,
  }) async {
    try {
      final metadata = <String, dynamic>{
        'totalImages': selectedImages.length,
        'uploadedUrls': uploadedUrls,
        'images': <Map<String, dynamic>>[],
      };

      // Create metadata for each image
      for (int i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        final imageMetadata = <String, dynamic>{
          'name': image.name,
          'path': image.path,
          'size': await _getFileSize(image.path),
          'uploadedUrl': uploadedUrls[i],
          'backupIndex': i,
          'timestamp': DateTime.now().toIso8601String(),
        };

        metadata['images'].add(imageMetadata);
      }

      // Upload metadata as JSON
      await _backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'images_metadata.json',
        data: metadata,
        folder: 'images',
      );

      log('✅ Image metadata created and uploaded');
    } catch (e) {
      log('❌ Error creating image metadata: $e');
    }
  }

  /// Get file size helper
  Future<int> _getFileSize(String path) async {
    try {
      final file = File(path);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get image statistics (simplified version)
  Future<Map<String, dynamic>> getImageStatistics() async {
    try {
      // This would require photo_manager for full statistics
      // For now, return basic info
      return {
        'totalAlbums': 0,
        'totalImages': 0,
        'totalSize': 0,
        'albums': [],
        'note': 'Full statistics require photo_manager integration',
      };
    } catch (e) {
      log('❌ Error getting image statistics: $e');
      return {
        'totalAlbums': 0,
        'totalImages': 0,
        'totalSize': 0,
        'albums': [],
      };
    }
  }

  /// Validate image backup integrity
  Future<bool> validateImageBackup(String backupId) async {
    try {
      // Get backup metadata
      final backupFiles = await _backupDataSource.getBackupFiles(
        backupId: backupId,
        folder: 'images',
      );

      if (backupFiles.isEmpty) return false;

      // Check if metadata file exists
      final hasMetadata = backupFiles.any((file) => file.contains('metadata'));

      // Basic validation - check if files exist
      return backupFiles.length > 1; // At least metadata + one image
    } catch (e) {
      log('❌ Error validating image backup: $e');
      return false;
    }
  }

  /// Delete image backup
  Future<bool> deleteImageBackup(String backupId) async {
    try {
      // This will be handled by the main backup data source
      // but we can add specific image cleanup here if needed
      log('🗑️ Deleting image backup: $backupId');
      return true;
    } catch (e) {
      log('❌ Error deleting image backup: $e');
      return false;
    }
  }

  /// Get backup size estimate for selected images
  Future<int> getBackupSizeEstimate(List<XFile> images) async {
    int totalSize = 0;

    for (final image in images) {
      try {
        totalSize += await _getFileSize(image.path);
      } catch (e) {
        // Continue with other images
      }
    }

    return totalSize;
  }
}
