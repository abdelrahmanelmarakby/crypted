// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.title,
    required this.subTitle,
    required this.onTap,
  });
  final String title;
  final String subTitle;
  final Function() onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey,
            ),
          ),
          // AppSpacer(widthRatio: .3),
          Text(
            subTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSize.xSmall,
              color: ColorsManager.primary,
              decoration: TextDecoration.underline,
              decorationColor: ColorsManager.primary,
            ),
          ),
        ],
      ),
    );
  }
}
