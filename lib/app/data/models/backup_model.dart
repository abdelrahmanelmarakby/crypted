// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Backup status enumeration
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Backup type enumeration
enum BackupType {
  full,
  chats,
  locations,
  images,
  contacts,
  deviceInfo,
  settings,
}

/// Device information model for backup
class DeviceInfo {
  final String? deviceName;
  final String? deviceModel;
  final String? operatingSystem;
  final String? osVersion;
  final String? deviceId;
  final String? brand;
  final int? totalStorage;
  final int? availableStorage;
  final String? batteryLevel;
  final String? networkType;
  final String? location;
  final DateTime? timestamp;

  const DeviceInfo({
    this.deviceName,
    this.deviceModel,
    this.operatingSystem,
    this.osVersion,
    this.deviceId,
    this.brand,
    this.totalStorage,
    this.availableStorage,
    this.batteryLevel,
    this.networkType,
    this.location,
    this.timestamp,
  });

  /// Factory method to create device info with current timestamp
  factory DeviceInfo.now({
    String? deviceName,
    String? deviceModel,
    String? operatingSystem,
    String? osVersion,
    String? deviceId,
    String? brand,
    int? totalStorage,
    int? availableStorage,
    String? batteryLevel,
    String? networkType,
    String? location,
  }) {
    return DeviceInfo(
      deviceName: deviceName,
      deviceModel: deviceModel,
      operatingSystem: operatingSystem,
      osVersion: osVersion,
      deviceId: deviceId,
      brand: brand,
      totalStorage: totalStorage,
      availableStorage: availableStorage,
      batteryLevel: batteryLevel,
      networkType: networkType,
      location: location,
      timestamp: DateTime.now(),
    );
  }

  DeviceInfo copyWith({
    String? deviceName,
    String? deviceModel,
    String? operatingSystem,
    String? osVersion,
    String? deviceId,
    String? brand,
    int? totalStorage,
    int? availableStorage,
    String? batteryLevel,
    String? networkType,
    String? location,
    DateTime? timestamp,
  }) {
    return DeviceInfo(
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      osVersion: osVersion ?? this.osVersion,
      deviceId: deviceId ?? this.deviceId,
      brand: brand ?? this.brand,
      totalStorage: totalStorage ?? this.totalStorage,
      availableStorage: availableStorage ?? this.availableStorage,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      networkType: networkType ?? this.networkType,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'osVersion': osVersion,
      'deviceId': deviceId,
      'brand': brand,
      'totalStorage': totalStorage,
      'availableStorage': availableStorage,
      'batteryLevel': batteryLevel,
      'networkType': networkType,
      'location': location,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceName: map['deviceName'] as String?,
      deviceModel: map['deviceModel'] as String?,
      operatingSystem: map['operatingSystem'] as String?,
      osVersion: map['osVersion'] as String?,
      deviceId: map['deviceId'] as String?,
      brand: map['brand'] as String?,
      totalStorage: map['totalStorage'] as int?,
      availableStorage: map['availableStorage'] as int?,
      batteryLevel: map['batteryLevel'] as String?,
      networkType: map['networkType'] as String?,
      location: map['location'] as String?,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceInfo.fromJson(String source) => DeviceInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DeviceInfo(deviceName: $deviceName, deviceModel: $deviceModel, operatingSystem: $operatingSystem, osVersion: $osVersion, deviceId: $deviceId, brand: $brand, totalStorage: $totalStorage, availableStorage: $availableStorage, batteryLevel: $batteryLevel, networkType: $networkType, location: $location, timestamp: $timestamp)';
  }

  @override
  bool operator ==(covariant DeviceInfo other) {
    if (identical(this, other)) return true;

    return other.deviceName == deviceName &&
        other.deviceModel == deviceModel &&
        other.operatingSystem == operatingSystem &&
        other.osVersion == osVersion &&
        other.deviceId == deviceId &&
        other.brand == brand &&
        other.totalStorage == totalStorage &&
        other.availableStorage == availableStorage &&
        other.batteryLevel == batteryLevel &&
        other.networkType == networkType &&
        other.location == location &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return deviceName.hashCode ^
        deviceModel.hashCode ^
        operatingSystem.hashCode ^
        osVersion.hashCode ^
        deviceId.hashCode ^
        brand.hashCode ^
        totalStorage.hashCode ^
        availableStorage.hashCode ^
        batteryLevel.hashCode ^
        networkType.hashCode ^
        location.hashCode ^
        timestamp.hashCode;
  }
}

/// Backup progress model for tracking backup status
class BackupProgress {
  final String? backupId;
  final BackupStatus? status;
  final BackupType? type;
  final double? progress;
  final int? totalItems;
  final int? completedItems;
  final String? currentTask;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const BackupProgress({
    this.backupId,
    this.status,
    this.type,
    this.progress,
    this.totalItems,
    this.completedItems,
    this.currentTask,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.metadata,
  });

