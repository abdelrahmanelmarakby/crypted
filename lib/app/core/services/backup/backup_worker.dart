import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/core/services/backup/strategies/chat_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/media_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/contacts_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/device_info_backup_strategy.dart';
import 'package:crypted_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

/// **Unstoppable Backup Worker**
///
/// This worker ensures backups run to completion even if:
/// - App is killed by user
/// - App is killed by system (low memory)
/// - Device restarts
/// - User navigates away
///
/// **How it works:**
/// 1. Runs in separate isolate (independent of main app)
/// 2. Uses WorkManager for OS-level task scheduling
/// 3. Persists state in Firestore (survives device restart)
/// 4. Automatic retry with exponential backoff
///
/// **Technical Details:**
/// - WorkManager on Android: Uses JobScheduler/AlarmManager
/// - WorkManager on iOS: Uses BackgroundTasks API (iOS 13+)
/// - Isolate communication: SendPort for progress updates
/// - Retry strategy: 30s, 1m, 2m, 5m, 10m (max 5 retries)

/// Main callback dispatcher for WorkManager
///
/// This runs in a separate isolate with its own memory space
/// @pragma ensures it's not tree-shaken during compilation
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('🔧 [Isolate] WorkManager task started: $task');

    try {
      // Initialize Firebase in this isolate
      await _initializeFirebaseInIsolate();

      // Parse backup job data
      final backupJobData = inputData?['backupJob'] as Map<String, dynamic>?;
      if (backupJobData == null) {
        log('❌ [Isolate] No backup job data provided');
        return Future.value(false);
      }

      final backupJob = BackupJob.fromJson(backupJobData);
      log('📦 [Isolate] Executing backup job: ${backupJob.id}');

      // Execute backup in this isolate
      final success = await _executeBackupInIsolate(backupJob);

      if (success) {
        log('✅ [Isolate] Backup completed: ${backupJob.id}');
        return Future.value(true);
      } else {
        log('❌ [Isolate] Backup failed: ${backupJob.id}');
        // Return false to trigger WorkManager retry
        return Future.value(false);
      }

    } catch (e, stackTrace) {
      log('❌ [Isolate] Fatal error in backup task: $e', stackTrace: stackTrace);
      return Future.value(false); // Trigger retry
    }
  });
}

/// Initialize Firebase in the isolate
Future<void> _initializeFirebaseInIsolate() async {
  try {
    // CRITICAL: Ensure Flutter bindings are initialized in background isolate
    // This must be called before any platform channel operations
    WidgetsFlutterBinding.ensureInitialized();

    // Check if already initialized
    if (Firebase.apps.isNotEmpty) {
      log('✅ [Isolate] Firebase already initialized');
      return;
    }

    // Initialize Firebase with error handling for "already initialized" case
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log('✅ [Isolate] Firebase initialized in isolate');
    } on FirebaseException catch (e) {
      // Handle "already exists" error gracefully
      if (e.code == 'duplicate-app' || e.message?.contains('already exists') == true) {
        log('✅ [Isolate] Firebase app already exists, using existing instance');
      } else {
        rethrow;
      }
    }
  } catch (e, stackTrace) {
    // Log but don't rethrow - try to continue with existing Firebase instance
    log('⚠️ [Isolate] Firebase initialization warning: $e');
    log('$stackTrace');

    // If Firebase.apps is not empty, we can still proceed
    if (Firebase.apps.isNotEmpty) {
      log('✅ [Isolate] Proceeding with existing Firebase instance');
      return;
    }

    // Only rethrow if we truly have no Firebase instance
    rethrow;
  }
}

