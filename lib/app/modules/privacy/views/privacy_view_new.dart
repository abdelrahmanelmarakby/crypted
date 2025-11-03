import 'package:crypted_app/app/modules/privacy/controllers/privacy_controller.dart';
import 'package:crypted_app/app/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyViewNew extends GetView<PrivacyController> {
  const PrivacyViewNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          Constants.kPrivacy.tr,
          style: StylesManager.bold(
            fontSize: FontSize.xLarge,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Sizes.size16),

            // Who Can See Section
            _buildSectionHeader('Who Can See'),
            _buildPrivacyCard(
              icon: Icons.person_outline,
              title: 'Profile Photo',
              subtitle: 'Control who can see your profile picture',
              value: controller.profilePictureValue,
              options: ['Everyone', 'My Contacts', 'Nobody'],
              onChanged: controller.updateProfilePicture,
            ),
            _buildPrivacyCard(
              icon: Icons.access_time,
              title: 'Last Seen',
              subtitle: 'Control who can see when you were last online',
              value: controller.lastSeenValue,
              options: ['Everyone', 'My Contacts', 'Nobody'],
              onChanged: controller.updateLastSeen,
            ),
            _buildPrivacyCard(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Control who can see your about info',
              value: controller.aboutValue,
              options: ['Everyone', 'My Contacts', 'Nobody'],
              onChanged: controller.updateAbout,
            ),
            _buildPrivacyCard(
              icon: Icons.visibility_outlined,
              title: 'Status',
              subtitle: 'Control who can see your status updates',
              value: controller.statusValue,
              options: ['Everyone', 'My Contacts', 'Nobody'],
              onChanged: controller.updateStatus,
            ),

            SizedBox(height: Sizes.size24),

            // Interactions Section
            _buildSectionHeader('Interactions'),
            _buildPrivacyCard(
              icon: Icons.group_outlined,
              title: 'Groups',
              subtitle: 'Control who can add you to groups',
              value: controller.groupsValue,
              options: ['Everyone', 'My Contacts'],
              onChanged: controller.updateGroups,
            ),
            _buildSwitchCard(
              icon: Icons.done_all,
              title: 'Read Receipts',
              subtitle: 'If turned off, you won\'t see others\' read receipts',
              value: controller.isReadReceiptsEnabled,
              onChanged: controller.toggleReadReceipts,
            ),

            SizedBox(height: Sizes.size24),

            // Security Section
            _buildSectionHeader('Security'),
            _buildActionCard(
              icon: Icons.block,
              title: 'Blocked Users',
              subtitle: 'View and manage blocked contacts',
              iconColor: Colors.red,
              onTap: _showBlockedUsers,
            ),
            _buildActionCard(
              icon: Icons.location_on_outlined,
              title: 'Live Location',
              subtitle: 'Manage active location sharing',
              iconColor: Colors.blue,
              onTap: _showLiveLocationChats,
            ),

            SizedBox(height: Sizes.size24),

            // Advanced Section
            _buildSectionHeader('Advanced'),
            _buildSwitchCard(
              icon: Icons.camera_alt_outlined,
              title: 'Camera Effects',
              subtitle: 'Use effects in camera and video calls',
              value: controller.isCameraEffectsEnabled,
              onChanged: controller.toggleCameraEffects,
            ),
            _buildPrivacyCard(
              icon: Icons.timer_outlined,
              title: 'Disappearing Messages',
              subtitle: 'Default timer for new chats',
              value: controller.defaultMessageTimerValue,
              options: ['Off', '24 Hours', '7 Days', '90 Days'],
              onChanged: controller.updateDefaultMessageTimer,
            ),

            SizedBox(height: Sizes.size32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.small,
      ),
      child: Text(
        title,
        style: StylesManager.semiBold(
          fontSize: FontSize.medium,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Obx(() => Container(
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
              onTap: () => _showPrivacyOptions(
                title: title,
                currentValue: value,
                options: options,
                onChanged: onChanged,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(Paddings.large),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: ColorsManager.primary,
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
                    Row(
                      children: [
                        Text(
                          value,
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
        ));
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Obx(() => Container(
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
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: ColorsManager.primary,
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
                  value: value.value,
                  onChanged: onChanged,
                  activeColor: ColorsManager.primary,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(Paddings.large),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
                Icon(
                  Icons.chevron_right,
                  color: ColorsManager.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyOptions({
    required String title,
    required String currentValue,
    required List<String> options,
    required Function(String) onChanged,
  }) {
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
                  Text(
                    title,
                    style: StylesManager.bold(
                      fontSize: FontSize.large,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Options
            ...options.map((option) => InkWell(
                  onTap: () {
                    onChanged(option);
                    Get.back();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Paddings.xLarge,
                      vertical: Paddings.large,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: StylesManager.medium(
                              fontSize: FontSize.medium,
                              color: currentValue == option
                                  ? ColorsManager.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (currentValue == option)
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

  void _showBlockedUsers() {
    // Implementation from previous code
    controller.getBlockedUsers().then((blockedUsers) {
      CustomBottomSheet.showInfo(
        title: 'Blocked Users',
        message: blockedUsers.isEmpty
            ? 'You haven\'t blocked anyone'
            : '${blockedUsers.length} user(s) blocked',
        icon: Icons.block,
        iconColor: Colors.red,
      );
    });
  }

  void _showLiveLocationChats() {
    // Implementation from previous code
    controller.getLiveLocationChats().then((chats) {
      CustomBottomSheet.showInfo(
        title: 'Live Location',
        message: chats.isEmpty
            ? 'No active location sharing'
            : '${chats.length} active location share(s)',
        icon: Icons.location_on,
        iconColor: Colors.blue,
      );
    });
  }
}
