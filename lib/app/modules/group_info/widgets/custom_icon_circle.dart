import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';

class CustomIconCircle extends StatelessWidget {
  const CustomIconCircle({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: ColorsManager.backgroundIconSetting,
      radius: Radiuss.large,
      child: SvgPicture.asset(
        path,
        colorFilter: ColorFilter.mode(ColorsManager.primary, BlendMode.srcIn),
      ),
    );
  }
}
