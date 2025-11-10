import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/group_info/controllers/group_info_controller.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// 🎨 Clean Minimalist Group Info View
/// Simple, beautiful, and functional
class GroupInfoView extends GetView<GroupInfoController> {
  const GroupInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      body: controller.isLoading.value
          ? _buildLoadingView()
          : CustomScrollView(
              slivers: [
                // Hero Header with Group Avatar
                _buildHeroHeader(),

                // Quick Actions
                _buildQuickActions(),

                // Group Stats
                _buildGroupStats(),

                // Description (if available)
                if (controller.hasDescription) _buildDescription(),

                // Members Section
                _buildMembersSection(),

                // Shared Media Preview
                _buildSharedMediaPreview(),

                // Group Settings
                _buildGroupSettings(),

                // Actions (Favorite, Starred, Export)
                _buildActions(),

                // Danger Zone
                _buildDangerZone(),

                // Bottom spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: Sizes.size20),
                ),
              ],
            ),
    ));
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
          ),
          SizedBox(height: Sizes.size10),
          Text(
            "Loading group info...",
            style: StylesManager.regular(fontSize: FontSize.medium),
          ),
        ],
      ),
    );
  }

  /// Hero Header with Group Avatar
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
        if (controller.isCurrentUserAdmin)
          IconButton(
            icon: Icon(Icons.edit, color: ColorsManager.primary),
            onPressed: () => _showEditGroupDialog(),
          ),
        IconButton(
          icon: Icon(Icons.more_vert, color: ColorsManager.black),
          onPressed: () => _showMoreOptions(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: ColorsManager.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),

              // Group Avatar
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorsManager.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildGroupAvatar(),
                  ),

                  // Group indicator badge
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ColorsManager.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorsManager.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: Sizes.size10),

              // Group Name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Paddings.large),
                child: Text(
                  controller.displayName,
                  style: StylesManager.bold(fontSize: FontSize.xXlarge),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: Sizes.size4),

              // Member Count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    color: ColorsManager.grey,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    controller.displayMemberCount,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    return controller.displayImage != null && controller.displayImage!.isNotEmpty
        ? ClipOval(
            child: AppCachedNetworkImage(
              imageUrl: controller.displayImage!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          )
        : CircleAvatar(
            radius: 60,
            backgroundColor: ColorsManager.navbarColor,
            child: Icon(
              Icons.group,
              size: 48,
              color: ColorsManager.black,
            ),
          );
  }

  /// Quick Actions
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
            if (controller.isCurrentUserAdmin)
              _buildQuickActionButton(
                icon: Iconsax.user_add_copy,
                label: 'Add',
                color: Colors.green,
                onTap: () => _showAddMemberDialog(),
              ),
            _buildQuickActionButton(
              icon: Iconsax.search_normal_copy,
              label: 'Search',
              color: Colors.orange,
              onTap: () => _searchInGroup(),
            ),
            _buildQuickActionButton(
              icon: Iconsax.gallery_copy,
              label: 'Media',
              color: Colors.purple,
              onTap: controller.viewMediaLinksDocuments,
            ),
            _buildQuickActionButton(
              icon: Iconsax.message_copy,
              label: 'Chat',
              color: ColorsManager.primary,
              onTap: () => Get.back(),
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ColorsManager.navbarColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorsManager.black, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Group Stats
  Widget _buildGroupStats() {
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
                icon: Icons.people,
                label: 'Members',
                value: '${controller.memberCount.value ?? 0}',
                color: ColorsManager.black,
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
                value: '0', // Placeholder
                color: ColorsManager.black,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Iconsax.calendar_copy,
                label: 'Created',
                value: 'Today', // Placeholder
                color: ColorsManager.black,
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

  /// Description Section
  Widget _buildDescription() {
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
              children: [
                Icon(
                  Iconsax.document_text_copy,
                  color: ColorsManager.black,
                  size: 20,
                ),
                SizedBox(width: Sizes.size4),
                Text(
                  'Description',
                  style: StylesManager.semiBold(fontSize: FontSize.medium),
                ),
              ],
            ),
            SizedBox(height: Sizes.size10),
            Text(
              controller.displayDescription,
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Members Section
  Widget _buildMembersSection() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(Paddings.large),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: ColorsManager.black,
                        size: 20,
                      ),
                      SizedBox(width: Sizes.size4),
                      Text(
                        'Members',
                        style: StylesManager.semiBold(fontSize: FontSize.medium),
                      ),
                    ],
                  ),
                  if (controller.isCurrentUserAdmin)
                    TextButton.icon(
                      onPressed: () => _showAddMemberDialog(),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: ColorsManager.primary,
                      ),
                    ),
                ],
              ),
            ),

            // Members List
            if (controller.members.value != null)
              ...controller.members.value!.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;
                final isLast = index == controller.members.value!.length - 1;

                return Column(
                  children: [
                    if (index > 0) Divider(height: 1, indent: 70),
                    _buildMemberTile(member),
                    if (isLast) SizedBox(height: Sizes.size10),
                  ],
                );
              }).toList()
            else
              Padding(
                padding: EdgeInsets.all(Paddings.large),
                child: Center(
                  child: Text(
                    'No members',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(dynamic member) {
    final isCurrentUser = member.uid == controller.currentUser?.uid;
    final isAdmin = controller.members.value!.first.uid == member.uid;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.xSmall,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: ColorsManager.navbarColor,
            backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty
                ? NetworkImage(member.imageUrl!)
                : null,
            child: member.imageUrl == null || member.imageUrl!.isEmpty
                ? Text(
                    member.fullName?.substring(0, 1).toUpperCase() ?? '?',
                    style: StylesManager.bold(
                      fontSize: FontSize.medium,
                      color: ColorsManager.black,
                    ),
                  )
                : null,
          ),

          SizedBox(width: Sizes.size10),

          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName ?? 'Unknown User',
                        style: StylesManager.semiBold(fontSize: FontSize.small),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      SizedBox(width: 4),
                      Text(
                        '(You)',
                        style: StylesManager.medium(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  isAdmin ? 'Group Admin' : 'Member',
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),

          // Admin badge or remove button
          if (isAdmin)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorsManager.navbarColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Admin',
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.black,
                ),
              ),
            )
          else if (controller.isCurrentUserAdmin && !isCurrentUser)
            IconButton(
              icon: Icon(Icons.more_vert, color: ColorsManager.black, size: 20),
              onPressed: () => _showMemberOptions(member),
            ),
        ],
      ),
    );
  }

  /// Shared Media Preview
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
                      color: ColorsManager.black,
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

            // Media Grid Preview
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

  /// Group Settings
  Widget _buildGroupSettings() {
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
              title: 'Mute Notifications',
              subtitle: 'Silence group messages',
              value: false,
              onChanged: (val) {},
            ),
            Divider(height: 1, indent: 70),
            Obx(() => _buildSwitchTile(
              icon: Iconsax.lock_copy,
              title: 'Lock Group',
              subtitle: 'Require authentication',
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
          Icon(icon, color: ColorsManager.black, size: 20),
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
            activeColor: ColorsManager.black,
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
            if (controller.isCurrentUserAdmin) ...[
              Divider(height: 1, indent: 70),
              _buildActionTile(
                icon: Iconsax.link_copy,
                title: 'Invite Link',
                iconColor: Colors.blue,
                onTap: () => _showInviteLink(),
              ),
            ],
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
            _buildActionTile(
              icon: Iconsax.logout_copy,
              title: Constants.kExitgroup.tr,
              iconColor: Colors.red,
              isDanger: true,
              onTap: controller.exitGroup,
            ),
            Divider(height: 1, indent: 70),
            _buildActionTile(
              icon: Iconsax.warning_2_copy,
              title: Constants.kReportgroup.tr,
              iconColor: Colors.red,
              isDanger: true,
              onTap: controller.reportGroup,
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
            Icon(icon, color: isDanger ? Colors.red : ColorsManager.black, size: 20),
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
    // Implement more options bottom sheet
  }

  void _showEditGroupDialog() {
    // Implement edit group dialog
    Get.snackbar(
      'Edit Group',
      'Group editing coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showAddMemberDialog() {
    Get.snackbar(
      'Add Member',
      'Add member functionality coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showMemberOptions(dynamic member) {
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
            ListTile(
              leading: Icon(Icons.person_remove, color: Colors.red),
              title: Text('Remove from Group'),
              onTap: () {
                Get.back();
                controller.removeMember(member.uid);
              },
            ),
            SizedBox(height: Paddings.large),
          ],
        ),
      ),
    );
  }

  void _searchInGroup() {
    Get.snackbar(
      'Search',
      'Search in ${controller.displayName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showInviteLink() {
    Get.snackbar(
      'Invite Link',
      'Group invite link: https://crypted.app/join/ABC123',
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 5),
    );
  }
}
