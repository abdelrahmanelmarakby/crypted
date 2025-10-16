import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomNotificationThemeSection extends StatelessWidget {
  const CustomNotificationThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      children: [
        CustomInfoItem(
          image: 'assets/icons/notification-bing.svg',
          title: Constants.knotification.tr,
        ),
        buildDivider(),
        CustomInfoItem(
          image: 'assets/icons/fi_9742096.svg',
          title: 'chat theme',
        ),
      ],
    );
  }
}
