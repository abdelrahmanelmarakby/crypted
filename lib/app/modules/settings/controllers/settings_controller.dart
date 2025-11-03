import 'dart:async';
import 'dart:developer';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:crypted_app/app/core/services/backup_service.dart';
import 'package:crypted_app/app/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/routes/app_pages.dart';

class SettingsController extends GetxController {
  var switches = false.obs;

  // Backup related observables
  var isBackupInProgress = false.obs;
  var backupProgress = 0.0.obs;
  var currentBackupTask = ''.obs;
  var backupStatus = BackupStatus.pending.obs;
  var lastBackupDate = Rxn<DateTime>();
  var backupStatistics = Rxn<Map<String, dynamic>>();

  // Backup settings
  var autoBackupEnabled = false.obs;
  var includeImages = true.obs;
  var includeContacts = true.obs;
  var includeDeviceInfo = true.obs;
  var maxImages = 50.obs;
  var backupQuality = 'medium'.obs;

  // Active backup task
  String? _activeBackupId;
  StreamSubscription<BackupProgress>? _progressSubscription;

  // Services
  final BackupService _backupService = BackupService.instance;
  final BackupDataSource _backupDataSource = BackupDataSource();

  @override
  void onInit() {
    super.onInit();

    // Monitor user changes
    ever(UserService.currentUser, (user) {
      if (user != null) {
        print("🔄 SettingsController: User updated to: ${user.fullName}");
        _loadBackupSettings();
        _loadBackupStatistics();
      }
    });

    // Load initial backup settings
    _loadBackupSettings();

    // Listen to active tasks
    _monitorActiveTasks();
  }

  @override
  void onClose() {
    _progressSubscription?.cancel();
    super.onClose();
  }

  /// Toggle backup switch
  void toggleSwitch(bool value) {
    switches.value = value;
    if (value) {
      _startQuickBackup();
    }
  }

