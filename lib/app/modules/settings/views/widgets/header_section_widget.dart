import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';

/// Header section — iOS-style settings title + tappable profile card
class HeaderSectionWidget extends StatelessWidget {
  const HeaderSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.xXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          // Title
          Text(
            Constants.kSetting.tr,
            style: StylesManager.bold(
              fontSize: FontSize.xXlarge,
              color: ColorsManager.black,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Profile card — tappable, navigates to profile edit
          const UserProfileCardWidget(),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}

/// User profile card — iOS-style grouped card, tappable
///
/// Shows avatar (64px), name, email, and a chevron arrow.
/// Entire card is tappable to navigate to the profile screen.
class UserProfileCardWidget extends StatelessWidget {
  const UserProfileCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(Routes.PROFILE),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                // Profile Image — 64px
                Obx(() {
                  final user = UserService.currentUser.value;
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorsManager.border,
                        width: 2,
                      ),
                    ),
                    child: user?.imageUrl != null &&
                            user!.imageUrl!.isNotEmpty
                        ? ClipOval(
                            child: AppCachedNetworkImage(
                              imageUrl: user.imageUrl!,
                              fit: BoxFit.cover,
                              height: 64,
                              width: 64,
                              isCircular: true,
                            ),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundImage: const AssetImage(
                              'assets/images/Profile Image111.png',
                            ),
                            backgroundColor: ColorsManager.primary,
                          ),
                  );
                }),
                const SizedBox(width: Spacing.sm),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                            UserService.currentUser.value?.fullName ??
                                Constants.kUser.tr,
                            style: StylesManager.semiBold(
                              fontSize: FontSize.large,
                              color: ColorsManager.black,
                            ),
                          )),
                      const SizedBox(height: Spacing.xxxs),
                      Obx(() => Text(
                            UserService.currentUser.value?.email ?? '',
                            style: StylesManager.regular(
                              fontSize: FontSize.small,
                              color: ColorsManager.grey,
                            ),
                          )),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: ColorsManager.lightGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
