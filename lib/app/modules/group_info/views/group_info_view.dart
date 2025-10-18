import 'package:crypted_app/app/modules/contactInfo/widgets/custom_notification_theme_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/custom_privacy_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: Sizes.size10),
          Text(
            "Loading group information...",
            style: StylesManager.regular(fontSize: FontSize.medium),
          ),
        ],
      ),
    );
  }

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
          ? _buildLoadingView()
          : RefreshIndicator(
              onRefresh: controller.refreshGroupData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: Sizes.size10),
                    ProfileHeader(),
                    SizedBox(height: Sizes.size10),
                    StatusSection(),
                    // SizedBox(height: Sizes.size10),
                    // _buildContactDetailsSection(),
                    // SizedBox(height: Sizes.size10),
                    // CustomNotificationThemeSection(),
                    // SizedBox(height: Sizes.size10),
                    // CustomPrivacySection(
                    //   onChanged: controller.toggleShowNotification,
                    //   switchValue: controller.isLockContactInfoEnabled,
                    // ),
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
                      Container(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      CustomContainer(
                        children: [
                          // Dynamic member list
                          ...controller.members.value?.map((member) => Column(
                            children: [
                              _buildMemberItem(member),
                              if (member != controller.members.value!.last) buildDivider(),
                            ],
                          )).toList() ?? [Container()],
                        ],
                      ),

                    // SizedBox(height: Sizes.size10),
                    // _buildExtrasSection(),
                    SizedBox(height: Sizes.size10),
                    CustomContainer(
                      children: [
                        _buildredChoise(Constants.kExitgroup.tr),
                        buildDivider(),
                        _buildredChoise(Constants.kReportgroup.tr),
                        SizedBox(height: Sizes.size10),
                      ],
                    ),
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

  Widget _buildContactDetailsSection() {
    return CustomContainer(
      children: [
        CustomInfoItem(
          image: 'assets/icons/fi_833281.svg',
          title: Constants.kmediaLinksdocuments.tr,
          type: '9',
        ),
        buildDivider(),
        CustomInfoItem(
          image: 'assets/icons/star.svg',
          title: Constants.kstarredmessages.tr,
          type: '9',
        ),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return CustomContainer(
      children: [
        _buildEndContactInfoItem(title: Constants.kAddtofavourite.tr),
        buildDivider(),
        _buildEndContactInfoItem(title: Constants.kAddtolist.tr),
        buildDivider(),
        _buildEndContactInfoItem(title: Constants.kExportchat.tr),
        buildDivider(),
        _buildredChoise(Constants.kClearChat.tr),
        SizedBox(height: Sizes.size10),
      ],
    );
  }

  Padding _buildredChoise(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.error2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(dynamic member) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          // Member avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorsManager.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: ColorsManager.primary.withOpacity(0.1),
              backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty
                  ? NetworkImage(member.imageUrl!)
                  : null,
              child: member.imageUrl == null || member.imageUrl!.isEmpty
                  ? Text(
                      member.fullName?.substring(0, 1).toUpperCase() ?? '?',
                      style: StylesManager.bold(
                        fontSize: FontSize.medium,
                        color: ColorsManager.primary,
                      ),
                    )
                  : null,
            ),
          ),

          SizedBox(width: Sizes.size4),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName ?? 'Unknown User',
                  style: StylesManager.medium(fontSize: FontSize.medium),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.uid == controller.currentUser?.uid ? 'You' : 'Member',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),

          // Admin badge for current user
          if (member.uid == controller.currentUser?.uid && controller.isCurrentUserAdmin)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.primary,
                ),
              ),
            ),

          // Remove button for non-admin members (if current user is admin)
          if (member.uid != controller.currentUser?.uid && controller.isCurrentUserAdmin)
            IconButton(
              icon: Icon(Icons.remove_circle, color: ColorsManager.error),
              onPressed: () {
                Get.defaultDialog(
                  title: "Remove Member",
                  middleText: "Are you sure you want to remove ${member.fullName} from the group?",
                  textConfirm: "Remove",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    controller.removeMember(member.uid!);
                    Get.back();
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEndContactInfoItem({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: StylesManager.medium(fontSize: FontSize.small),
            ),
          ),
        ],
      ),
    );
  }
}
