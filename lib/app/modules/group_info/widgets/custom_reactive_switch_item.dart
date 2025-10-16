import 'package:crypted_app/app/modules/group_info/widgets/custom_icon_circle.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class CustomReactiveSwitchItem extends StatelessWidget {
  const CustomReactiveSwitchItem({
    super.key,
    required this.title,
    required this.image,
    required this.onChanged,
    required this.switchValue,
  });

  final String title;
  final String image;
  final Function(bool) onChanged;
  final RxBool switchValue;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomContainer(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Paddings.normal),
            child: Row(
              children: [
                CustomIconCircle(path: image),
                SizedBox(width: Sizes.size4),
                Text(
                  title,
                  style: StylesManager.medium(fontSize: FontSize.small),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: switchValue.value,
                    onChanged: onChanged,
                    activeTrackColor: ColorsManager.primary,
                    activeColor: ColorsManager.white,
                    inactiveThumbColor: ColorsManager.white,
                    inactiveTrackColor: ColorsManager.veryLightGrey,
                    trackOutlineColor: const WidgetStatePropertyAll(
                      ColorsManager.veryLightGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
