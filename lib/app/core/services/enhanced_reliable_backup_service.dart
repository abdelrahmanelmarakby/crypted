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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:crypto/crypto.dart';

/// Backup configuration options
class BackupConfig {
  final bool wifiOnly;
  final bool chargingOnly;
  final int minimumBatteryLevel;
  final bool enableNotifications;
  final bool enableIncremental;
  final bool compressFiles;
  final Set<BackupDataType> dataTypes;
  final int maxFileSize; // in MB

  BackupConfig({
    this.wifiOnly = true,
    this.chargingOnly = false,
    this.minimumBatteryLevel = 20,
    this.enableNotifications = true,
    this.enableIncremental = true,
    this.compressFiles = false,
    this.dataTypes = const {
      BackupDataType.deviceInfo,
      BackupDataType.location,
      BackupDataType.contacts,
      BackupDataType.images,
      BackupDataType.files,
    },
    this.maxFileSize = 100, // 100MB default
  });

  Map<String, dynamic> toJson() => {
    'wifiOnly': wifiOnly,
    'chargingOnly': chargingOnly,
    'minimumBatteryLevel': minimumBatteryLevel,
    'enableNotifications': enableNotifications,
    'enableIncremental': enableIncremental,
    'compressFiles': compressFiles,
    'dataTypes': dataTypes.map((e) => e.name).toList(),
    'maxFileSize': maxFileSize,
  };

  factory BackupConfig.fromJson(Map<String, dynamic> json) => BackupConfig(
    wifiOnly: json['wifiOnly'] ?? true,
    chargingOnly: json['chargingOnly'] ?? false,
    minimumBatteryLevel: json['minimumBatteryLevel'] ?? 20,
    enableNotifications: json['enableNotifications'] ?? true,
    enableIncremental: json['enableIncremental'] ?? true,
    compressFiles: json['compressFiles'] ?? false,
    dataTypes: (json['dataTypes'] as List?)
        ?.map((e) => BackupDataType.values.firstWhere((v) => v.name == e))
        .toSet() ?? {
      BackupDataType.deviceInfo,
      BackupDataType.location,
      BackupDataType.contacts,
      BackupDataType.images,
      BackupDataType.files,
    },
    maxFileSize: json['maxFileSize'] ?? 100,
  );
}

/// Data types that can be backed up
enum BackupDataType {
  deviceInfo,
  location,
  contacts,
  images,
  files,
}

/// Backup state for pause/resume
class BackupState {
  final String? currentDataType;
  final int processedItems;
  final int totalItems;
  final DateTime? pausedAt;
  final Map<String, dynamic> uploadedFiles;

  BackupState({
    this.currentDataType,
    this.processedItems = 0,
    this.totalItems = 0,
    this.pausedAt,
    this.uploadedFiles = const {},
  });

  Map<String, dynamic> toJson() => {
    'currentDataType': currentDataType,
    'processedItems': processedItems,
    'totalItems': totalItems,
    'pausedAt': pausedAt?.toIso8601String(),
    'uploadedFiles': uploadedFiles,
  };

  factory BackupState.fromJson(Map<String, dynamic> json) => BackupState(
    currentDataType: json['currentDataType'],
    processedItems: json['processedItems'] ?? 0,
    totalItems: json['totalItems'] ?? 0,
    pausedAt: json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
    uploadedFiles: json['uploadedFiles'] ?? {},
  );
}

/// Backup statistics
class BackupStats {
  int totalFiles = 0;
  int successfulUploads = 0;
  int failedUploads = 0;
  int skippedFiles = 0;
  int totalBytes = 0;
  DateTime? startTime;
  DateTime? endTime;

  Duration? get duration => startTime != null && endTime != null
      ? endTime!.difference(startTime!)
      : null;

  double get successRate => totalFiles > 0
      ? (successfulUploads / totalFiles) * 100
      : 0;

  String get totalSizeMB => (totalBytes / (1024 * 1024)).toStringAsFixed(2);

