import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/backup_controller.dart';

/// Backup Stats Widget - Stateful & Explanatory Design
///
/// Design Philosophy:
/// - Show meaningful stats with context (not just numbers)
/// - Explain what each stat means for the user
/// - Animated counters for visual feedback
/// - State-aware empty state with guidance
class BackupStatsWidget extends GetView<BackupController> {
  const BackupStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.lastBackupStats.value;

      if (stats == null) {
        return _buildEmptyState();
      }

      final contactsCount = stats['contacts_count'] ?? 0;
      final imagesCount = stats['images_count'] ?? 0;
      final filesCount = stats['files_count'] ?? 0;
      final totalItems = contactsCount + imagesCount + filesCount;

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
            // Stats Grid - 2x2 with explanations
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // First row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: contactsCount,
                          label: 'Chats',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: Colors.blue,
                          explanation: 'Conversations backed up',
                          index: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          value: imagesCount,
                          label: 'Media',
                          icon: Icons.photo_library_outlined,
                          color: Colors.purple,
                          explanation: 'Photos & videos saved',
                          index: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: filesCount,
                          label: 'Files',
                          icon: Icons.folder_outlined,
                          color: Colors.orange,
                          explanation: 'Documents & attachments',
                          index: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          value: totalItems,
                          label: 'Total',
                          icon: Icons.inventory_2_outlined,
                          color: ColorsManager.primary,
                          explanation: 'All items protected',
                          isHighlighted: true,
                          index: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Storage info footer
            _buildStorageInfo(stats),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms);
    });
  }

  Widget _buildStatCard({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
    required String explanation,
    bool isHighlighted = false,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showStatDetails(label, value, explanation, icon, color);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? ColorsManager.primary.withValues(alpha: 0.05)
              : ColorsManager.zenSurface,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(
                  color: ColorsManager.primary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and value row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: color,
                  ),
                ),
                const Spacer(),
                // Tap hint
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: ColorsManager.zenMuted.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Large number with animation
            _AnimatedCounter(
              value: value,
              style: StylesManager.zenStat(
                color: isHighlighted
                    ? ColorsManager.primary
                    : ColorsManager.zenCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.zenGray,
              ),
            ),
            const SizedBox(height: 2),
            // Explanation
            Text(
              explanation,
              style: StylesManager.zenCaption(
                color: ColorsManager.zenMuted,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
          .slideY(begin: 0.2, end: 0, duration: 300.ms),
    );
  }

  Widget _buildStorageInfo(Map<String, dynamic> stats) {
    final storageUsed = stats['storage_used'] ?? 0;
    final storageLimit = stats['storage_limit'] ?? 5000; // Default 5GB
    final usagePercent = (storageUsed / storageLimit * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.zenBorder.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 18,
                color: ColorsManager.zenGray,
              ),
              const SizedBox(width: 8),
              Text(
                'Cloud Storage',
                style: StylesManager.dmSansMedium(
                  fontSize: 14,
                  color: ColorsManager.zenCharcoal,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatStorage(storageUsed)} / ${_formatStorage(storageLimit)}',
                style: StylesManager.zenCaption(
                  color: ColorsManager.zenGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Storage bar
          Stack(
            children: [
              // Background
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Used
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: (Get.width - 72) * (usagePercent / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: usagePercent > 80
                        ? [ColorsManager.warning, ColorsManager.error]
                        : [ColorsManager.primary, ColorsManager.primary],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Storage tip
          Row(
            children: [
              Icon(
                usagePercent > 80
                    ? Icons.warning_amber_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 14,
                color: usagePercent > 80
                    ? ColorsManager.warning
                    : ColorsManager.zenMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  usagePercent > 80
                      ? 'Running low on storage. Consider upgrading.'
                      : 'Your data is safely stored in the cloud',
                  style: StylesManager.zenCaption(
                    color: usagePercent > 80
                        ? ColorsManager.warning
                        : ColorsManager.zenMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          // Empty state icon with animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorsManager.zenBorder.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 36,
              color: ColorsManager.zenMuted,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
              ),
          const SizedBox(height: 20),
          Text(
            'No backup data yet',
            style: StylesManager.dmSansSemiBold(
              fontSize: 18,
              color: ColorsManager.zenCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your backup statistics will appear here\nafter your first successful backup',
            style: StylesManager.zenBody(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // What to expect section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsManager.info.withValues(alpha: 0.05),
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
                      color: ColorsManager.info,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What you\'ll see',
                      style: StylesManager.dmSansMedium(
                        fontSize: 13,
                        color: ColorsManager.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildExpectationItem('Number of chats backed up'),
                _buildExpectationItem('Media files (photos & videos)'),
                _buildExpectationItem('Documents & attachments'),
                _buildExpectationItem('Cloud storage usage'),
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

  Widget _buildExpectationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: ColorsManager.zenMuted,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: StylesManager.zenCaption(),
          ),
        ],
      ),
    );
  }

  void _showStatDetails(
    String label,
    int value,
    String explanation,
    IconData icon,
    Color color,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: StylesManager.dmSansBold(
                        fontSize: 32,
                        color: ColorsManager.zenCharcoal,
                      ),
                    ),
                    Text(
                      label,
                      style: StylesManager.zenBody(
                        color: ColorsManager.zenGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Divider
            Container(
              height: 1,
              color: ColorsManager.zenBorder,
            ),
            const SizedBox(height: 20),
            // Explanation
            Text(
              'What this means',
              style: StylesManager.dmSansMedium(
                fontSize: 15,
                color: ColorsManager.zenCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDetailedExplanation(label, value),
              style: StylesManager.zenBody(),
            ),
            const SizedBox(height: 20),
            // Tip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorsManager.zenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: ColorsManager.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getTip(label),
                      style: StylesManager.zenCaption(
                        color: ColorsManager.zenGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _getDetailedExplanation(String label, int value) {
    switch (label) {
      case 'Chats':
        return 'You have $value chat conversations safely backed up. This includes all messages, timestamps, and delivery status for each conversation.';
      case 'Media':
        return 'Your backup contains $value media files including photos and videos. These are stored in their original quality.';
      case 'Files':
        return 'You have $value documents and attachments backed up. This includes PDFs, voice messages, and other file types.';
      case 'Total':
        return 'In total, $value items are protected in your backup. All items are encrypted and can be restored to any device.';
      default:
        return 'This data is safely backed up and encrypted.';
    }
  }

  String _getTip(String label) {
    switch (label) {
      case 'Chats':
        return 'Run regular backups to capture new conversations';
      case 'Media':
        return 'Media files use the most storage space';
      case 'Files':
        return 'Delete old files to reduce backup time';
      case 'Total':
        return 'Your data can be restored on any new device';
      default:
        return 'Keep your backup up to date';
    }
  }

  String _formatStorage(int mb) {
    if (mb >= 1000) {
      return '${(mb / 1000).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }
}

/// Animated counter widget for visual feedback
class _AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCounter({
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$animatedValue',
          style: style,
        );
      },
    );
  }
}
