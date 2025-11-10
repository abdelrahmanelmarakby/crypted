import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class GroupDangerOption extends StatelessWidget {
  final String title;

  const GroupDangerOption({
    super.key,
    required this.title,
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
          Expanded(
            child: Text(
              title,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.error2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
