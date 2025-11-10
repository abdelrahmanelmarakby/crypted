import 'package:crypted_app/app/modules/group_info/widgets/custom_icon_circle.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class ContactInfoItem extends StatelessWidget {
  final String title;
  final String image;

  const ContactInfoItem({
    super.key,
    required this.title,
    required this.image,
  });

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
        ],
      ),
    );
  }
}
