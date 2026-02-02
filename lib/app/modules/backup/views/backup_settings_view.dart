import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import '../controllers/backup_controller.dart';

/// Backup Settings View - Zen/Minimal Design
///
/// Design Philosophy:
/// - Clean sections with minimal visual noise
/// - Typography-driven hierarchy
/// - Subtle dividers, no cards
/// - Consistent spacing rhythm
class BackupSettingsView extends GetView<BackupController> {
  const BackupSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: ColorsManager.scaffoldBg(context),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Minimal Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Automatic Backup Section
                  _buildSectionTitle('Automatic Backup'),
                  const SizedBox(height: 16),
                  _buildAutoBackupSettings(),
                  const SizedBox(height: 40),

                  // Notifications Section
                  _buildSectionTitle('Notifications'),
                  const SizedBox(height: 16),
                  _buildNotificationSettings(),
                  const SizedBox(height: 40),

                  // What Gets Backed Up Section
                  _buildSectionTitle('What gets backed up'),
                  const SizedBox(height: 16),
                  _buildBackupContentsInfo(),
                  const SizedBox(height: 40),

                  // Important Info Section
                  _buildInfoSection(),
                  const SizedBox(height: 40),

                  // iOS Notice
                  if (Platform.isIOS) ...[
                    _buildIOSNotice(),
                    const SizedBox(height: 40),
                  ],

