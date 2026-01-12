import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';
import 'package:crypted_app/app/modules/settings_v2/shared/widgets/settings_widgets.dart';
import '../controllers/privacy_settings_controller.dart';

/// Enhanced Privacy Settings View
/// Modern, comprehensive privacy settings interface with score card

class PrivacySettingsView extends GetView<PrivacySettingsController> {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundIconSetting,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          Constants.kPrivacy.tr,
          style: StylesManager.semiBold(fontSize: FontSize.xLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        final service = Get.find<PrivacySettingsService>();

        if (service.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: Paddings.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Score Card
                _buildScoreCard(service),

                // Profile visibility
                _buildProfileVisibilitySection(service),

                // Communication settings
                _buildCommunicationSection(service),

                // Messages/Content
                _buildContentSection(service),

                // Security
                _buildSecuritySection(service),

                // Blocked contacts
                _buildBlockedSection(service),

                // Live location
                _buildLocationSection(service),

                // Advanced & Reset
                _buildAdvancedSection(service),

                const SizedBox(height: Sizes.size32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildScoreCard(PrivacySettingsService service) {
    return Obx(() => ScoreCard(
          score: service.privacyScore.value,
          label: _getScoreLabel(service.privacyScore.value),
          onTap: () => _showPrivacyCheckup(),
          actionLabel: 'Run Checkup',
        ));
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent Protection';
    if (score >= 60) return 'Good Protection';
    if (score >= 40) return 'Fair Protection';
    return 'Needs Attention';
  }

  Widget _buildProfileVisibilitySection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        title: 'Who can see my personal info',
        children: [
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.visibility_rounded,
                iconColor: Colors.blue,
                title: 'Last Seen',
                subtitle: _getExceptionText(
                    service.settings.value.profileVisibility.lastSeen),
                value: service.settings.value.profileVisibility.lastSeen.level,
                options: _visibilityOptions,
                onChanged: controller.updateLastSeenVisibility,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.photo_rounded,
                iconColor: Colors.blue,
                title: 'Profile Photo',
                subtitle: _getExceptionText(
                    service.settings.value.profileVisibility.profilePhoto),
                value: service.settings.value.profileVisibility.profilePhoto.level,
                options: _visibilityOptions,
                onChanged: controller.updateProfilePhotoVisibility,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.info_rounded,
                iconColor: Colors.blue,
                title: 'About',
                subtitle: _getExceptionText(
                    service.settings.value.profileVisibility.about),
                value: service.settings.value.profileVisibility.about.level,
                options: _visibilityOptions,
                onChanged: controller.updateAboutVisibility,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.circle_rounded,
                iconColor: Colors.green,
                title: 'Online Status',
                value: service.settings.value.profileVisibility.onlineStatus.level,
                options: _visibilityOptions,
                onChanged: controller.updateOnlineStatusVisibility,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.amp_stories_rounded,
                iconColor: Colors.orange,
                title: 'Status',
                value: service.settings.value.profileVisibility.status.level,
                options: _visibilityOptions,
                onChanged: controller.updateStatusVisibility,
              )),
        ],
      ),
    );
  }

  Widget _buildCommunicationSection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        title: 'Who can contact me',
        children: [
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.chat_rounded,
                iconColor: ColorsManager.primary,
                title: 'Messages',
                value: service.settings.value.communication.whoCanMessage.level,
                options: _visibilityOptions,
                onChanged: controller.updateWhoCanMessage,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.call_rounded,
                iconColor: ColorsManager.primary,
                title: 'Calls',
                value: service.settings.value.communication.whoCanCall.level,
                options: _visibilityOptions,
                onChanged: controller.updateWhoCanCall,
              )),
          Obx(() => SettingsDropdown<VisibilityLevel>(
                icon: Icons.group_add_rounded,
                iconColor: ColorsManager.primary,
                title: 'Add to Groups',
                value: service.settings.value.communication.whoCanAddToGroups.level,
                options: _visibilityOptions,
                onChanged: controller.updateWhoCanAddToGroups,
              )),
        ],
      ),
    );
  }

  Widget _buildContentSection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        title: 'Messages',
        children: [
          Obx(() => SettingsSwitch(
                icon: Icons.done_all_rounded,
                iconColor: Colors.blue,
                title: 'Read Receipts',
                subtitle: 'Let people know when you\'ve read their messages',
                value: service.settings.value.communication.showReadReceipts,
                onChanged: controller.toggleReadReceipts,
              )),
          Obx(() => SettingsSwitch(
                icon: Icons.keyboard_rounded,
                iconColor: Colors.blue,
                title: 'Typing Indicator',
                subtitle: 'Show when you\'re typing',
                value: service.settings.value.communication.showTypingIndicator,
                onChanged: controller.toggleTypingIndicator,
              )),
          Obx(() => SettingsSwitch(
                icon: Icons.screenshot_rounded,
                iconColor: Colors.orange,
                title: 'Allow Screenshots',
                subtitle: 'Others can screenshot your messages',
                value: service.settings.value.contentProtection.allowScreenshots,
                onChanged: controller.toggleScreenshots,
              )),
          Obx(() => SettingsSwitch(
                icon: Icons.forward_rounded,
                iconColor: Colors.orange,
                title: 'Allow Forwarding',
                subtitle: 'Others can forward your messages',
                value: service.settings.value.contentProtection.allowForwarding,
                onChanged: controller.toggleForwarding,
              )),
          Obx(() => SettingsDropdown<DisappearingDuration>(
                icon: Icons.timer_rounded,
                iconColor: Colors.purple,
                title: 'Default Disappearing Messages',
                value: service.settings.value.contentProtection.defaultDisappearingDuration,
                options: DisappearingDuration.values
                    .map((d) => DropdownOption(
                          value: d,
                          label: d.displayName,
                        ))
                    .toList(),
                onChanged: controller.updateDefaultDisappearingDuration,
              )),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        title: 'Security',
        children: [
          Obx(() => SettingsTile(
                icon: Icons.lock_rounded,
                iconColor: service.settings.value.security.twoStepVerification.enabled
                    ? Colors.green
                    : Colors.grey,
                title: 'Two-Step Verification',
                subtitle: service.settings.value.security.twoStepVerification.enabled
                    ? 'Enabled'
                    : 'Add extra security to your account',
                onTap: () => _showTwoStepSettings(),
              )),
          Obx(() => SettingsTile(
                icon: Icons.fingerprint_rounded,
                iconColor: service.settings.value.security.appLock.enabled
                    ? Colors.green
                    : Colors.grey,
                title: 'App Lock',
                subtitle: service.settings.value.security.appLock.enabled
                    ? 'Enabled - ${service.settings.value.security.appLock.timeout.displayName}'
                    : 'Require authentication to open app',
                onTap: () => _showAppLockSettings(),
              )),
          SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.purple,
            title: 'Chat Lock',
            subtitle: '${service.settings.value.security.lockedChats.length} locked chats',
            onTap: () => _showLockedChats(),
          ),
          Obx(() => SettingsTile(
                icon: Icons.devices_rounded,
                iconColor: Colors.blue,
                title: 'Active Sessions',
                subtitle: '${service.activeSessions.length} devices',
                onTap: () => _showActiveSessions(),
              )),
        ],
      ),
    );
  }

  Widget _buildBlockedSection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        children: [
          Obx(() => SettingsTile(
                icon: Icons.block_rounded,
                iconColor: Colors.red,
                title: 'Blocked Users',
                subtitle: '${service.settings.value.blockedUsers.length} contacts',
                onTap: () => _showBlockedUsers(),
              )),
        ],
      ),
    );
  }

  Widget _buildLocationSection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: SettingsSection(
        children: [
          Obx(() => SettingsTile(
                icon: Icons.location_on_rounded,
                iconColor: Colors.green,
                title: 'Live Location',
                subtitle: service.settings.value.activeLiveLocationShares.isEmpty
                    ? 'Not sharing with anyone'
                    : 'Sharing with ${service.settings.value.activeLiveLocationShares.length} chats',
                onTap: () => _showLiveLocationShares(),
              )),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(PrivacySettingsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.medium),
      child: Column(
        children: [
          SettingsSection(
            children: [
              Obx(() => SettingsSwitch(
                    icon: Icons.photo_library_rounded,
                    title: 'Hide Media in Gallery',
                    subtitle: 'Media won\'t appear in device gallery',
                    value: service.settings.value.contentProtection.hideMediaInGallery,
                    onChanged: controller.toggleHideMediaInGallery,
                  )),
            ],
          ),
          SettingsSection(
            children: [
              SettingsTile(
                icon: Icons.restore_rounded,
                iconColor: Colors.red,
                title: 'Reset Privacy Settings',
                subtitle: 'Restore all settings to defaults',
                onTap: controller.resetToDefaults,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  List<DropdownOption<VisibilityLevel>> get _visibilityOptions => [
        DropdownOption(
          value: VisibilityLevel.everyone,
          label: 'Everyone',
          icon: Icons.public_rounded,
        ),
        DropdownOption(
          value: VisibilityLevel.contacts,
          label: 'My Contacts',
          icon: Icons.people_rounded,
        ),
        DropdownOption(
          value: VisibilityLevel.nobody,
          label: 'Nobody',
          icon: Icons.lock_rounded,
        ),
      ];

  String? _getExceptionText(VisibilitySettingWithExceptions setting) {
    final totalExceptions =
        setting.includedUsers.length + setting.excludedUsers.length;
    if (totalExceptions == 0) return null;
    return '$totalExceptions exceptions';
  }

  void _showPrivacyCheckup() {
    Get.bottomSheet(
      _PrivacyCheckupSheet(controller: controller),
      isScrollControlled: true,
    );
  }

  void _showTwoStepSettings() {
    Get.snackbar(
      'Coming Soon',
      'Two-step verification setup will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showAppLockSettings() {
    Get.bottomSheet(
      _AppLockSettingsSheet(controller: controller),
      isScrollControlled: true,
    );
  }

  void _showLockedChats() {
    Get.bottomSheet(
      _LockedChatsSheet(controller: controller),
      isScrollControlled: true,
    );
  }

  void _showActiveSessions() {
    Get.bottomSheet(
      _ActiveSessionsSheet(controller: controller),
      isScrollControlled: true,
    );
  }

  void _showBlockedUsers() {
    Get.bottomSheet(
      _BlockedUsersSheet(controller: controller),
      isScrollControlled: true,
    );
  }

  void _showLiveLocationShares() {
    Get.snackbar(
      'Live Location',
      'No active location shares',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// ============================================================================
// BOTTOM SHEETS
// ============================================================================

class _PrivacyCheckupSheet extends StatelessWidget {
  final PrivacySettingsController controller;

  const _PrivacyCheckupSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: ColorsManager.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Sizes.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Checkup',
                        style: StylesManager.bold(fontSize: FontSize.large),
                      ),
                      Text(
                        'Review your privacy settings',
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
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<PrivacyCheckupResult>(
              future: controller.runPrivacyCheckup(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final result = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(Paddings.large),
                  children: [
                    ScoreCard(
                      score: result.score,
                      label: result.scoreLabel,
                    ),
                    if (result.issues.isNotEmpty) ...[
                      const SizedBox(height: Sizes.size16),
                      Text(
                        'Issues Found',
                        style: StylesManager.semiBold(fontSize: FontSize.medium),
                      ),
                      const SizedBox(height: Sizes.size8),
                      ...result.issues.map((issue) => _buildIssueCard(issue)),
                    ],
                    if (result.recommendations.isNotEmpty) ...[
                      const SizedBox(height: Sizes.size16),
                      Text(
                        'Recommendations',
                        style: StylesManager.semiBold(fontSize: FontSize.medium),
                      ),
                      const SizedBox(height: Sizes.size8),
                      ...result.recommendations.map((rec) => _buildRecommendationCard(rec)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildIssueCard(PrivacyIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: StylesManager.medium(fontSize: FontSize.small),
                ),
                Text(
                  issue.description,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          if (issue.canAutoFix)
            TextButton(
              onPressed: () => controller.autoFixIssue(issue.id),
              child: const Text('Fix'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(PrivacyRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: StylesManager.medium(fontSize: FontSize.small),
                ),
                Text(
                  rec.description,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          if (rec.actionLabel != null)
            TextButton(
              onPressed: () {},
              child: Text(rec.actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _AppLockSettingsSheet extends StatelessWidget {
  final PrivacySettingsController controller;

  const _AppLockSettingsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Text(
                'App Lock',
                style: StylesManager.semiBold(fontSize: FontSize.large),
              ),
            ),
            const Divider(height: 1),
            Obx(() {
              final service = Get.find<PrivacySettingsService>();
              final settings = service.settings.value.security.appLock;

              return Column(
                children: [
                  SettingsSwitch(
                    icon: Icons.lock_rounded,
                    title: 'Enable App Lock',
                    value: settings.enabled,
                    onChanged: controller.toggleAppLock,
                  ),
                  if (settings.enabled) ...[
                    const Divider(height: 1, indent: 56),
                    SettingsSwitch(
                      icon: Icons.fingerprint_rounded,
                      title: 'Use Biometrics',
                      value: settings.biometricEnabled,
                      onChanged: controller.toggleBiometric,
                    ),
                    const Divider(height: 1, indent: 56),
                    SettingsDropdown<AppLockTimeout>(
                      icon: Icons.timer_rounded,
                      title: 'Lock Timeout',
                      value: settings.timeout,
                      options: AppLockTimeout.values
                          .map((t) => DropdownOption(
                                value: t,
                                label: t.displayName,
                              ))
                          .toList(),
                      onChanged: controller.updateAppLockTimeout,
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: Paddings.large),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _LockedChatsSheet extends StatelessWidget {
  final PrivacySettingsController controller;

  const _LockedChatsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Text(
              'Locked Chats',
              style: StylesManager.semiBold(fontSize: FontSize.large),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final lockedChats = controller.settings.security.lockedChats;

              if (lockedChats.isEmpty) {
                return SettingsEmptyState(
                  icon: Icons.lock_open_rounded,
                  title: 'No Locked Chats',
                  subtitle: 'Lock a chat to require authentication to view it',
                );
              }

              return ListView.builder(
                itemCount: lockedChats.length,
                itemBuilder: (context, index) {
                  final chat = lockedChats[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      child: const Icon(Icons.lock, color: Colors.purple),
                    ),
                    title: Text(chat.chatName ?? 'Chat'),
                    subtitle: Text('Locked ${_formatDate(chat.lockedAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.lock_open),
                      onPressed: () => controller.unlockChat(chat.chatId),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActiveSessionsSheet extends StatelessWidget {
  final PrivacySettingsController controller;

  const _ActiveSessionsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Row(
              children: [
                Text(
                  'Active Sessions',
                  style: StylesManager.semiBold(fontSize: FontSize.large),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.terminateAllOtherSessions,
                  child: const Text('Log Out All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final sessions = controller.activeSessions;

              if (sessions.isEmpty) {
                return SettingsEmptyState(
                  icon: Icons.devices,
                  title: 'No Other Sessions',
                  subtitle: 'This is your only active session',
                );
              }

              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ColorsManager.primary.withOpacity(0.1),
                      child: Icon(
                        _getDeviceIcon(session.deviceType),
                        color: ColorsManager.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(session.deviceName),
                        if (session.isCurrentSession) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Current',
                              style: StylesManager.medium(
                                fontSize: FontSize.xSmall,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${session.location ?? 'Unknown location'} • ${_formatLastActive(session.lastActive)}',
                    ),
                    trailing: session.isCurrentSession
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            onPressed: () =>
                                controller.terminateSession(session.sessionId),
                          ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet_android;
      case 'desktop':
        return Icons.computer;
      case 'web':
        return Icons.language;
      default:
        return Icons.devices;
    }
  }

  String _formatLastActive(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BlockedUsersSheet extends StatelessWidget {
  final PrivacySettingsController controller;

  const _BlockedUsersSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.block, color: Colors.red, size: 24),
                ),
                const SizedBox(width: Sizes.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocked Users',
                        style: StylesManager.bold(fontSize: FontSize.large),
                      ),
                      Text(
                        'Users you have blocked',
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
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final blocked = controller.blockedUsers;

              if (blocked.isEmpty) {
                return SettingsEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No Blocked Users',
                  subtitle: 'You haven\'t blocked anyone',
                );
              }

              return ListView.builder(
                itemCount: blocked.length,
                itemBuilder: (context, index) {
                  final user = blocked[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ColorsManager.primary.withOpacity(0.1),
                      backgroundImage: user.userPhotoUrl != null
                          ? NetworkImage(user.userPhotoUrl!)
                          : null,
                      child: user.userPhotoUrl == null
                          ? Text(
                              user.userName?.substring(0, 1).toUpperCase() ?? '?',
                              style: StylesManager.semiBold(
                                color: ColorsManager.primary,
                              ),
                            )
                          : null,
                    ),
                    title: Text(user.userName ?? 'Unknown'),
                    subtitle: Text('Blocked ${_formatDate(user.blockedAt)}'),
                    trailing: TextButton(
                      onPressed: () => controller.unblockUser(user.userId),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
