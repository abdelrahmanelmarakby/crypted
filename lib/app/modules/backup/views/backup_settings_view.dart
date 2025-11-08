import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import '../controllers/backup_controller.dart';

class BackupSettingsView extends GetView<BackupController> {
  const BackupSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Backup Settings'),
        elevation: 0,
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto Backup Section
          _buildSectionCard(
            context,
            title: 'Automatic Backup',
            icon: Icons.schedule,
            iconColor: Colors.blue,
            children: [
              Obx(() => _buildSwitchTile(
                context,
                title: 'Enable Auto Backup',
                subtitle: Platform.isIOS
                    ? 'Not available on iOS'
                    : 'Automatically backup your data periodically',
                value: controller.autoBackupEnabled.value,
                onChanged: Platform.isIOS ? null : controller.toggleAutoBackup,
                icon: Icons.backup_outlined,
              )),

              Obx(() {
                if (!controller.autoBackupEnabled.value || Platform.isIOS) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    const Divider(height: 1),
                    _buildListTile(
                      context,
                      title: 'Backup Interval',
                      subtitle: 'Every ${controller.autoBackupInterval.value} hours',
                      icon: Icons.timer_outlined,
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () => _showIntervalPicker(context),
                    ),
                    const Divider(height: 1),
                    Obx(() => _buildSwitchTile(
                      context,
                      title: 'WiFi Only',
                      subtitle: 'Only backup when connected to WiFi',
                      value: controller.backupOnWifiOnly.value,
                      onChanged: controller.toggleBackupOnWifiOnly,
                      icon: Icons.wifi,
                    )),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionCard(
            context,
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              Obx(() => _buildSwitchTile(
                context,
                title: 'Show Notifications',
                subtitle: 'Get notified about backup status',
                value: controller.showNotifications.value,
                onChanged: controller.toggleNotifications,
                icon: Icons.notification_important_outlined,
              )),
            ],
          ),

          const SizedBox(height: 16),

          // What Gets Backed Up
          _buildSectionCard(
            context,
            title: 'What Gets Backed Up',
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.green,
            children: [
              _buildInfoTile(
                context,
                icon: Icons.smartphone,
                title: 'Device Information',
                subtitle: 'Brand, model, platform',
                color: Colors.blue,
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: 'Current location and address',
                color: Colors.red,
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.contacts_outlined,
                title: 'Contacts',
                subtitle: 'All your contacts',
                color: Colors.purple,
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.image_outlined,
                title: 'Images',
                subtitle: 'Photos from your gallery',
                color: Colors.pink,
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.video_library_outlined,
                title: 'Files & Videos',
                subtitle: 'Videos and other media',
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Important Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoPoint(
                  '🔒 Your data is encrypted during transfer',
                  Colors.blue.shade900,
                ),
                const SizedBox(height: 8),
                _buildInfoPoint(
                  '☁️ Backups are stored securely in the cloud',
                  Colors.blue.shade900,
                ),
                const SizedBox(height: 8),
                _buildInfoPoint(
                  '⏱️ Large backups may take several minutes',
                  Colors.blue.shade900,
                ),
                const SizedBox(height: 8),
                _buildInfoPoint(
                  '📶 Ensure stable internet connection',
                  Colors.blue.shade900,
                ),
                const SizedBox(height: 8),
                _buildInfoPoint(
                  '📱 Keep app open during backup',
                  Colors.blue.shade900,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Platform Notice for iOS
          if (Platform.isIOS) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Auto backup is not available on iOS due to platform limitations. Please use manual backup.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Danger Zone
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDeleteBackups(context),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete All Backups',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Permanently delete all backup data',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: StylesManager.bold(
                    fontSize: FontSize.large,
                    color: ColorsManager.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    required IconData icon,
  }) {
    final isDisabled = onChanged == null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDisabled ? Colors.grey : ColorsManager.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDisabled ? Colors.grey : ColorsManager.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDisabled ? Colors.grey : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ColorsManager.primary,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ColorsManager.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: ColorsManager.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.check,
          color: Colors.green.shade700,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      color: ColorsManager.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Backup Interval',
                    style: StylesManager.bold(
                      fontSize: FontSize.xLarge,
                      color: ColorsManager.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...intervals.map((hours) {
              final isSelected = controller.autoBackupInterval.value == hours;
              String subtitle;
              if (hours == 24) {
                subtitle = 'Daily';
              } else if (hours == 48) {
                subtitle = 'Every 2 days';
              } else if (hours == 72) {
                subtitle = 'Every 3 days';
              } else {
                subtitle = 'Every $hours hours';
              }

              return Column(
                children: [
                  if (hours != intervals.first) const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorsManager.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: isSelected ? ColorsManager.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Every $hours hours',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? ColorsManager.primary : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? ColorsManager.primary.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: ColorsManager.primary,
                            size: 24,
                          )
                        : const SizedBox.shrink(),
                    onTap: () {
                      controller.updateAutoBackupInterval(hours);
                      Get.back();
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBackups(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Delete All Backups?')),
          ],
        ),
        content: const Text(
          'This will permanently delete all your backup data from the cloud. This action cannot be undone.\n\nAre you sure you want to continue?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => controller.deleteAllBackups(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
