import 'dart:io' show Platform;
import 'dart:async';
import 'dart:developer';
import 'package:battery_plus/battery_plus.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Device info collector utility
/// Collects comprehensive device information for backup purposes
class DeviceInfoCollector {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Collect comprehensive device information
  Future<DeviceInfo> collectDeviceInfo() async {
    try {
      log('📱 Starting device info collection...');

      var deviceInfo = DeviceInfo.now();

      // Get basic device information
      deviceInfo = await _collectBasicDeviceInfo(deviceInfo);

      // Get battery information
      deviceInfo = await _collectBatteryInfo(deviceInfo);

      // Get network information
      deviceInfo = await _collectNetworkInfo(deviceInfo);

      // Get location information (with permission check)
      deviceInfo = await _collectLocationInfo(deviceInfo);

      // Get storage information
      deviceInfo = await _collectStorageInfo(deviceInfo);

      // Get app information
      deviceInfo = await _collectAppInfo(deviceInfo);

      // Get permissions status
      deviceInfo = await _collectPermissionsInfo(deviceInfo);

      log('✅ Device info collection completed');
      return deviceInfo;
    } catch (e) {
      log('❌ Error collecting device info: $e');
      return DeviceInfo.now(
        deviceName: 'Unknown Device',
        deviceModel: 'Unknown Model',
        operatingSystem: 'Unknown OS',
      );
    }
  }

