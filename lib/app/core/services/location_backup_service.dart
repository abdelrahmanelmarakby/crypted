import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:crypted_app/app/core/services/device_info_collector.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location data model for backup
class LocationData {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final String? address;
  final DateTime? timestamp;
  final String? locationType; // current, saved, frequent
  final Map<String, dynamic>? metadata;

  const LocationData({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.address,
    this.timestamp,
    this.locationType,
    this.metadata,
  });

  factory LocationData.current({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? address,
    Map<String, dynamic>? metadata,
  }) {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      address: address,
      timestamp: DateTime.now(),
      locationType: 'current',
      metadata: metadata,
    );
  }

  factory LocationData.fromPosition(Position position, {String? address, Map<String, dynamic>? metadata}) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      address: address,
      timestamp: position.timestamp,
      locationType: 'gps',
      metadata: metadata,
    );
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? address,
    DateTime? timestamp,
    String? locationType,
    Map<String, dynamic>? metadata,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      locationType: locationType ?? this.locationType,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'address': address,
      'timestamp': timestamp?.toIso8601String(),
      'locationType': locationType,
      'metadata': metadata,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      accuracy: map['accuracy'] as double?,
      altitude: map['altitude'] as double?,
      speed: map['speed'] as double?,
      heading: map['heading'] as double?,
      address: map['address'] as String?,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : null,
      locationType: map['locationType'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationData.fromJson(String source) => LocationData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LocationData(latitude: $latitude, longitude: $longitude, accuracy: $accuracy, altitude: $altitude, speed: $speed, heading: $heading, address: $address, timestamp: $timestamp, locationType: $locationType, metadata: $metadata)';
  }

  @override
  bool operator ==(covariant LocationData other) {
    if (identical(this, other)) return true;

    return other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.altitude == altitude &&
        other.speed == speed &&
        other.heading == heading &&
        other.address == address &&
        other.timestamp == timestamp &&
        other.locationType == locationType;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        accuracy.hashCode ^
        altitude.hashCode ^
        speed.hashCode ^
        heading.hashCode ^
        address.hashCode ^
        timestamp.hashCode ^
        locationType.hashCode;
  }
}

/// Location history model for backup
class LocationHistory {
  final List<LocationData> locations;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final Map<String, dynamic>? metadata;

  const LocationHistory({
    required this.locations,
    this.startDate,
    this.endDate,
    this.description,
    this.metadata,
  });