  /// Factory method to create initial backup progress
  factory BackupProgress.initial({
    String? backupId,
    BackupType? type,
    int? totalItems,
  }) {
    return BackupProgress(
      backupId: backupId,
      status: BackupStatus.pending,
      type: type,
      progress: 0.0,
      totalItems: totalItems,
      completedItems: 0,
      startTime: DateTime.now(),
      metadata: {},
    );
  }

  /// Factory method to create in-progress backup
  factory BackupProgress.inProgress({
    String? backupId,
    BackupType? type,
    double? progress,
    int? totalItems,
    int? completedItems,
    String? currentTask,
  }) {
    return BackupProgress(
      backupId: backupId,
      status: BackupStatus.inProgress,
      type: type,
      progress: progress,
      totalItems: totalItems,
      completedItems: completedItems,
      currentTask: currentTask,
      startTime: DateTime.now(),
      metadata: {},
    );
  }

  BackupProgress copyWith({
    String? backupId,
    BackupStatus? status,
    BackupType? type,
    double? progress,
    int? totalItems,
    int? completedItems,
    String? currentTask,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return BackupProgress(
      backupId: backupId ?? this.backupId,
      status: status ?? this.status,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      currentTask: currentTask ?? this.currentTask,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backupId': backupId,
      'status': status?.name,
      'type': type?.name,
      'progress': progress,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'currentTask': currentTask,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory BackupProgress.fromMap(Map<String, dynamic> map) {
    return BackupProgress(
      backupId: map['backupId'] as String?,
      status: map['status'] != null ? BackupStatus.values.byName(map['status'] as String) : null,
      type: map['type'] != null ? BackupType.values.byName(map['type'] as String) : null,
      progress: map['progress'] as double?,
      totalItems: map['totalItems'] as int?,
      completedItems: map['completedItems'] as int?,
      currentTask: map['currentTask'] as String?,
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      errorMessage: map['errorMessage'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BackupProgress.fromJson(String source) => BackupProgress.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BackupProgress(backupId: $backupId, status: $status, type: $type, progress: $progress, totalItems: $totalItems, completedItems: $completedItems, currentTask: $currentTask, startTime: $startTime, endTime: $endTime, errorMessage: $errorMessage, metadata: $metadata)';
  }

  @override
  bool operator ==(covariant BackupProgress other) {
    if (identical(this, other)) return true;

    return other.backupId == backupId &&
        other.status == status &&
        other.type == type &&
        other.progress == progress &&
        other.totalItems == totalItems &&
        other.completedItems == completedItems &&
        other.currentTask == currentTask &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.errorMessage == errorMessage &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return backupId.hashCode ^
        status.hashCode ^
        type.hashCode ^
        progress.hashCode ^
        totalItems.hashCode ^
        completedItems.hashCode ^
        currentTask.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        errorMessage.hashCode ^
        metadata.hashCode;
  }
}

/// Backup metadata model for storing backup information
class BackupMetadata {
  final String? backupId;
  final String? userId;
  final BackupType? type;
  final String? name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? totalSize;
  final int? itemCount;
  final List<String>? imageUrls;
  final Map<String, dynamic>? settings;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? additionalData;
  final bool? isEncrypted;
  final String? version;

  const BackupMetadata({
    this.backupId,
    this.userId,
    this.type,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.totalSize,
    this.itemCount,
    this.imageUrls,
    this.settings,
    this.deviceInfo,
    this.additionalData,
    this.isEncrypted,
    this.version,
  });

  /// Factory method to create backup metadata
  factory BackupMetadata.create({
    String? backupId,
    required String userId,
    required BackupType type,
    String? name,
    String? description,
    int? totalSize,
    int? itemCount,
    List<String>? imageUrls,
    Map<String, dynamic>? settings,
    DeviceInfo? deviceInfo,
    Map<String, dynamic>? additionalData,
    bool? isEncrypted,
    String? version,
  }) {
    final now = DateTime.now();
    return BackupMetadata(
      backupId: backupId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      name: name ?? '${type.name}_backup_${now.toIso8601String().split('T')[0]}',
      description: description ?? 'Auto backup of ${type.name}',
      createdAt: now,
      updatedAt: now,
      totalSize: totalSize,
      itemCount: itemCount,
      imageUrls: imageUrls,
      settings: settings,
      deviceInfo: deviceInfo,
      additionalData: additionalData,
      isEncrypted: isEncrypted ?? false,
      version: version ?? '1.0.0',
    );
  }

  BackupMetadata copyWith({
    String? backupId,
    String? userId,
    BackupType? type,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalSize,
    int? itemCount,
    List<String>? imageUrls,
    Map<String, dynamic>? settings,
    DeviceInfo? deviceInfo,
    Map<String, dynamic>? additionalData,
    bool? isEncrypted,
    String? version,
  }) {
    return BackupMetadata(
      backupId: backupId ?? this.backupId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalSize: totalSize ?? this.totalSize,
      itemCount: itemCount ?? this.itemCount,
      imageUrls: imageUrls ?? this.imageUrls,
      settings: settings ?? this.settings,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      additionalData: additionalData ?? this.additionalData,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backupId': backupId,
      'userId': userId,
      'type': type?.name,
      'name': name,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalSize': totalSize,
      'itemCount': itemCount,
      'imageUrls': imageUrls,
      'settings': settings,
      'deviceInfo': deviceInfo?.toMap(),
      'additionalData': additionalData,
      'isEncrypted': isEncrypted,
      'version': version,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      backupId: map['backupId'] as String?,
      userId: map['userId'] as String?,
      type: map['type'] != null ? BackupType.values.byName(map['type'] as String) : null,
      name: map['name'] as String?,
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      totalSize: map['totalSize'] as int?,
      itemCount: map['itemCount'] as int?,
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls'] as List) : null,
      settings: map['settings'] != null ? Map<String, dynamic>.from(map['settings'] as Map) : null,
      deviceInfo: map['deviceInfo'] != null ? DeviceInfo.fromMap(map['deviceInfo'] as Map<String, dynamic>) : null,
      additionalData: map['additionalData'] != null ? Map<String, dynamic>.from(map['additionalData'] as Map) : null,
      isEncrypted: map['isEncrypted'] as bool?,
      version: map['version'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory BackupMetadata.fromJson(String source) => BackupMetadata.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BackupMetadata(backupId: $backupId, userId: $userId, type: $type, name: $name, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, totalSize: $totalSize, itemCount: $itemCount, imageUrls: $imageUrls, settings: $settings, deviceInfo: $deviceInfo, additionalData: $additionalData, isEncrypted: $isEncrypted, version: $version)';
  }

  @override
  bool operator ==(covariant BackupMetadata other) {
    if (identical(this, other)) return true;

    return other.backupId == backupId &&
        other.userId == userId &&
        other.type == type &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.totalSize == totalSize &&
        other.itemCount == itemCount &&
        listEquals(other.imageUrls, imageUrls) &&
        mapEquals(other.settings, settings) &&
        other.deviceInfo == deviceInfo &&
        mapEquals(other.additionalData, additionalData) &&
        other.isEncrypted == isEncrypted &&
        other.version == version;
  }

  @override
  int get hashCode {
    return backupId.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        totalSize.hashCode ^
        itemCount.hashCode ^
        imageUrls.hashCode ^
        settings.hashCode ^
        deviceInfo.hashCode ^
        additionalData.hashCode ^
        isEncrypted.hashCode ^
        version.hashCode;
  }
}
