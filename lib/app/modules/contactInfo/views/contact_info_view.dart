import 'package:crypted_app/app/modules/contactInfo/widgets/contact_details_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/contact_extras_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/custom_notification_theme_section.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/profile_header_contact.dart';
import 'package:crypted_app/app/modules/contactInfo/widgets/status_section.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            const ProfileHeaderContact(),
            SizedBox(height: Sizes.size10),
            const StatusSection(),
            SizedBox(height: Sizes.size10),
            const ContactDetailsSection(),
            SizedBox(height: Sizes.size10),
            const CustomNotificationThemeSection(),
            SizedBox(height: Sizes.size10),
            const ContactExtrasSection(),
          ],
        ),
      ),
    );
  }
}
