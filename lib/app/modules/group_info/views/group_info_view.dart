import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_actions_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_details_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_loading_view.dart';
import 'package:crypted_app/app/modules/group_info/widgets/admin_action_widgets.dart';
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

  void _showAddMemberSheet(BuildContext context) {
    Get.snackbar(
      'Coming Soon',
      'Add member functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
    // TODO: Implement contact picker to add new members
    // This would typically show a list of contacts that are not already members
  }
}
