import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/contactInfo/controllers/contact_info_controller.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to find ContactInfoController, if not available (e.g., in GroupInfoView), skip
    ContactInfoController? contactController;
    try {
      contactController = Get.find<ContactInfoController>();
    } catch (e) {
      // Controller not found, this might be used in a group context
      // Return empty widget or group-specific content
      return const SizedBox.shrink();
    }

    final currentUserId = UserService.currentUserValue?.uid;
    final contactUserId = contactController.user.value?.uid;

    // Check if viewing own profile
    final isOwnProfile = currentUserId != null && currentUserId == contactUserId;
    final bioText = contactController.user.value?.bio ?? Constants.kJustenjoyingthelittlethingsinlife.tr;

    return CustomContainer(
      children: [
        Padding(
          padding: const EdgeInsets.all(Paddings.xSmall),
          child: isOwnProfile
              ? CustomTextField(
                  labelColor: ColorsManager.grey,
                  height: Sizes.size34,
                  name: Constants.kStatus.tr,
                  hint: Constants.kJustenjoyingthelittlethingsinlife.tr,
                  borderColor: ColorsManager.borderColor,
                  onSubmit: (value) {
                    contactController?.updateBio(value);
                  },
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
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Constants.kStatus.tr,
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bioText,
                      style: StylesManager.regular(
                        fontSize: FontSize.medium,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
