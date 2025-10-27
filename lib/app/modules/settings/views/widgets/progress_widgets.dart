import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';

/// Floating progress button
class FloatingProgressButtonWidget extends StatelessWidget {
  const FloatingProgressButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.showBackupProgressSheet(),
          borderRadius: BorderRadius.circular(60),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() => Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator.adaptive(
                      strokeWidth: 4,
                      value: controller.backupProgress.value,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(controller.backupProgress.value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.backup,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}

/// Enhanced inline progress display with detailed progress information
class EnhancedProgressDisplayWidget extends StatelessWidget {
  const EnhancedProgressDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Obx(() {
      if (controller.isBackupInProgress.value) {
        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with progress percentage and animated indicator
              Row(
                children: [
                  // Animated progress circle
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: controller.backupProgress.value,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backup in Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(controller.backupProgress.value * 100).toInt()}% Complete • ${_getEstimatedTimeRemaining()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cancel button with enhanced styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => controller.cancelBackup(),
                      icon: const Icon(
                        Icons.cancel,
                        size: 18,
                        color: Colors.red,
                      ),
                      tooltip: 'Cancel Backup',
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Enhanced progress bar with gradient
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: controller.backupProgress.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.blueAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Detailed current task with enhanced information
              Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
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
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getTaskIcon(controller.currentBackupTask.value),
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTaskTitle(controller.currentBackupTask.value),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getDetailedProgressText(controller.currentBackupTask.value),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(controller.backupProgress.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getProgressStage(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_shouldShowDetailedProgress()) ...[
                          const SizedBox(height: 16),
                          // Sub-progress bar for current task
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _getSubProgress(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getSubProgressText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              // Backup status indicator with enhanced styling
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.getFormattedBackupStatus(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  /// Get estimated time remaining for backup
  String _getEstimatedTimeRemaining() {
    final controller = Get.find<SettingsController>();
    final progress = controller.backupProgress.value;
    if (progress <= 0) return 'Calculating...';
    if (progress >= 1) return 'Complete';

    // Estimate based on current progress (assuming 2-5 minutes total)
    final remaining = (1 - progress) * 3; // Assume 3 minutes total
    final minutes = remaining ~/ 60;
    final seconds = (remaining % 60).toInt();

    if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    } else {
      return '${seconds}s remaining';
    }
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

  /// Get detailed progress text with location-specific information
  String _getDetailedProgressText(String task) {
    // For location backup, try to get current location and show it
    if (task.toLowerCase().contains('location')) {
      // In a real implementation, you would get the current location
      // For now, we'll show a placeholder that could be enhanced
      return 'Uploading Location Data, address (Mansoura, Egypt)';
    } else if (task.toLowerCase().contains('contact')) {
      return 'Backing up contacts and phone numbers';
    } else if (task.toLowerCase().contains('image') || task.toLowerCase().contains('photo')) {
      return 'Uploading photos and media files';
    } else if (task.toLowerCase().contains('device')) {
      return 'Collecting device information and specifications';
    } else if (task.toLowerCase().contains('chat')) {
      return 'Backing up conversations and messages';
    } else {
      return task;
    }
  }

  /// Get current progress stage
  String _getProgressStage() {
    final controller = Get.find<SettingsController>();
    final progress = controller.backupProgress.value;
    if (progress < 0.2) return 'Starting...';
    if (progress < 0.4) return 'In Progress...';
    if (progress < 0.6) return 'Processing...';
    if (progress < 0.8) return 'Almost Done...';
    return 'Finalizing...';
  }

  /// Check if detailed progress should be shown
  bool _shouldShowDetailedProgress() {
    final controller = Get.find<SettingsController>();
    return controller.backupProgress.value > 0.1; // Show when progress > 10%
  }

  /// Get sub-progress for current task (0.0 to 1.0)
  double _getSubProgress() {
    final controller = Get.find<SettingsController>();
    final progress = controller.backupProgress.value;
    // Simulate sub-progress within the current task
    return (progress * 5) % 1.0; // Cycle through 5 sub-tasks
  }

  /// Get sub-progress text
  String _getSubProgressText() {
    final controller = Get.find<SettingsController>();
    final progress = controller.backupProgress.value;
    final subProgress = (progress * 5) % 1.0;

    if (subProgress < 0.2) return 'Gathering data...';
    if (subProgress < 0.4) return 'Processing files...';
    if (subProgress < 0.6) return 'Compressing data...';
    if (subProgress < 0.8) return 'Uploading to server...';
    return 'Finalizing...';
  }

  /// Get status color based on backup status
  Color _getStatusColor() {
    final controller = Get.find<SettingsController>();
    switch (controller.backupStatus.value) {
      case BackupStatus.pending:
        return Colors.grey;
      case BackupStatus.inProgress:
        return Colors.blue;
      case BackupStatus.completed:
        return Colors.green;
      case BackupStatus.failed:
        return Colors.red;
      case BackupStatus.cancelled:
        return Colors.orange;
    }
  }
}
