import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/contactInfo/controllers/contact_info_controller.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// 🎨 Enhanced Contact Info View
/// Modern, beautiful UI with rich engagement features
/// Better than WhatsApp, Telegram combined! 🚀
class ContactInfoView extends GetView<ContactInfoController> {
  const ContactInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      body: CustomScrollView(
        slivers: [
          // Hero Header with Avatar
          _buildHeroHeader(),

          // Quick Actions
          _buildQuickActions(),

          // Stats Section
          _buildStatsSection(),

          // Shared Media Preview
          _buildSharedMediaPreview(),

          // Info Cards
          _buildInfoCards(),

          // Privacy & Settings
          _buildPrivacySettings(),

          // Actions (Favorite, Export, etc.)
          _buildActions(),

          // Danger Zone
          _buildDangerZone(),

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: Sizes.size20),
          ),
        ],
      ),
    );
  }

  /// Hero Header with stunning visuals
  Widget _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: ColorsManager.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: ColorsManager.black),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: ColorsManager.black),
          onPressed: () => _showMoreOptions(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(() => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorsManager.primary.withOpacity(0.1),
                ColorsManager.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60), // Space for app bar

              // Avatar with online status
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ColorsManager.primary,
                          ColorsManager.primary.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorsManager.white,
                      ),
                      padding: EdgeInsets.all(4),
                      child: _buildAvatar(),
                    ),
                  ),

                  // Online status indicator
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorsManager.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: Sizes.size10),

              // Name
              Text(
                controller.displayName,
                style: StylesManager.bold(fontSize: FontSize.xXlarge),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Sizes.size4),

              // Status/Bio
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Paddings.xXLarge),
                child: Text(
                  controller.displaySubtitle,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildAvatar() {
    return controller.userImage != null && controller.userImage!.isNotEmpty
        ? ClipOval(
            child: AppCachedNetworkImage(
              imageUrl: controller.userImage!,
              fit: BoxFit.cover,
              width: 112,
              height: 112,
            ),
          )
        : CircleAvatar(
            radius: 56,
            backgroundColor: ColorsManager.primary.withOpacity(0.1),
            child: Text(
              controller.userName.isNotEmpty
                  ? controller.userName.substring(0, 1).toUpperCase()
                  : '?',
              style: StylesManager.bold(
                fontSize: 48,
                color: ColorsManager.primary,
              ),
            ),
          );
  }

  /// Quick Action Buttons (Call, Video, Message, etc.)
  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.normal,
        ),
        padding: EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickActionButton(
              icon: Iconsax.call_copy,
              label: 'Call',
              color: Colors.green,
              onTap: () => _makeVoiceCall(),
            ),
            _buildQuickActionButton(
              icon: Iconsax.video_copy,
              label: 'Video',
              color: Colors.blue,
              onTap: () => _makeVideoCall(),
            ),
            _buildQuickActionButton(
              icon: Iconsax.message_copy,
              label: 'Message',
              color: ColorsManager.primary,
              onTap: () => _openChat(),
            ),
            _buildQuickActionButton(
              icon: Iconsax.search_normal_copy,
              label: 'Search',
              color: Colors.orange,
              onTap: () => _searchInChat(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: Sizes.size4),
          Text(
            label,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Stats Section (Messages, Media, etc.)
  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        padding: EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Iconsax.message_text_copy,
                label: 'Messages',
                value: '1.2K',
                color: Colors.blue,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Iconsax.gallery_copy,
                label: 'Media',
                value: '342',
                color: Colors.purple,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Iconsax.document_copy,
                label: 'Files',
                value: '28',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: Sizes.size4),
        Text(
          value,
          style: StylesManager.bold(
            fontSize: FontSize.large,
            color: ColorsManager.black,
          ),
        ),
        Text(
          label,
          style: StylesManager.regular(
            fontSize: FontSize.xSmall,
            color: ColorsManager.grey,
          ),
        ),
      ],
    );
  }

  /// Shared Media Preview Gallery
  Widget _buildSharedMediaPreview() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        padding: EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.gallery_copy,
                      color: ColorsManager.primary,
                      size: 20,
                    ),
                    SizedBox(width: Sizes.size4),
                    Text(
                      'Shared Media',
                      style: StylesManager.semiBold(fontSize: FontSize.medium),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: controller.viewMediaLinksDocuments,
                  child: Text(
                    'View All',
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizes.size10),

            // Media Grid Preview (3x2)
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: ColorsManager.navbarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.gallery_copy,
                    color: ColorsManager.grey.withOpacity(0.3),
                    size: 32,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Info Cards (Bio, Phone, Email)
  Widget _buildInfoCards() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Iconsax.user_copy,
              title: 'Bio',
              subtitle: controller.userBio,
              onTap: () {},
            ),
            Divider(height: 1, indent: 70),
            _buildInfoCard(
              icon: Iconsax.call_copy,
              title: 'Phone',
              subtitle: controller.userPhone,
              onTap: () {},
            ),
            Divider(height: 1, indent: 70),
            _buildInfoCard(
              icon: Iconsax.sms_copy,
              title: 'Email',
              subtitle: controller.userEmail,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(Paddings.large),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ColorsManager.primary, size: 22),
            ),
            SizedBox(width: Sizes.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: StylesManager.medium(fontSize: FontSize.small),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Privacy & Settings
  Widget _buildPrivacySettings() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: Iconsax.notification_copy,
              title: 'Notifications',
              subtitle: 'Mute notifications from this chat',
              value: false,
              onChanged: (val) {},
            ),
            Divider(height: 1, indent: 70),
            Obx(() => _buildSwitchTile(
              icon: Iconsax.lock_copy,
              title: 'Lock Chat',
              subtitle: 'Require authentication to open',
              value: controller.isLockContactInfoEnabled.value,
              onChanged: controller.toggleShowNotification,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.all(Paddings.large),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 22),
          ),
          SizedBox(width: Sizes.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.semiBold(fontSize: FontSize.small),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: ColorsManager.primary,
          ),
        ],
      ),
    );
  }

  /// Actions Section
  Widget _buildActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Obx(() => _buildActionTile(
              icon: controller.isFavorite.value
                  ? Iconsax.star_1_copy
                  : Iconsax.star_copy,
              title: controller.isFavorite.value
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
              iconColor: Colors.amber,
              onTap: controller.toggleFavorite,
            )),
            Divider(height: 1, indent: 70),
            _buildActionTile(
              icon: Iconsax.document_text_copy,
              title: 'Starred Messages',
              iconColor: Colors.orange,
              onTap: controller.viewStarredMessages,
            ),
            Divider(height: 1, indent: 70),
            _buildActionTile(
              icon: Iconsax.export_copy,
              title: 'Export Chat',
              iconColor: Colors.blue,
              onTap: controller.exportChat,
            ),
          ],
        ),
      ),
    );
  }

  /// Danger Zone
  Widget _buildDangerZone() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.xSmall,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Obx(() => _buildActionTile(
              icon: Iconsax.slash_copy,
              title: controller.isBlocked.value ? 'Unblock User' : 'Block User',
              iconColor: Colors.red,
              isDanger: true,
              onTap: controller.toggleBlockUser,
            )),
            Divider(height: 1, indent: 70),
            _buildActionTile(
              icon: Iconsax.trash_copy,
              title: 'Clear Chat',
              iconColor: Colors.red,
              isDanger: true,
              onTap: controller.clearChat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(Paddings.large),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: Sizes.size10),
            Expanded(
              child: Text(
                title,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: isDanger ? Colors.red : ColorsManager.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorsManager.grey.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: Paddings.normal),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Paddings.large),
            // More options here
            SizedBox(height: Paddings.large),
          ],
        ),
      ),
    );
  }

  void _makeVoiceCall() {
    Get.snackbar(
      'Voice Call',
      'Calling ${controller.displayName}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _makeVideoCall() {
    Get.snackbar(
      'Video Call',
      'Starting video call with ${controller.displayName}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _openChat() {
    Get.back(); // Return to chat
  }

  void _searchInChat() {
    Get.snackbar(
      'Search',
      'Search in chat with ${controller.displayName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
