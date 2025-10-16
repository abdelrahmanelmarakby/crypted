import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemSearch extends StatelessWidget {
  const ItemSearch({super.key, required this.image, required this.iconName});
  final String image;
  final String iconName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
          child: Row(
            children: [
              SvgPicture.asset(image),
              SizedBox(width: Sizes.size10),
              Text(
                iconName,
                style: StylesManager.medium(fontSize: FontSize.medium),
              ),
              Spacer(),
              SvgPicture.asset('assets/icons/Input Icon.svg'),
            ],
          ),
        ),
        Divider(
          indent: 22,
          endIndent: 22,
          color: ColorsManager.navbarColor,
          thickness: 1,
        ),
      ],
    );
  }
}
