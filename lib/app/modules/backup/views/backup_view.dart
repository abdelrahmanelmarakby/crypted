import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/backup_controller.dart';
import '../widgets/backup_progress_widget.dart';
import '../widgets/backup_stats_widget.dart';
import '../widgets/backup_history_widget.dart';

/// Backup View - Stateful & Explanatory Design
///
/// Design Philosophy:
/// - Clear visual states: Empty → Ready → In Progress → Complete/Error
/// - Educational UI that guides users through the backup process
/// - Progressive disclosure with expandable sections
/// - Micro-interactions for every state change
class BackupView extends GetView<BackupController> {
  const BackupView({super.key});

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

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Section - State-aware
                  _buildHeroSection(),
                  const SizedBox(height: 32),

                  // Progress Section (when running)
                  Obx(() {
                    if (controller.isBackupRunning.value) {
                      return Column(
                        children: [
                          const BackupProgressWidget()
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // What Gets Backed Up - Explanatory Section
                  _buildExplanatoryBackupTypes(),
                  const SizedBox(height: 40),

                  // Stats Section with State Awareness
                  _buildStatsSection(),
                  const SizedBox(height: 40),

                  // History Section
                  _buildHistorySection(),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          // Back Button
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
          const Spacer(),
          // Help Button with tooltip
          GestureDetector(
            onTap: () => _showHelpSheet(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: ColorsManager.zenCharcoal,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings Button
          GestureDetector(
            onTap: () => Get.toNamed('/backup/settings'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorsManager.zenBorder,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: ColorsManager.zenCharcoal,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Section with multiple states
  Widget _buildHeroSection() {
    return Obx(() {
      final isRunning = controller.isBackupRunning.value;
      final hasError = controller.hasError.value;
      final hasBackup = controller.lastBackupDate.value != null;
      final progress = controller.backupProgress.value;

      // Determine current state
      final BackupState currentState = isRunning
          ? BackupState.inProgress
          : hasError
              ? BackupState.error
              : hasBackup
                  ? BackupState.complete
                  : BackupState.empty;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _getStateBackgroundColor(currentState),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getStateBorderColor(currentState),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Icon & Title Row
            Row(
              children: [
                // Animated State Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getStateIconBackground(currentState),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildStateIcon(currentState, progress),
                ),
                const SizedBox(width: 16),
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStateTitle(currentState),
                        style: StylesManager.dmSansBold(
                          fontSize: 22,
                          color: _getStateTitleColor(currentState),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStateSubtitle(currentState),
                        style: StylesManager.zenBody(
                          color: _getStateSubtitleColor(currentState),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // State-specific content
            _buildStateContent(currentState),

            // Error details (if error state)
            if (currentState == BackupState.error) ...[
              const SizedBox(height: 16),
              _buildErrorDetails(),
            ],

            const SizedBox(height: 20),

            // Action Button - State aware
            _buildActionButton(currentState),

            const SizedBox(height: 12),

            // Explanatory text below button
            Center(
              child: Text(
                _getActionExplanation(currentState),
                style: StylesManager.zenCaption(
                  color: _getStateSubtitleColor(currentState),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStateIcon(BackupState state, double progress) {
    switch (state) {
      case BackupState.empty:
        return Icon(
          Icons.cloud_outlined,
          color: ColorsManager.zenGray,
          size: 28,
        );
      case BackupState.inProgress:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: ColorsManager.primary.withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(ColorsManager.primary),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}',
              style: StylesManager.dmSansBold(
                fontSize: 10,
                color: ColorsManager.primary,
              ),
            ),
          ],
        );
      case BackupState.complete:
        return Icon(
          Icons.cloud_done_rounded,
          color: ColorsManager.primary,
          size: 28,
        );
      case BackupState.error:
        return Icon(
          Icons.cloud_off_rounded,
          color: ColorsManager.error,
          size: 28,
        );
    }
  }

  Widget _buildStateContent(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return _buildEmptyStateContent();
      case BackupState.inProgress:
        return _buildInProgressContent();
      case BackupState.complete:
        return _buildCompleteContent();
      case BackupState.error:
        return const SizedBox.shrink(); // Error details shown separately
    }
  }

  Widget _buildEmptyStateContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: ColorsManager.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why backup?',
                  style: StylesManager.dmSansMedium(
                    fontSize: 13,
                    color: ColorsManager.info,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Protect your chats, media, and contacts from data loss. Restore anytime on any device.',
                  style: StylesManager.zenCaption(
                    color: ColorsManager.zenGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPulsingDot(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.backupStatus.value,
                      style: StylesManager.dmSansMedium(
                        fontSize: 13,
                        color: ColorsManager.zenCharcoal,
                      ),
                    )),
                const SizedBox(height: 2),
                Text(
                  'This backup will complete even if you close the app',
                  style: StylesManager.zenCaption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ColorsManager.warning,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
            duration: 600.ms)
        .then()
        .scale(
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
            duration: 600.ms);
  }

  Widget _buildCompleteContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: ColorsManager.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => Text(
                  'Last backup: ${controller.lastBackupDateFormatted}',
                  style: StylesManager.dmSansMedium(
                    fontSize: 13,
                    color: ColorsManager.primary,
                  ),
                )),
          ),
          GestureDetector(
            onTap: () => controller.refreshBackupHistory(),
            child: Icon(
              Icons.refresh_rounded,
              color: ColorsManager.primary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorsManager.error.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: ColorsManager.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'What went wrong',
                style: StylesManager.dmSansMedium(
                  fontSize: 13,
                  color: ColorsManager.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                controller.errorMessage.value,
                style: StylesManager.zenBody(color: ColorsManager.zenGray),
              )),
          const SizedBox(height: 12),
          // Troubleshooting tips
          _buildTroubleshootingTip('Check your internet connection'),
          _buildTroubleshootingTip('Make sure you have enough storage'),
          _buildTroubleshootingTip('Try again in a few minutes'),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: ColorsManager.zenMuted,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            tip,
            style: StylesManager.zenCaption(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BackupState state) {
    final isRunning = state == BackupState.inProgress;

    return GestureDetector(
      onTap: isRunning ? null : controller.startBackup,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isRunning
              ? ColorsManager.zenBorder
              : state == BackupState.error
                  ? ColorsManager.error
                  : ColorsManager.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRunning)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ColorsManager.zenMuted),
                ),
              )
            else
              Icon(
                state == BackupState.error
                    ? Icons.refresh_rounded
                    : state == BackupState.complete
                        ? Icons.cloud_sync_rounded
                        : Icons.cloud_upload_rounded,
                color: ColorsManager.white,
                size: 22,
              ),
            const SizedBox(width: 10),
            Text(
              _getActionButtonText(state),
              style: StylesManager.dmSansSemiBold(
                fontSize: 16,
                color: isRunning ? ColorsManager.zenMuted : ColorsManager.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Explanatory Backup Types Section
  Widget _buildExplanatoryBackupTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'What gets backed up',
              style: StylesManager.zenHeading(),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showBackupTypesInfo(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: ColorsManager.zenMuted,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Toggle to include or exclude from backup',
          style: StylesManager.zenCaption(),
        ),
        const SizedBox(height: 20),

        // Backup type cards with explanations
        _buildBackupTypeCard(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: Colors.blue,
          title: 'Chats & Messages',
          description:
              'All conversations, text messages, and message attachments',
          sizeEstimate: '~2.5 GB',
          value: controller.backupChats,
          isExpanded: true,
        ),
        const SizedBox(height: 12),
        _buildBackupTypeCard(
          icon: Icons.photo_library_outlined,
          iconColor: Colors.purple,
          title: 'Media Files',
          description: 'Photos, videos, voice messages, and shared files',
          sizeEstimate: '~5.2 GB',
          value: controller.backupMedia,
        ),
        const SizedBox(height: 12),
        _buildBackupTypeCard(
          icon: Icons.contacts_outlined,
          iconColor: Colors.teal,
          title: 'Contacts',
          description: 'Phone contacts synced with this app',
          sizeEstimate: '~12 MB',
          value: controller.backupContacts,
        ),
        const SizedBox(height: 12),
        _buildBackupTypeCard(
          icon: Icons.smartphone_outlined,
          iconColor: Colors.orange,
          title: 'Device Settings',
          description: 'App preferences, notification settings, and themes',
          sizeEstimate: '~1 MB',
          value: controller.backupDeviceInfo,
        ),
      ],
    );
  }

  Widget _buildBackupTypeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String sizeEstimate,
    required RxBool value,
    bool isExpanded = false,
  }) {
    return Obx(() {
      final isEnabled = value.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? ColorsManager.white
              : ColorsManager.zenBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? ColorsManager.zenBorder : Colors.transparent,
            width: 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? iconColor.withValues(alpha: 0.1)
                        : ColorsManager.zenBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? iconColor : ColorsManager.zenMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StylesManager.dmSansMedium(
                          fontSize: 15,
                          color: isEnabled
                              ? ColorsManager.zenCharcoal
                              : ColorsManager.zenMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: StylesManager.zenCaption(
                          color: ColorsManager.zenMuted,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Toggle
                _buildAnimatedToggle(value),
              ],
            ),
            // Size estimate row
            if (isEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      color: ColorsManager.zenMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Estimated size: $sizeEstimate',
                      style: StylesManager.zenCaption(),
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

  Widget _buildAnimatedToggle(RxBool value) {
    return Obx(() => GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            value.value = !value.value;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              color:
                  value.value ? ColorsManager.primary : ColorsManager.zenBorder,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              alignment:
                  value.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: ColorsManager.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: value.value
                    ? Icon(
                        Icons.check_rounded,
                        color: ColorsManager.primary,
                        size: 16,
                      )
                    : null,
              ),
            ),
          ),
        ));
  }

  Widget _buildStatsSection() {
    return Obx(() {
      final hasStats = controller.lastBackupStats.value != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Backup Summary',
                style: StylesManager.zenHeading(),
              ),
              const Spacer(),
              if (hasStats)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: ColorsManager.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: StylesManager.zenCaption(
                          color: ColorsManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const BackupStatsWidget(),
        ],
      );
    });
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Backup History',
              style: StylesManager.zenHeading(),
            ),
            Obx(() {
              final count = controller.backupHistory.length;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorsManager.zenBorder,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count ${count == 1 ? 'backup' : 'backups'}',
                  style: StylesManager.zenCaption(),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'View details of previous backups',
          style: StylesManager.zenCaption(),
        ),
        const SizedBox(height: 16),
        const BackupHistoryWidget(),
      ],
    );
  }

  // Helper methods for state management
  Color _getStateBackgroundColor(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return ColorsManager.zenBorder.withValues(alpha: 0.5);
      case BackupState.inProgress:
        return ColorsManager.warning.withValues(alpha: 0.05);
      case BackupState.complete:
        return ColorsManager.primary.withValues(alpha: 0.05);
      case BackupState.error:
        return ColorsManager.error.withValues(alpha: 0.05);
    }
  }

  Color _getStateBorderColor(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return ColorsManager.zenBorder;
      case BackupState.inProgress:
        return ColorsManager.warning.withValues(alpha: 0.3);
      case BackupState.complete:
        return ColorsManager.primary.withValues(alpha: 0.3);
      case BackupState.error:
        return ColorsManager.error.withValues(alpha: 0.3);
    }
  }

  Color _getStateIconBackground(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return ColorsManager.zenBorder;
      case BackupState.inProgress:
        return ColorsManager.warning.withValues(alpha: 0.15);
      case BackupState.complete:
        return ColorsManager.primary.withValues(alpha: 0.15);
      case BackupState.error:
        return ColorsManager.error.withValues(alpha: 0.15);
    }
  }

