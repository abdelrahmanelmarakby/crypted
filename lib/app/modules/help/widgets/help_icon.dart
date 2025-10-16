import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HelpIcon extends StatelessWidget {
  const HelpIcon(this.image, {super.key});
  final String image;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.size48,
      height: Sizes.size48,
      decoration: BoxDecoration(
        color: ColorsManager.backgroundIconSetting,
        borderRadius: BorderRadius.circular(Radiuss.xSmall),
      ),

      child: Padding(
        padding: const EdgeInsets.all(Paddings.normal),
        child: SvgPicture.asset(image),
      ),
    );
  }
}
