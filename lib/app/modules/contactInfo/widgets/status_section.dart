import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      children: [
        Padding(
          padding: const EdgeInsets.all(Paddings.xSmall),
          child: CustomTextField(
            labelColor: ColorsManager.grey,
            height: Sizes.size34,
            name: Constants.kStatus.tr,
            hint: Constants.kJustenjoyingthelittlethingsinlife.tr,
            borderColor: ColorsManager.borderColor,
            suffixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Paddings.xLarge),
              child: SvgPicture.asset(
                'assets/icons/edit-2.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