  String _getStateTitle(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return 'Cloud Backup';
      case BackupState.inProgress:
        return 'Backing Up...';
      case BackupState.complete:
        return 'Backup Complete';
      case BackupState.error:
        return 'Backup Failed';
    }
  }

  String _getStateSubtitle(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return 'Your data is not backed up yet';
      case BackupState.inProgress:
        return 'Please keep the app open';
      case BackupState.complete:
        return 'Your data is safely stored';
      case BackupState.error:
        return 'Something went wrong';
    }
  }

  Color _getStateTitleColor(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return ColorsManager.zenCharcoal;
      case BackupState.inProgress:
        return ColorsManager.warning;
      case BackupState.complete:
        return ColorsManager.primary;
      case BackupState.error:
        return ColorsManager.error;
    }
  }

  Color _getStateSubtitleColor(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return ColorsManager.zenGray;
      case BackupState.inProgress:
        return ColorsManager.zenGray;
      case BackupState.complete:
        return ColorsManager.zenGray;
      case BackupState.error:
        return ColorsManager.zenGray;
    }
  }

  String _getActionButtonText(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return 'Create First Backup';
      case BackupState.inProgress:
        return 'Backup in Progress...';
      case BackupState.complete:
        return 'Backup Again';
      case BackupState.error:
        return 'Try Again';
    }
  }

  String _getActionExplanation(BackupState state) {
    switch (state) {
      case BackupState.empty:
        return 'Your data will be encrypted and stored securely';
      case BackupState.inProgress:
        return 'This may take a few minutes depending on data size';
      case BackupState.complete:
        return 'Create a new backup to capture recent changes';
      case BackupState.error:
        return 'Check your connection and try again';
    }
  }

  void _showHelpSheet() {
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
            Text(
              'How Backup Works',
              style: StylesManager.zenTitle(),
            ),
            const SizedBox(height: 20),
            _buildHelpItem(
              '1',
              'Choose what to backup',
              'Select the types of data you want to include in your backup',
            ),
            _buildHelpItem(
              '2',
              'Start the backup',
              'Tap the backup button to begin. Stay connected to the internet.',
            ),
            _buildHelpItem(
              '3',
              'Data is encrypted',
              'Your data is encrypted before being sent to our secure servers',
            ),
            _buildHelpItem(
              '4',
              'Restore anytime',
              'Restore your backup on this device or a new device',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildHelpItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: StylesManager.dmSansBold(
                  fontSize: 14,
                  color: ColorsManager.primary,
                ),
              ),
            ),
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
                    color: ColorsManager.zenCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: StylesManager.zenCaption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupTypesInfo() {
    Get.snackbar(
      'Backup Types',
      'Toggle each type to include or exclude from backup. Larger selections take longer to backup.',
      backgroundColor: ColorsManager.zenCharcoal,
      colorText: ColorsManager.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Backup state enumeration
enum BackupState {
  empty, // No backup yet
  inProgress, // Backup running
  complete, // Backup successful
  error, // Backup failed
}
