import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/notification_settings_service.dart';
import 'package:crypted_app/app/modules/settings_v2/shared/widgets/settings_widgets.dart';
import '../controllers/notification_settings_controller.dart';

/// Enhanced Notification Settings View
/// Modern, comprehensive notification settings interface

class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundIconSetting,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          Constants.kNotifications.tr,
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
        final service = Get.find<NotificationSettingsService>();

        if (service.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Paddings.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master switch and DND quick toggle
                _buildMasterSection(service),

                // Do Not Disturb
                _buildDNDSection(service),

                // Message notifications
                _buildMessageSection(service),

                // Group notifications
                _buildGroupSection(service),

                // Status notifications
                _buildStatusSection(service),

                // Call settings
                _buildCallSection(service),

                // Reminders
                _buildReminderSection(service),

                // In-app settings
                _buildInAppSection(service),

                // Advanced
                _buildAdvancedSection(service),

                // Reset button
                _buildResetButton(),

                const SizedBox(height: Sizes.size32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMasterSection(NotificationSettingsService service) {
    return SettingsSection(
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.notifications_rounded,
              iconColor: ColorsManager.primary,
              title: 'Notifications',
              subtitle: 'Enable or disable all notifications',
              value: service.settings.value.global.masterSwitch,
              onChanged: controller.toggleMasterSwitch,
            )),
      ],
    );
  }

  Widget _buildDNDSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Do Not Disturb',
      children: [
        Obx(() {
          final dnd = service.settings.value.dnd;
          return SettingsSwitch(
            icon: Icons.do_not_disturb_on_rounded,
            iconColor: Colors.indigo,
            title: 'Do Not Disturb',
            subtitle: dnd.isActive
                ? 'Active${dnd.quickToggleUntil != null ? ' until ${_formatTime(dnd.quickToggleUntil!)}' : ''}'
                : 'Pause notifications temporarily',
            value: dnd.quickToggleEnabled,
            onChanged: (enabled) => controller.toggleQuickDND(enabled),
          );
        }),
        SettingsTile(
          icon: Icons.schedule_rounded,
          iconColor: Colors.indigo,
          title: 'Scheduled',
          subtitle: 'Set up automatic DND times',
          onTap: () => _showDNDScheduleSettings(),
        ),
        SettingsTile(
          icon: Icons.person_rounded,
          iconColor: Colors.indigo,
          title: 'Allowed Contacts',
          subtitle: 'People who can reach you during DND',
          onTap: () => _showAllowedContactsSettings(),
        ),
      ],
    );
  }

  Widget _buildMessageSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Message Notifications',
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.chat_bubble_rounded,
              iconColor: Colors.blue,
              title: 'Messages',
              subtitle: 'Notifications for private messages',
              value: service.settings.value.messages.enabled,
              onChanged: controller.toggleMessageNotifications,
            )),
        Obx(() => SettingsDropdown<NotificationSound>(
              icon: Icons.volume_up_rounded,
              iconColor: Colors.blue,
              title: 'Sound',
              value: service.settings.value.messages.sound.sound,
              options: NotificationSound.values
                  .map((s) => DropdownOption(
                        value: s,
                        label: s.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateMessageSound,
            )),
        Obx(() => SettingsDropdown<VibrationPattern>(
              icon: Icons.vibration_rounded,
              iconColor: Colors.blue,
              title: 'Vibration',
              value: service.settings.value.messages.vibration,
              options: VibrationPattern.values
                  .map((v) => DropdownOption(
                        value: v,
                        label: v.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateMessageVibration,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.favorite_rounded,
              iconColor: Colors.blue,
              title: 'Reaction Notifications',
              subtitle: 'When someone reacts to your message',
              value: service.settings.value.messages.reactions,
              onChanged: controller.toggleMessageReactions,
            )),
      ],
    );
  }

  Widget _buildGroupSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Group Notifications',
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.group_rounded,
              iconColor: Colors.green,
              title: 'Groups',
              subtitle: 'Notifications for group messages',
              value: service.settings.value.groups.enabled,
              onChanged: controller.toggleGroupNotifications,
            )),
        Obx(() => SettingsDropdown<NotificationSound>(
              icon: Icons.volume_up_rounded,
              iconColor: Colors.green,
              title: 'Sound',
              value: service.settings.value.groups.sound.sound,
              options: NotificationSound.values
                  .map((s) => DropdownOption(
                        value: s,
                        label: s.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateGroupSound,
            )),
        Obx(() => SettingsDropdown<VibrationPattern>(
              icon: Icons.vibration_rounded,
              iconColor: Colors.green,
              title: 'Vibration',
              value: service.settings.value.groups.vibration,
              options: VibrationPattern.values
                  .map((v) => DropdownOption(
                        value: v,
                        label: v.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateGroupVibration,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.alternate_email_rounded,
              iconColor: Colors.green,
              title: 'Mentions Only',
              subtitle: 'Only notify when you are mentioned',
              value: service.settings.value.groups.mentionsOnly,
              onChanged: controller.toggleMentionsOnly,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.favorite_rounded,
              iconColor: Colors.green,
              title: 'Reaction Notifications',
              subtitle: 'When someone reacts to your message',
              value: service.settings.value.groups.reactions,
              onChanged: controller.toggleGroupReactions,
            )),
      ],
    );
  }

  Widget _buildStatusSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Status Notifications',
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.circle_rounded,
              iconColor: Colors.orange,
              title: 'Status Updates',
              subtitle: 'When contacts post new status',
              value: service.settings.value.status.enabled,
              onChanged: controller.toggleStatusNotifications,
            )),
        Obx(() => SettingsDropdown<NotificationSound>(
              icon: Icons.volume_up_rounded,
              iconColor: Colors.orange,
              title: 'Sound',
              value: service.settings.value.status.sound.sound,
              options: NotificationSound.values
                  .map((s) => DropdownOption(
                        value: s,
                        label: s.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateStatusSound,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.favorite_rounded,
              iconColor: Colors.orange,
              title: 'Reaction Notifications',
              subtitle: 'When someone reacts to your status',
              value: service.settings.value.status.reactions,
              onChanged: controller.toggleStatusReactions,
            )),
      ],
    );
  }

  Widget _buildCallSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Calls',
      children: [
        Obx(() => SettingsDropdown<NotificationSound>(
              icon: Icons.ring_volume_rounded,
              iconColor: Colors.purple,
              title: 'Ringtone',
              value: service.settings.value.calls.ringtone.sound,
              options: NotificationSound.values
                  .map((s) => DropdownOption(
                        value: s,
                        label: s.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateCallRingtone,
            )),
        Obx(() => SettingsDropdown<VibrationPattern>(
              icon: Icons.vibration_rounded,
              iconColor: Colors.purple,
              title: 'Vibration',
              value: service.settings.value.calls.vibration,
              options: VibrationPattern.values
                  .map((v) => DropdownOption(
                        value: v,
                        label: v.displayName,
                      ))
                  .toList(),
              onChanged: controller.updateCallVibration,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.do_not_disturb_rounded,
              iconColor: Colors.purple,
              title: 'Silent During DND',
              subtitle: 'Mute call ringtone when DND is active',
              value: service.settings.value.calls.silentWhenDND,
              onChanged: controller.toggleSilentCallsDuringDND,
            )),
      ],
    );
  }

  Widget _buildReminderSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Reminders',
      subtitle: 'Get occasional reminders about messages or status updates you haven\'t seen',
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.alarm_rounded,
              iconColor: Colors.teal,
              title: 'Reminders',
              value: service.settings.value.reminders.enabled,
              onChanged: controller.toggleReminderNotifications,
            )),
      ],
    );
  }

  Widget _buildInAppSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'In-App Notifications',
      children: [
        Obx(() => SettingsSwitch(
              icon: Icons.volume_up_rounded,
              iconColor: ColorsManager.primary,
              title: 'Sounds',
              subtitle: 'Play sounds when app is open',
              value: service.settings.value.global.inAppSounds,
              onChanged: controller.toggleInAppSounds,
            )),
        Obx(() => SettingsSwitch(
              icon: Icons.vibration_rounded,
              iconColor: ColorsManager.primary,
              title: 'Vibration',
              subtitle: 'Vibrate when app is open',
              value: service.settings.value.global.inAppVibration,
              onChanged: controller.toggleInAppVibration,
            )),
      ],
    );
  }

  Widget _buildAdvancedSection(NotificationSettingsService service) {
    return SettingsSection(
      title: 'Advanced',
      children: [
        Obx(() => SettingsDropdown<PreviewLevel>(
              icon: Icons.preview_rounded,
              title: 'Preview',
              value: service.settings.value.global.showPreviews,
              options: PreviewLevel.values
                  .map((p) => DropdownOption(
                        value: p,
                        label: p.displayName,
                        description: p.description,
                      ))
                  .toList(),
              onChanged: controller.updatePreviewLevel,
            )),
        Obx(() => SettingsDropdown<NotificationGrouping>(
              icon: Icons.view_list_rounded,
              title: 'Notification Grouping',
              value: service.settings.value.global.grouping,
              options: NotificationGrouping.values
                  .map((g) => DropdownOption(
                        value: g,
                        label: g.displayName,
                        description: g.description,
                      ))
                  .toList(),
              onChanged: controller.updateGrouping,
            )),
        SettingsTile(
          icon: Icons.chat_rounded,
          title: 'Muted Chats',
          subtitle: '${controller.mutedChats.length} chats muted',
          onTap: () => _showMutedChats(),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Container(
      margin: const EdgeInsets.only(top: Paddings.large),
      child: SettingsSection(
        children: [
          SettingsTile(
            icon: Icons.restore_rounded,
            iconColor: Colors.red,
            title: 'Reset Notification Settings',
            subtitle: 'Restore all settings to defaults',
            onTap: controller.resetToDefaults,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showDNDScheduleSettings() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Row(
                children: [
                  Text(
                    'DND Schedules',
                    style: StylesManager.semiBold(fontSize: FontSize.large),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Add new schedule
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final schedules =
                    Get.find<NotificationSettingsService>().settings.value.dnd.schedules;

                if (schedules.isEmpty) {
                  return SettingsEmptyState(
                    icon: Icons.schedule,
                    title: 'No Schedules',
                    subtitle: 'Add a schedule to automatically enable DND',
                    actionLabel: 'Add Schedule',
                    onAction: () {
                      // Add schedule
                    },
                  );
                }

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return _buildScheduleItem(schedule);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildScheduleItem(DNDSchedule schedule) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.schedule, color: Colors.indigo),
      ),
      title: Text(schedule.name),
      subtitle: Text(
        '${_formatTimeOfDay(schedule.startTime)} - ${_formatTimeOfDay(schedule.endTime)}',
      ),
      trailing: Switch.adaptive(
        value: schedule.enabled,
        onChanged: (value) {
          controller.updateDNDSchedule(schedule.copyWith(enabled: value));
        },
        activeColor: ColorsManager.primary,
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showAllowedContactsSettings() {
    Get.snackbar(
      'Coming Soon',
      'Allowed contacts feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showMutedChats() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Text(
                'Muted Chats',
                style: StylesManager.semiBold(fontSize: FontSize.large),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final mutedChats = controller.mutedChats;

                if (mutedChats.isEmpty) {
                  return SettingsEmptyState(
                    icon: Icons.notifications_off,
                    title: 'No Muted Chats',
                    subtitle: 'You haven\'t muted any chats',
                  );
                }

                return ListView.builder(
                  itemCount: mutedChats.length,
                  itemBuilder: (context, index) {
                    final chat = mutedChats[index];
                    return ListTile(
                      title: Text('Chat ${chat.chatId.substring(0, 8)}...'),
                      subtitle: chat.mutedUntil != null
                          ? Text('Muted until ${_formatTime(chat.mutedUntil!)}')
                          : const Text('Muted indefinitely'),
                      trailing: TextButton(
                        onPressed: () => controller.unmuteChat(chat.chatId),
                        child: const Text('Unmute'),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBottomSheetHandle() {
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
