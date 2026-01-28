import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'device_info_collector.dart';

/// Service that provides device context and location data for analytics
/// with intelligent caching to minimize performance impact
class AnalyticsDeviceContextService extends GetxService {
  static AnalyticsDeviceContextService get instance => Get.find();

  // Cache for device info (changes rarely)
  Map<String, dynamic>? _cachedDeviceContext;
  DateTime? _deviceCacheTime;
  static const Duration _deviceCacheDuration = Duration(hours: 24);

  // Cache for location data (more frequent updates needed)
  Map<String, dynamic>? _cachedLocationContext;
  DateTime? _locationCacheTime;
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  // Timeout for location operations to prevent blocking
  static const Duration _locationTimeout = Duration(seconds: 10);

  // Privacy settings
  bool _deviceTrackingEnabled = true;
  bool _locationTrackingEnabled = false; // Opt-in by default

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      // Pre-warm device context cache
      await getDeviceContext();
    } catch (e) {
      log('Failed to initialize AnalyticsDeviceContextService: $e');
    }
  }

  /// Gets comprehensive device context with caching
  /// Returns empty map if device tracking is disabled or on error
  Future<Map<String, dynamic>> getDeviceContext() async {
    if (!_deviceTrackingEnabled) {
      return {};
    }

    // Check cache validity
    if (_cachedDeviceContext != null &&
        _deviceCacheTime != null &&
        DateTime.now().difference(_deviceCacheTime!) < _deviceCacheDuration) {
      return Map<String, dynamic>.from(_cachedDeviceContext!);
    }

    try {
      // Collect fresh device info
      final deviceInfo = await _collectDeviceInfo();

      // Update cache
      _cachedDeviceContext = deviceInfo;
      _deviceCacheTime = DateTime.now();

      return Map<String, dynamic>.from(deviceInfo);
    } catch (e) {
      log('Error collecting device context: $e');
      // Return cached data if available, otherwise empty map
      return _cachedDeviceContext != null
          ? Map<String, dynamic>.from(_cachedDeviceContext!)
          : {};
    }
  }

  /// Gets location context with caching and reverse geocoding
  /// Returns empty map if location tracking is disabled, permission denied, or on error
  Future<Map<String, dynamic>> getLocationContext() async {
    if (!_locationTrackingEnabled) {
      return {};
    }

    // Check cache validity
    if (_cachedLocationContext != null &&
        _locationCacheTime != null &&
        DateTime.now().difference(_locationCacheTime!) <
            _locationCacheDuration) {
      return Map<String, dynamic>.from(_cachedLocationContext!);
    }

    try {
      // Collect fresh location with timeout
      final locationData = await _collectLocation()
          .timeout(_locationTimeout, onTimeout: () => <String, dynamic>{});

      if (locationData.isEmpty) {
        return {};
      }

      // Update cache
      _cachedLocationContext = locationData;
      _locationCacheTime = DateTime.now();

      return Map<String, dynamic>.from(locationData);
    } catch (e) {
      log('Error collecting location context: $e');
      // Return cached data if available, otherwise empty map
      return _cachedLocationContext != null
          ? Map<String, dynamic>.from(_cachedLocationContext!)
          : {};
    }
  }

  /// Collects comprehensive device information
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    final deviceInfoCollector = Get.find<DeviceInfoCollector>();
    final packageInfo = await PackageInfo.fromPlatform();

    final deviceInfoMap = <String, dynamic>{};

    try {
      // Collect device info using the DeviceInfoCollector
      final deviceInfo = await deviceInfoCollector.collectDeviceInfo();

      // Basic device info
      deviceInfoMap['device_model'] = deviceInfo.deviceModel ?? 'Unknown';
      deviceInfoMap['device_brand'] = deviceInfo.brand ?? 'Unknown';
      deviceInfoMap['os'] = deviceInfo.operatingSystem ?? 'Unknown';
      deviceInfoMap['os_version'] = deviceInfo.osVersion ?? 'Unknown';

      // App version (dynamic, not hardcoded)
      deviceInfoMap['app_version'] =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      // Network info
      if (deviceInfo.networkType != null) {
        deviceInfoMap['network_type'] = deviceInfo.networkType;
      }

      // Battery info
      if (deviceInfo.batteryLevel != null) {
        deviceInfoMap['battery_level'] = deviceInfo.batteryLevel;
      }

      // Storage info
      if (deviceInfo.availableStorage != null) {
        deviceInfoMap['storage_available_gb'] =
            _bytesToGB(deviceInfo.availableStorage);
      }
      if (deviceInfo.totalStorage != null) {
        deviceInfoMap['storage_total_gb'] = _bytesToGB(deviceInfo.totalStorage);
      }

      // Platform info
      deviceInfoMap['platform'] = deviceInfo.operatingSystem?.toLowerCase();
    } catch (e) {
      log('Error in _collectDeviceInfo: $e');
    }

    return deviceInfoMap;
  }

  /// Collects location data with reverse geocoding
  Future<Map<String, dynamic>> _collectLocation() async {
    try {
      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('Location permission denied');
        return {};
      }

      // Check if location service is enabled
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        log('Location service disabled');
        return {};
      }

      // Get current position with medium accuracy (battery optimization)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.toIso8601String(),
        'cached': false,
      };

      // Perform reverse geocoding with timeout
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => <Placemark>[],
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locationData['city'] = place.locality ?? place.subAdministrativeArea;
          locationData['country'] = place.country;
          locationData['country_code'] = place.isoCountryCode;
          locationData['postal_code'] = place.postalCode;
        }
      } catch (e) {
        log('Reverse geocoding failed: $e');
        // Continue without city/country info
      }

      return locationData;
    } catch (e) {
      log('Error collecting location: $e');
      return {};
    }
  }

  /// Convert bytes to gigabytes
  double? _bytesToGB(int? bytes) {
    if (bytes == null) return null;
    return (bytes / (1024 * 1024 * 1024)).toDouble();
  }

  /// Enable or disable device tracking
  void setDeviceTrackingEnabled(bool enabled) {
    _deviceTrackingEnabled = enabled;
    if (!enabled) {
      // Clear device cache when disabled
      _cachedDeviceContext = null;
      _deviceCacheTime = null;
    }
  }

  /// Enable or disable location tracking
  void setLocationTrackingEnabled(bool enabled) {
    _locationTrackingEnabled = enabled;
    if (!enabled) {
      // Clear location cache when disabled
      _cachedLocationContext = null;
      _locationCacheTime = null;
    }
  }

  /// Check if device tracking is enabled
  bool get isDeviceTrackingEnabled => _deviceTrackingEnabled;

  /// Check if location tracking is enabled
  bool get isLocationTrackingEnabled => _locationTrackingEnabled;

  /// Request location permission if needed
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      log('Error requesting location permission: $e');
      return false;
    }
  }

  /// Invalidate device context cache (force refresh on next request)
  void invalidateDeviceCache() {
    _cachedDeviceContext = null;
    _deviceCacheTime = null;
  }

  /// Invalidate location context cache (force refresh on next request)
  void invalidateLocationCache() {
    _cachedLocationContext = null;
    _locationCacheTime = null;
  }

  /// Get cache status information (useful for debugging)
  Map<String, dynamic> getCacheStatus() {
    return {
      'device_tracking_enabled': _deviceTrackingEnabled,
      'location_tracking_enabled': _locationTrackingEnabled,
      'device_cache_valid': _cachedDeviceContext != null &&
          _deviceCacheTime != null &&
          DateTime.now().difference(_deviceCacheTime!) < _deviceCacheDuration,
      'location_cache_valid': _cachedLocationContext != null &&
          _locationCacheTime != null &&
          DateTime.now().difference(_locationCacheTime!) <
              _locationCacheDuration,
      'device_cache_age_minutes': _deviceCacheTime != null
          ? DateTime.now().difference(_deviceCacheTime!).inMinutes
          : null,
      'location_cache_age_minutes': _locationCacheTime != null
          ? DateTime.now().difference(_locationCacheTime!).inMinutes
          : null,
    };
  }

  /// Get example of what data would be collected (for privacy info display)
  Map<String, dynamic> getCollectedDataExample() {
    return {
      'device_context': {
        'device_model': 'Example: iPhone 14 Pro',
        'device_brand': 'Example: Apple',
        'os': 'Example: iOS',
        'os_version': 'Example: 17.2',
        'app_version': 'Example: 1.0.2+4',
        'network_type': 'Example: wifi',
        'battery_level': 'Example: 85',
        'battery_state': 'Example: charging',
        'storage_available_gb': 'Example: 45.3',
        'storage_total_gb': 'Example: 128',
        'memory_available_mb': 'Example: 2048',
        'memory_total_mb': 'Example: 4096',
        'screen_width': 'Example: 1179',
        'screen_height': 'Example: 2556',
        'pixel_ratio': 'Example: 3.0',
      },
      'location_context': {
        'latitude': 'Example: 37.7749',
        'longitude': 'Example: -122.4194',
        'accuracy': 'Example: 10.5 meters',
        'city': 'Example: San Francisco',
        'country': 'Example: United States',
        'timestamp': 'Example: 2024-01-27T10:30:00Z',
      },
    };
  }
}