  factory LocationHistory.create({
    List<LocationData>? locations,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return LocationHistory(
      locations: locations ?? [],
      startDate: startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      endDate: endDate ?? DateTime.now(),
      description: description ?? 'Location history backup',
      metadata: metadata ?? {},
    );
  }

  LocationHistory copyWith({
    List<LocationData>? locations,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return LocationHistory(
      locations: locations ?? this.locations,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locations': locations.map((x) => x.toMap()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'metadata': metadata,
    };
  }

  factory LocationHistory.fromMap(Map<String, dynamic> map) {
    return LocationHistory(
      locations: List<LocationData>.from(
        (map['locations'] as List).map<LocationData>(
          (x) => LocationData.fromMap(x as Map<String, dynamic>),
        ),
      ),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      description: map['description'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationHistory.fromJson(String source) => LocationHistory.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LocationHistory(locations: ${locations.length}, startDate: $startDate, endDate: $endDate, description: $description, metadata: $metadata)';
  }
}

/// Location backup service
/// Handles collecting, processing, and uploading location data for backup
class LocationBackupService {
  final BackupDataSource _backupDataSource = BackupDataSource();
  final DeviceInfoCollector _deviceInfoCollector = DeviceInfoCollector();

  /// Get current location
  Future<LocationData?> getCurrentLocation({bool requestPermission = true}) async {
    try {
      log('📍 Getting current location...');

      // Check permission
      var permission = await Permission.location.status;
      if (!permission.isGranted) {
        if (requestPermission) {
          permission = await Permission.location.request();
        }

        if (!permission.isGranted) {
          log('❌ Location permission denied');
          return null;
        }
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ Location services are disabled');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

        // Try to get address (simplified - in real implementation use geocoding package)
        String? address;
        try {
          // Note: For address lookup, you'd typically use the geocoding package
          // For now, we'll use a placeholder
          address = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        } catch (e) {
          log('❌ Error getting address: $e');
        }

      final locationData = LocationData.fromPosition(position, address: address);
      log('✅ Current location retrieved: ${locationData.latitude}, ${locationData.longitude}');

      return locationData;
    } catch (e) {
      log('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Get location history for specified days
  Future<LocationHistory> getLocationHistory({
    int days = 7,
    int maxLocations = 1000,
  }) async {
    try {
      log('📍 Getting location history for $days days...');

      // Check permission
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        await Permission.location.request();
        final newPermission = await Permission.location.status;
        if (!newPermission.isGranted) {
          throw Exception('Location permission required for location history');
        }
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Note: In a real implementation, you'd get historical location data
      // For now, we'll create a sample history with current location
      // and some simulated historical points

      final locations = <LocationData>[];

      // Add current location
      final currentLocation = await getCurrentLocation(requestPermission: false);
      if (currentLocation != null) {
        locations.add(currentLocation);
      }

      // Add some sample historical locations (in a real app, this would come from actual location history)
      for (int i = 1; i <= 5; i++) {
        final historicalDate = endDate.subtract(Duration(days: i));
        locations.add(LocationData.current(
          latitude: (currentLocation?.latitude ?? 0) + (0.001 * i),
          longitude: (currentLocation?.longitude ?? 0) + (0.001 * i),
          address: 'Historical location $i',
          metadata: {
            'isHistorical': true,
            'confidence': 0.8 - (i * 0.1),
            'source': 'simulated',
          },
        ).copyWith(timestamp: historicalDate));
      }

      // Sort by timestamp (newest first)
      locations.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));

      // Limit to max locations
      if (locations.length > maxLocations) {
        locations.removeRange(maxLocations, locations.length);
      }

      final history = LocationHistory.create(
        locations: locations,
        startDate: startDate,
        endDate: endDate,
        description: 'Location history for $days days',
      );

      log('✅ Location history retrieved: ${locations.length} locations');
      return history;

    } catch (e) {
      log('❌ Error getting location history: $e');
      rethrow;
    }
  }

  /// Get saved/favorite locations
  Future<List<LocationData>> getSavedLocations() async {
    try {
      log('📍 Getting saved locations...');

      // Check permission
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        await Permission.location.request();
        final newPermission = await Permission.location.status;
        if (!newPermission.isGranted) {
          return [];
        }
      }

      // In a real implementation, you would get saved locations from:
      // - User's saved places
      // - Home/Work locations
      // - Frequently visited places
      // - Custom saved locations

      // For now, return current location as "saved"
      final currentLocation = await getCurrentLocation(requestPermission: false);
      final savedLocations = <LocationData>[];

      if (currentLocation != null) {
        savedLocations.add(currentLocation.copyWith(locationType: 'saved'));
      }

      log('✅ Saved locations retrieved: ${savedLocations.length} locations');
      return savedLocations;

    } catch (e) {
      log('❌ Error getting saved locations: $e');
      return [];
    }
  }

  /// Create location backup
  Future<BackupProgress> createLocationBackup({
    required String userId,
    required String backupId,
    int historyDays = 7,
    bool includeHistory = true,
    bool includeSavedLocations = true,
    bool includeCurrentLocation = true,
    Function(double)? onProgress,
  }) async {
    try {
      log('📍 Starting location backup process...');

      // Check permissions
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        await Permission.location.request();
        final newPermission = await Permission.location.status;
        if (!newPermission.isGranted) {
          throw Exception('Location permission required for backup');
        }
      }

      // Initialize backup progress
      var progress = BackupProgress.initial(
        backupId: backupId,
        type: BackupType.deviceInfo, // Using deviceInfo type for location
        totalItems: 0,
      );

      // Update progress to in-progress
      progress = progress.copyWith(status: BackupStatus.inProgress);
      await _backupDataSource.updateBackupProgress(progress);

      final locationData = <String, dynamic>{};
      int totalItems = 0;

      // Get current location
      if (includeCurrentLocation) {
        final currentLocation = await getCurrentLocation(requestPermission: false);
        if (currentLocation != null) {
          locationData['currentLocation'] = currentLocation.toMap();
          totalItems++;
        }
      }

      // Get location history
      if (includeHistory) {
        final history = await getLocationHistory(days: historyDays);
        locationData['history'] = history.toMap();
        totalItems += history.locations.length;
      }

      // Get saved locations
      if (includeSavedLocations) {
        final savedLocations = await getSavedLocations();
        locationData['savedLocations'] = savedLocations.map((l) => l.toMap()).toList();
        totalItems += savedLocations.length;
      }

      // Add device and permission info
      locationData['deviceInfo'] = (await _deviceInfoCollector.collectDeviceInfo()).toMap();
      locationData['permissions'] = await _deviceInfoCollector.checkBackupPermissions();
      locationData['backupMetadata'] = {
        'includeCurrentLocation': includeCurrentLocation,
        'includeHistory': includeHistory,
        'includeSavedLocations': includeSavedLocations,
        'historyDays': historyDays,
        'totalItems': totalItems,
        'timestamp': DateTime.now().toIso8601String(),
      };

      progress = progress.copyWith(totalItems: totalItems);
      await _backupDataSource.updateBackupProgress(progress);

      // Upload location data as JSON
      await _backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'location_data.json',
        data: locationData,
        folder: 'location',
      );

      // Complete backup
      progress = progress.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        completedItems: totalItems,
        currentTask: 'Location backup completed',
      );
      await _backupDataSource.updateBackupProgress(progress);

      log('✅ Location backup completed successfully');
      return progress;

    } catch (e) {
      log('❌ Error in location backup: $e');

      // Update progress with error
      final errorProgress = BackupProgress(
        backupId: backupId,
        status: BackupStatus.failed,
        type: BackupType.deviceInfo,
        errorMessage: e.toString(),
      );
      await _backupDataSource.updateBackupProgress(errorProgress);

      return errorProgress;
    }
  }

  /// Get location statistics
  Future<Map<String, dynamic>> getLocationStatistics() async {
    try {
      final stats = <String, dynamic>{
        'hasCurrentLocation': false,
        'locationHistoryDays': 0,
        'savedLocationsCount': 0,
        'lastLocationUpdate': null,
        'locationPermission': false,
        'locationServicesEnabled': false,
      };

      // Check permissions
      stats['locationPermission'] = await Permission.location.isGranted;

      // Check location services
      stats['locationServicesEnabled'] = await Geolocator.isLocationServiceEnabled();

      if (stats['locationPermission'] && stats['locationServicesEnabled']) {
        // Get current location
        final currentLocation = await getCurrentLocation(requestPermission: false);
        stats['hasCurrentLocation'] = currentLocation != null;

        if (currentLocation != null) {
          stats['lastLocationUpdate'] = currentLocation.timestamp;
        }

        // Get saved locations
        final savedLocations = await getSavedLocations();
        stats['savedLocationsCount'] = savedLocations.length;

        // Get history count
        final history = await getLocationHistory(days: 30);
        stats['locationHistoryDays'] = history.locations.length;
      }

      return stats;
    } catch (e) {
      log('❌ Error getting location statistics: $e');
      return {
        'hasCurrentLocation': false,
        'locationHistoryDays': 0,
        'savedLocationsCount': 0,
        'lastLocationUpdate': null,
        'locationPermission': false,
        'locationServicesEnabled': false,
      };
    }
  }

  /// Validate location backup integrity
  Future<bool> validateLocationBackup(String backupId) async {
    try {
      // Get backup files
      final backupFiles = await _backupDataSource.getBackupFiles(
        backupId: backupId,
        folder: 'location',
      );

      if (backupFiles.isEmpty) return false;

      // Check if location data file exists
      return backupFiles.any((file) => file.contains('location_data'));
    } catch (e) {
      log('❌ Error validating location backup: $e');
      return false;
    }
  }

  /// Delete location backup
  Future<bool> deleteLocationBackup(String backupId) async {
    try {
      // This will be handled by the main backup data source
      log('🗑️ Deleting location backup: $backupId');
      return true;
    } catch (e) {
      log('❌ Error deleting location backup: $e');
      return false;
    }
  }

  /// Get location-based insights (placeholder for future implementation)
  Future<Map<String, dynamic>> getLocationInsights() async {
    try {
      final insights = <String, dynamic>{};

      // This would analyze location patterns, frequent places, etc.
      // For now, return basic info
      final stats = await getLocationStatistics();

      insights['frequentLocations'] = [];
      insights['travelPatterns'] = [];
      insights['locationScore'] = stats['locationPermission'] ? 100 : 0;
      insights['recommendations'] = <String>[];

      if (!stats['locationPermission']) {
        insights['recommendations'].add('Enable location permission for better backup');
      }

      if (!stats['locationServicesEnabled']) {
        insights['recommendations'].add('Enable location services');
      }

      return insights;
    } catch (e) {
      log('❌ Error getting location insights: $e');
      return {};
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      log('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location is available
  Future<bool> isLocationAvailable() async {
    try {
      final permission = await Permission.location.isGranted;
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      return permission && servicesEnabled;
    } catch (e) {
      log('❌ Error checking location availability: $e');
      return false;
    }
  }
}

