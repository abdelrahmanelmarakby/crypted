import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({super.key, required this.title, required this.type});
  final String title, type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: StylesManager.regular(fontSize: FontSize.small),
            ),
          ),
          ...[
            Text(
              type,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
            ),
            SizedBox(width: Sizes.size4),
          ],
          Icon(Icons.keyboard_arrow_right, color: ColorsManager.grey),
        ],
      ),
    );
  }
}
