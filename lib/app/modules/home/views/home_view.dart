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
import 'package:crypted_app/app/modules/home/widgets/mood_picker_sheet.dart';
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
        backgroundColor: ColorsManager.scaffoldBg(context),
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
                    Semantics(
                      label: 'Profile picture. Double tap to open settings',
                      button: true,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.toNamed(Routes.SETTINGS);
                            },
                            child: Obx(() {
                              final user = UserService.currentUser.value;
                              if (user?.imageUrl != null &&
                                  user!.imageUrl!.isNotEmpty) {
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
                          // Mood badge (Phase 14.5)
                          Positioned(
                            bottom: -2,
                            right: -4,
                            child: Obx(() {
                              final mood = UserService.currentUser.value?.mood;
                              return GestureDetector(
                                onTap: () => MoodPickerSheet.show(context),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: ColorsManager.scaffoldBg(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ColorsManager.scaffoldBg(context),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: mood != null && mood.isNotEmpty
                                      ? Text(mood,
                                          style: const TextStyle(fontSize: 12))
                                      : Icon(Icons.add,
                                          size: 12,
                                          color: ColorsManager.primary),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: Sizes.size12),
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.kHello.tr,
                            style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey),
                          ),
                          Obx(() => Text(
                                controller.myUser.value?.fullName ??
                                    UserService.currentUser.value?.fullName ??
                                    Constants.kUser.tr,
                                style: StylesManager.regular(
                                    fontSize: FontSize.medium,
                                    color: ColorsManager.textPrimaryAdaptive(
                                        context)),
                              )),
                          // Mood text (Phase 14.5)
                          Obx(() {
                            final moodText =
                                UserService.currentUser.value?.moodText;
                            if (moodText == null || moodText.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: () => MoodPickerSheet.show(context),
                              child: Text(
                                moodText,
                                style: StylesManager.regular(
                                  fontSize: FontSize.xSmall,
                                  color: ColorsManager.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Spacer(),
                    // Fix #7: Single container instead of nested CircleAvatars
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorsManager.surfaceAdaptive(context),
                        border: Border.all(
                          color: ColorsManager.dividerAdaptive(context),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.to(() => Search());
                        },
                        tooltip: 'Search',
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
