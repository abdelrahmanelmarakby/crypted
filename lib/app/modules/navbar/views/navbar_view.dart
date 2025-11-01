import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:crypted_app/app/modules/calls/views/calls_view.dart';
import 'package:crypted_app/app/modules/home/views/home_view.dart';
import 'package:crypted_app/app/modules/settings/views/settings_view.dart';
import 'package:crypted_app/app/modules/stories/views/stories_view.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/navbar_controller.dart';

class NavbarView extends GetView<NavbarController> {
  const NavbarView({super.key});

  // Micro-animated icon wrapper
  Widget _buildAnimatedIcon({
    required String assetPath,
    required bool isActive,
    required int index,
  }) {
    return Obx(() {
      final isCurrentlyActive = controller.selectedIndex.value == index;

      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: isCurrentlyActive ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + (value * 0.15), // Scale up by 15% when active
            child: Transform.rotate(
              angle: value * 0.05, // Slight rotation for effect
              child: SvgPicture.asset(
                assetPath,
                colorFilter: ColorFilter.mode(
                  Color.lerp(
                    ColorsManager.lightGrey,
                    ColorsManager.primary,
                    value,
                  )!,
                  BlendMode.srcIn,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const HomeView(),
            const CallsView(),
            const StoriesView(),
            const SettingsView(), // Direct widget usage in navbar is fine
          ],
        ),
        extendBody: true,
        bottomNavigationBar: AnimatedNotchBottomBar(
          notchBottomBarController: NotchBottomBarController(
            index: controller.selectedIndex.value,
          ),
          color: ColorsManager.navbarColor,

          showLabel: true,
          textOverflow: TextOverflow.visible,
          maxLine: 1,
          shadowElevation: 5,
          kBottomRadius: 5,
          notchColor: ColorsManager.navbarColor,
          removeMargins: true,
          showShadow: true,
          durationInMilliSeconds: 300,
          itemLabelStyle: const TextStyle(fontSize: FontSize.xXSmall),
          elevation: 1,
          kIconSize: Sizes.size24,
          bottomBarItems: [
            BottomBarItem(
              inActiveItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/home-01.svg',
                isActive: false,
                index: 0,
              ),
              activeItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/home-01.svg',
                isActive: true,
                index: 0,
              ),
              itemLabelWidget: Obx(() {
                final isActive = controller.selectedIndex.value == 0;
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -2 * value), // Slight upward movement
                      child: Text(
                        Constants.kHome.tr,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: Color.lerp(
                            ColorsManager.grey,
                            ColorsManager.primary,
                            value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            BottomBarItem(
              inActiveItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/call-calling.svg',
                isActive: false,
                index: 1,
              ),
              activeItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/call-calling.svg',
                isActive: true,
                index: 1,
              ),
              itemLabelWidget: Obx(() {
                final isActive = controller.selectedIndex.value == 1;
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -2 * value),
                      child: Text(
                        Constants.kCalls.tr,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: Color.lerp(
                            ColorsManager.grey,
                            ColorsManager.primary,
                            value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            BottomBarItem(
              inActiveItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/story.svg',
                isActive: false,
                index: 2,
              ),
              activeItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/story.svg',
                isActive: true,
                index: 2,
              ),
              itemLabelWidget: Obx(() {
                final isActive = controller.selectedIndex.value == 2;
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -2 * value),
                      child: Text(
                        Constants.kStories.tr,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: Color.lerp(
                            ColorsManager.grey,
                            ColorsManager.primary,
                            value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            BottomBarItem(
              inActiveItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/setting-2.svg',
                isActive: false,
                index: 3,
              ),
              activeItem: _buildAnimatedIcon(
                assetPath: 'assets/icons/setting-2.svg',
                isActive: true,
                index: 3,
              ),
              itemLabelWidget: Obx(() {
                final isActive = controller.selectedIndex.value == 3;
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -2 * value),
                      child: Text(
                        Constants.kSetting.tr,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: Color.lerp(
                            ColorsManager.grey,
                            ColorsManager.primary,
                            value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
          onTap: (index) {
            HapticFeedback.lightImpact();
            controller.changePage(index);
          },
        ),
      ),
    );
  }
}
