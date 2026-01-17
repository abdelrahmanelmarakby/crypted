import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_actions_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_details_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_loading_view.dart';
import 'package:crypted_app/app/modules/group_info/widgets/admin_action_widgets.dart';
import 'package:crypted_app/app/modules/group_info/widgets/add_member_picker.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_permissions_editor.dart';
import 'package:crypted_app/app/modules/group_info/widgets/profile_header.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../controllers/group_info_controller.dart';

class GroupInfoView extends GetView<GroupInfoController> {
  const GroupInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kGroupInfo.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: controller.isRefreshing.value ? null : controller.refreshGroupData,
            icon: controller.isRefreshing.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorsManager.primary,
                    ),
                  )
                : Icon(Icons.refresh, color: ColorsManager.primary),
          ),
        ],
      ),
      body: controller.isLoading.value
          ? const GroupLoadingView()
          : RefreshIndicator(
              onRefresh: controller.refreshGroupData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: Sizes.size10),
                    const ProfileHeader(),
                    SizedBox(height: Sizes.size10),
                    const StatusSection(),
                    SizedBox(height: Sizes.size10),
                    const GroupDetailsSection(),
                    SizedBox(height: Sizes.size10),
                    // Member count and search
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.displayMemberCount,
                            style: StylesManager.regular(fontSize: FontSize.small),
                          ),
                        ),
                        // Add member button (admin only)
                        Obx(() {
                          if (!controller.isCurrentUserAdmin) return const SizedBox.shrink();
                          return IconButton(
                            icon: Icon(Icons.person_add, color: ColorsManager.primary, size: 22),
                            onPressed: () => _showAddMemberSheet(context),
                            tooltip: 'Add member',
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: Sizes.size4),

                    // Member search bar
                    Obx(() {
                      if ((controller.members.value?.length ?? 0) > 5) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: Sizes.size4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: controller.memberSearchController,
                            onChanged: controller.updateMemberSearch,
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                              suffixIcon: controller.memberSearchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
                                      onPressed: controller.clearMemberSearch,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Loading indicator for members
                    if (controller.isLoading.value)
                      SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else
                      Obx(() {
                        final members = controller.filteredMembers;

                        if (members.isEmpty && controller.memberSearchQuery.value.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No members found',
                                  style: StylesManager.regular(
                                    fontSize: FontSize.medium,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return CustomContainer(
                          children: [
                            // Dynamic member list with admin actions
                            ...members.map((member) {
                              final isAdmin = controller.isUserAdmin(member.uid ?? '');
                              final isCreator = controller.isUserCreator(member.uid ?? '');
                              final isCurrentUser = member.uid == controller.currentUser?.uid;
                              final canManage = controller.isCurrentUserAdmin && !isCreator;

                              return Column(
                                children: [
                                  AdminMemberTile(
                                    member: member,
                                    isAdmin: isAdmin,
                                    isCreator: isCreator,
                                    isCurrentUser: isCurrentUser,
                                    canManage: canManage,
                                    onViewProfile: () {
                                      if (!isCurrentUser) {
                                        Get.toNamed(
                                          Routes.OTHER_USER_INFO,
                                          arguments: {'userId': member.uid, 'user': member},
                                        );
                                      }
                                    },
                                    onMakeAdmin: canManage && !isAdmin
                                        ? () => controller.makeAdmin(member.uid!)
                                        : null,
                                    onRemoveAdmin: canManage && isAdmin && !isCreator
                                        ? () => controller.removeAdmin(member.uid!)
                                        : null,
                                    onRemoveMember: canManage
                                        ? () => controller.removeMember(member.uid!)
                                        : null,
                                  ),
                                  if (member != members.last) buildDivider(),
                                ],
                              );
                            }).toList(),
                          ],
                        );
                      }),

                    SizedBox(height: Sizes.size10),
                    const GroupActionsSection(),
                    SizedBox(height: Sizes.size4),

                    // Invite Link Section
                    _buildInviteLinkSection(context),
                    SizedBox(height: Sizes.size4),

                    // Group Permissions (admin only)
                    Obx(() {
                      if (!controller.isCurrentUserAdmin) return const SizedBox.shrink();
                      return Column(
                        children: [
                          PermissionsSummaryTile(
                            permissions: controller.permissions.value,
                            onTap: () => _showPermissionsEditor(context),
                          ),
                          SizedBox(height: Sizes.size4),
                        ],
                      );
                    }),

                    // Show admin status
                    if (controller.isCurrentUserAdmin)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'You are the group admin',
                            style: StylesManager.medium(
                              fontSize: FontSize.xXSmall,
                              color: ColorsManager.primary,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Created by group admin',
                            style: StylesManager.medium(fontSize: FontSize.xXSmall),
                          ),
                          Text(
                            'Group created',
                            style: StylesManager.medium(fontSize: FontSize.xXSmall),
                          ),
                        ],
                      ),

                    SizedBox(height: Sizes.size4),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAddMemberSheet(BuildContext context) async {
    final existingMemberIds = controller.members.value
            ?.map((m) => m.uid)
            .whereType<String>()
            .toList() ??
        [];

    final selectedMembers = await AddMemberPicker.show(
      context: context,
      existingMemberIds: existingMemberIds,
    );

    if (selectedMembers != null && selectedMembers.isNotEmpty) {
      // Add each member
      for (final member in selectedMembers) {
        await controller.addMember(member);
      }

      Get.snackbar(
        'Success',
        '${selectedMembers.length} member${selectedMembers.length == 1 ? '' : 's'} added to group',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _showPermissionsEditor(BuildContext context) async {
    final roomId = controller.roomId;
    if (roomId == null) return;

    final updatedPermissions = await GroupPermissionsEditor.show(
      context: context,
      roomId: roomId,
      initialPermissions: controller.permissions.value,
    );

    if (updatedPermissions != null) {
      await controller.updatePermissions(updatedPermissions);
      Get.snackbar(
        'Success',
        'Group permissions updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Build invite link section
  Widget _buildInviteLinkSection(BuildContext context) {
    return CustomContainer(
      children: [
        // Invite link tile
        Obx(() {
          final hasLink = controller.hasInviteLink.value;
          final link = controller.primaryInviteLink.value;

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.link,
                color: ColorsManager.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Invite Link',
              style: StylesManager.medium(fontSize: FontSize.medium),
            ),
            subtitle: hasLink
                ? Text(
                    link?.fullLink ?? 'Tap to view',
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    'Create a link to invite people',
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasLink)
                  IconButton(
                    icon: Icon(Iconsax.copy, size: 18, color: ColorsManager.primary),
                    onPressed: controller.copyInviteLink,
                    tooltip: 'Copy link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                if (hasLink)
                  IconButton(
                    icon: Icon(Iconsax.share, size: 18, color: ColorsManager.primary),
                    onPressed: controller.shareInviteLink,
                    tooltip: 'Share link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: ColorsManager.grey,
                ),
              ],
            ),
            onTap: () => controller.openInviteLinkManager(context),
          );
        }),
      ],
    );
  }
}
