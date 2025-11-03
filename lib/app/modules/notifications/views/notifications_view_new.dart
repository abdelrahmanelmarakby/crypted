import 'package:crypted_app/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:crypted_app/app/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsViewNew extends GetView<NotificationsController> {
  const NotificationsViewNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          Constants.kNotifications.tr,
          style: StylesManager.bold(
            fontSize: FontSize.xLarge,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.orange),
            onPressed: _showResetConfirmation,
            tooltip: 'Reset to default',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Sizes.size16),

            // Messages Section
            _buildSectionHeader(
              'Messages',
              Icons.message_outlined,
              Colors.blue,
            ),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.notifications_outlined,
                  title: 'Show Notifications',
                  subtitle: 'Get notified about new messages',
                  value: controller.isShowNotificationEnabled.value,
                  onChanged: controller.toggleShowNotification,
                )),
            Obx(() => _buildSoundSelector(
                  icon: Icons.volume_up_outlined,
                  title: 'Notification Sound',
                  subtitle: 'Choose your message notification sound',
                  currentSound: controller.soundMessage,
                  onSoundChanged: controller.updateSoundMessage,
                  enabled: controller.isShowNotificationEnabled.value,
                )),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'Reaction Notifications',
                  subtitle: 'Get notified when someone reacts to your message',
                  value: controller.isReactionNotificationEnabled.value,
                  onChanged: controller.toggleReactionNotification,
                )),

            SizedBox(height: Sizes.size24),

            // Groups Section
            _buildSectionHeader(
              'Groups',
              Icons.group_outlined,
              Colors.purple,
            ),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.notifications_outlined,
                  title: 'Show Notifications',
                  subtitle: 'Get notified about group messages',
                  value: controller.isShowGroupNotificationEnabled.value,
                  onChanged: controller.toggleShowGroupNotification,
                )),
            Obx(() => _buildSoundSelector(
                  icon: Icons.volume_up_outlined,
                  title: 'Notification Sound',
                  subtitle: 'Choose your group notification sound',
                  currentSound: controller.soundGroup,
                  onSoundChanged: controller.updateSoundGroup,
                  enabled: controller.isShowGroupNotificationEnabled.value,
                )),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'Reaction Notifications',
                  subtitle: 'Get notified about group message reactions',
                  value: controller.isReactionGroupNotificationEnabled.value,
                  onChanged: controller.toggleReactionGroupNotification,
                )),

            SizedBox(height: Sizes.size24),

            // Status Section
            _buildSectionHeader(
              'Status Updates',
              Icons.fiber_manual_record,
              Colors.green,
            ),
            Obx(() => _buildSoundSelector(
                  icon: Icons.volume_up_outlined,
                  title: 'Notification Sound',
                  subtitle: 'Choose your status notification sound',
                  currentSound: controller.soundStatus,
                  onSoundChanged: controller.updateSoundStatus,
                  enabled: true,
                )),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'Reaction Notifications',
                  subtitle: 'Get notified about status reactions',
                  value: controller.isReactionStatusNotificationEnabled.value,
                  onChanged: controller.toggleReactionStatusNotification,
                )),

            SizedBox(height: Sizes.size24),

            // Other Settings
            _buildSectionHeader(
              'Other',
              Icons.settings_outlined,
              Colors.orange,
            ),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.alarm,
                  title: 'Reminders',
                  subtitle: 'Get occasional reminders about updates',
                  value: controller.isRemindersNotificationEnabled.value,
                  onChanged: controller.toggleRemindersNotification,
                )),
            Obx(() => _buildNotificationToggle(
                  icon: Icons.visibility_outlined,
                  title: 'Show Preview',
                  subtitle: 'Show message preview in notifications',
                  value: controller.isShowPreviewEnabled.value,
                  onChanged: controller.toggleShowPreview,
                )),

            SizedBox(height: Sizes.size32),

            // Info Card
            _buildInfoCard(),

            SizedBox(height: Sizes.size32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.small,
      ),
      padding: EdgeInsets.all(Paddings.normal),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: Sizes.size8),
          Text(
            title,
            style: StylesManager.semiBold(
              fontSize: FontSize.medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.xSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(Paddings.large),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: value
                    ? ColorsManager.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: value ? ColorsManager.primary : Colors.grey,
                size: 24,
              ),
            ),
            SizedBox(width: Sizes.size16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: Sizes.size4),
                  Text(
                    subtitle,
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Sizes.size12),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: ColorsManager.primary.withValues(alpha: 0.5),
              activeColor: ColorsManager.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector({
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentSound,
    required Function(String) onSoundChanged,
    required bool enabled,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.xSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => _showSoundPicker(currentSound, onSoundChanged)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(Paddings.large),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled
                        ? ColorsManager.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? ColorsManager.primary : Colors.grey,
                    size: 24,
                  ),
                ),
                SizedBox(width: Sizes.size16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      SizedBox(height: Sizes.size4),
                      Text(
                        subtitle,
                        style: StylesManager.regular(
                          fontSize: FontSize.small,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sizes.size12),
                if (enabled)
                  Row(
                    children: [
                      Text(
                        currentSound,
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: ColorsManager.primary,
                        ),
                      ),
                      SizedBox(width: Sizes.size8),
                      Icon(
                        Icons.chevron_right,
                        color: ColorsManager.grey,
                        size: 20,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Paddings.large),
      padding: EdgeInsets.all(Paddings.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ColorsManager.primary,
            size: 24,
          ),
          SizedBox(width: Sizes.size12),
          Expanded(
            child: Text(
              'Customize your notification preferences to stay updated on what matters most to you',
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSoundPicker(String currentSound, Function(String) onSoundChanged) {
    final sounds = ['Note', 'Bell', 'Chime', 'Alert', 'Ding', 'Silent'];

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(Paddings.large),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Icon(Icons.music_note, color: ColorsManager.primary),
                      SizedBox(width: Sizes.size12),
                      Text(
                        'Choose Sound',
                        style: StylesManager.bold(
                          fontSize: FontSize.large,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Sound Options
            ...sounds.map((sound) => InkWell(
                  onTap: () {
                    onSoundChanged(sound);
                    Get.back();
                    if (sound != 'Silent') {
                      // Play sound preview
                      Get.snackbar(
                        'Sound Changed',
                        'Notification sound set to $sound',
                        duration: Duration(seconds: 1),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Paddings.xLarge,
                      vertical: Paddings.large,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sound == 'Silent'
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: currentSound == sound
                              ? ColorsManager.primary
                              : Colors.grey,
                          size: 24,
                        ),
                        SizedBox(width: Sizes.size16),
                        Expanded(
                          child: Text(
                            sound,
                            style: StylesManager.medium(
                              fontSize: FontSize.medium,
                              color: currentSound == sound
                                  ? ColorsManager.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (currentSound == sound)
                          Icon(
                            Icons.check_circle,
                            color: ColorsManager.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                )),
            SizedBox(height: Sizes.size16),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  void _showResetConfirmation() async {
    final confirmed = await CustomBottomSheet.showConfirmation(
      title: 'Reset Notifications',
      message:
          'Are you sure you want to reset all notification settings to default? This action cannot be undone.',
      confirmText: 'Reset',
      confirmColor: Colors.orange,
      icon: Icons.restart_alt,
      iconColor: Colors.orange,
    );

    if (confirmed == true) {
      controller.resetNotificationSettings();
      Get.snackbar(
        'Success',
        'Notification settings have been reset',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }
}
