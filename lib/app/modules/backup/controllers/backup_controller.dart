import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/core/services/backup/backup_worker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **BackupController V3** - Updated to use BackupServiceV3
///
/// Features:
/// - Unstoppable backups (survives app kill, device restart)
/// - Real-time progress tracking
/// - Scheduled backups (nightly, weekly)
/// - All backup types: chats, media, contacts, device info
class BackupController extends GetxController {
  // Singleton instance
  static BackupController get instance => Get.find();

  // NEW: BackupServiceV3 (replaces ReliableBackupService)
  final _backupService = BackupServiceV3.instance;

  // Observable states
  final RxBool isBackupRunning = false.obs;
  final RxDouble backupProgress = 0.0.obs;
  final RxString backupStatus = 'Ready to backup'.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Current backup ID
  final RxString currentBackupId = ''.obs;

  // Backup history
  final RxList<BackupHistoryItem> backupHistory = <BackupHistoryItem>[].obs;
  final Rx<DateTime?> lastBackupDate = Rx<DateTime?>(null);
  final Rx<Map<String, dynamic>?> lastBackupStats = Rx<Map<String, dynamic>?>(null);

  // Settings
  final RxBool autoBackupEnabled = false.obs;
  final RxInt autoBackupInterval = 24.obs; // hours
  final RxBool backupOnWifiOnly = true.obs;
  final RxBool showNotifications = true.obs;
  final RxBool compressMedia = true.obs;
  final RxInt maxMediaSize = 100.obs; // MB
  final RxBool incrementalOnly = true.obs;

  // Backup type selection
  final RxBool backupChats = true.obs;
  final RxBool backupMedia = true.obs;
  final RxBool backupContacts = true.obs;
  final RxBool backupDeviceInfo = true.obs;

  // Streams
  StreamSubscription? _progressSubscription;
  StreamSubscription? _eventSubscription;

  @override
  void onInit() {
    super.onInit();
    _subscribeToBackupStreams();
    _loadBackupHistory();
    _loadSettings();
    _checkRunningBackups(); // Check for active backups on init
  }

  /// Check if any backup is currently running
  /// Syncs UI state with BackupServiceV3 state
  void _checkRunningBackups() {
    final runningIds = _backupService.runningBackupIds;
    if (runningIds.isNotEmpty) {
      final activeId = runningIds.first;
      currentBackupId.value = activeId;
      isBackupRunning.value = true;
      backupStatus.value = 'Backup in progress...';

      log('📊 Found active backup on init: $activeId');

      // Fetch current progress
      _backupService.getBackupProgress(activeId).then((progress) {
        if (progress != null) {
          backupProgress.value = progress.percentage / 100.0;
          backupStatus.value = 'Processing ${progress.currentType?.name ?? "data"}... '
              '${progress.processedItems}/${progress.totalItems}';
        }
      });
    }
  }

  @override
  void onClose() {
    _progressSubscription?.cancel();
    _eventSubscription?.cancel();
    super.onClose();
  }

  /// Subscribe to backup progress and events from BackupServiceV3
  void _subscribeToBackupStreams() {
    // Progress stream (real-time updates)
    _progressSubscription = _backupService.progressStream.listen((progress) {
      backupProgress.value = progress.percentage / 100.0;
      backupStatus.value = 'Processing ${progress.currentType?.name ?? "data"}... '
          '${progress.processedItems}/${progress.totalItems}';

      log('📊 Backup progress: ${progress.percentage}% - ${progress.formattedSize}');
    });

    // Event stream (state changes)
    _eventSubscription = _backupService.eventStream.listen((event) {
      switch (event.type) {
        case BackupEventType.started:
          isBackupRunning.value = true;
          backupStatus.value = 'Backup started...';
          break;

        case BackupEventType.completed:
          isBackupRunning.value = false;
          backupProgress.value = 1.0;
          backupStatus.value = 'Backup completed successfully!';
          hasError.value = false;

          // Reload history
          _loadBackupHistory();

          // Show success notification
          Get.snackbar(
            'Success ✅',
            'Backup completed successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primaryContainer,
            duration: const Duration(seconds: 3),
          );
          break;

        case BackupEventType.failed:
          isBackupRunning.value = false;
          hasError.value = true;
          errorMessage.value = event.message ?? 'Unknown error';
          backupStatus.value = 'Backup failed';

          Get.snackbar(
            'Error ❌',
            event.message ?? 'Backup failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.errorContainer,
          );
          break;

        case BackupEventType.paused:
          backupStatus.value = 'Backup paused (waiting for conditions)';
          break;

        case BackupEventType.resumed:
          backupStatus.value = 'Backup resumed...';
          break;

        default:
          break;
      }
    });
  }