                  // Danger Zone
                  _buildDangerZone(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Row(
        children: [
          // Back Button - minimal circle
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: ColorsManager.zenCharcoal,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: StylesManager.zenTitle(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: StylesManager.zenHeading(),
    );
  }

  Widget _buildAutoBackupSettings() {
    return Column(
      children: [
        // Enable Auto Backup
        Obx(() => _buildSettingRow(
              icon: Icons.schedule_rounded,
              title: 'Enable Auto Backup',
              subtitle: Platform.isIOS
                  ? 'Not available on iOS'
                  : 'Backup periodically in the background',
              trailing: _buildSwitch(
                value: controller.autoBackupEnabled.value,
                onChanged: Platform.isIOS ? null : controller.toggleAutoBackup,
              ),
              enabled: !Platform.isIOS,
            )),

        // Interval Picker (only if auto backup enabled)
        Obx(() {
          if (!controller.autoBackupEnabled.value || Platform.isIOS) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              _buildMinimalDivider(),
              _buildSettingRow(
                icon: Icons.timer_outlined,
                title: 'Backup Interval',
                subtitle: 'Every ${controller.autoBackupInterval.value} hours',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: ColorsManager.zenMuted,
                  size: 20,
                ),
                onTap: () => _showIntervalPicker(Get.context!),
              ),
              _buildMinimalDivider(),
              _buildSettingRow(
                icon: Icons.wifi_rounded,
                title: 'WiFi Only',
                subtitle: 'Only backup on WiFi connection',
                trailing: _buildSwitch(
                  value: controller.backupOnWifiOnly.value,
                  onChanged: controller.toggleBackupOnWifiOnly,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Obx(() => _buildSettingRow(
          icon: Icons.notifications_outlined,
          title: 'Show Notifications',
          subtitle: 'Get notified about backup status',
          trailing: _buildSwitch(
            value: controller.showNotifications.value,
            onChanged: controller.toggleNotifications,
          ),
        ));
  }

  Widget _buildBackupContentsInfo() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.smartphone_outlined,
          title: 'Device Information',
          subtitle: 'Brand, model, platform',
        ),
        _buildMinimalDivider(),
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          title: 'Location',
          subtitle: 'Current location and address',
        ),
        _buildMinimalDivider(),
        _buildInfoRow(
          icon: Icons.contacts_outlined,
          title: 'Contacts',
          subtitle: 'All your contacts',
        ),
        _buildMinimalDivider(),
        _buildInfoRow(
          icon: Icons.photo_library_outlined,
          title: 'Images',
          subtitle: 'Photos from your gallery',
        ),
        _buildMinimalDivider(),
        _buildInfoRow(
          icon: Icons.video_library_outlined,
          title: 'Files & Videos',
          subtitle: 'Videos and other media',
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final infoItems = [
      ('Your data is encrypted during transfer', Icons.lock_outline_rounded),
      ('Backups are stored securely in the cloud', Icons.cloud_outlined),
      ('Large backups may take several minutes', Icons.hourglass_empty_rounded),
      ('Ensure stable internet connection', Icons.signal_wifi_4_bar_rounded),
      ('Keep app open during backup', Icons.phone_android_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.info.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: ColorsManager.info,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Important Information',
                style: StylesManager.dmSansSemiBold(
                  fontSize: 15,
                  color: ColorsManager.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...infoItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.$2,
                      size: 16,
                      color: ColorsManager.zenGray,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$1,
                        style: StylesManager.zenBody(),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildIOSNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorsManager.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: ColorsManager.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Auto backup is not available on iOS due to platform limitations. Please use manual backup.',
              style: StylesManager.zenBody(
                color: ColorsManager.zenCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: StylesManager.dmSansSemiBold(
            fontSize: 14,
            color: ColorsManager.error,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _confirmDeleteBackups(Get.context!),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsManager.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorsManager.error.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: ColorsManager.error,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete All Backups',
                        style: StylesManager.dmSansMedium(
                          fontSize: 15,
                          color: ColorsManager.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permanently delete all backup data',
                        style: StylesManager.zenCaption(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ColorsManager.error.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  enabled ? ColorsManager.zenCharcoal : ColorsManager.zenMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: StylesManager.dmSansMedium(
                      fontSize: 15,
                      color: enabled
                          ? ColorsManager.zenCharcoal
                          : ColorsManager.zenMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: StylesManager.zenCaption(),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: ColorsManager.zenGray,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.dmSansMedium(
                    fontSize: 14,
                    color: ColorsManager.zenCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: StylesManager.zenCaption(),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_rounded,
            color: ColorsManager.primary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: isDisabled
              ? ColorsManager.zenBorder
              : value
                  ? ColorsManager.primary
                  : ColorsManager.zenBorder,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: ColorsManager.white,
              shape: BoxShape.circle,
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalDivider() {
    return Container(
      height: 1,
      color: ColorsManager.zenBorder,
    );
  }

  void _showIntervalPicker(BuildContext context) {
    final intervals = [6, 12, 24, 48, 72];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Backup Interval',
                style: StylesManager.zenHeading(),
              ),
            ),
            const SizedBox(height: 20),
            ...intervals.map((hours) {
              final isSelected = controller.autoBackupInterval.value == hours;
              String displayText;
              if (hours == 24) {
                displayText = 'Daily (24 hours)';
              } else if (hours == 48) {
                displayText = 'Every 2 days';
              } else if (hours == 72) {
                displayText = 'Every 3 days';
              } else {
                displayText = 'Every $hours hours';
              }

              return GestureDetector(
                onTap: () {
                  controller.updateAutoBackupInterval(hours);
                  Get.back();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: hours == intervals.first
                          ? BorderSide.none
                          : BorderSide(color: ColorsManager.zenBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                          style: StylesManager.dmSansMedium(
                            fontSize: 15,
                            color: isSelected
                                ? ColorsManager.primary
                                : ColorsManager.zenCharcoal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_rounded,
                          color: ColorsManager.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBackups(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ColorsManager.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: ColorsManager.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete All Backups?',
                style: StylesManager.zenHeading(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete all your backup data from the cloud. This action cannot be undone.',
                style: StylesManager.zenBody(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorsManager.zenBorder,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: StylesManager.dmSansMedium(
                              fontSize: 15,
                              color: ColorsManager.zenCharcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.deleteAllBackups();
                        Get.back();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorsManager.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Delete',
                            style: StylesManager.dmSansMedium(
                              fontSize: 15,
                              color: ColorsManager.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
