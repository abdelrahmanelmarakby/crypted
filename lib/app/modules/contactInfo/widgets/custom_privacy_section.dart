import 'package:crypted_app/app/modules/group_info/widgets/custom_info_item.dart';
import 'package:crypted_app/app/modules/group_info/widgets/custom_reactive_switch_item.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomPrivacySection extends StatelessWidget {
  const CustomPrivacySection({
    super.key,
    required this.onChanged,
    required this.switchValue,
  });
  final Function(bool) onChanged;
  final RxBool switchValue;
  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      children: [
        CustomInfoItem(
          image: 'assets/icons/security-safe.svg',
          title: Constants.kEncryption.tr,
        ),
        buildDivider(),
        CustomReactiveSwitchItem(
          image: 'assets/icons/lock (1).svg',
          title: Constants.klockchat.tr,
          switchValue: switchValue,
          onChanged: onChanged,
        ),
        buildDivider(),
        CustomInfoItem(
          image: 'assets/icons/fi_833602.svg',
          title: Constants.kDisappearingMessages.tr,
          type: Constants.kOff.tr,
        ),
      ],
    );
  }
}