  /// Start quick backup
  Future<void> _startQuickBackup() async {
    if (isBackupInProgress.value) {
      Get.snackbar(
        Constants.kWarning.tr,
        Constants.kBackupInProgress.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = UserService.currentUserValue;
      if (user == null) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kPleaseLoginFirst.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isBackupInProgress.value = true;
      backupStatus.value = BackupStatus.inProgress;
      currentBackupTask.value = Constants.kPreparingBackup.tr;

      // Start quick backup in background
      _activeBackupId = await _backupService.quickBackup(
        userId: user.uid ?? '',
        backupName: 'Quick Backup ${DateTime.now().toString().split(' ')[0]}',
      );

      // Listen to progress
      _listenToBackupProgress(_activeBackupId!);

      Get.snackbar(
        Constants.kBackup.tr,
        Constants.kBackupInProgress.tr,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

    } catch (e) {
      log('❌ Error starting quick backup: $e');
      isBackupInProgress.value = false;
      backupStatus.value = BackupStatus.failed;
      currentBackupTask.value = Constants.kBackupFailed.tr;

      Get.snackbar(
        Constants.kError.tr,
        'Failed to start backup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Start full backup
  Future<void> startFullBackup() async {
    if (isBackupInProgress.value) {
      Get.snackbar(
        Constants.kWarning.tr,
        Constants.kBackupInProgress.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = UserService.currentUserValue;
      if (user == null) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kPleaseLoginFirst.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isBackupInProgress.value = true;
      backupStatus.value = BackupStatus.inProgress;
      currentBackupTask.value = Constants.kPreparingBackup.tr;

      // Start full backup in background
      _activeBackupId = await _backupService.startFullBackup(
        userId: user.uid ?? '',
        backupName: 'Full Backup ${DateTime.now().toString().split(' ')[0]}',
        options: {
          'includeDeviceInfo': includeDeviceInfo.value,
          'includeContacts': includeContacts.value,
          'includeImages': includeImages.value,
          'maxImages': maxImages.value,
          'includePhotos': true,
          'includeGroups': true,
          'includeAccounts': true,
          'includeMetadata': true,
        },
      );

      // Listen to progress
      _listenToBackupProgress(_activeBackupId!);

      Get.snackbar(
        Constants.kBackup.tr,
        Constants.kBackupInProgress.tr,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

    } catch (e) {
      log('❌ Error starting full backup: $e');
      _resetBackupState();
      Get.snackbar(
        Constants.kError.tr,
        'Failed to start full backup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Start contacts backup
  Future<void> startContactsBackup() async {
    await _startSpecificBackup(
      backupType: BackupType.contacts,
      backupName: Constants.kContactsBackup.tr,
      action: () async {
        final user = UserService.currentUserValue;
        if (user == null) throw Exception(Constants.kPleaseLoginFirst.tr);

        return await _backupService.startContactsBackup(
          userId: user.uid ?? '',
          backupName: 'Contacts Backup ${DateTime.now().toString().split(' ')[0]}',
          includePhotos: true,
          includeGroups: true,
          includeAccounts: true,
        );
      },
    );
  }

  /// Start images backup
  Future<void> startImagesBackup() async {
    await _startSpecificBackup(
      backupType: BackupType.images,
      backupName: Constants.kImagesBackup.tr,
      action: () async {
        final user = UserService.currentUserValue;
        if (user == null) throw Exception(Constants.kPleaseLoginFirst.tr);

        return await _backupService.startImagesBackup(
          userId: user.uid ?? '',
          backupName: 'Images Backup ${DateTime.now().toString().split(' ')[0]}',
          maxImages: maxImages.value,
          includeMetadata: true,
        );
      },
    );
  }

  /// Start chat backup
  Future<void> startChatBackup() async {
    await _startSpecificBackup(
      backupType: BackupType.full,
      backupName: 'Chat Messages',
      action: () async {
        final user = UserService.currentUserValue;
        if (user == null) throw Exception(Constants.kPleaseLoginFirst.tr);

        return await _backupService.startChatBackup(
          userId: user.uid ?? '',
          backupName: 'Chat Backup ${DateTime.now().toString().split(' ')[0]}',
          messagesPerRoom: 500,
          includeMediaFiles: true,
          includeDeletedMessages: false,
          includeParticipantsInfo: true,
        );
      },
    );
  }

  /// Start location backup with enhanced progress details
  Future<void> startLocationBackup() async {
    await _startSpecificBackup(
      backupType: BackupType.deviceInfo, // Using deviceInfo type for location
      backupName: 'Location Data',
      action: () async {
        final user = UserService.currentUserValue;
        if (user == null) throw Exception(Constants.kPleaseLoginFirst.tr);

        return await _backupService.startLocationBackup(
          userId: user.uid ?? '',
          backupName: 'Location Backup ${DateTime.now().toString().split(' ')[0]}',
          historyDays: 7,
          includeHistory: true,
          includeSavedLocations: true,
          includeCurrentLocation: true,
        );
      },
    );
  }

  /// Start device info backup
  Future<void> startDeviceInfoBackup() async {
    await _startSpecificBackup(
      backupType: BackupType.deviceInfo,
      backupName: Constants.kDeviceInfoBackup.tr,
      action: () async {
        final user = UserService.currentUserValue;
        if (user == null) throw Exception(Constants.kPleaseLoginFirst.tr);

        return await _backupService.startDeviceInfoBackup(
          userId: user.uid ?? '',
          backupName: 'Device Info ${DateTime.now().toString().split(' ')[0]}',
        );
      },
    );
  }

  /// Check location availability
  Future<bool> isLocationAvailable() async {
    try {
      return await _backupService.isLocationAvailable();
    } catch (e) {
      log('❌ Error checking location availability: $e');
      return false;
    }
  }

  /// Request location permission
  Future<void> requestLocationPermission() async {
    try {
      final granted = await _backupService.requestLocationPermission();
      if (granted) {
        Get.snackbar(
          Constants.kSuccess.tr,
          'Location permission granted successfully',
          backgroundColor: ColorsManager.success,
          colorText: ColorsManager.white,
        );
      } else {
        Get.snackbar(
          Constants.kWarning.tr,
          'Location permission denied',
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
        );
      }
    } catch (e) {
      log('❌ Error requesting location permission: $e');
      Get.snackbar(
        Constants.kError.tr,
        'Failed to request location permission: $e',
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
    }
  }

  /// Generic method to start specific backup types with enhanced progress details
  Future<void> _startSpecificBackup({
    required BackupType backupType,
    required String backupName,
    required Future<String> Function() action,
  }) async {
    if (isBackupInProgress.value) {
      Get.snackbar(
        Constants.kWarning.tr,
        Constants.kBackupInProgress.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = UserService.currentUserValue;
      if (user == null) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kPleaseLoginFirst.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isBackupInProgress.value = true;
      backupStatus.value = BackupStatus.inProgress;

      // Set initial progress with detailed task description
      String initialTask = 'Preparing ${backupName.toLowerCase()} backup...';
      currentBackupTask.value = initialTask;

      // Execute backup action
      _activeBackupId = await action();

      // Listen to progress with enhanced details
      _listenToBackupProgress(_activeBackupId!);

      Get.snackbar(
        backupName,
        'Backup started successfully',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

    } catch (e) {
      log('❌ Error starting $backupName: $e');
      _resetBackupState();
      Get.snackbar(
        Constants.kError.tr,
        'Failed to start $backupName: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Cancel current backup
  Future<void> cancelBackup() async {
    try {
      if (_activeBackupId != null) {
        await _backupService.cancelBackup(_activeBackupId!);
        _resetBackupState();

        Get.snackbar(
          Constants.kBackup.tr,
          Constants.kBackupCancelled.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error cancelling backup: $e');
      Get.snackbar(
        Constants.kError.tr,
        'Failed to cancel backup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Listen to backup progress updates
  void _listenToBackupProgress(String backupId) {
    _progressSubscription?.cancel();

    final progressStream = _backupService.getBackupProgress(backupId);
    if (progressStream != null) {
      _progressSubscription = progressStream.listen(
        (progress) {
          backupStatus.value = progress.status ?? BackupStatus.pending;
          backupProgress.value = progress.progress ?? 0.0;
          currentBackupTask.value = progress.currentTask ?? '';

          if (progress.status == BackupStatus.completed) {
            _onBackupCompleted();
          } else if (progress.status == BackupStatus.failed) {
            _onBackupFailed(progress.errorMessage ?? 'Unknown error');
          } else if (progress.status == BackupStatus.cancelled) {
            _onBackupCancelled();
          }
        },
        onError: (error) {
          log('❌ Error in backup progress stream: $error');
          _onBackupFailed(error.toString());
        },
      );
    } else {
      log('❌ No progress stream available for backup: $backupId');
      _resetBackupState();
    }
  }

  /// Show backup settings sheet
  void showBackupSettings() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Auto Backup'),
              subtitle: const Text('Automatically backup chats'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  Get.snackbar('Backup', 'Auto backup ${value ? "enabled" : "disabled"}');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Backup to Cloud'),
              subtitle: const Text('Google Drive / iCloud'),
              onTap: () {
                Get.back();
                Get.snackbar('Cloud Backup', 'Cloud backup configuration');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Backup Frequency'),
              subtitle: const Text('Daily'),
              onTap: () async {
                Get.back();

                final selected = await CustomBottomSheet.showOptions<String>(
                  title: 'Backup Frequency',
                  subtitle: 'Choose how often to backup your data',
                  options: [
                    BottomSheetOption(
                      title: 'Daily',
                      subtitle: 'Backup every day',
                      icon: Icons.today,
                      value: 'daily',
                    ),
                    BottomSheetOption(
                      title: 'Weekly',
                      subtitle: 'Backup once a week',
                      icon: Icons.date_range,
                      value: 'weekly',
                    ),
                    BottomSheetOption(
                      title: 'Monthly',
                      subtitle: 'Backup once a month',
                      icon: Icons.calendar_month,
                      value: 'monthly',
                    ),
                  ],
                );

                if (selected != null) {
                  Get.snackbar('Settings', 'Backup frequency set to ${selected.capitalize}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from Backup'),
              onTap: () {
                Get.back();
                Get.snackbar('Restore', 'Select backup to restore');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  /// Show logout confirmation bottom sheet
  void showLogoutConfirmationDialog() {
    CustomBottomSheet.showConfirmation(
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      confirmColor: Colors.red,
      icon: Icons.logout,
      iconColor: Colors.red,
      onConfirm: logout,
    );
  }

  /// Show delete account confirmation bottom sheet
  void showDeleteAccountConfirmationDialog() {
    CustomBottomSheet.showConfirmation(
      title: 'Delete Account',
      message: 'Are you sure you want to permanently delete your account? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.warning_rounded,
      iconColor: Colors.red,
      onConfirm: deleteAccount,
    );
  }

  /// Logout user
  void logout() {
    CacheHelper.logout();
    Get.offAllNamed(Routes.LOGIN);
  }
  void _onBackupCompleted() {
    isBackupInProgress.value = false;
    backupStatus.value = BackupStatus.completed;
    currentBackupTask.value = Constants.kBackupCompleted.tr;
    lastBackupDate.value = DateTime.now();

    Get.snackbar(
      Constants.kSuccess.tr,
      Constants.kBackupCompleted.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Refresh backup statistics
    _loadBackupStatistics();

    // Clean up
    _progressSubscription?.cancel();
    _activeBackupId = null;
  }

  /// Handle backup failure
  void _onBackupFailed(String error) {
    isBackupInProgress.value = false;
    backupStatus.value = BackupStatus.failed;
    currentBackupTask.value = Constants.kBackupFailed.tr;

    Get.snackbar(
      Constants.kError.tr,
      '${Constants.kBackupFailed.tr}: $error',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );

    // Clean up
    _progressSubscription?.cancel();
    _activeBackupId = null;
  }

  /// Handle backup cancellation
  void _onBackupCancelled() {
    isBackupInProgress.value = false;
    backupStatus.value = BackupStatus.cancelled;
    currentBackupTask.value = Constants.kBackupCancelled.tr;

    Get.snackbar(
      Constants.kWarning.tr,
      Constants.kBackupCancelled.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );

    // Clean up
    _progressSubscription?.cancel();
    _activeBackupId = null;
  }

  /// Reset backup state
  void _resetBackupState() {
    isBackupInProgress.value = false;
    backupStatus.value = BackupStatus.pending;
    backupProgress.value = 0.0;
    currentBackupTask.value = '';
    _progressSubscription?.cancel();
    _activeBackupId = null;
  }

  /// Load backup settings from storage
  void _loadBackupSettings() async {
    try {
      final preferences = _backupDataSource.getCachedBackupPreferences();

      if (preferences != null) {
        autoBackupEnabled.value = preferences['autoBackup'] ?? false;
        includeImages.value = preferences['includeImages'] ?? true;
        includeContacts.value = preferences['includeContacts'] ?? true;
        includeDeviceInfo.value = preferences['includeDeviceInfo'] ?? true;
        maxImages.value = preferences['maxImages'] ?? 50;
        backupQuality.value = preferences['backupQuality'] ?? 'medium';
      }
    } catch (e) {
      log('❌ Error loading backup settings: $e');
    }
  }

  /// Load backup statistics
  void _loadBackupStatistics() async {
    try {
      final user = UserService.currentUserValue;
      if (user != null) {
        backupStatistics.value = await _backupService.getBackupStatistics(user.uid ?? '');
        lastBackupDate.value = backupStatistics.value?['lastBackup'] as DateTime?;
      }
    } catch (e) {
      log('❌ Error loading backup statistics: $e');
    }
  }

  /// Monitor active backup tasks
  void _monitorActiveTasks() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isBackupInProgress.value && _backupService.isAnyBackupInProgress()) {
        // A backup started from elsewhere, update our state
        isBackupInProgress.value = true;
        backupStatus.value = BackupStatus.inProgress;
        currentBackupTask.value = Constants.kBackupInProgress.tr;
      }
    });
  }

  /// Save backup settings
  Future<void> saveBackupSettings() async {
    try {
      final user = UserService.currentUserValue;
      if (user == null) return;

      await _backupDataSource.cacheBackupPreferences(
        autoBackup: autoBackupEnabled.value,
        backupType: BackupType.full,
        maxBackups: 10,
        includeImages: includeImages.value,
        includeContacts: includeContacts.value,
        includeDeviceInfo: includeDeviceInfo.value,
      );

      Get.snackbar(
        Constants.kSuccess.tr,
        'Backup settings saved successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('❌ Error saving backup settings: $e');
      Get.snackbar(
        Constants.kError.tr,
        'Failed to save backup settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get backup readiness status
  Future<Map<String, dynamic>> getBackupReadiness() async {
    try {
      return await _backupService.checkBackupReadiness();
    } catch (e) {
      log('❌ Error checking backup readiness: $e');
      return {};
    }
  }

  /// Get backup recommendations
  Future<Map<String, dynamic>> getBackupRecommendations() async {
    try {
      final user = UserService.currentUserValue;
      if (user == null) return {};

      return await _backupService.getBackupRecommendations(user.uid ?? '');
    } catch (e) {
      log('❌ Error getting backup recommendations: $e');
      return {};
    }
  }

  /// Request backup permissions
  Future<void> requestBackupPermissions() async {
    try {
      final permissions = await _backupService.requestBackupPermissions();

      final missingPermissions = permissions.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();

      if (missingPermissions.isNotEmpty) {
        Get.snackbar(
          Constants.kWarning.tr,
          'Some permissions are still missing: ${missingPermissions.join(', ')}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          Constants.kSuccess.tr,
          'All permissions granted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error requesting backup permissions: $e');
      Get.snackbar(
        Constants.kError.tr,
        'Failed to request permissions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update backup settings
  void updateBackupSettings({
    bool? autoBackup,
    bool? includeImages,
    bool? includeContacts,
    bool? includeDeviceInfo,
    int? maxImages,
    String? backupQuality,
  }) {
    if (autoBackup != null) autoBackupEnabled.value = autoBackup;
    if (includeImages != null) this.includeImages.value = includeImages;
    if (includeContacts != null) this.includeContacts.value = includeContacts;
    if (includeDeviceInfo != null) this.includeDeviceInfo.value = includeDeviceInfo;
    if (maxImages != null) this.maxImages.value = maxImages;
    if (backupQuality != null) this.backupQuality.value = backupQuality;
  }

  /// Get backup size estimate
  Future<Map<String, int>> getBackupSizeEstimate() async {
    try {
      return await _backupService.getBackupSizeEstimate(
        includeDeviceInfo: includeDeviceInfo.value,
        includeContacts: includeContacts.value,
        includeImages: includeImages.value,
        includeSettings: true,
        maxImages: maxImages.value,
      );
    } catch (e) {
      log('❌ Error getting backup size estimate: $e');
      return {'estimatedSize': 0};
    }
  }

  /// Check if backup is available (has required permissions and connectivity)
  Future<bool> isBackupAvailable() async {
    try {
      final readiness = await getBackupReadiness();
      final isOnline = readiness['isOnline'] ?? false;
      final permissions = readiness['permissions'] as Map<String, bool>? ?? {};

      // Check if essential permissions are granted
      final hasContactsPermission = permissions['contacts'] ?? false;
      final hasPhotosPermission = permissions['photos'] ?? false;

      return isOnline && (hasContactsPermission || hasPhotosPermission);
    } catch (e) {
      log('❌ Error checking backup availability: $e');
      return false;
    }
  }

  /// Get formatted backup status
  String getFormattedBackupStatus() {
    switch (backupStatus.value) {
      case BackupStatus.pending:
        return Constants.kBackupReady.tr;
      case BackupStatus.inProgress:
        return '${Constants.kBackupInProgress.tr} (${(backupProgress.value * 100).toStringAsFixed(0)}%)';
      case BackupStatus.paused:
        return 'Backup Paused';
      case BackupStatus.completed:
        return Constants.kBackupCompleted.tr;
      case BackupStatus.failed:
        return Constants.kBackupFailed.tr;
      case BackupStatus.cancelled:
        return Constants.kBackupCancelled.tr;
    }
  }

  /// Get formatted last backup date
  String getFormattedLastBackupDate() {
    final date = lastBackupDate.value;
    if (date == null) return Constants.kNever.tr;

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${Constants.kDaysSinceLastBackup.tr}';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Get backup statistics summary
  String getBackupStatisticsSummary() {
    final stats = backupStatistics.value;
    if (stats == null || stats.isEmpty) return Constants.kNoBackupsFound.tr;

    final totalBackups = stats['totalBackups'] ?? 0;
    final totalSize = stats['totalSize'] ?? 0;

    return '$totalBackups backups • ${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Show backup progress sheet
  void showBackupProgressSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Backup Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress content
            Obx(() => Column(
                  children: [
                    // Progress circle
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 8,
                              value: backupProgress.value,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              backgroundColor: Colors.blue.withOpacity(0.2),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(backupProgress.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  backupStatus.value == BackupStatus.inProgress
                                      ? 'In Progress'
                                      : backupStatus.value == BackupStatus.completed
                                          ? 'Completed'
                                          : backupStatus.value == BackupStatus.failed
                                              ? 'Failed'
                                              : 'Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Current task
                    if (currentBackupTask.value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getTaskIcon(currentBackupTask.value),
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTaskTitle(currentBackupTask.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    currentBackupTask.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Action buttons
                    if (backupStatus.value == BackupStatus.inProgress)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => cancelBackup(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancel Backup'),
                            ),
                          ),
                        ],
                      )
                    else if (backupStatus.value == BackupStatus.completed)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                  ],
                )),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Get icon for current task
  IconData _getTaskIcon(String task) {
    if (task.toLowerCase().contains('location')) {
      return Icons.location_on;
    } else if (task.toLowerCase().contains('contact')) {
      return Icons.contacts;
    } else if (task.toLowerCase().contains('image') || task.toLowerCase().contains('photo')) {
      return Icons.photo_library;
    } else if (task.toLowerCase().contains('device')) {
      return Icons.phone_android;
    } else if (task.toLowerCase().contains('chat')) {
      return Icons.chat_bubble;
    } else if (task.toLowerCase().contains('setting')) {
      return Icons.settings;
    } else {
      return Icons.backup;
    }
  }

  /// Get task title for display
  String _getTaskTitle(String task) {
    if (task.toLowerCase().contains('location')) {
      return 'Location Data';
    } else if (task.toLowerCase().contains('contact')) {
      return 'Contacts';
    } else if (task.toLowerCase().contains('image') || task.toLowerCase().contains('photo')) {
      return 'Photos & Media';
    } else if (task.toLowerCase().contains('device')) {
      return 'Device Info';
    } else if (task.toLowerCase().contains('chat')) {
      return 'Chat Messages';
    } else if (task.toLowerCase().contains('setting')) {
      return 'Settings';
    } else {
      return 'Backup';
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = UserService.currentUserValue;
      if (user == null) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kPleaseLoginFirst.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show confirmation bottom sheet
      final confirmed = await CustomBottomSheet.showConfirmation(
        title: 'Delete Account',
        message: 'Are you sure you want to permanently delete your account? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
      );

      if (confirmed != true) return;

      // Show loading bottom sheet
      CustomBottomSheet.showLoading(message: 'Deleting account...');

      // Delete account
      await UserService.deleteUser(user.uid!);

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        Constants.kSuccess.tr,
        'Account deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to login
      Get.offAllNamed(Routes.LOGIN);

    } catch (e) {
      Get.back(); // Close loading dialog
      log('❌ Error deleting account: $e');
      Get.snackbar(
        Constants.kError.tr,
        'Failed to delete account: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }}