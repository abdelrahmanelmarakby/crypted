import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import '../controllers/backup_controller.dart';
import '../widgets/backup_progress_widget.dart';
import '../widgets/backup_stats_widget.dart';
import '../widgets/backup_history_widget.dart';
import 'package:intl/intl.dart';

class BackupView extends GetView<BackupController> {
  const BackupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        elevation: 0,
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed('/backup/settings'),
            tooltip: 'Backup Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refreshBackupHistory();
        },
        color: ColorsManager.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Gradient
              _buildHeaderSection(context),

              const SizedBox(height: 16),

              // Progress Widget (shown when backup is running)
              Obx(() {
                if (controller.isBackupRunning.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const BackupProgressWidget(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    _buildStatusCard(context),
                    const SizedBox(height: 20),

                    // Quick Stats
                    const BackupStatsWidget(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 28),

                    // Backup History Section
                    _buildHistoryHeader(context),
                    const SizedBox(height: 12),
                    const BackupHistoryWidget(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Obx(() {
          final hasBackup = controller.lastBackupDate.value != null;
          final lastBackup = controller.lastBackupDateFormatted;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasBackup ? Icons.cloud_done : Icons.cloud_off_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasBackup ? 'Backup Active' : 'No Backup Yet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasBackup ? 'Last backup: $lastBackup' : 'Start your first backup',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Obx(() {
      final stats = controller.lastBackupStats.value;

      return Container(
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: ColorsManager.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Backup Status',
                  style: StylesManager.bold(
                    fontSize: FontSize.large,
                    color: ColorsManager.black,
                  ),
                ),
              ],
            ),

            if (stats != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              _buildStatusRow(
                icon: Icons.storage_outlined,
                label: 'Storage Used',
                value: _calculateStorageSize(stats),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildStatusRow(
                icon: Icons.access_time,
                label: 'Last Updated',
                value: _formatTimestamp(stats['last_backup_completed_at']),
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatusRow(
                icon: Icons.check_circle_outline,
                label: 'Status',
                value: 'Completed',
                color: Colors.teal,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.backup_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No backup data available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Start Backup" to begin',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (controller.hasError.value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Obx(() {
      final isRunning = controller.isBackupRunning.value;

      return Column(
        children: [
          // Main Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isRunning ? controller.stopBackup : controller.startBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : ColorsManager.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRunning ? Icons.stop_circle_outlined : Icons.backup_outlined,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRunning ? 'Stop Backup' : 'Start Backup Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onTap: () async {
                    await controller.refreshBackupHistory();
                    Get.snackbar(
                      'Refreshed',
                      'Backup data has been refreshed',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: ColorsManager.primary,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.restore,
                  label: 'Restore',
                  onTap: () {
                    _showRestoreDialog(context);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: ColorsManager.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsManager.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Backup History',
          style: StylesManager.bold(
            fontSize: FontSize.xLarge,
            color: ColorsManager.black,
          ),
        ),
        Obx(() {
          final count = controller.backupHistory.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: ColorsManager.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _calculateStorageSize(Map<String, dynamic> stats) {
    // Rough estimation based on item counts
    final contacts = stats['contacts_count'] ?? 0;
    final images = stats['images_count'] ?? 0;
    final files = stats['files_count'] ?? 0;

    // Estimate: 1KB per contact, 500KB per image, 2MB per file
    final sizeKB = (contacts * 1) + (images * 500) + (files * 2000);

    if (sizeKB < 1024) {
      return '${sizeKB.toStringAsFixed(0)} KB';
    } else if (sizeKB < 1024 * 1024) {
      return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeKB / (1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';

    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showRestoreDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restore, color: ColorsManager.primary),
            ),
            const SizedBox(width: 12),
            const Text('Restore Backup'),
          ],
        ),
        content: const Text(
          'Restore feature is coming soon. This will allow you to restore your contacts, images, and files from a previous backup.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
