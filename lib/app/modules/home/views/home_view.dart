import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/modules/home/widgets/search.dart';
import 'package:crypted_app/app/modules/home/widgets/stories_carousel.dart';
import 'package:crypted_app/app/modules/home/widgets/tabs_chat.dart';
import 'package:crypted_app/app/modules/stories/views/story_camera_screen.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Swipe-up velocity threshold to open camera
  static const double _swipeUpThreshold = -800;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < _swipeUpThreshold) {
          Get.to(() => const StoryCameraScreen());
        }
      },
      child: Scaffold(
        backgroundColor: ColorsManager.white,
        body: SafeArea(
          bottom: false,
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(
              top: Paddings.xLarge,
              right: Paddings.normal,
              left: Paddings.normal,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(Routes.SETTINGS);
                      },
                      child: Obx(() {
                        final user = UserService.currentUser.value;
                        if (user?.imageUrl != null && user!.imageUrl!.isNotEmpty) {
                          return ClipOval(
                            child: AppCachedNetworkImage(
                              imageUrl: user.imageUrl!,
                              fit: BoxFit.cover,
                              height: Radiuss.xLarge * 2,
                              width: Radiuss.xLarge * 2,
                              isCircular: true,
                            ),
                          );
                        } else {
                          return CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/Profile Image111.png',
                            ),
                            radius: Radiuss.xLarge,
                          );
                        }
                      }),
                    ),
                    SizedBox(width: Sizes.size12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Constants.kHello.tr,
                          style: StylesManager.regular(fontSize: FontSize.small, color: ColorsManager.grey),
                        ),
                        Obx(() => Text(
                              controller.myUser.value?.fullName ??
                                  UserService.currentUser.value?.fullName ??
                                  Constants.kUser.tr,
                              style: StylesManager.regular(
                                  fontSize: FontSize.medium, color: ColorsManager.black),
                            )),
                      ],
                    ),
                    Spacer(),
                    // Fix #7: Single container instead of nested CircleAvatars
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorsManager.white,
                        border: Border.all(
                          color: ColorsManager.border,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.to(() => Search());
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/search-normal.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Sizes.size14),
                // Stories Carousel
                const StoriesCarousel(),
                SizedBox(height: Sizes.size12),
                Expanded(child: TabsChat()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