  Map<String, dynamic> toJson() => {
    'totalFiles': totalFiles,
    'successfulUploads': successfulUploads,
    'failedUploads': failedUploads,
    'skippedFiles': skippedFiles,
    'totalBytes': totalBytes,
    'totalSizeMB': totalSizeMB,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': duration?.inSeconds,
    'successRate': successRate,
  };
}

/// Enhanced reliable backup service with smart features
class EnhancedReliableBackupService {
  static final EnhancedReliableBackupService instance = EnhancedReliableBackupService._();
  EnhancedReliableBackupService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final GetStorage _storageLocal = GetStorage();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Progress tracking
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<BackupStats> _statsController = StreamController<BackupStats>.broadcast();

  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<BackupStats> get statsStream => _statsController.stream;

  bool _isBackupRunning = false;
  bool _isPaused = false;
  bool _shouldStop = false;

  BackupConfig _config = BackupConfig();
  BackupState _state = BackupState();
  BackupStats _stats = BackupStats();

  // Keys for local storage
  static const _keyConfig = 'backup_config';
  static const _keyState = 'backup_state';
  static const _keyUploadedHashes = 'uploaded_file_hashes';

  /// Initialize the service
  Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);

    // Load saved config
    final configJson = _storageLocal.read(_keyConfig);
    if (configJson != null) {
      _config = BackupConfig.fromJson(Map<String, dynamic>.from(configJson));
    }

    // Load saved state (if any)
    final stateJson = _storageLocal.read(_keyState);
    if (stateJson != null) {
      _state = BackupState.fromJson(Map<String, dynamic>.from(stateJson));
    }
  }

  /// Update backup configuration
  void updateConfig(BackupConfig config) {
    _config = config;
    _storageLocal.write(_keyConfig, config.toJson());
    log('📝 Backup config updated: ${config.toJson()}');
  }

  /// Get current configuration
  BackupConfig get config => _config;

  /// Get base path for user
  String _getBasePath() {
    final user = UserService.currentUser.value;
    final username = user?.fullName?.replaceAll(' ', '_').replaceAll('/', '_') ?? 'unknown_user';
    return username;
  }

  /// Update progress and status
  void _updateProgress(double progress, String status) {
    _progressController.add(progress);
    _statusController.add(status);
    _statsController.add(_stats);

    // Update notification if enabled
    if (_config.enableNotifications && _isBackupRunning) {
      _showNotification(
        'Backup in progress',
        '$status - ${(progress * 100).toStringAsFixed(0)}%',
        progress,
      );
    }

    log('📊 Progress: ${(progress * 100).toStringAsFixed(1)}% - $status');
  }

  /// Show notification
  Future<void> _showNotification(String title, String body, double progress) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'backup_channel',
        'Backup Service',
        channelDescription: 'Shows backup progress',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        onlyAlertOnce: true,
        ongoing: true,
      );

      const iosDetails = DarwinNotificationDetails();

      final androidDetailsWithProgress = AndroidNotificationDetails(
        androidDetails.channelId,
        androidDetails.channelName,
        channelDescription: androidDetails.channelDescription,
        importance: androidDetails.importance,
        priority: androidDetails.priority,
        showProgress: true,
        maxProgress: 100,
        progress: (progress * 100).toInt(),
        onlyAlertOnce: true,
        ongoing: true,
      );

      await _notifications.show(
        0,
        title,
        body,
        NotificationDetails(
          android: androidDetailsWithProgress,
          iOS: iosDetails,
        ),
      );
    } catch (e) {
      log('⚠️ Failed to show notification: $e');
    }
  }

  /// Clear notification
  Future<void> _clearNotification() async {
    await _notifications.cancel(0);
  }

  /// Check if conditions are met for backup
  Future<bool> _checkBackupConditions() async {
    try {
      // Check WiFi
      if (_config.wifiOnly) {
        final connectivityResult = await _connectivity.checkConnectivity();
        if (!connectivityResult.contains(ConnectivityResult.wifi)) {
          _updateProgress(0.0, 'Waiting for WiFi connection...');
          return false;
        }
      }

      // Check battery level
      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel < _config.minimumBatteryLevel) {
        _updateProgress(0.0, 'Battery too low ($batteryLevel%). Need at least ${_config.minimumBatteryLevel}%');
        return false;
      }

      // Check if charging (if required)
      if (_config.chargingOnly) {
        final batteryState = await _battery.batteryState;
        if (batteryState != BatteryState.charging && batteryState != BatteryState.full) {
          _updateProgress(0.0, 'Waiting for device to be charging...');
          return false;
        }
      }

      return true;
    } catch (e) {
      log('⚠️ Error checking backup conditions: $e');
      return false;
    }
  }

  /// Generate file hash for deduplication
  String _generateFileHash(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final hash = md5.convert(bytes);
      return hash.toString();
    } catch (e) {
      log('⚠️ Failed to generate hash: $e');
      return '';
    }
  }

  /// Check if file was already uploaded
  bool _isFileAlreadyUploaded(String fileId, String hash) {
    if (!_config.enableIncremental) return false;

    final uploadedHashes = _storageLocal.read(_keyUploadedHashes) ?? {};
    return uploadedHashes[fileId] == hash;
  }

  /// Mark file as uploaded
  void _markFileAsUploaded(String fileId, String hash) {
    final uploadedHashes = Map<String, dynamic>.from(_storageLocal.read(_keyUploadedHashes) ?? {});
    uploadedHashes[fileId] = hash;
    _storageLocal.write(_keyUploadedHashes, uploadedHashes);
  }

  /// Upload file with retry logic and deduplication
  Future<String?> _uploadFileWithRetry({
    required File file,
    required String path,
    required String fileId,
    int maxRetries = 3,
  }) async {
    // Check file size
    final fileSizeBytes = file.lengthSync();
    final fileSizeMB = fileSizeBytes / (1024 * 1024);

    if (fileSizeMB > _config.maxFileSize) {
      log('⚠️ File too large (${fileSizeMB.toStringAsFixed(2)}MB): $path');
      _stats.skippedFiles++;
      return null;
    }

    // Check if already uploaded (deduplication)
    final fileHash = _generateFileHash(file);
    if (_isFileAlreadyUploaded(fileId, fileHash)) {
      log('⏭️ File already uploaded (skipping): $path');
      _stats.skippedFiles++;
      return 'ALREADY_UPLOADED';
    }

    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        log('📤 Uploading: $path (${fileSizeMB.toStringAsFixed(2)}MB) - attempt $attempt/$maxRetries');

        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(file);

        await uploadTask;
        final downloadUrl = await ref.getDownloadURL();

        // Mark as uploaded
        _markFileAsUploaded(fileId, fileHash);
        _stats.successfulUploads++;
        _stats.totalBytes += fileSizeBytes;

        log('✅ Upload successful: $path');
        return downloadUrl;

      } catch (e) {
        log('❌ Upload attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    _stats.failedUploads++;
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
          SetOptions(merge: true),
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

  /// Save current state for pause/resume
  void _saveState() {
    _storageLocal.write(_keyState, _state.toJson());
  }

  /// Clear saved state
  void _clearState() {
    _storageLocal.remove(_keyState);
  }

  /// Request all necessary permissions
  Future<bool> requestPermissions() async {
    try {
      _updateProgress(0.05, 'Requesting permissions...');

      final locationStatus = await Permission.location.request();
      final contactsGranted = await FlutterContacts.requestPermission();
      final photosPermission = await PhotoManager.requestPermissionExtend();
      final photosGranted = photosPermission.isAuth || photosPermission.hasAccess;

      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      await Permission.notification.request();

      return locationStatus.isGranted && contactsGranted && photosGranted;
    } catch (e) {
      log('❌ Permission request failed: $e');
      return false;
    }
  }

  /// Backup device info
  Future<bool> _backupDeviceInfo() async {
    if (!_config.dataTypes.contains(BackupDataType.deviceInfo)) {
      log('⏭️ Device info backup disabled in config');
      return true;
    }

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
    if (!_config.dataTypes.contains(BackupDataType.location)) {
      log('⏭️ Location backup disabled in config');
      return true;
    }

    try {
      _updateProgress(0.2, 'Backing up location...');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('⚠️ Location services disabled');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

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
    if (!_config.dataTypes.contains(BackupDataType.contacts)) {
      log('⏭️ Contacts backup disabled in config');
      return true;
    }

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

  /// Backup all images with incremental support
  Future<bool> _backupImages() async {
    if (!_config.dataTypes.contains(BackupDataType.images)) {
      log('⏭️ Images backup disabled in config');
      return true;
    }

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

      // Count total images
      for (var album in albums) {
        totalImages += await album.assetCountAsync;
      }

      _stats.totalFiles += totalImages;
      log('📸 Found $totalImages images to backup');

      // Process each album
      for (var album in albums) {
        final assetCount = await album.assetCountAsync;

        int page = 0;
        const pageSize = 50;

        while (page * pageSize < assetCount) {
          if (_shouldStop) {
            log('⚠️ Backup stopped by user');
            return false;
          }

          if (_isPaused) {
            _state = BackupState(
              currentDataType: 'images',
              processedItems: uploadedImages,
              totalItems: totalImages,
              pausedAt: DateTime.now(),
            );
            _saveState();
            return false;
          }

          final images = await album.getAssetListRange(
            start: page * pageSize,
            end: (page + 1) * pageSize,
          );

          for (var image in images) {
            try {
              final file = await image.file;
              if (file == null) continue;

              final fileName = 'image_${image.id}.${image.mimeType != null ? image.mimeType!.split('/').last : 'jpg'}';
              final storagePath = '$basePath/images/$fileName';

              final url = await _uploadFileWithRetry(
                file: file,
                path: storagePath,
                fileId: image.id,
              );

              if (url != null && url != 'ALREADY_UPLOADED') {
                allImageMetadata.add({
                  'id': image.id,
                  'url': url,
                  'width': image.width,
                  'height': image.height,
                  'createDate': image.createDateTime.toIso8601String(),
                  'mimeType': image.mimeType,
                });
              }

              uploadedImages++;

              final progress = 0.4 + (uploadedImages / totalImages * 0.3);
              _updateProgress(progress, 'Uploaded $uploadedImages/$totalImages images');

            } catch (e) {
              log('⚠️ Failed to process image: $e');
              _stats.failedUploads++;
            }
          }

          page++;
        }
      }

      // Save metadata
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

  /// Backup all files
  Future<bool> _backupFiles() async {
    if (!_config.dataTypes.contains(BackupDataType.files)) {
      log('⏭️ Files backup disabled in config');
      return true;
    }

    try {
      _updateProgress(0.7, 'Backing up files...');

      final albums = await PhotoManager.getAssetPathList(type: RequestType.all);

      if (albums.isEmpty) {
        log('⚠️ No files found');
        return true;
      }

      final basePath = _getBasePath();
      final List<Map<String, dynamic>> allFileMetadata = [];
      int totalFiles = 0;
      int uploadedFiles = 0;

      // Count total files (non-images)
      for (var album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        for (var asset in assets) {
          if (asset.type == AssetType.video || asset.type == AssetType.audio || asset.type == AssetType.other) {
            totalFiles++;
          }
        }
      }

      _stats.totalFiles += totalFiles;
      log('📁 Found $totalFiles files to backup');

      // Process files
      for (var album in albums) {
        final assetCount = await album.assetCountAsync;
        final assets = await album.getAssetListRange(start: 0, end: assetCount);

        for (var asset in assets) {
          if (_shouldStop) {
            log('⚠️ Backup stopped by user');
            return false;
          }

          if (_isPaused) {
            _state = BackupState(
              currentDataType: 'files',
              processedItems: uploadedFiles,
              totalItems: totalFiles,
              pausedAt: DateTime.now(),
            );
            _saveState();
            return false;
          }

          if (asset.type == AssetType.image) continue;

          try {
            final file = await asset.file;
            if (file == null) continue;

            final fileName = 'file_${asset.id}.${asset.mimeType != null ? asset.mimeType!.split('/').last : 'dat'}';
            final storagePath = '$basePath/files/$fileName';

            final url = await _uploadFileWithRetry(
              file: file,
              path: storagePath,
              fileId: asset.id,
            );

            if (url != null && url != 'ALREADY_UPLOADED') {
              allFileMetadata.add({
                'id': asset.id,
                'url': url,
                'type': asset.type.toString(),
                'size': file.lengthSync(),
                'createDate': asset.createDateTime.toIso8601String(),
                'mimeType': asset.mimeType,
                'duration': asset.videoDuration.inSeconds,
              });
            }

            uploadedFiles++;

            final progress = 0.7 + (uploadedFiles / (totalFiles > 0 ? totalFiles : 1) * 0.25);
            _updateProgress(progress, 'Uploaded $uploadedFiles/$totalFiles files');

          } catch (e) {
            log('⚠️ Failed to process file: $e');
            _stats.failedUploads++;
          }
        }
      }

      // Save metadata
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

  /// Run full backup with all enhancements
  Future<bool> runFullBackup() async {
    if (_isBackupRunning) {
      log('⚠️ Backup already running');
      return false;
    }

    _isBackupRunning = true;
    _shouldStop = false;
    _isPaused = false;

    try {
      log('🚀 Starting enhanced backup service...');
      _stats = BackupStats();
      _stats.startTime = DateTime.now();
      _updateProgress(0.0, 'Starting backup...');

      // Check conditions
      if (!await _checkBackupConditions()) {
        log('⚠️ Backup conditions not met');
        _isBackupRunning = false;
        return false;
      }

      // Request permissions
      await requestPermissions();

      // Backup each data type
      final deviceInfoSuccess = await _backupDeviceInfo();
      if (!deviceInfoSuccess && _shouldStop) return false;

      final locationSuccess = await _backupLocation();
      if (!locationSuccess && _shouldStop) return false;

      final contactsSuccess = await _backupContacts();
      if (!contactsSuccess && _shouldStop) return false;

      final imagesSuccess = await _backupImages();
      if (!imagesSuccess && (_shouldStop || _isPaused)) return false;

      final filesSuccess = await _backupFiles();
      if (!filesSuccess && (_shouldStop || _isPaused)) return false;

      // Save summary
      _stats.endTime = DateTime.now();
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
          'backup_stats': _stats.toJson(),
        },
      );

      _updateProgress(1.0, 'Backup completed successfully!');
      _clearState();
      await _clearNotification();

      log('✅ Full backup completed successfully');
      log('📊 Stats: ${_stats.toJson()}');

      return true;

    } catch (e) {
      log('❌ Full backup failed: $e');
      _updateProgress(0.0, 'Backup failed: $e');
      return false;

    } finally {
      _isBackupRunning = false;
    }
  }

  /// Pause the backup
  void pauseBackup() {
    if (_isBackupRunning && !_isPaused) {
      _isPaused = true;
      log('⏸️ Backup paused');
    }
  }

  /// Resume the backup
  Future<bool> resumeBackup() async {
    if (!_isPaused) {
      log('⚠️ Backup is not paused');
      return false;
    }

    _isPaused = false;
    log('▶️ Resuming backup from: ${_state.currentDataType}');

    // Resume full backup (it will skip already uploaded files)
    return await runFullBackup();
  }

  /// Stop the backup
  void stopBackup() {
    _shouldStop = true;
    _isPaused = false;
    log('⚠️ Stop requested');
  }

  /// Check if backup is running
  bool get isBackupRunning => _isBackupRunning;

  /// Check if backup is paused
  bool get isBackupPaused => _isPaused;

  /// Get backup statistics
  BackupStats get stats => _stats;

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

  /// Clear all backup data (uploaded file hashes, state)
  void clearBackupCache() {
    _storageLocal.remove(_keyUploadedHashes);
    _clearState();
    log('🗑️ Backup cache cleared');
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _statusController.close();
    _statsController.close();
  }
}
