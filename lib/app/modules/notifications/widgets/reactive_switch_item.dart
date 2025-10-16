import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class ReactiveSwitchItem extends StatelessWidget {
  const ReactiveSwitchItem({
    super.key,
    required this.title,
    required this.switchValue,
    required this.onChanged,
  });
  final String title;
  final RxBool switchValue;
  final Function(bool) onChanged;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: ColorsManager.navbarColor,
          borderRadius: BorderRadius.circular(8),
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Paddings.normal),
          child: Row(
            children: [
              Text(
                title,
                style: StylesManager.regular(fontSize: FontSize.small),
              ),
              Spacer(),
              Switch(
                trackOutlineColor: const WidgetStatePropertyAll(
                  ColorsManager.veryLightGrey,
                ),
                inactiveTrackColor: ColorsManager.veryLightGrey,
                inactiveThumbColor: ColorsManager.white,
                activeTrackColor: ColorsManager.primary,
                activeColor: ColorsManager.white,
                value: switchValue.value,
                onChanged: (val) => onChanged(val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
