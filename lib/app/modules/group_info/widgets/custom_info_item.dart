import 'package:crypted_app/app/modules/group_info/widgets/custom_icon_circle.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class CustomInfoItem extends StatelessWidget {
  const CustomInfoItem({
    super.key,
    required this.title,
    this.type,
    required this.image,
  });

  final String title;
  final String? type;
  final String image;

  @override
  Widget build(BuildContext context) {
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
          if (type != null)
            Text(
              type!,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
            ),
          if (type != null) SizedBox(width: Sizes.size4),
          Icon(Icons.keyboard_arrow_right, color: ColorsManager.grey),
        ],
      ),
    );
  }
}
