import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';

/// Backup section widget with modern card design
class BackupSectionWidget extends StatelessWidget {
  const BackupSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Constants.kBackup.tr,
                style: StylesManager.bold(
                  fontSize: FontSize.xLarge,
                  color: ColorsManager.textPrimaryAdaptive(context),
                ),
              ),
              IconButton(
                onPressed: () =>
                    Get.find<SettingsController>().showBackupSettings(),
                tooltip: 'Backup settings',
                icon: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: ColorsManager.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          SizedBox(height: Sizes.size16),
          // Quick Actions
          const QuickActionsWidget(),
          SizedBox(height: Sizes.size20),
          // Backup Statistics Card
          Obx(() => BackupStatsCardWidget(
                statistics:
                    Get.find<SettingsController>().getBackupStatisticsSummary(),
                lastBackupDate:
                    Get.find<SettingsController>().getFormattedLastBackupDate(),
              )),
          SizedBox(height: Sizes.size20),
          // Individual Backup Options
          const BackupOptionsWidget(),
        ],
      ),
    );
  }
}

/// Quick action buttons with smooth animations
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Row(
      children: [
        Expanded(
          child: QuickActionCardWidget(
            title: Constants.kQuickBackup.tr,
            subtitle: '30 sec',
            icon: Icons.flash_on,
            color: ColorsManager.accent,
            onTap: () => controller.startFullBackup(),
          ),
        ),
        SizedBox(width: Sizes.size12),
        Expanded(
          child: QuickActionCardWidget(
            title: Constants.kFullBackup.tr,
            subtitle: '5 min',
            icon: Icons.backup,
            color: ColorsManager.primary,
            onTap: () => controller.startFullBackup(),
          ),
        ),
      ],
    );
  }
}

/// Modern quick action card
class QuickActionCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: Sizes.size12),
            Text(
              title,
              style: StylesManager.semiBold(
                fontSize: FontSize.medium,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size4),
            Text(
              subtitle,
              style: StylesManager.regular(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Backup statistics card
class BackupStatsCardWidget extends StatelessWidget {
  final String statistics;
  final String lastBackupDate;

  const BackupStatsCardWidget({
    super.key,
    required this.statistics,
    required this.lastBackupDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.cardAdaptive(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.textPrimaryAdaptive(context)
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: ColorsManager.primary,
            ),
          ),
          SizedBox(width: Sizes.size16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statistics,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.black,
                  ),
                ),
                SizedBox(height: Sizes.size4),
                Text(
                  lastBackupDate,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backup options with modern list tiles
class BackupOptionsWidget extends StatelessWidget {
  const BackupOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Column(
      children: [
        BackupOptionTileWidget(
          title: Constants.kDeviceInfoBackup.tr,
          subtitle: 'Device details and specifications',
          icon: Icons.phone_android,
          onTap: () => controller.startDeviceInfoBackup(),
        ),
        SizedBox(height: Sizes.size8),
        BackupOptionTileWidget(
          title: Constants.kContactsBackup.tr,
          subtitle: 'Phone contacts and groups',
          icon: Icons.contacts,
          onTap: () => controller.startContactsBackup(),
        ),
        SizedBox(height: Sizes.size8),
        BackupOptionTileWidget(
          title: Constants.kImagesBackup.tr,
          subtitle: 'Photos and media files',
          icon: Icons.photo_library,
          onTap: () => controller.startImagesBackup(),
        ),
        SizedBox(height: Sizes.size8),
        BackupOptionTileWidget(
          title: 'Location Data',
          subtitle: 'Current location and history',
          icon: Icons.location_on,
          onTap: () => controller.startLocationBackup(),
        ),
        SizedBox(height: Sizes.size8),
        BackupOptionTileWidget(
          title: 'Chat Messages',
          subtitle: 'Conversations and media',
          icon: Icons.chat_bubble,
          onTap: () => controller.startChatBackup(),
        ),
        SizedBox(height: Sizes.size16),
        // Auto Backup Toggle
        const AutoBackupToggleWidget(),
      ],
    );
  }
}

/// Modern backup option tile with smooth interactions
class BackupOptionTileWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const BackupOptionTileWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorsManager.cardAdaptive(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.textPrimaryAdaptive(context)
                  .withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ColorsManager.primary,
                size: 20,
              ),
            ),
            SizedBox(width: Sizes.size16),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorsManager.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto backup toggle with modern design
class AutoBackupToggleWidget extends StatelessWidget {
  const AutoBackupToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.cardAdaptive(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.textPrimaryAdaptive(context)
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsManager.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.autorenew,
              color: ColorsManager.accent,
              size: 20,
            ),
          ),
          SizedBox(width: Sizes.size16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Constants.kAutoBackup.tr,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.black,
                  ),
                ),
                SizedBox(height: Sizes.size4),
                Text(
                  'Automatically backup daily',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Switch(
                  key: ValueKey(controller.autoBackupEnabled.value),
                  value: controller.autoBackupEnabled.value,
                  onChanged: (value) {
                    controller.autoBackupEnabled.value = value;
                    controller.saveBackupSettings();
                    _showFeedbackSnackBar(
                      'Auto backup ${value ? 'enabled' : 'disabled'}',
                      value ? ColorsManager.success : ColorsManager.grey,
                    );
                  },
                  activeThumbColor: ColorsManager.primary,
                  inactiveTrackColor: ColorsManager.borderColor,
                ),
              )),
        ],
      ),
    );
  }

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
          color: Colors.white,
        ),
      ),
    );
  }
}
