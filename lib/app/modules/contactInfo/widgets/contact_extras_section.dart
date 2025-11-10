import 'package:crypted_app/app/modules/contactInfo/widgets/contact_info_item.dart';
import 'package:crypted_app/app/widgets/custom_container.dart';
import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/contact_info_controller.dart';

class ContactExtrasSection extends GetView<ContactInfoController> {
  const ContactExtrasSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      children: [
        GestureDetector(
          onTap: controller.toggleFavorite,
          child: Obx(
            () => ContactInfoItem(
              image: 'assets/icons/star.svg',
              title: controller.isFavorite.value
                  ? 'Remove from favourite'
                  : Constants.kAddtofavourite.tr,
            ),
          ),
        ),
        buildDivider(),
        ContactInfoItem(
          image: 'assets/icons/note-add.svg',
          title: Constants.kAddtolist.tr,
        ),
        buildDivider(),
        GestureDetector(
          onTap: controller.exportChat,
          child: ContactInfoItem(
            image: 'assets/icons/export (1).svg',
            title: Constants.kExportchat.tr,
          ),
        ),
        buildDivider(),
        GestureDetector(
          onTap: controller.clearChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Paddings.xXSmall,
              horizontal: Paddings.normal,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorsManager.backgroundError,
                  radius: Radiuss.large,
                  child: SvgPicture.asset(
                    'assets/icons/trash.svg',
                    colorFilter: ColorFilter.mode(
                      ColorsManager.error2,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(width: Sizes.size4),
                Expanded(
                  child: Text(
                    Constants.kClearChat.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.error2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Sizes.size10),
      ],
    );
  }
}
