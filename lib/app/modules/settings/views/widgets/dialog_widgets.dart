import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';

/// Backup settings sheet widget
class BackupSettingsSheetWidget extends StatelessWidget {
  const BackupSettingsSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorsManager.white,
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
                Constants.kBackupSettings.tr,
                style: StylesManager.bold(
                  fontSize: FontSize.xLarge,
                  color: ColorsManager.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close,
                  color: ColorsManager.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: Sizes.size20),
          // Include options
          Text(
            'Include in Backup',
            style: StylesManager.semiBold(
              fontSize: FontSize.medium,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size16),
          // Settings toggles
          Obx(() => Column(
                children: [
                  _buildSheetToggleTile(
                    title: Constants.kDeviceInfoBackup.tr,
                    subtitle: 'Device details and specifications',
                    value: controller.includeDeviceInfo.value,
                    onChanged: (value) {
                      controller.includeDeviceInfo.value = value;
                    },
                  ),
                  SizedBox(height: Sizes.size12),
                  _buildSheetToggleTile(
                    title: Constants.kContactsBackup.tr,
                    subtitle: 'Phone contacts and groups',
                    value: controller.includeContacts.value,
                    onChanged: (value) {
                      controller.includeContacts.value = value;
                    },
                  ),
                  SizedBox(height: Sizes.size12),
                  _buildSheetToggleTile(
                    title: Constants.kImagesBackup.tr,
                    subtitle: 'Photos and media files',
                    value: controller.includeImages.value,
                    onChanged: (value) {
                      controller.includeImages.value = value;
                    },
                  ),
                  SizedBox(height: Sizes.size20),
                  // Max images setting
                  Text(
                    Constants.kMaxImages.tr,
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: ColorsManager.black,
                    ),
                  ),
                  SizedBox(height: Sizes.size12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorsManager.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() => DropdownButton<int>(
                          value: controller.maxImages.value,
                          onChanged: (value) {
                            if (value != null) {
                              controller.maxImages.value = value;
                            }
                          },
                          items: [25, 50, 100, 200, 500].map((count) {
                            return DropdownMenuItem(
                              value: count,
                              child: Text('$count images'),
                            );
                          }).toList(),
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                        )),
                  ),
                  SizedBox(height: Sizes.size24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.saveBackupSettings();
                        Get.back();
                        _showFeedbackSnackBar('Settings saved successfully', ColorsManager.success);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: ColorsManager.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Constants.kSave.tr,
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  /// Sheet toggle tile
  Widget _buildSheetToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorsManager.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.black,
                  ),
                ),
                SizedBox(height: Sizes.size4),
                Text(
                  subtitle,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorsManager.primary,
          ),
        ],
      ),
    );
  }
}

/// Backup progress sheet widget
class BackupProgressSheetWidget extends StatelessWidget {
  const BackupProgressSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                Constants.kBackupProgress.tr,
                style: StylesManager.bold(
                  fontSize: FontSize.xLarge,
                  color: ColorsManager.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close,
                  color: ColorsManager.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: Sizes.size20),
          // Progress indicator
          Obx(() => SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 8,
                      value: controller.backupProgress.value,
                      valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
                      backgroundColor: ColorsManager.primary.withOpacity(0.2),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(controller.backupProgress.value * 100).toInt()}%',
                          style: StylesManager.bold(
                            fontSize: FontSize.large,
                            color: ColorsManager.primary,
                          ),
                        ),
                        SizedBox(height: Sizes.size4),
                        Text(
                          'Complete',
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          SizedBox(height: Sizes.size20),
          // Current task
          Obx(() => Text(
                controller.currentBackupTask.value,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: ColorsManager.black,
                ),
                textAlign: TextAlign.center,
              )),
          SizedBox(height: Sizes.size8),
          Obx(() => Text(
                controller.getFormattedBackupStatus(),
                style: StylesManager.regular(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              )),
          SizedBox(height: Sizes.size24),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.cancelBackup();
                Get.back();
                _showFeedbackSnackBar('Backup cancelled', ColorsManager.accent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.error,
                foregroundColor: ColorsManager.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                Constants.kCancel.tr,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logout confirmation dialog widget
class LogoutConfirmationDialogWidget extends StatelessWidget {
  const LogoutConfirmationDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsManager.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                size: 32,
                color: ColorsManager.error,
              ),
            ),
            SizedBox(height: Sizes.size16),
            // Title
            Text(
              'Sign Out',
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: ColorsManager.black,
              ),
            ),
            SizedBox(height: Sizes.size8),
            // Subtitle
            Text(
              'Are you sure you want to sign out?',
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: ColorsManager.borderColor),
                    ),
                    child: Text(
                      Constants.kCancel.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                        color: ColorsManager.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Sizes.size12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.find<SettingsController>().logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.error,
                      foregroundColor: ColorsManager.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      Constants.kLogout.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete account confirmation dialog widget
class DeleteAccountConfirmationDialogWidget extends StatelessWidget {
  const DeleteAccountConfirmationDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsManager.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                size: 32,
                color: ColorsManager.error,
              ),
            ),
            SizedBox(height: Sizes.size16),
            // Title
            Text(
              'Delete Account',
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: ColorsManager.black,
              ),
            ),
            SizedBox(height: Sizes.size8),
            // Subtitle
            Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: ColorsManager.borderColor),
                    ),
                    child: Text(
                      Constants.kCancel.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                        color: ColorsManager.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Sizes.size12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back(); // Close dialog
                      await Get.find<SettingsController>().deleteAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.error,
                      foregroundColor: ColorsManager.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete Account',
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Show feedback snackbar
void _showFeedbackSnackBar(String message, Color color) {
  Get.showSnackbar(
    GetSnackBar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      icon: Icon(
        color == ColorsManager.success ? Icons.check_circle : Icons.info,
        color: ColorsManager.white,
      ),
    ),
  );
}
