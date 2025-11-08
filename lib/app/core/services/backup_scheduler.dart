import 'dart:async';
import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crypted_app/app/core/services/reliable_backup_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('Background task started: $task');
      await Firebase.initializeApp();

      switch (task) {
        case 'autoBackupTask':
          await _performAutoBackup();
          break;
        case 'dailyBackupUpdate':
          await _performDailyBackupUpdate();
          break;
        default:
          log('Unknown task: $task');
      }

      return Future.value(true);
    } catch (e) {
      log('Background task failed: $e');
      return Future.value(false);
    }
  });
}

Future<void> _performAutoBackup() async {
  try {
    log('Starting automatic backup');
    final backupService = ReliableBackupService.instance;
    final success = await backupService.runFullBackup();
    if (success) {
      log('Automatic backup completed successfully');
    }
  } catch (e) {
    log('Error performing auto backup: $e');
  }
}

Future<void> _performDailyBackupUpdate() async {
  try {
    log('Starting daily backup update');
    final backupService = ReliableBackupService.instance;
    final success = await backupService.runFullBackup();
    if (success) {
      log('Daily backup update completed successfully');
    }
  } catch (e) {
    log('Error performing daily backup update: $e');
  }
}

class BackupScheduler {
  static final BackupScheduler _instance = BackupScheduler._internal();
  factory BackupScheduler() => _instance;
  BackupScheduler._internal();

  static BackupScheduler get instance => _instance;

  Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      log('Backup scheduler initialized');
    } catch (e) {
      log('Error initializing backup scheduler: $e');
    }
  }

  Future<void> scheduleDailyBackupUpdate() async {
    try {
      await Workmanager().cancelByUniqueName('dailyBackupUpdate');

      final now = DateTime.now();
      var nextRun = DateTime(now.year, now.month, now.day, 2, 0);

      if (now.hour >= 2) {
        nextRun = nextRun.add(const Duration(days: 1));
      }

      final initialDelay = nextRun.difference(now);

      await Workmanager().registerPeriodicTask(
        'dailyBackupUpdate',
        'dailyBackupUpdate',
        frequency: const Duration(days: 1),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
      );

      log('Scheduled daily backup update at 2 AM');
    } catch (e) {
      log('Error scheduling daily backup update: $e');
    }
  }

  Future<void> cancelDailyBackupUpdate() async {
    try {
      await Workmanager().cancelByUniqueName('dailyBackupUpdate');
      log('Cancelled daily backup update');
    } catch (e) {
      log('Error cancelling daily backup update: $e');
    }
  }

  Future<void> cancelAllBackupTasks() async {
    try {
      await Workmanager().cancelAll();
      log('Cancelled all backup tasks');
    } catch (e) {
      log('Error cancelling backup tasks: $e');
    }
  }
}
