import 'package:crypted_app/app/core/services/enhanced_backup_service.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/backup_configuration_bottom_sheet.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleBackupSwitchWidget extends StatefulWidget {
  const SimpleBackupSwitchWidget({super.key});

  @override
  State<SimpleBackupSwitchWidget> createState() =>
      _SimpleBackupSwitchWidgetState();
}

class _SimpleBackupSwitchWidgetState extends State<SimpleBackupSwitchWidget> {
  final _backupService = EnhancedBackupService.instance;
  final _settingsController = Get.find<SettingsController>();

  BackupState _currentState = BackupState.idle;
  double _currentProgress = 0.0;
  Map<String, dynamic> _backupStats = {};

  final RxBool _autoBackupEnabled = false.obs;

  @override
  void initState() {
    super.initState();
    _loadBackupStats();
    _setupListeners();
  }

  void _setupListeners() {
    _backupService.stateStream.listen((state) {
      if (mounted) setState(() => _currentState = state);
    });

    _backupService.progressStream.listen((progress) {
      if (mounted) setState(() => _currentProgress = progress);
    });
  }

  Future<void> _loadBackupStats() async {
    final stats = await _backupService.getBackupStats();
    setState(() => _backupStats = stats);
  }

  Future<void> _toggleAutoBackup(bool value) async {
    _autoBackupEnabled.value = value;

    if (value) {
      // When enabled, trigger auto-backup of all available data
      try {
        Get.snackbar(
          Constants.kBackup.tr,
          'Starting automatic backup of all data...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary,
          colorText: Colors.white,
        );

        // Run backup without auto-requesting permissions (they should already be granted)
        await _backupService.runFullBackup(autoRequestPermissions: false);
        await _loadBackupStats();

        Get.snackbar(
          Constants.kSuccess.tr,
          'Auto backup completed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          Constants.kError.tr,
          'Auto backup failed: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        _autoBackupEnabled.value = false;
      }
    }

    // Save the preference
    _settingsController.updateBackupSettings(autoBackup: value);
  }

  void _showBackupConfiguration() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackupConfigurationBottomSheet(),
    );
  }

  String _getLastBackupText() {
    if (_backupStats['lastBackup'] == null) {
      return Constants.kNever.tr;
    }

    final lastBackup = _backupStats['lastBackup'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(lastBackup);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastBackup.day}/${lastBackup.month}/${lastBackup.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBackingUp = _currentState != BackupState.idle &&
        _currentState != BackupState.completed &&
        _currentState != BackupState.failed;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.normal,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showBackupConfiguration,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with switch
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.backup_rounded,
                        color: ColorsManager.primary,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: Sizes.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.kAutoBackup.tr,
                            style: StylesManager.bold(
                              fontSize: FontSize.large,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Automatically backup all data',
                            style: StylesManager.regular(
                              fontSize: FontSize.small,
                              color: ColorsManager.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() => Switch.adaptive(
                          value: _autoBackupEnabled.value,
                          onChanged: isBackingUp ? null : _toggleAutoBackup,
                          activeColor: ColorsManager.primary,
                          activeTrackColor: ColorsManager.primary.withValues(alpha: 0.5),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade300,
                        )),
                  ],
                ),

                // Progress indicator when backing up
                if (isBackingUp) ...[
                  SizedBox(height: Sizes.size16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _currentProgress,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorsManager.primary),
                              ),
                            ),
                            SizedBox(width: Sizes.size8),
                            Expanded(
                              child: Text(
                                Constants.kBackupInProgress.tr,
                                style: StylesManager.medium(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.primary,
                                ),
                              ),
                            ),
                            Text(
                              '${(_currentProgress * 100).toInt()}%',
                              style: StylesManager.semiBold(
                                fontSize: FontSize.small,
                                color: ColorsManager.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Sizes.size8),
                        LinearProgressIndicator(
                          value: _currentProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ColorsManager.primary),
                        ),
                      ],
                    ),
                  ),
                ],

                // Last backup info
                if (!isBackingUp) ...[
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: ColorsManager.grey,
                      ),
                      SizedBox(width: Sizes.size8),
                      Text(
                        '${Constants.kLastBackup.tr}: ${_getLastBackupText()}',
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: ColorsManager.grey,
                      ),
                    ],
                  ),
                ],

                // Tap to configure hint
                if (!isBackingUp) ...[
                  SizedBox(height: Sizes.size8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: Sizes.size4),
                        Text(
                          'Tap to configure backup settings',
                          style: StylesManager.regular(
                            fontSize: FontSize.xXSmall,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
