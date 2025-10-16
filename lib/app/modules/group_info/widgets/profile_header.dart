import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: Sizes.size104,
          height: Sizes.size104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radiuss.xXLarge150),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Paddings.xXSmall),
            child: Image.asset(
              'assets/images/Profile Image111.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: Sizes.size8),
        Text(
          'elgam3a',
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
        SizedBox(height: Sizes.size4),
        Text(
          '3 Members',
          style: StylesManager.medium(fontSize: FontSize.medium),
        ),
        SizedBox(height: Sizes.size10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: ColorsManager.backgroundIconSetting,
              radius: Radiuss.xXLarge,
              child: SvgPicture.asset(
                'assets/icons/call-calling.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),

            SizedBox(width: Sizes.size10),
            CircleAvatar(
              backgroundColor: ColorsManager.backgroundIconSetting,
              radius: Radiuss.xXLarge,
              child: SvgPicture.asset(
                'assets/icons/search-normal (1).svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
