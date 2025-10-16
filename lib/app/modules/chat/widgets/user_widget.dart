// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserWidget extends StatelessWidget {
  const UserWidget({
    super.key,
    this.user,
    this.isInvited = false,
    required this.onTap,
  });
  final SocialMediaUser? user;
  final bool isInvited;
  final Function() onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radiuss.xLarge),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: ColorsManager.grey.withValues(alpha: 0.1),
              blurRadius: Radiuss.small,
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey, width: .2),
            bottom: BorderSide(color: Colors.grey, width: .2),
          ),
        ),
        padding: const EdgeInsets.all(10),
        width: context.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipOval(
              child: AppCachedNetworkImage(
                height: Sizes.size48,
                width: Sizes.size48,
                imageUrl: user?.imageUrl ?? '',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: Sizes.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? Constants.kNoName.tr,
                    style: StylesManager.bold(
                      color: ColorsManager.black,
                      fontSize: FontSize.xLarge,
                    ),
                  ),
                  Text(
                    user?.email ?? "",
                    style: StylesManager.regular(
                      color: ColorsManager.grey,
                      fontSize: FontSize.medium,
                    ),
                  ),
                ],
              ),
            ),
            if (isInvited)
              const Icon(Icons.person_add, color: ColorsManager.primary)
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: ColorsManager.borderColor,
              ),
          ],
        ),
      ),
    );
  }
}
