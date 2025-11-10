import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_actions_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_details_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_loading_view.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_member_item.dart';
import 'package:crypted_app/app/modules/group_info/widgets/profile_header.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.displayMemberCount,
                        style: StylesManager.regular(fontSize: FontSize.small),
                      ),
                    ),
                    SizedBox(height: Sizes.size4),

                    // Loading indicator for members
                    if (controller.isLoading.value)
                      SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else
                      CustomContainer(
                        children: [
                          // Dynamic member list
                          ...controller.members.value?.map((member) => Column(
                            children: [
                              GroupMemberItem(member: member),
                              if (member != controller.members.value!.last) buildDivider(),
                            ],
                          )).toList() ?? [Container()],
                        ],
                      ),

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
}
