import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../controllers/backup_controller.dart';

/// Backup History Widget - Stateful & Explanatory Design
///
/// Design Philosophy:
/// - Staggered entrance animations for visual delight
/// - Clear success/failure states with explanations
/// - Educational empty state guiding users
/// - Detailed bottom sheet with actionable information
class BackupHistoryWidget extends GetView<BackupController> {
  const BackupHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.backupHistory;

      if (history.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorsManager.zenBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // List of history items with staggered animation
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: history.length > 5 ? 5 : history.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: ColorsManager.zenBorder,
              ),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryItem(context, item, index == 0, index)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 80 * index),
                      duration: 300.ms,
                    )
                    .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: Duration(milliseconds: 80 * index),
                      duration: 300.ms,
                    );
              },
            ),

            // View all link (if more than 5)
            if (history.length > 5)
              GestureDetector(
                onTap: () => _showAllHistory(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ColorsManager.zenSurface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all ${history.length} backups',
                          style: StylesManager.dmSansMedium(
                            fontSize: 14,
                            color: ColorsManager.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: ColorsManager.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms);
    });
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorsManager.zenBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Animated icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.history_rounded,
                size: 36,
                color: ColorsManager.zenMuted,
              ),
            ],
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
              ),
          const SizedBox(height: 20),
          Text(
            'No backup history yet',
            style: StylesManager.dmSansSemiBold(
              fontSize: 18,
              color: ColorsManager.zenCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed backups will appear here\nso you can track when you last saved your data',
            style: StylesManager.zenBody(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // What history shows section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsManager.zenSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: ColorsManager.zenGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What you\'ll see here',
                      style: StylesManager.dmSansMedium(
                        fontSize: 13,
                        color: ColorsManager.zenCharcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoItem(Icons.calendar_today_rounded, 'Date & time of each backup'),
                _buildInfoItem(Icons.check_circle_outline_rounded, 'Success or failure status'),
                _buildInfoItem(Icons.analytics_outlined, 'Items backed up count'),
                _buildInfoItem(Icons.restore_rounded, 'Option to restore from any backup'),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: ColorsManager.zenMuted,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: StylesManager.zenCaption(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    BackupHistoryItem item,
    bool isLatest,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBackupDetails(context, item);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Status Icon with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.success
                    ? ColorsManager.primary.withValues(alpha: 0.1)
                    : ColorsManager.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: item.success ? ColorsManager.primary : ColorsManager.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and badge row
                  Row(
                    children: [
                      Text(
                        item.formattedDate,
                        style: StylesManager.dmSansMedium(
                          fontSize: 15,
                          color: ColorsManager.zenCharcoal,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorsManager.primary,
                                ColorsManager.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Latest',
                            style: StylesManager.zenCaption(
                              color: ColorsManager.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Status text with explanation
                  Row(
                    children: [
                      Text(
                        item.success
                            ? '${item.itemsBackedUp} items saved'
                            : 'Backup failed',
                        style: StylesManager.zenCaption(
                          color: item.success
                              ? ColorsManager.zenGray
                              : ColorsManager.error,
                        ),
                      ),
                      if (item.success) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorsManager.zenMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getRelativeTime(item.date),
                          style: StylesManager.zenCaption(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow with hover hint
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: ColorsManager.zenMuted,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDetails(BuildContext context, BackupHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: ColorsManager.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with status
                        _buildDetailHeader(item),
                        const SizedBox(height: 24),

                        // Divider
                        Container(height: 1, color: ColorsManager.zenBorder),
                        const SizedBox(height: 24),

                        // Explanation section
                        Text(
                          'Backup Details',
                          style: StylesManager.dmSansSemiBold(
                            fontSize: 16,
                            color: ColorsManager.zenCharcoal,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats cards
                        if (item.stats != null) ...[
                          _buildDetailCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            color: Colors.blue,
                            label: 'Conversations',
                            value: '${item.stats!['contacts_count'] ?? 0}',
                            explanation: 'Chat threads backed up',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailCard(
                            icon: Icons.photo_library_outlined,
                            color: Colors.purple,
                            label: 'Media Files',
                            value: '${item.stats!['images_count'] ?? 0}',
                            explanation: 'Photos and videos saved',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailCard(
                            icon: Icons.folder_outlined,
                            color: Colors.orange,
                            label: 'Documents',
                            value: '${item.stats!['files_count'] ?? 0}',
                            explanation: 'Files and attachments',
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Timestamp details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorsManager.zenSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _buildTimestampRow(
                                'Backup started',
                                DateFormat('MMM d, yyyy • h:mm a').format(item.date),
                              ),
                              const SizedBox(height: 10),
                              _buildTimestampRow(
                                'Duration',
                                _formatDuration(item.duration),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Actions
                        if (item.success) ...[
                          _buildActionButton(
                            icon: Icons.restore_rounded,
                            label: 'Restore from this backup',
                            explanation: 'Replace current data with this backup',
                            onTap: () => _confirmRestore(item),
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete this backup',
                          explanation: 'Remove from backup history',
                          onTap: () => _confirmDelete(item),
                          isDangerous: true,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailHeader(BackupHistoryItem item) {
    return Row(
      children: [
        // Status Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item.success
                ? ColorsManager.primary.withValues(alpha: 0.1)
                : ColorsManager.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            item.success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: item.success ? ColorsManager.primary : ColorsManager.error,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.success ? 'Backup Successful' : 'Backup Failed',
                style: StylesManager.dmSansBold(
                  fontSize: 20,
                  color: ColorsManager.zenCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.success
                    ? '${item.itemsBackedUp} items safely stored'
                    : 'The backup could not be completed',
                style: StylesManager.zenBody(
                  color: ColorsManager.zenGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String explanation,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorsManager.zenBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: StylesManager.zenBody(
                    color: ColorsManager.zenGray,
                  ),
                ),
                Text(
                  explanation,
                  style: StylesManager.zenCaption(),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: StylesManager.dmSansBold(
              fontSize: 22,
              color: ColorsManager.zenCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: StylesManager.zenBody(),
        ),
        Text(
          value,
          style: StylesManager.dmSansMedium(
            fontSize: 14,
            color: ColorsManager.zenCharcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String explanation,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDangerous = false,
  }) {
    final color = isDangerous
        ? ColorsManager.error
        : isPrimary
            ? ColorsManager.primary
            : ColorsManager.zenGray;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : isDangerous
                  ? ColorsManager.error.withValues(alpha: 0.05)
                  : ColorsManager.zenSurface,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? Border.all(color: ColorsManager.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: StylesManager.dmSansMedium(
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  Text(
                    explanation,
                    style: StylesManager.zenCaption(),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BackupHistoryItem item) {
    Get.back();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Restore Backup?', style: StylesManager.zenHeading()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will replace your current data with the backup from ${item.formattedDate}.',
              style: StylesManager.zenBody(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: ColorsManager.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Current data will be overwritten',
                      style: StylesManager.zenCaption(
                        color: ColorsManager.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.zenGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.restoreBackup(item);
            },
            child: Text(
              'Restore',
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BackupHistoryItem item) {
    Get.back();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Backup?', style: StylesManager.zenHeading()),
        content: Text(
          'This backup will be permanently removed. You won\'t be able to restore from it.',
          style: StylesManager.zenBody(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.zenGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteBackup(item);
            },
            child: Text(
              'Delete',
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllHistory() {
    // Navigate to full history page
    Get.snackbar(
      'Coming Soon',
      'Full backup history view is being built',
      backgroundColor: ColorsManager.zenCharcoal,
      colorText: ColorsManager.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown';

    if (duration.inMinutes < 1) {
      return '${duration.inSeconds} seconds';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
    }
  }
}
