import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Device info backup strategy - backs up device and app metadata
///
/// **Features:**
/// - App version and build number
/// - Device model, OS version, platform
/// - Backup timestamp and configuration
/// - Lightweight (single JSON document, ~1KB)
class DeviceInfoBackupStrategy extends BackupStrategy {
  final BackupDataSource _backupDataSource = BackupDataSource();

  @override
  Future<BackupResult> execute(BackupContext context) async {
    try {
      log('📱 Starting device info backup...');

      // Collect device information
      final deviceInfo = await _collectDeviceInfo();

      // Collect app information
      final appInfo = await _collectAppInfo();

      // Create backup data structure
      final backupData = {
        'deviceInfo': deviceInfo,
        'appInfo': appInfo,
        'backupInfo': {
          'backupId': context.backupId,
          'userId': context.userId,
          'backupDate': DateTime.now().toIso8601String(),
          'backupTypes': context.options.toString(),
          'wifiOnly': context.options.wifiOnly,
          'compressMedia': context.options.compressMedia,
          'incrementalOnly': context.options.incrementalOnly,
        },
        'metadata': {
          'backupVersion': '3.0',
          'platform': Platform.operatingSystem,
        },
      };

      // Upload as JSON with organized folder structure
      // Path: backups/{userId}/{backupId}/device_info/device_info.json
      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'device_info.json',
        data: backupData,
        folder: 'device_info',
        userId: context.userId,
      );

      // Estimate bytes transferred (tiny file, ~1KB)
      const bytesTransferred = 1024;

      log('✅ Device info backup completed');

      return BackupResult(
        totalItems: 1,
        successfulItems: 1,
        failedItems: 0,
        bytesTransferred: bytesTransferred,
      );

    } catch (e, stackTrace) {
      log('❌ Device info backup failed: $e', stackTrace: stackTrace);
      return BackupResult(
        totalItems: 1,
        successfulItems: 0,
        failedItems: 1,
        bytesTransferred: 0,
        errors: ['Device info backup failed: $e'],
      );
    }
  }

  @override
  Future<int> estimateItemCount(BackupContext context) async {
    return 1; // Single device info document
  }

  /// Device info is a fixed small size (~5KB)
  /// Contains device metadata, app info, and backup configuration
  @override
  Future<int> estimateBytesPerItem(BackupContext context) async {
    // Device info is predictable - always ~5KB regardless of device
    // Contains: device model, OS, app version, backup config
    return 5 * 1024; // 5KB
  }

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    return true; // Always backup device info (lightweight)
  }

  // Private helper methods

  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'androidVersion': androidInfo.version.release,
          'androidSdkInt': androidInfo.version.sdkInt,
          'androidId': androidInfo.id,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'hardware': androidInfo.hardware,
          'product': androidInfo.product,
          'board': androidInfo.board,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'sysname': iosInfo.utsname.sysname,
            'release': iosInfo.utsname.release,
          },
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'message': 'Device info not available for this platform',
        };
      }
    } catch (e) {
      log('❌ Error collecting device info: $e');
      return {
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _collectAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      return {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'buildSignature': packageInfo.buildSignature,
      };
    } catch (e) {
      log('❌ Error collecting app info: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}
