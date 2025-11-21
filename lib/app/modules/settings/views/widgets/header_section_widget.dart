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

/// Header section widget with user info and status
class HeaderSectionWidget extends StatelessWidget {
  const HeaderSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          Text(
            Constants.kSetting.tr,
            style: StylesManager.bold(
              fontSize: FontSize.xXlarge,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size8),
          Text(
            'Manage your account and preferences',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),
          SizedBox(height: Sizes.size24),
          // User Profile Card
          const UserProfileCardWidget(),
        ],
      ),
    );
  }
}

/// User profile card widget with clean design
class UserProfileCardWidget extends StatelessWidget {
  const UserProfileCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Obx(() {
            final user = UserService.currentUser.value;
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorsManager.borderColor,
                  width: 2,
                ),
              ),
              child: user?.imageUrl != null && user!.imageUrl!.isNotEmpty
                  ? ClipOval(
                      child: AppCachedNetworkImage(
                        imageUrl: user.imageUrl!,
                        fit: BoxFit.cover,
                        height: 56,
                        width: 56,
                        isCircular: true,
                      ),
                    )
                  : CircleAvatar(
                      backgroundImage: const AssetImage(
                        'assets/images/Profile Image111.png',
                      ),
                      backgroundColor: ColorsManager.primary,
                    ),
            );
          }),
          SizedBox(width: Sizes.size16),
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
                SizedBox(height: Sizes.size4),
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
          // Edit Button
          IconButton(
            onPressed: () => Get.toNamed(Routes.PROFILE),
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: ColorsManager.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
              foregroundColor: ColorsManager.primary,
            ),
          ),
        ],
      ),
    );
  }
}
