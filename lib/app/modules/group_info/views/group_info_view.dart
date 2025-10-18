import 'package:crypted_app/app/modules/contactInfo/widgets/custom_notification_theme_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/custom_privacy_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
import 'package:crypted_app/app/modules/group_info/widgets/item_group_member.dart';
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
          TextButton(
            onPressed: () {},
            child: Text(
              Constants.kEdit.tr,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Sizes.size10),
            ProfileHeader(),
            SizedBox(height: Sizes.size10),
            StatusSection(),
            SizedBox(height: Sizes.size10),
            _buildContactDetailsSection(),
            SizedBox(height: Sizes.size10),
            CustomNotificationThemeSection(),
            SizedBox(height: Sizes.size10),
            CustomPrivacySection(
              onChanged: controller.toggleShowNotification,
              switchValue: controller.isLockContactInfoEnabled,
            ),
            SizedBox(height: Sizes.size10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.displayMemberCount,
                style: StylesManager.regular(fontSize: FontSize.small),
              ),
            ),
            SizedBox(height: Sizes.size4),
            CustomContainer(
              children: [
                ItemGroupMember(
                  imageUser: 'assets/images/Profile Image111.png',
                  userName: 'Ahmed Adel',
                  userStatus: 'availabe',
                  isAdmin: true,
                ),
                buildDivider(),
                ItemGroupMember(
                  imageUser: 'assets/images/Profile Image111.png',
                  userName: 'Ahmed Ehab',
                  userStatus: '"Just enjoying the little things in life."',
                ),
                buildDivider(),
                ItemGroupMember(
                  imageUser: 'assets/images/Profile Image111.png',
                  userName: 'Mohamed Abdo',
                ),
              ],
            ),
            SizedBox(height: Sizes.size10),
            _buildExtrasSection(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'created by you',
                  style: StylesManager.medium(fontSize: FontSize.xXSmall),
                ),
                Text(
                  'created by you',
                  style: StylesManager.medium(fontSize: FontSize.xXSmall),
                ),
              ],
            ),
            SizedBox(height: Sizes.size4),
          ],
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