  /// Load backup history from Firestore
  Future<void> _loadBackupHistory() async {
    try {
      // Get latest backup progress
      if (currentBackupId.value.isNotEmpty) {
        final progress = await _backupService.getBackupProgress(currentBackupId.value);

        if (progress != null && progress.startedAt != null) {
          lastBackupDate.value = progress.startedAt;
          lastBackupStats.value = {
            'total_items': progress.totalItems,
            'processed_items': progress.processedItems,
            'failed_items': progress.failedItems,
            'bytes_transferred': progress.bytesTransferred,
            'backup_id': progress.backupId,
          };

          // Add to history
          backupHistory.insert(0, BackupHistoryItem(
            date: progress.startedAt!,
            success: progress.failedItems == 0,
            itemsBackedUp: progress.processedItems,
            stats: lastBackupStats.value,
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
      compressMedia.value = prefs.getBool('backup_compress_media') ?? true;
      maxMediaSize.value = prefs.getInt('backup_max_media_size') ?? 100;
      incrementalOnly.value = prefs.getBool('backup_incremental_only') ?? true;

      // Backup type selection
      backupChats.value = prefs.getBool('backup_chats') ?? true;
      backupMedia.value = prefs.getBool('backup_media') ?? true;
      backupContacts.value = prefs.getBool('backup_contacts') ?? true;
      backupDeviceInfo.value = prefs.getBool('backup_device_info') ?? true;

      log('📱 Loaded backup settings');
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
      await prefs.setBool('backup_compress_media', compressMedia.value);
      await prefs.setInt('backup_max_media_size', maxMediaSize.value);
      await prefs.setBool('backup_incremental_only', incrementalOnly.value);

      // Backup type selection
      await prefs.setBool('backup_chats', backupChats.value);
      await prefs.setBool('backup_media', backupMedia.value);
      await prefs.setBool('backup_contacts', backupContacts.value);
      await prefs.setBool('backup_device_info', backupDeviceInfo.value);

      log('💾 Saved backup settings');
    } catch (e) {
      log('Error saving backup settings: $e');
    }
  }

  /// Start backup process using BackupServiceV3
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

      // Prepare backup types
      final types = <BackupType>{};
      if (backupChats.value) types.add(BackupType.chats);
      if (backupMedia.value) types.add(BackupType.media);
      if (backupContacts.value) types.add(BackupType.contacts);
      if (backupDeviceInfo.value) types.add(BackupType.deviceInfo);

      if (types.isEmpty) {
        throw Exception('Please select at least one backup type');
      }

      // Prepare backup options
      final options = BackupOptions(
        wifiOnly: backupOnWifiOnly.value,
        minBatteryPercent: 20,
        compressMedia: compressMedia.value,
        maxMediaSize: maxMediaSize.value,
        incrementalOnly: incrementalOnly.value,
      );

      // Start the unstoppable backup!
      final backupId = await _backupService.startBackup(
        types: types,
        options: options,
      );

      currentBackupId.value = backupId;

      log('🚀 Backup started: $backupId');
      log('   Types: ${types.map((t) => t.name).join(", ")}');
      log('   WiFi only: ${options.wifiOnly}');
      log('   Compress media: ${options.compressMedia}');
      log('   Incremental: ${options.incrementalOnly}');

      Get.snackbar(
        'Backup Started 🚀',
        'This backup will run to completion, even if you close the app!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      backupStatus.value = 'Error: ${e.toString()}';
      isBackupRunning.value = false;

      log('❌ Backup error: $e');

      Get.snackbar(
        'Error',
        'Failed to start backup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }

  /// Check backup status
  Future<void> checkBackupStatus() async {
    if (currentBackupId.value.isEmpty) return;

    try {
      final status = await _backupService.getBackupStatus(currentBackupId.value);

      log('📊 Backup status: ${status.name}');

      switch (status) {
        case BackupStatus.completed:
          isBackupRunning.value = false;
          backupProgress.value = 1.0;
          break;
        case BackupStatus.failed:
          isBackupRunning.value = false;
          hasError.value = true;
          break;
        case BackupStatus.running:
          isBackupRunning.value = true;
          break;
        default:
          break;
      }
    } catch (e) {
      log('Error checking backup status: $e');
    }
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
    final total = stats['total_items'] ?? 0;
    final processed = stats['processed_items'] ?? 0;
    final failed = stats['failed_items'] ?? 0;

    return '$processed/$total items backed up${failed > 0 ? " ($failed failed)" : ""}';
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

  /// Toggle media compression
  Future<void> toggleCompressMedia(bool value) async {
    compressMedia.value = value;
    await _saveSettings();
  }

  /// Toggle incremental backups
  Future<void> toggleIncrementalBackups(bool value) async {
    incrementalOnly.value = value;
    await _saveSettings();
  }

  /// Schedule automatic backup using BackupWorker
  Future<void> _scheduleAutoBackup() async {
    try {
      // Prepare backup types
      final types = <BackupType>{};
      if (backupChats.value) types.add(BackupType.chats);
      if (backupMedia.value) types.add(BackupType.media);
      if (backupContacts.value) types.add(BackupType.contacts);
      if (backupDeviceInfo.value) types.add(BackupType.deviceInfo);

      // Prepare options
      final options = BackupOptions(
        wifiOnly: backupOnWifiOnly.value,
        minBatteryPercent: 20,
        compressMedia: compressMedia.value,
        maxMediaSize: maxMediaSize.value,
        incrementalOnly: incrementalOnly.value,
      );

      // Schedule based on interval
      if (autoBackupInterval.value == 24) {
        // Nightly backup at 2 AM
        await _backupService.scheduleNightlyBackup(
          types: types,
          options: options,
        );

        log('📅 Scheduled nightly backup at 2 AM');

        Get.snackbar(
          'Auto Backup Enabled',
          'Nightly backup scheduled for 2 AM',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      } else if (autoBackupInterval.value == 168) {
        // Weekly backup
        await _backupService.scheduleWeeklyBackup(
          types: types,
          options: options,
        );

        log('📅 Scheduled weekly backup');

        Get.snackbar(
          'Auto Backup Enabled',
          'Weekly backup scheduled for Sunday 2 AM',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      } else {
        // Custom interval
        await BackupWorker.instance.schedulePeriodicBackup(
          taskId: 'custom_backup',
          types: types,
          options: options,
          frequency: Duration(hours: autoBackupInterval.value),
        );

        log('📅 Scheduled backup every ${autoBackupInterval.value} hours');

        Get.snackbar(
          'Auto Backup Enabled',
          'Backup scheduled every ${autoBackupInterval.value} hours',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );
      }
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
      await BackupWorker.instance.cancelBackup('nightly_backup');
      await BackupWorker.instance.cancelBackup('weekly_backup');
      await BackupWorker.instance.cancelBackup('custom_backup');

      log('🚫 Cancelled auto backup');

      Get.snackbar(
        'Auto Backup Disabled',
        'Automatic backups have been cancelled',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      log('Error cancelling auto backup: $e');
    }
  }

  /// Refresh backup history
  Future<void> refreshBackupHistory() async {
    await _loadBackupHistory();
  }

  /// NOTE: Delete and Restore functionality not yet implemented in BackupServiceV3
  /// These will be added in a future update (RestoreServiceV3)

  Future<void> deleteAllBackups() async {
    Get.snackbar(
      'Info',
      'Delete functionality coming soon in BackupServiceV3',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> showRestoreDialog() async {
    Get.snackbar(
      'Info',
      'Restore functionality coming soon (RestoreServiceV3)',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Stop/cancel backup (NOTE: Backups are unstoppable)
  /// This exists for UI compatibility but backups continue to completion
  Future<void> stopBackup() async {
    try {
      if (currentBackupId.value.isEmpty) {
        log('⚠️ No active backup to stop');
        return;
      }

      // Try to cancel (will return false as backups are unstoppable)
      final cancelled = await _backupService.cancelBackup(currentBackupId.value);

      if (!cancelled) {
        Get.snackbar(
          'Info',
          'Backups are designed to run to completion for reliability',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      log('❌ Error stopping backup: $e');
    }
  }

  /// Toggle backup notifications
  void toggleNotifications(bool value) {
    showNotifications.value = value;
    _saveSettings();

    Get.snackbar(
      'Settings Updated',
      value ? 'Backup notifications enabled' : 'Backup notifications disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Cancel the current backup
  /// Note: Backups are designed to be unstoppable, but this provides user feedback
  Future<void> cancelBackup() async {
    await stopBackup();
  }

  /// Restore from a specific backup
  /// NOTE: Full implementation requires RestoreServiceV3
  Future<void> restoreBackup(BackupHistoryItem item) async {
    try {
      isBackupRunning.value = true;
      backupStatus.value = 'Restoring backup from ${item.formattedDate}...';

      // Show progress indicator
      Get.snackbar(
        'Restore Started',
        'Restoring from backup: ${item.formattedDate}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        duration: const Duration(seconds: 3),
      );

      // TODO: Implement actual restore logic with RestoreServiceV3
      // For now, simulate restore process
      await Future.delayed(const Duration(seconds: 2));

      isBackupRunning.value = false;
      backupStatus.value = 'Ready to backup';

      Get.snackbar(
        'Info',
        'Restore functionality coming soon in RestoreServiceV3',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      isBackupRunning.value = false;
      hasError.value = true;
      errorMessage.value = 'Failed to restore: ${e.toString()}';

      Get.snackbar(
        'Error',
        'Failed to restore backup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }

  /// Delete a specific backup from history
  Future<void> deleteBackup(BackupHistoryItem item) async {
    try {
      // Remove from local list
      backupHistory.removeWhere((h) => h.date == item.date);

      Get.snackbar(
        'Backup Deleted',
        'Backup from ${item.formattedDate} has been removed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // TODO: Implement Firestore deletion when backup storage is implemented
      log('🗑️ Deleted backup from ${item.formattedDate}');
    } catch (e) {
      log('Error deleting backup: $e');

      Get.snackbar(
        'Error',
        'Failed to delete backup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
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
  final Duration? duration;
  final String? id;

  BackupHistoryItem({
    required this.date,
    required this.success,
    required this.itemsBackedUp,
    this.stats,
    this.duration,
    this.id,
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