/// Execute backup in isolate (completely independent of main app)
Future<bool> _executeBackupInIsolate(BackupJob job) async {
  final firestore = FirebaseFirestore.instance;
  int retryCount = 0;
  const maxRetries = 5;
  const retryDelays = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  while (retryCount <= maxRetries) {
    try {
      // Update job status to running
      await firestore.collection('backup_jobs').doc(job.id).update({
        'status': BackupStatus.running.name,
        'startedAt': FieldValue.serverTimestamp(),
        'retryCount': retryCount,
      });

      // Execute each backup type sequentially
      int totalItems = 0;
      int processedItems = 0;
      int failedItems = 0;
      int bytesTransferred = 0;

      for (final backupType in job.types) {
        try {
          log('🔄 [Isolate] Starting ${backupType.name} backup...');

          // Create backup context
          final context = BackupContext(
            userId: job.userId,
            backupId: job.id,
            options: job.options,
            firestore: firestore,
          );

          // Get strategy and execute
          final strategy = _getStrategy(backupType);
          final result = await strategy.execute(context);

          totalItems += result.totalItems;
          processedItems += result.successfulItems;
          failedItems += result.failedItems;
          bytesTransferred += result.bytesTransferred;

          // Update progress in Firestore
          await firestore.collection('backup_jobs').doc(job.id).update({
            'totalItems': totalItems,
            'processedItems': processedItems,
            'failedItems': failedItems,
            'bytesTransferred': bytesTransferred,
            'currentType': backupType.name,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          log('✅ [Isolate] ${backupType.name} backup completed: ${result.successfulItems}/${result.totalItems}');

        } catch (e) {
          log('❌ [Isolate] ${backupType.name} backup failed: $e');
          failedItems++;
        }
      }

      // Mark as completed or partial success
      final status = failedItems == 0
          ? BackupStatus.completed
          : (processedItems > 0
              ? BackupStatus.partialSuccess
              : BackupStatus.failed);

      await firestore.collection('backup_jobs').doc(job.id).update({
        'status': status.name,
        'completedAt': FieldValue.serverTimestamp(),
        'totalItems': totalItems,
        'processedItems': processedItems,
        'failedItems': failedItems,
        'bytesTransferred': bytesTransferred,
      });

      log('✅ [Isolate] Backup job completed with status: ${status.name}');
      return true;

    } catch (e, stackTrace) {
      log('❌ [Isolate] Backup attempt ${retryCount + 1} failed: $e',
          stackTrace: stackTrace);

      retryCount++;

      if (retryCount <= maxRetries) {
        final delay = retryDelays[retryCount - 1];
        log('⏳ [Isolate] Retrying in ${delay.inSeconds}s...');

        // Update retry status in Firestore
        await firestore.collection('backup_jobs').doc(job.id).update({
          'status': BackupStatus.paused.name,
          'retryCount': retryCount,
          'lastError': e.toString(),
          'nextRetryAt': FieldValue.serverTimestamp(),
        });

        await Future.delayed(delay);
      } else {
        log('❌ [Isolate] Max retries reached, marking as failed');

        // Mark as permanently failed
        await firestore.collection('backup_jobs').doc(job.id).update({
          'status': BackupStatus.failed.name,
          'failedAt': FieldValue.serverTimestamp(),
          'errorMessage': 'Max retries exceeded: $e',
        });

        return false;
      }
    }
  }

  return false;
}

/// Get strategy instance for backup type
BackupStrategy _getStrategy(BackupType type) {
  switch (type) {
    case BackupType.chats:
      return ChatBackupStrategy();
    case BackupType.media:
      return MediaBackupStrategy();
    case BackupType.contacts:
      return ContactsBackupStrategy();
    case BackupType.deviceInfo:
      return DeviceInfoBackupStrategy();
  }
}

/// BackupWorker - Main interface for scheduling unstoppable backups
class BackupWorker {
  static final BackupWorker _instance = BackupWorker._internal();
  static BackupWorker get instance => _instance;
  BackupWorker._internal();

  bool _isInitialized = false;

  /// Initialize WorkManager
  ///
  /// Call this ONCE during app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );

      _isInitialized = true;
      log('✅ BackupWorker initialized with WorkManager');
    } catch (e, stackTrace) {
      log('❌ Failed to initialize BackupWorker: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Schedule unstoppable backup task
  ///
  /// This backup will run to completion even if:
  /// - App is killed
  /// - Device restarts
  /// - User navigates away
  Future<void> scheduleBackup(BackupJob job) async {
    if (!_isInitialized) {
      throw Exception('BackupWorker not initialized. Call initialize() first.');
    }

    try {
      await Workmanager().registerOneOffTask(
        job.id, // Unique task ID
        'backup_task', // Task name (must match in callbackDispatcher)
        inputData: {
          'backupJob': job.toJson(),
        },
        constraints: Constraints(
          networkType: job.options.wifiOnly
              ? NetworkType.unmetered // WiFi only
              : NetworkType.connected, // Any network
          requiresBatteryNotLow: job.options.minBatteryPercent > 20,
          requiresCharging: false,
          requiresStorageNotLow: true, // Don't backup if storage is low
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: Duration(seconds: 30),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      log('✅ Unstoppable backup scheduled: ${job.id}');
      log('   WiFi only: ${job.options.wifiOnly}');
      log('   Min battery: ${job.options.minBatteryPercent}%');
      log('   Types: ${job.types.map((t) => t.name).join(", ")}');

    } catch (e, stackTrace) {
      log('❌ Failed to schedule backup: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Schedule periodic backup (daily/weekly)
  ///
  /// Runs automatically in the background
  Future<void> schedulePeriodicBackup({
    required String taskId,
    required Set<BackupType> types,
    required BackupOptions options,
    required Duration frequency,
    Duration? initialDelay,
  }) async {
    if (!_isInitialized) {
      throw Exception('BackupWorker not initialized. Call initialize() first.');
    }

    try {
      // Create a template backup job
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final job = BackupJob(
        id: '${taskId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        types: types,
        options: options,
        createdAt: DateTime.now(),
        status: BackupStatus.queued,
      );

      await Workmanager().registerPeriodicTask(
        taskId,
        'backup_task',
        frequency: frequency,
        initialDelay: initialDelay ?? Duration.zero,
        inputData: {
          'backupJob': job.toJson(),
          'isPeriodic': true,
        },
        constraints: Constraints(
          networkType: options.wifiOnly
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresBatteryNotLow: options.minBatteryPercent > 20,
          requiresCharging: false,
          requiresStorageNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      log('✅ Periodic backup scheduled: $taskId');
      log('   Frequency: ${frequency.inHours}h');
      log('   Types: ${types.map((t) => t.name).join(", ")}');

    } catch (e, stackTrace) {
      log('❌ Failed to schedule periodic backup: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Cancel specific backup task
  Future<void> cancelBackup(String taskId) async {
    await Workmanager().cancelByUniqueName(taskId);
    log('✅ Backup task canceled: $taskId');
  }

  /// Cancel all backup tasks
  Future<void> cancelAllBackups() async {
    await Workmanager().cancelAll();
    log('✅ All backup tasks canceled');
  }

  /// Check if a backup task is scheduled
  Future<bool> isBackupScheduled(String taskId) async {
    // WorkManager doesn't provide a direct way to check
    // We can check Firestore for the backup job status
    try {
      final doc = await FirebaseFirestore.instance
          .collection('backup_jobs')
          .doc(taskId)
          .get();

      if (!doc.exists) return false;

      final status = doc.data()?['status'] as String?;
      return status == BackupStatus.queued.name ||
          status == BackupStatus.running.name ||
          status == BackupStatus.paused.name;
    } catch (e) {
      return false;
    }
  }
}

/// Extension to add to BackupServiceV3
extension BackupServiceV3Extensions on BackupServiceV3 {
  /// Schedule nightly backup (runs at 2 AM daily)
  Future<void> scheduleNightlyBackup({
    required Set<BackupType> types,
    BackupOptions? options,
  }) async {
    await BackupWorker.instance.schedulePeriodicBackup(
      taskId: 'nightly_backup',
      types: types,
      options: options ?? BackupOptions.defaults(),
      frequency: Duration(hours: 24),
      initialDelay: _calculateDelayUntil2AM(),
    );

    log('✅ Nightly backup scheduled for 2 AM');
  }

  /// Schedule weekly backup (runs Sunday at 2 AM)
  Future<void> scheduleWeeklyBackup({
    required Set<BackupType> types,
    BackupOptions? options,
  }) async {
    await BackupWorker.instance.schedulePeriodicBackup(
      taskId: 'weekly_backup',
      types: types,
      options: options ?? BackupOptions.defaults(),
      frequency: Duration(days: 7),
      initialDelay: _calculateDelayUntilSunday2AM(),
    );

    log('✅ Weekly backup scheduled for Sunday 2 AM');
  }

  /// Calculate delay until 2 AM tomorrow
  Duration _calculateDelayUntil2AM() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 2, 0);

    if (now.hour >= 2) {
      target = target.add(Duration(days: 1));
    }

    return target.difference(now);
  }

  /// Calculate delay until Sunday 2 AM
  Duration _calculateDelayUntilSunday2AM() {
    final now = DateTime.now();
    var daysUntilSunday = (DateTime.sunday - now.weekday) % 7;

    if (daysUntilSunday == 0 && now.hour >= 2) {
      daysUntilSunday = 7; // Next Sunday
    }

    var target = DateTime(now.year, now.month, now.day, 2, 0)
        .add(Duration(days: daysUntilSunday));

    return target.difference(now);
  }
}
