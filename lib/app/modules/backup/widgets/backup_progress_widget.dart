import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/backup_controller.dart';

/// Backup Progress Widget - Stateful & Explanatory Design
///
/// Design Philosophy:
/// - Shows clear phases: Preparing → Encrypting → Uploading → Verifying
/// - Each phase has explanatory text helping users understand the process
/// - Smooth animations between states
/// - Educational tooltips for technical terms
class BackupProgressWidget extends GetView<BackupController> {
  const BackupProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = controller.backupProgress.value;
      final status = controller.backupStatus.value;
      final currentPhase = _getPhaseFromProgress(progress);

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorsManager.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with overall progress
            _buildProgressHeader(progress),

            const SizedBox(height: 24),

            // Phase indicators - step by step
            _buildPhaseIndicators(currentPhase),

            const SizedBox(height: 24),

            // Current phase explanation
            _buildCurrentPhaseExplanation(currentPhase, status),

            const SizedBox(height: 20),

            // Linear progress with gradient
            _buildProgressBar(progress),

            const SizedBox(height: 16),

            // Time estimate
            _buildTimeEstimate(progress),
          ],
        ),
      );
    });
  }

  Widget _buildProgressHeader(double progress) {
    final percentage = (progress * 100).toInt();

    return Row(
      children: [
        // Animated percentage ring
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              // Background ring
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  backgroundColor: ColorsManager.zenBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.zenBorder,
                  ),
                ),
              ),
              // Progress ring with gradient effect
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Percentage text
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage',
                      style: StylesManager.dmSansBold(
                        fontSize: 22,
                        color: ColorsManager.zenCharcoal,
                      ),
                    ),
                    Text(
                      '%',
                      style: StylesManager.zenCaption(
                        color: ColorsManager.zenMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Status text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup in Progress',
                style: StylesManager.dmSansSemiBold(
                  fontSize: 18,
                  color: ColorsManager.zenCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your data is being securely processed',
                style: StylesManager.zenCaption(),
              ),
              const SizedBox(height: 8),
              // Security badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: ColorsManager.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'End-to-end encrypted',
                      style: StylesManager.zenCaption(
                        color: ColorsManager.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicators(BackupPhase currentPhase) {
    return Row(
      children: BackupPhase.values.map((phase) {
        final isCompleted = phase.index < currentPhase.index;
        final isCurrent = phase == currentPhase;

        return Expanded(
          child: Row(
            children: [
              // Phase indicator
              Expanded(
                child: Column(
                  children: [
                    // Icon circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? ColorsManager.primary
                            : isCurrent
                                ? ColorsManager.primary.withValues(alpha: 0.15)
                                : ColorsManager.zenBorder,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: ColorsManager.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: ColorsManager.white,
                              size: 18,
                            )
                          : Icon(
                              _getPhaseIcon(phase),
                              color: isCurrent
                                  ? ColorsManager.primary
                                  : ColorsManager.zenMuted,
                              size: 16,
                            ),
                    )
                        .animate(target: isCurrent ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.1, 1.1),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                        ),
                    const SizedBox(height: 8),
                    // Phase label
                    Text(
                      _getPhaseName(phase),
                      style: StylesManager.zenCaption(
                        color: isCompleted || isCurrent
                            ? ColorsManager.zenCharcoal
                            : ColorsManager.zenMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Connector line (except last)
              if (phase != BackupPhase.verifying)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [ColorsManager.primary, ColorsManager.primary]
                            : isCurrent
                                ? [
                                    ColorsManager.primary,
                                    ColorsManager.zenBorder
                                  ]
                                : [ColorsManager.zenBorder, ColorsManager.zenBorder],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentPhaseExplanation(BackupPhase phase, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.zenSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Animated indicator
          _buildPulsingIndicator(),
          const SizedBox(width: 14),
          // Explanation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPhaseTitle(phase),
                  style: StylesManager.dmSansMedium(
                    fontSize: 14,
                    color: ColorsManager.zenCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPhaseDescription(phase),
                  style: StylesManager.zenCaption(),
                ),
                const SizedBox(height: 8),
                // Current status
                Text(
                  status,
                  style: StylesManager.zenCaption(
                    color: ColorsManager.primary,
                  ),
                ),
              ],
            ),
          ),
          // Info tooltip
          GestureDetector(
            onTap: () => _showPhaseInfo(phase),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: ColorsManager.zenMuted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ColorsManager.primary,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 800.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 800.ms,
        );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar container
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress fill with gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 8,
              width: Get.width * 0.75 * progress, // Approximate width calculation
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary,
                    ColorsManager.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeEstimate(double progress) {
    // Calculate estimated time based on progress
    final remainingPercentage = 100 - (progress * 100).toInt();
    final estimatedMinutes = (remainingPercentage / 20).ceil(); // Rough estimate

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: ColorsManager.zenMuted,
            ),
            const SizedBox(width: 6),
            Text(
              estimatedMinutes > 0
                  ? 'About $estimatedMinutes min remaining'
                  : 'Almost done...',
              style: StylesManager.zenCaption(),
            ),
          ],
        ),
        // Cancel option (subtle)
        GestureDetector(
          onTap: () => _showCancelConfirmation(),
          child: Text(
            'Cancel',
            style: StylesManager.zenCaption(
              color: ColorsManager.zenMuted,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  BackupPhase _getPhaseFromProgress(double progress) {
    if (progress < 0.25) return BackupPhase.preparing;
    if (progress < 0.5) return BackupPhase.encrypting;
    if (progress < 0.85) return BackupPhase.uploading;
    return BackupPhase.verifying;
  }

  IconData _getPhaseIcon(BackupPhase phase) {
    switch (phase) {
      case BackupPhase.preparing:
        return Icons.folder_open_outlined;
      case BackupPhase.encrypting:
        return Icons.lock_outline_rounded;
      case BackupPhase.uploading:
        return Icons.cloud_upload_outlined;
      case BackupPhase.verifying:
        return Icons.verified_outlined;
    }
  }

  String _getPhaseName(BackupPhase phase) {
    switch (phase) {
      case BackupPhase.preparing:
        return 'Prepare';
      case BackupPhase.encrypting:
        return 'Encrypt';
      case BackupPhase.uploading:
        return 'Upload';
      case BackupPhase.verifying:
        return 'Verify';
    }
  }

  String _getPhaseTitle(BackupPhase phase) {
    switch (phase) {
      case BackupPhase.preparing:
        return 'Preparing your data...';
      case BackupPhase.encrypting:
        return 'Encrypting your data...';
      case BackupPhase.uploading:
        return 'Uploading to cloud...';
      case BackupPhase.verifying:
        return 'Verifying integrity...';
    }
  }

  String _getPhaseDescription(BackupPhase phase) {
    switch (phase) {
      case BackupPhase.preparing:
        return 'Gathering chats, media, and contacts for backup';
      case BackupPhase.encrypting:
        return 'Your data is being encrypted before leaving your device';
      case BackupPhase.uploading:
        return 'Securely transferring encrypted data to our servers';
      case BackupPhase.verifying:
        return 'Making sure everything was backed up correctly';
    }
  }

  void _showPhaseInfo(BackupPhase phase) {
    final String title;
    final String description;

    switch (phase) {
      case BackupPhase.preparing:
        title = 'Data Preparation';
        description =
            'We scan your device to identify all chats, media files, and contacts that need to be backed up. This ensures nothing is missed.';
        break;
      case BackupPhase.encrypting:
        title = 'End-to-End Encryption';
        description =
            'Your data is encrypted using AES-256 encryption before it ever leaves your device. Only you can decrypt and access this data.';
        break;
      case BackupPhase.uploading:
        title = 'Secure Upload';
        description =
            'Encrypted data is transferred to our secure cloud servers over HTTPS. The connection is verified to prevent interception.';
        break;
      case BackupPhase.verifying:
        title = 'Integrity Verification';
        description =
            'We compare checksums to ensure all data was transferred correctly. If any file is corrupted, it will be re-uploaded automatically.';
        break;
    }

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPhaseIcon(phase),
                    color: ColorsManager.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: StylesManager.zenHeading(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: StylesManager.zenBody(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCancelConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Cancel Backup?',
          style: StylesManager.zenHeading(),
        ),
        content: Text(
          'Your backup progress will be lost. You can start a new backup anytime.',
          style: StylesManager.zenBody(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Continue Backup',
              style: StylesManager.dmSansMedium(
                fontSize: 14,
                color: ColorsManager.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelBackup();
            },
            child: Text(
              'Cancel',
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
}

/// Backup phases for progress tracking
enum BackupPhase {
  preparing,
  encrypting,
  uploading,
  verifying,
}
