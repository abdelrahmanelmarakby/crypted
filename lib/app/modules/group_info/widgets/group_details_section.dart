import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_info_controller.dart';

class GroupDetailsSection extends GetView<GroupInfoController> {
  const GroupDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
}
