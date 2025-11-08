import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/reliable_backup_service.dart';
import 'package:crypted_app/app/core/services/backup_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackupController extends GetxController {
  // Singleton instance
  static BackupController get instance => Get.find();

  // Backup service
  final _backupService = ReliableBackupService.instance;

  // Observable states
  final RxBool isBackupRunning = false.obs;
  final RxDouble backupProgress = 0.0.obs;
  final RxString backupStatus = 'Ready to backup'.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Backup history
  final RxList<BackupHistoryItem> backupHistory = <BackupHistoryItem>[].obs;
  final Rx<DateTime?> lastBackupDate = Rx<DateTime?>(null);
  final Rx<Map<String, dynamic>?> lastBackupStats = Rx<Map<String, dynamic>?>(null);

  // Settings
  final RxBool autoBackupEnabled = false.obs;
  final RxInt autoBackupInterval = 24.obs; // hours
  final RxBool backupOnWifiOnly = true.obs;
  final RxBool showNotifications = true.obs;

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Streams
  StreamSubscription? _progressSubscription;
  StreamSubscription? _statusSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _subscribeToBackupProgress();
    _loadBackupHistory();
    _loadSettings();
    _initializeBackupScheduler();
  }

  /// Initialize backup scheduler with daily cron job
  Future<void> _initializeBackupScheduler() async {
    try {
      await BackupScheduler.instance.initialize();
      await BackupScheduler.instance.scheduleDailyBackupUpdate();
      log('✅ Backup scheduler initialized with daily cron job');
    } catch (e) {
      log('❌ Error initializing backup scheduler: $e');
    }
  }

  @override
  void onClose() {
    _progressSubscription?.cancel();
    _statusSubscription?.cancel();
    super.onClose();
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Subscribe to backup progress and status streams
  void _subscribeToBackupProgress() {
    _progressSubscription = _backupService.progressStream.listen((progress) {
      backupProgress.value = progress;

      // Update notification with progress
      if (showNotifications.value && isBackupRunning.value) {
        _showProgressNotification(progress);
      }
    });

    _statusSubscription = _backupService.statusStream.listen((status) {
      backupStatus.value = status;
      log('📊 Backup status: $status');
    });
  }

  /// Public method to refresh backup history
  Future<void> refreshBackupHistory() async {
    await _loadBackupHistory();
  }

  /// Load backup history from Firestore
  Future<void> _loadBackupHistory() async {
    try {
      final backupData = await _backupService.getBackupStatus();

      if (backupData != null) {
        lastBackupDate.value = backupData['last_backup_completed_at']?.toDate();
        lastBackupStats.value = backupData;

        // Create history item
        if (lastBackupDate.value != null) {
          backupHistory.insert(0, BackupHistoryItem(
            date: lastBackupDate.value!,
            success: true,
            itemsBackedUp: (backupData['contacts_count'] ?? 0) +
                          (backupData['images_count'] ?? 0) +
                          (backupData['files_count'] ?? 0),
            stats: backupData,
          ));
        }
      }
    } catch (e) {
      log('Error loading backup history: $e');
    }
  }

  /// Load backup settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      autoBackupEnabled.value = prefs.getBool('backup_auto_enabled') ?? false;
      autoBackupInterval.value = prefs.getInt('backup_interval') ?? 24;
      backupOnWifiOnly.value = prefs.getBool('backup_wifi_only') ?? true;
      showNotifications.value = prefs.getBool('backup_show_notifications') ?? true;

      log('📱 Loaded backup settings: auto=$autoBackupEnabled, interval=$autoBackupInterval');
    } catch (e) {
      log('Error loading backup settings: $e');
    }
  }

  /// Save backup settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backup_auto_enabled', autoBackupEnabled.value);
      await prefs.setInt('backup_interval', autoBackupInterval.value);
      await prefs.setBool('backup_wifi_only', backupOnWifiOnly.value);
      await prefs.setBool('backup_show_notifications', showNotifications.value);

      log('💾 Saved backup settings');
    } catch (e) {
      log('Error saving backup settings: $e');
    }
  }

  /// Start backup process
  Future<void> startBackup() async {
    if (isBackupRunning.value) {
      Get.snackbar(
        'Backup In Progress',
        'A backup is already running',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isBackupRunning.value = true;
      hasError.value = false;
      errorMessage.value = '';
      backupProgress.value = 0.0;
      backupStatus.value = 'Starting backup...';

      // Show initial notification
      if (showNotifications.value) {
        await _showNotification(
          'Backup Started',
          'Your data backup has started',
        );
      }

      // Run the backup
      final success = await _backupService.runFullBackup();

      if (success) {
        // Backup completed successfully
        backupProgress.value = 1.0;
        backupStatus.value = 'Backup completed successfully!';

        // Reload history
        await _loadBackupHistory();

        // Show success notification
        if (showNotifications.value) {
          await _showNotification(
            'Backup Complete ✅',
            'All your data has been backed up successfully',
          );
        }

        Get.snackbar(
          'Success',
          'Backup completed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Backup failed
        hasError.value = true;
        errorMessage.value = 'Backup failed or was cancelled';
        backupStatus.value = 'Backup failed';

        if (showNotifications.value) {
          await _showNotification(
            'Backup Failed ❌',
            'There was an error backing up your data',
          );
        }

        Get.snackbar(
          'Error',
          'Backup failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
        );
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      backupStatus.value = 'Error: ${e.toString()}';

      log('❌ Backup error: $e');

      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    } finally {
      isBackupRunning.value = false;
    }
  }

  /// Stop backup process
  void stopBackup() {
    if (!isBackupRunning.value) return;

    _backupService.stopBackup();
    backupStatus.value = 'Backup stopped by user';

    Get.snackbar(
      'Stopped',
      'Backup has been stopped',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show notification
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Notifications',
      channelDescription: 'Notifications for backup progress and status',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Show progress notification
  Future<void> _showProgressNotification(double progress) async {
    final percentage = (progress * 100).toInt();

    final androidDetails = AndroidNotificationDetails(
      'backup_progress_channel',
      'Backup Progress',
      channelDescription: 'Shows backup progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      ongoing: true,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      'Backing up your data...',
      '$percentage% complete',
      details,
    );
  }

  /// Get formatted last backup date
  String get lastBackupDateFormatted {
    if (lastBackupDate.value == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastBackupDate.value!);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${(diff.inDays / 7).floor()} weeks ago';
    }
  }

  /// Get backup stats summary
  String get backupStatsSummary {
    if (lastBackupStats.value == null) return 'No backup data';

    final stats = lastBackupStats.value!;
    final contacts = stats['contacts_count'] ?? 0;
    final images = stats['images_count'] ?? 0;
    final files = stats['files_count'] ?? 0;

    return '$contacts contacts, $images images, $files files';
  }

  /// Toggle auto backup
  Future<void> toggleAutoBackup(bool value) async {
    autoBackupEnabled.value = value;
    await _saveSettings();

    if (value) {
      await _scheduleAutoBackup();
    } else {
      await _cancelAutoBackup();
    }
  }

  /// Update auto backup interval
  Future<void> updateAutoBackupInterval(int hours) async {
    autoBackupInterval.value = hours;
    await _saveSettings();

    if (autoBackupEnabled.value) {
      await _scheduleAutoBackup();
    }
  }

  /// Toggle backup on WiFi only
  Future<void> toggleBackupOnWifiOnly(bool value) async {
    backupOnWifiOnly.value = value;
    await _saveSettings();
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    showNotifications.value = value;
    await _saveSettings();
  }

  /// Schedule automatic backup
  Future<void> _scheduleAutoBackup() async {
    try {
      // iOS doesn't support periodic tasks in Workmanager
      if (Platform.isIOS) {
        log('⚠️ iOS does not support background periodic tasks. Auto backup disabled on iOS.');
        Get.snackbar(
          'Info',
          'Auto backup is only available on Android devices',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        autoBackupEnabled.value = false;
        await _saveSettings();
        return;
      }

      await Workmanager().cancelByUniqueName('autoBackup');

      await Workmanager().registerPeriodicTask(
        'autoBackup',
        'autoBackupTask',
        frequency: Duration(hours: autoBackupInterval.value),
        initialDelay: Duration(hours: autoBackupInterval.value),
        constraints: Constraints(
          networkType: backupOnWifiOnly.value
            ? NetworkType.unmetered
            : NetworkType.connected,
        ),
      );

      log('📅 Scheduled auto backup every ${autoBackupInterval.value} hours');
    } catch (e) {
      log('Error scheduling auto backup: $e');
      Get.snackbar(
        'Error',
        'Failed to schedule auto backup: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Cancel automatic backup
  Future<void> _cancelAutoBackup() async {
    try {
      await Workmanager().cancelByUniqueName('autoBackup');
      log('🚫 Cancelled auto backup');
    } catch (e) {
      log('Error cancelling auto backup: $e');
    }
  }

  /// Delete all backups
  Future<void> deleteAllBackups() async {
    try {
      await _backupService.deleteAllBackups();
      backupHistory.clear();
      lastBackupDate.value = null;
      lastBackupStats.value = null;

      Get.back(); // Close confirmation dialog
      Get.snackbar(
        'Success',
        'All backups deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      log('🗑️ Deleted all backups');
    } catch (e) {
      log('Error deleting backups: $e');
      Get.snackbar(
        'Error',
        'Failed to delete backups: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

/// Backup history item model
class BackupHistoryItem {
  final DateTime date;
  final bool success;
  final int itemsBackedUp;
  final Map<String, dynamic>? stats;

  BackupHistoryItem({
    required this.date,
    required this.success,
    required this.itemsBackedUp,
    this.stats,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
