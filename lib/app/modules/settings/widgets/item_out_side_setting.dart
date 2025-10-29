import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ItemOutSideSetting extends StatelessWidget {
  ItemOutSideSetting({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSwitched = false,
    this.onChanged,
  });
  final String icon;
  final String title;
  final bool isSwitched;
  final ValueChanged<bool>? onChanged;
  void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Paddings.xXSmall),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorsManager.backgroundIconSetting,
                  radius: Radiuss.xLarge22,
                  child: SvgPicture.asset(icon),
                ),
                SizedBox(width: Sizes.size10),
                Text(
                  title,
                  style: StylesManager.medium(fontSize: FontSize.medium),
                ),

                Spacer(),
                if (onChanged != null)
                  Switch(
                    trackOutlineColor: WidgetStatePropertyAll(
                      ColorsManager.veryLightGrey,
                    ),
                    inactiveTrackColor: ColorsManager.veryLightGrey,
                    inactiveThumbColor: ColorsManager.white,
                    activeTrackColor: ColorsManager.primary,
                    activeThumbColor: ColorsManager.white,
                    value: isSwitched,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
          SizedBox(height: Sizes.size4),
        ],
      ),
    );
  }
}