  /// Collect basic device information
  Future<DeviceInfo> _collectBasicDeviceInfo(DeviceInfo deviceInfo) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return deviceInfo.copyWith(
          deviceName: androidInfo.model,
          deviceModel: androidInfo.model,
          brand: androidInfo.brand,
          operatingSystem: 'Android',
          osVersion: androidInfo.version.release,
          deviceId: androidInfo.id,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return deviceInfo.copyWith(
          deviceName: iosInfo.name,
          deviceModel: iosInfo.model,
          operatingSystem: 'iOS',
          osVersion: iosInfo.systemVersion,
          deviceId: iosInfo.identifierForVendor,
        );
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return deviceInfo.copyWith(
          deviceName: windowsInfo.computerName,
          deviceModel: 'Windows PC',
          operatingSystem: 'Windows',
          osVersion: windowsInfo.displayVersion,
          deviceId: windowsInfo.deviceId,
        );
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return deviceInfo.copyWith(
          deviceName: macInfo.computerName,
          deviceModel: macInfo.model,
          operatingSystem: 'macOS',
          osVersion: macInfo.osRelease,
          deviceId: macInfo.systemGUID,
        );
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return deviceInfo.copyWith(
          deviceName: linuxInfo.name,
          deviceModel: linuxInfo.version ?? 'Linux',
          operatingSystem: 'Linux',
          osVersion: linuxInfo.version,
          deviceId: linuxInfo.machineId,
        );
      }
      return deviceInfo;
    } catch (e) {
      log('❌ Error collecting basic device info: $e');
      return deviceInfo;
    }
  }

  /// Collect battery information
  Future<DeviceInfo> _collectBatteryInfo(DeviceInfo deviceInfo) async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      var batteryInfo = '$batteryLevel%';

      // Add battery state information
      switch (batteryState) {
        case BatteryState.charging:
          batteryInfo = '$batteryInfo (Charging)';
          break;
        case BatteryState.discharging:
          batteryInfo = '$batteryInfo (Discharging)';
          break;
        case BatteryState.full:
          batteryInfo = '$batteryInfo (Full)';
          break;
        case BatteryState.connectedNotCharging:
          batteryInfo = '$batteryInfo (Connected Not Charging)';
          break;
        case BatteryState.unknown:
          batteryInfo = '$batteryInfo (Unknown)';
          break;

      }

      return deviceInfo.copyWith(batteryLevel: batteryInfo);
    } catch (e) {
      log('❌ Error collecting battery info: $e');
      return deviceInfo.copyWith(batteryLevel: 'Unknown');
    }
  }

  /// Collect network information
  Future<DeviceInfo> _collectNetworkInfo(DeviceInfo deviceInfo) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      String networkInfo;
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkInfo = 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        networkInfo = 'Mobile Data';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        networkInfo = 'Ethernet';
      } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
        networkInfo = 'VPN';
      } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
        networkInfo = 'Bluetooth';
      } else if (connectivityResult.contains(ConnectivityResult.other)) {
        networkInfo = 'Other';
      } else {
        networkInfo = 'No Connection';
      }

      // Get WiFi information if connected
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        try {
          final wifiName = await _networkInfo.getWifiName();
          final wifiBSSID = await _networkInfo.getWifiBSSID();
          final wifiIP = await _networkInfo.getWifiIP();

          if (wifiName != null || wifiBSSID != null || wifiIP != null) {
            final wifiDetails = <String>[];
            if (wifiName != null) wifiDetails.add('Name: $wifiName');
            if (wifiBSSID != null) wifiDetails.add('BSSID: $wifiBSSID');
            if (wifiIP != null) wifiDetails.add('IP: $wifiIP');
            networkInfo = '$networkInfo (${wifiDetails.join(', ')})';
          }
        } catch (e) {
          log('❌ Error collecting WiFi info: $e');
        }
      }

      return deviceInfo.copyWith(networkType: networkInfo);
    } catch (e) {
      log('❌ Error collecting network info: $e');
      return deviceInfo.copyWith(networkType: 'Unknown');
    }
  }

  /// Collect location information
  Future<DeviceInfo> _collectLocationInfo(DeviceInfo deviceInfo) async {
    try {
      final locationPermission = await Permission.location.status;

      if (locationPermission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        return deviceInfo.copyWith(location: '${position.latitude}, ${position.longitude}');
      } else {
        return deviceInfo.copyWith(location: 'Permission denied');
      }
    } catch (e) {
      log('❌ Error collecting location info: $e');
      return deviceInfo.copyWith(location: 'Unable to determine');
    }
  }

  /// Collect storage information
  Future<DeviceInfo> _collectStorageInfo(DeviceInfo deviceInfo) async {
    try {
      // Note: This is a simplified version. In a real app, you'd want to use
      // platform-specific APIs to get accurate storage information
      return deviceInfo.copyWith(
        totalStorage: 0, // Placeholder
        availableStorage: 0, // Placeholder
      );
    } catch (e) {
      log('❌ Error collecting storage info: $e');
      return deviceInfo;
    }
  }

  /// Collect app information
  Future<DeviceInfo> _collectAppInfo(DeviceInfo deviceInfo) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Store app info in deviceInfo for backup purposes
      return deviceInfo.copyWith(
        operatingSystem: '${deviceInfo.operatingSystem} (${packageInfo.appName} v${packageInfo.version})',
      );
    } catch (e) {
      log('❌ Error collecting app info: $e');
      return deviceInfo;
    }
  }

  /// Collect permissions status
  Future<DeviceInfo> _collectPermissionsInfo(DeviceInfo deviceInfo) async {
    try {
      final permissions = <Permission>[
        Permission.camera,
        Permission.microphone,
        Permission.photos,
        Permission.contacts,
        Permission.location,
        Permission.storage,
        Permission.notification,
      ];

      final permissionsStatus = <String, String>{};

      for (final permission in permissions) {
        final status = await permission.status;
        permissionsStatus[permission.toString()] = status.toString();
      }

      // Create a copy with permissions info
      final currentMap = deviceInfo.toMap();
      currentMap['permissions'] = permissionsStatus;
      return DeviceInfo.fromMap(currentMap);
    } catch (e) {
      log('❌ Error collecting permissions info: $e');
      return deviceInfo;
    }
  }

  /// Collect device info for specific categories
  Future<Map<String, dynamic>> collectDeviceInfoByCategory(List<String> categories) async {
    final result = <String, dynamic>{};
    final fullDeviceInfo = await collectDeviceInfo();

    for (final category in categories) {
      switch (category.toLowerCase()) {
        case 'basic':
          result['basic'] = {
            'deviceName': fullDeviceInfo.deviceName,
            'deviceModel': fullDeviceInfo.deviceModel,
            'operatingSystem': fullDeviceInfo.operatingSystem,
            'osVersion': fullDeviceInfo.osVersion,
            'deviceId': fullDeviceInfo.deviceId,
            'brand': fullDeviceInfo.brand,
          };
          break;
        case 'battery':
          result['battery'] = {
            'batteryLevel': fullDeviceInfo.batteryLevel,
          };
          break;
        case 'network':
          result['network'] = {
            'networkType': fullDeviceInfo.networkType,
          };
          break;
        case 'location':
          result['location'] = {
            'location': fullDeviceInfo.location,
          };
          break;
        case 'storage':
          result['storage'] = {
            'totalStorage': fullDeviceInfo.totalStorage,
            'availableStorage': fullDeviceInfo.availableStorage,
          };
          break;
        default:
          result[category] = {};
      }
    }

    return result;
  }

  /// Check if device has required permissions for backup
  Future<Map<String, bool>> checkBackupPermissions() async {
    final permissions = <String, bool>{};

    try {
      permissions['contacts'] = await Permission.contacts.isGranted;
      permissions['photos'] = await Permission.photos.isGranted;
      permissions['storage'] = await Permission.storage.isGranted;
      permissions['camera'] = await Permission.camera.isGranted;
      permissions['microphone'] = await Permission.microphone.isGranted;
    } catch (e) {
      log('❌ Error checking permissions: $e');
    }

    return permissions;
  }

  /// Request permissions needed for backup
  Future<Map<String, bool>> requestBackupPermissions() async {
    final results = <String, bool>{};

    try {
      results['contacts'] = await Permission.contacts.request().isGranted;
      results['photos'] = await Permission.photos.request().isGranted;
      results['storage'] = await Permission.storage.request().isGranted;
      results['camera'] = await Permission.camera.request().isGranted;
      results['microphone'] = await Permission.microphone.request().isGranted;
    } catch (e) {
      log('❌ Error requesting permissions: $e');
    }

    return results;
  }

  /// Get device identifier for backup naming
  Future<String> getDeviceIdentifier() async {
    try {
      final deviceInfo = await collectDeviceInfo();
      final identifier = deviceInfo.deviceId ?? deviceInfo.deviceModel ?? 'unknown_device';
      return identifier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    } catch (e) {
      log('❌ Error getting device identifier: $e');
      return 'unknown_device';
    }
  }

  /// Check if device is online
  Future<bool> isDeviceOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      log('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Get device storage usage
  Future<Map<String, int>> getStorageUsage() async {
    try {
      // This is a placeholder implementation
      // In a real app, you'd use platform-specific APIs
      return {
        'total': 0,
        'available': 0,
        'used': 0,
      };
    } catch (e) {
      log('❌ Error getting storage usage: $e');
      return {
        'total': 0,
        'available': 0,
        'used': 0,
      };
    }
  }
}
