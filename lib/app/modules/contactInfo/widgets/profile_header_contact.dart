import 'package:crypted_app/app/modules/contactInfo/controllers/contact_info_controller.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ProfileHeaderContact extends GetView<ContactInfoController> {
  const ProfileHeaderContact({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      children: [
        Container(
          width: Sizes.size104,
          height: Sizes.size104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radiuss.xXLarge150),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Paddings.xXSmall),
            child: controller.userImage != null && controller.userImage!.isNotEmpty
                ? ClipOval(
                    child: AppCachedNetworkImage(
                      imageUrl: controller.userImage!,
                      fit: BoxFit.cover,
                      height: Sizes.size104,
                      width: Sizes.size104,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: ColorsManager.primary.withOpacity(0.1),
                    child: Text(
                      controller.userName.isNotEmpty ? controller.userName.substring(0, 1).toUpperCase() : '?',
                      style: StylesManager.bold(
                        fontSize: FontSize.xXlarge,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(height: Sizes.size4),
        Text(
          controller.userName,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
        SizedBox(height: Sizes.size4),
        Text(
          controller.userEmail,
          style: StylesManager.medium(fontSize: FontSize.medium),
        ),
        if (controller.userBio.isNotEmpty && controller.userBio != "No bio available") ...[
          SizedBox(height: Sizes.size10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
            child: Text(
              controller.userBio,
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    ));
  }
}
