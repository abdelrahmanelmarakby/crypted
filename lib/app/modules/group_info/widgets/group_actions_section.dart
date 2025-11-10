import 'package:crypted_app/app/modules/group_info/widgets/group_danger_option.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_info_controller.dart';

class GroupActionsSection extends GetView<GroupInfoController> {
  const GroupActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      children: [
        GestureDetector(
          onTap: controller.exitGroup,
          child: GroupDangerOption(title: Constants.kExitgroup.tr),
        ),
        buildDivider(),
        GestureDetector(
          onTap: controller.reportGroup,
          child: GroupDangerOption(title: Constants.kReportgroup.tr),
        ),
        SizedBox(height: Sizes.size10),
      ],
    );
  }
}
