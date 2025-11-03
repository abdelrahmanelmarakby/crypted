import 'package:crypted_app/app/modules/contactInfo/widgets/custom_notification_theme_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/custom_privacy_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/profile_header_contact.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/app/modules/group_info/widgets/custom_icon_circle.dart';
import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:crypted_app/core/themes/color_manager.dart';

import '../controllers/contact_info_controller.dart';

class ContactInfoView extends GetView<ContactInfoController> {
  const ContactInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kContactInfo.tr,
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
            ProfileHeaderContact(),
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
            _buildExtrasSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDetailsSection() {
    return CustomContainer(
      children: [
        GestureDetector(
          onTap: controller.viewMediaLinksDocuments,
          child: CustomInfoItem(
            image: 'assets/icons/fi_833281.svg',
            title: Constants.kmediaLinksdocuments.tr,
            type: '9',
          ),
        ),
        buildDivider(),
        //
        GestureDetector(
          onTap: controller.viewStarredMessages,
          child: CustomInfoItem(
            image: 'assets/icons/star.svg',
            title: Constants.kstarredmessages.tr,
            type: '9',
          ),
        ),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return CustomContainer(
      children: [
        GestureDetector(
          onTap: controller.toggleFavorite,
          child: Obx(() => _buildEndContactInfoItem(
                image: 'assets/icons/star.svg',
                title: controller.isFavorite.value
                    ? 'Remove from favourite'
                    : Constants.kAddtofavourite.tr,
              )),
        ),
        buildDivider(),
        _buildEndContactInfoItem(
          image: 'assets/icons/note-add.svg',
          title: Constants.kAddtolist.tr,
        ),
        buildDivider(),
        GestureDetector(
          onTap: controller.exportChat,
          child: _buildEndContactInfoItem(
            image: 'assets/icons/export (1).svg',
            title: Constants.kExportchat.tr,
          ),
        ),
        buildDivider(),
        GestureDetector(
          onTap: controller.clearChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Paddings.xXSmall,
              horizontal: Paddings.normal,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorsManager.backgroundError,
                  radius: Radiuss.large,
                  child: SvgPicture.asset(
                    'assets/icons/trash.svg',
                    colorFilter: ColorFilter.mode(
                      ColorsManager.error2,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(width: Sizes.size4),
                Expanded(
                  child: Text(
                    Constants.kClearChat.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.error2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Sizes.size10),
      ],
    );
  }

  Widget _buildEndContactInfoItem({
    required String title,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          CustomIconCircle(path: image),
          SizedBox(width: Sizes.size4),
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
