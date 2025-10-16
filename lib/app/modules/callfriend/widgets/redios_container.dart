import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RediosContainer extends StatelessWidget {
  const RediosContainer({
    super.key,
    required this.image,
    required this.backgroundColor,
  });
  final String image;
  final Color backgroundColor;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: Sizes.size38,
        height: Sizes.size38,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(Radiuss.xXLarge150),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Paddings.small),
          child: SvgPicture.asset(
            image,
            width: Sizes.size20,
            height: Sizes.size20,
          ),
        ),
      ),
    );
  }
}
