import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:get_storage/get_storage.dart';
import 'enhanced_reliable_backup_service.dart';

/// Backup schedule options
enum BackupSchedule {
  disabled,
  daily,
  weekly,
  monthly,
}

/// Backup scheduler using WorkManager for background tasks
class BackupScheduler {
  static const _taskName = 'auto-backup-task';
  static const _keySchedule = 'backup_schedule';

  static final BackupScheduler instance = BackupScheduler._();
  BackupScheduler._();

  final GetStorage _storage = GetStorage();

  /// Initialize WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false,
    );
    log('✅ BackupScheduler initialized');
  }

  /// Get current schedule
  BackupSchedule getSchedule() {
    final scheduleString = _storage.read(_keySchedule);
    if (scheduleString == null) return BackupSchedule.disabled;

    return BackupSchedule.values.firstWhere(
      (e) => e.name == scheduleString,
      orElse: () => BackupSchedule.disabled,
    );
  }

  /// Set backup schedule
  Future<void> setSchedule(BackupSchedule schedule) async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelByUniqueName(_taskName);

      if (schedule == BackupSchedule.disabled) {
        _storage.write(_keySchedule, schedule.name);
        log('📅 Backup schedule disabled');
        return;
      }

      // Register new task based on schedule
      Duration frequency;
      switch (schedule) {
        case BackupSchedule.daily:
          frequency = Duration(days: 1);
          break;
        case BackupSchedule.weekly:
          frequency = Duration(days: 7);
          break;
        case BackupSchedule.monthly:
          frequency = Duration(days: 30);
          break;
        default:
          return;
      }

      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: Duration(minutes: 30),
      );

      _storage.write(_keySchedule, schedule.name);
      log('📅 Backup schedule set to: ${schedule.name}');

    } catch (e) {
      log('❌ Failed to set backup schedule: $e');
    }
  }

  /// Schedule one-time backup
  Future<void> scheduleOneTimeBackup({
    Duration delay = Duration.zero,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        'one-time-backup-${DateTime.now().millisecondsSinceEpoch}',
        'one-time-backup',
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      log('📅 One-time backup scheduled with delay: ${delay.inMinutes} minutes');
    } catch (e) {
      log('❌ Failed to schedule one-time backup: $e');
    }
  }

  /// Cancel all scheduled backups
  Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      _storage.write(_keySchedule, BackupSchedule.disabled.name);
      log('🗑️ All backup schedules cancelled');
    } catch (e) {
      log('❌ Failed to cancel schedules: $e');
    }
  }

  /// Background task callback dispatcher
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        log('🔄 Background backup task started: $task');

        // Initialize GetStorage for background context
        await GetStorage.init();

        // Initialize the backup service
        final backupService = EnhancedReliableBackupService.instance;
        await backupService.initialize();

        // Run the backup
        final success = await backupService.runFullBackup();

        log(success
            ? '✅ Background backup completed successfully'
            : '❌ Background backup failed');

        return success;

      } catch (e) {
        log('❌ Background backup error: $e');
        return false;
      }
    });
  }
}
