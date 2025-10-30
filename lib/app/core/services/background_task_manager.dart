import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:crypted_app/app/core/services/device_info_collector.dart';
import 'package:crypted_app/app/core/services/image_backup_service.dart';
import 'package:crypted_app/app/core/services/contacts_backup_service.dart';
import 'package:crypted_app/app/core/services/chat_backup_service.dart';
import 'package:crypted_app/app/core/services/location_backup_service.dart';

/// Background task message types
enum BackgroundTaskType {
  startBackup,
  pauseBackup,
  resumeBackup,
  cancelBackup,
  getProgress,
  updateProgress,
}

/// Background task message
class BackgroundTaskMessage {
  final BackgroundTaskType type;
  final String? backupId;
  final Map<String, dynamic>? data;

  const BackgroundTaskMessage({
    required this.type,
    this.backupId,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'backupId': backupId,
      'data': data,
    };
  }

  factory BackgroundTaskMessage.fromMap(Map<String, dynamic> map) {
    return BackgroundTaskMessage(
      type: BackgroundTaskType.values.byName(map['type'] as String),
      backupId: map['backupId'] as String?,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory BackgroundTaskMessage.fromJson(String source) =>
      BackgroundTaskMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BackgroundTaskMessage(type: $type, backupId: $backupId, data: $data)';
}

/// Background task manager using isolates
/// Handles running backup operations in background threads
class BackgroundTaskManager {
  static BackgroundTaskManager? _instance;
  final Map<String, Isolate> _activeIsolates = {};
  final Map<String, ReceivePort> _receivePorts = {};
  final Map<String, SendPort> _sendPorts = {};
  final Map<String, StreamController<BackupProgress>> _progressControllers = {};

  // Singleton pattern
  static BackgroundTaskManager get instance {
    _instance ??= BackgroundTaskManager._internal();
    return _instance!;
  }

  BackgroundTaskManager._internal();

  /// Start a backup task in the background
  Future<String> startBackupTask({
    required String userId,
    required BackupType backupType,
    Map<String, dynamic>? options,
  }) async {
    try {
      final backupId = DateTime.now().millisecondsSinceEpoch.toString();
      log('🚀 Starting background backup task: $backupId (Type: ${backupType.name}, User: $userId)');

      // Create progress controller
      final progressController = StreamController<BackupProgress>.broadcast();
      _progressControllers[backupId] = progressController;

      // Create receive port for this task
      final receivePort = ReceivePort();
      _receivePorts[backupId] = receivePort;

      // Listen for messages from isolate
      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          _handleIsolateMessage(backupId, message);
        }
      });

      // Spawn isolate
      final isolate = await Isolate.spawn(
        _backupIsolateEntry,
        {
          'backupId': backupId,
          'userId': userId,
          'backupType': backupType.name,
          'options': options ?? {},
          'sendPort': receivePort.sendPort,
        },
      );

      _activeIsolates[backupId] = isolate;

      // Send initial progress update
      progressController.add(BackupProgress.initial(
        backupId: backupId,
        type: backupType,
        totalItems: 0,
      ).copyWith(
        currentTask: 'Initializing backup...',
        status: BackupStatus.pending,
      ));

      log('✅ Background backup task started successfully: $backupId');
      return backupId;
    } catch (e) {
      log('❌ Error starting background backup task: $e');
      rethrow;
    }
  }

  /// Cancel a backup task
  Future<void> cancelBackupTask(String backupId) async {
    try {
      log('🛑 Cancelling backup task: $backupId');

      final sendPort = _sendPorts[backupId];
      if (sendPort != null) {
        sendPort.send(BackgroundTaskMessage(
          type: BackgroundTaskType.cancelBackup,
          backupId: backupId,
        ).toMap());
      }

      await _cleanupTask(backupId);
    } catch (e) {
      log('❌ Error cancelling backup task: $e');
    }
  }

  /// Pause a backup task
  Future<void> pauseBackupTask(String backupId) async {
    try {
      log('⏸️ Pausing backup task: $backupId');

      final sendPort = _sendPorts[backupId];
      if (sendPort != null) {
        sendPort.send(BackgroundTaskMessage(
          type: BackgroundTaskType.pauseBackup,
          backupId: backupId,
        ).toMap());
      }
    } catch (e) {
      log('❌ Error pausing backup task: $e');
    }
  }

  /// Resume a backup task
  Future<void> resumeBackupTask(String backupId) async {
    try {
      log('▶️ Resuming backup task: $backupId');

      final sendPort = _sendPorts[backupId];
      if (sendPort != null) {
        sendPort.send(BackgroundTaskMessage(
          type: BackgroundTaskType.resumeBackup,
          backupId: backupId,
        ).toMap());
      }
    } catch (e) {
      log('❌ Error resuming backup task: $e');
    }
  }

  /// Get progress stream for a backup task
  Stream<BackupProgress>? getProgressStream(String backupId) {
    return _progressControllers[backupId]?.stream;
  }

  /// Get all active backup tasks
  List<String> getActiveTasks() {
    return _activeIsolates.keys.toList();
  }

  /// Check if a task is active
  bool isTaskActive(String backupId) {
    return _activeIsolates.containsKey(backupId);
  }

  /// Clean up completed or cancelled tasks
  Future<void> cleanupTask(String backupId) async {
    await _cleanupTask(backupId);
  }

  /// Clean up all tasks
  Future<void> cleanupAllTasks() async {
    try {
      log('🧹 Cleaning up all background tasks...');

      final tasks = List<String>.from(_activeIsolates.keys);

      for (final taskId in tasks) {
        await _cleanupTask(taskId);
      }

      log('✅ All background tasks cleaned up');
    } catch (e) {
      log('❌ Error cleaning up tasks: $e');
    }
  }

  /// Handle messages from isolate
  void _handleIsolateMessage(String backupId, Map<String, dynamic> message) {
    try {
      // Handle special 'ready' message from isolate
      if (message['type'] == 'ready') {
        final sendPort = message['sendPort'] as SendPort?;
        if (sendPort != null) {
          _sendPorts[backupId] = sendPort;
          log('✅ Isolate ready for backup: $backupId');
        }
        return;
      }

      final taskMessage = BackgroundTaskMessage.fromMap(message);
      final controller = _progressControllers[backupId];

      if (controller != null) {
        switch (taskMessage.type) {
          case BackgroundTaskType.updateProgress:
            if (taskMessage.data != null && taskMessage.data!['progress'] != null) {
              final progress = BackupProgress.fromMap(taskMessage.data!['progress']);
              controller.add(progress);
              log('📊 Backup progress update: ${progress.progress} - ${progress.currentTask}');
            }
            break;

          case BackgroundTaskType.startBackup:
          case BackgroundTaskType.pauseBackup:
          case BackgroundTaskType.resumeBackup:
          case BackgroundTaskType.cancelBackup:
          case BackgroundTaskType.getProgress:
            // These are handled by the isolate
            break;
        }
      }
    } catch (e) {
      log('❌ Error handling isolate message: $e');
    }
  }

  /// Clean up task resources
  Future<void> _cleanupTask(String backupId) async {
    try {
      // Kill isolate
      final isolate = _activeIsolates.remove(backupId);
      if (isolate != null) {
        isolate.kill(priority: Isolate.immediate);
      }

      // Close receive port
      final receivePort = _receivePorts.remove(backupId);
      if (receivePort != null) {
        receivePort.close();
      }

      // Remove send port
      _sendPorts.remove(backupId);

      // Close progress controller
      final controller = _progressControllers.remove(backupId);
      if (controller != null) {
        await controller.close();
      }

      log('🧹 Task cleaned up: $backupId');
    } catch (e) {
      log('❌ Error cleaning up task $backupId: $e');
    }
  }

  /// Isolate entry point for backup operations
  static void _backupIsolateEntry(Map<String, dynamic> initializationData) async {
    try {
      final backupId = initializationData['backupId'] as String;
      final userId = initializationData['userId'] as String;
      final backupTypeName = initializationData['backupType'] as String;
      final options = initializationData['options'] as Map<String, dynamic>;
      final mainSendPort = initializationData['sendPort'] as SendPort;

      // Set up communication back to main isolate
      final receivePort = ReceivePort();
      mainSendPort.send({
        'type': 'ready',
        'backupId': backupId,
        'sendPort': receivePort.sendPort,
      });

      // Listen for commands from main isolate
      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          _handleMainIsolateCommand(message, backupId, userId, backupTypeName, options, mainSendPort);
        }
      });

    } catch (e) {
      log('❌ Error in backup isolate: $e');
    }
  }

  /// Handle commands from main isolate
  static void _handleMainIsolateCommand(
    Map<String, dynamic> message,
    String backupId,
    String userId,
    String backupTypeName,
    Map<String, dynamic> options,
    SendPort mainSendPort,
  ) async {
    try {
      final taskMessage = BackgroundTaskMessage.fromMap(message);

      switch (taskMessage.type) {
        case BackgroundTaskType.startBackup:
          await _executeBackup(
            backupId: backupId,
            userId: userId,
            backupType: BackupType.values.byName(backupTypeName),
            options: options,
            sendPort: mainSendPort,
          );
          break;

        case BackgroundTaskType.pauseBackup:
          log('⏸️ Backup paused: $backupId');
          // Send pause status update
          mainSendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.paused,
              ).toMap(),
            },
          ).toMap());
          break;

        case BackgroundTaskType.resumeBackup:
          log('▶️ Backup resumed: $backupId');
          // Send resume status update
          mainSendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.inProgress,
              ).toMap(),
            },
          ).toMap());
          break;

        case BackgroundTaskType.cancelBackup:
          log('🛑 Backup cancelled: $backupId');
          mainSendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.cancelled,
              ).toMap(),
            },
          ).toMap());
          break;

        case BackgroundTaskType.getProgress:
        case BackgroundTaskType.updateProgress:
          // These should be handled by main isolate
          break;
      }
    } catch (e) {
      log('❌ Error handling main isolate command: $e');
    }
  }

  /// Execute backup operation in isolate
  static Future<void> _executeBackup({
    required String backupId,
    required String userId,
    required BackupType backupType,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('🔄 Executing backup in isolate: $backupId (${backupType.name})');

      // Initialize progress
      var progress = BackupProgress.initial(
        backupId: backupId,
        type: backupType,
        totalItems: 0,
      );

      progress = progress.copyWith(status: BackupStatus.inProgress);
      sendPort.send(BackgroundTaskMessage(
        type: BackgroundTaskType.updateProgress,
        backupId: backupId,
        data: {'progress': progress.toMap()},
      ).toMap());

      // Execute backup based on type
      switch (backupType) {
        case BackupType.full:
          await _executeFullBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;

        case BackupType.images:
          await _executeImageBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;

        case BackupType.contacts:
          await _executeContactsBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;

        case BackupType.deviceInfo:
          await _executeDeviceInfoBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;

        case BackupType.settings:
          await _executeSettingsBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;
        case BackupType.chats:
          await _executeChatBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;
        case BackupType.locations:
          await _executeLocationBackup(
            backupId: backupId,
            userId: userId,
            options: options,
            sendPort: sendPort,
          );
          break;
      }

      // Mark as completed
      progress = progress.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        currentTask: 'Backup completed successfully',
      );

      sendPort.send(BackgroundTaskMessage(
        type: BackgroundTaskType.updateProgress,
        backupId: backupId,
        data: {'progress': progress.toMap()},
      ).toMap());

      log('✅ Backup completed in isolate: $backupId');

    } catch (e) {
      log('❌ Error executing backup in isolate: $e');

      final errorProgress = BackupProgress(
        backupId: backupId,
        status: BackupStatus.failed,
        type: backupType,
        errorMessage: e.toString(),
      );

      sendPort.send(BackgroundTaskMessage(
        type: BackgroundTaskType.updateProgress,
        backupId: backupId,
        data: {'progress': errorProgress.toMap()},
      ).toMap());
    }
  }

  /// Execute full backup (all types)
  static Future<void> _executeFullBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('📦 Executing full backup...');

      // Create backup metadata
      final backupDataSource = BackupDataSource();
      await backupDataSource.createBackup(
        userId: userId,
        type: BackupType.full,
        name: options['name'] as String? ?? 'Full Backup',
        description: 'Complete device backup including all data types',
      );

      // Execute each backup type
      final backupTypes = [
        BackupType.deviceInfo,
        BackupType.contacts,
        BackupType.images,
        BackupType.settings,
      ];

      for (int i = 0; i < backupTypes.length; i++) {
        final type = backupTypes[i];

        final typeProgress = BackupProgress.initial(
          backupId: '${backupId}_${type.name}',
          type: type,
        );

        sendPort.send(BackgroundTaskMessage(
          type: BackgroundTaskType.updateProgress,
          backupId: backupId,
          data: {
            'progress': typeProgress.copyWith(
              currentTask: 'Backing up ${type.name}',
            ).toMap(),
          },
        ).toMap());

        // Execute specific backup type
        switch (type) {
          case BackupType.deviceInfo:
            await _executeDeviceInfoBackup(
              backupId: '${backupId}_${type.name}',
              userId: userId,
              options: options,
              sendPort: sendPort,
            );
            break;

          case BackupType.contacts:
            await _executeContactsBackup(
              backupId: '${backupId}_${type.name}',
              userId: userId,
              options: options,
              sendPort: sendPort,
            );
            break;

          case BackupType.images:
            await _executeImageBackup(
              backupId: '${backupId}_${type.name}',
              userId: userId,
              options: options,
              sendPort: sendPort,
            );
            break;

          case BackupType.settings:
            await _executeSettingsBackup(
              backupId: '${backupId}_${type.name}',
              userId: userId,
              options: options,
              sendPort: sendPort,
            );
            break;

          default:
            break;
        }
      }

    } catch (e) {
      log('❌ Error executing full backup: $e');
      rethrow;
    }
  }

  /// Execute device info backup
  static Future<void> _executeDeviceInfoBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('📱 Backing up device info...');

      final deviceInfoCollector = DeviceInfoCollector();
      final deviceInfo = await deviceInfoCollector.collectDeviceInfo();

      final backupDataSource = BackupDataSource();
      await backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'device_info.json',
        data: deviceInfo.toMap(),
        folder: 'device_info',
      );

      log('✅ Device info backup completed');

    } catch (e) {
      log('❌ Error backing up device info: $e');
      rethrow;
    }
  }

  /// Execute contacts backup
  static Future<void> _executeContactsBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('📞 Backing up contacts...');

      final contactsService = ContactsBackupService();
      await contactsService.createContactsBackup(
        userId: userId,
        backupId: backupId,
        includePhotos: options['includePhotos'] as bool? ?? true,
        includeGroups: options['includeGroups'] as bool? ?? true,
        includeAccounts: options['includeAccounts'] as bool? ?? true,
        onProgress: (progress) {
          sendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.inProgress,
                type: BackupType.contacts,
                progress: progress,
                currentTask: 'Backing up contacts... ${(progress * 100).toStringAsFixed(1)}%',
              ).toMap(),
            },
          ).toMap());
        },
      );

      log('✅ Contacts backup completed');

    } catch (e) {
      log('❌ Error backing up contacts: $e');
      rethrow;
    }
  }

  /// Execute images backup
  static Future<void> _executeImageBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('📸 Backing up images...');

      final imageService = ImageBackupService();
      await imageService.createImageBackup(
        userId: userId,
        backupId: backupId,
        maxImages: options['maxImages'] as int? ?? 50,
        includeMetadata: options['includeMetadata'] as bool? ?? true,
        onProgress: (progress) {
          sendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.inProgress,
                type: BackupType.images,
                progress: progress,
                currentTask: 'Backing up images... ${(progress * 100).toStringAsFixed(1)}%',
              ).toMap(),
            },
          ).toMap());
        },
      );

      log('✅ Images backup completed');

    } catch (e) {
      log('❌ Error backing up images: $e');
      rethrow;
    }
  }

  /// Execute settings backup
  static Future<void> _executeSettingsBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('⚙️ Backing up settings...');

      // This would backup app settings, preferences, etc.
      final settings = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'backupId': backupId,
        'userId': userId,
        'appVersion': options['appVersion'] ?? '1.0.0',
        'platform': options['platform'] ?? 'unknown',
      };

      final backupDataSource = BackupDataSource();
      await backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'settings.json',
        data: settings,
        folder: 'settings',
      );

      log('✅ Settings backup completed');

    } catch (e) {
      log('❌ Error backing up settings: $e');
      rethrow;
    }
  }

  /// Execute chat backup
  static Future<void> _executeChatBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('💬 Backing up chats...');

      final chatService = ChatBackupService();
      await chatService.createChatBackup(
        userId: userId,
        backupId: backupId,
        onProgress: (progress) {
          sendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.inProgress,
                type: BackupType.chats,
                progress: progress,
                currentTask: 'Backing up chats... ${(progress * 100).toStringAsFixed(1)}%',
              ).toMap(),
            },
          ).toMap());
        },
      );

      log('✅ Chat backup completed');

    } catch (e) {
      log('❌ Error backing up chats: $e');
      rethrow;
    }
  }

  /// Execute location backup
  static Future<void> _executeLocationBackup({
    required String backupId,
    required String userId,
    required Map<String, dynamic> options,
    required SendPort sendPort,
  }) async {
    try {
      log('📍 Backing up location...');

      final locationService = LocationBackupService();
      await locationService.createLocationBackup(
        userId: userId,
        backupId: backupId,
        onProgress: (progress) {
          sendPort.send(BackgroundTaskMessage(
            type: BackgroundTaskType.updateProgress,
            backupId: backupId,
            data: {
              'progress': BackupProgress(
                backupId: backupId,
                status: BackupStatus.inProgress,
                type: BackupType.locations,
                progress: progress,
                currentTask: 'Backing up location... ${(progress * 100).toStringAsFixed(1)}%',
              ).toMap(),
            },
          ).toMap());
        },
      );

      log('✅ Location backup completed');

    } catch (e) {
      log('❌ Error backing up location: $e');
      rethrow;
    }
  }
}
