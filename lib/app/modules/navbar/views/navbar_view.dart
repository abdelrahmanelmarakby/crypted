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

  // Micro-animated icon wrapper for regular tabs
  Widget _buildAnimatedIcon({
    required String assetPath,
    required bool isActive,
    required int barIndex,
    required String semanticLabel,
  }) {
    return Obx(() {
      final isCurrentlyActive = controller.selectedIndex.value == barIndex;

      return Semantics(
        label: semanticLabel,
        button: true,
        selected: isCurrentlyActive,
        child: TweenAnimationBuilder<double>(
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
        ),
      );
    });
  }

  // Special camera icon — outlined style to avoid visual collision with notch
  Widget _buildCameraIcon() {
    return Semantics(
      label: 'Camera',
      button: true,
      child: Icon(
        Icons.camera_alt_rounded,
        color: ColorsManager.primary,
        size: 26,
      ),
    );
  }

  // Animated label builder for regular tabs
  Widget _buildAnimatedLabel(String text, int barIndex) {
    return Obx(() {
      final isActive = controller.selectedIndex.value == barIndex;
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2 * value),
            child: Text(
              text,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            HomeView(), // Page 0
            CallsView(), // Page 1
            StoriesView(), // Page 2 (bar index 3)
            SettingsView(), // Page 3 (bar index 4)
          ],
        ),
        extendBody: true,
        bottomNavigationBar: Semantics(
          label: 'Main navigation',
          child: AnimatedNotchBottomBar(
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
              // Index 0: Home
              BottomBarItem(
                inActiveItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/home-01.svg',
                  isActive: false,
                  barIndex: 0,
                  semanticLabel: 'Home tab',
                ),
                activeItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/home-01.svg',
                  isActive: true,
                  barIndex: 0,
                  semanticLabel: 'Home tab',
                ),
                itemLabelWidget: _buildAnimatedLabel(Constants.kHome.tr, 0),
              ),
              // Index 1: Calls
              BottomBarItem(
                inActiveItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/call-calling.svg',
                  isActive: false,
                  barIndex: 1,
                  semanticLabel: 'Calls tab',
                ),
                activeItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/call-calling.svg',
                  isActive: true,
                  barIndex: 1,
                  semanticLabel: 'Calls tab',
                ),
                itemLabelWidget: _buildAnimatedLabel(Constants.kCalls.tr, 1),
              ),
              // Index 2: Camera (virtual — opens fullscreen route)
              BottomBarItem(
                inActiveItem: _buildCameraIcon(),
                activeItem: _buildCameraIcon(),
                itemLabelWidget: Text(
                  Constants.kCamera.tr,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
              // Index 3: Stories
              BottomBarItem(
                inActiveItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/story.svg',
                  isActive: false,
                  barIndex: 3,
                  semanticLabel: 'Stories tab',
                ),
                activeItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/story.svg',
                  isActive: true,
                  barIndex: 3,
                  semanticLabel: 'Stories tab',
                ),
                itemLabelWidget: _buildAnimatedLabel(Constants.kStories.tr, 3),
              ),
              // Index 4: Settings
              BottomBarItem(
                inActiveItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/setting-2.svg',
                  isActive: false,
                  barIndex: 4,
                  semanticLabel: 'Settings tab',
                ),
                activeItem: _buildAnimatedIcon(
                  assetPath: 'assets/icons/setting-2.svg',
                  isActive: true,
                  barIndex: 4,
                  semanticLabel: 'Settings tab',
                ),
                itemLabelWidget: _buildAnimatedLabel(Constants.kSetting.tr, 4),
              ),
            ],
            onTap: (index) {
              HapticFeedback.lightImpact();
              controller.changePage(index);
            },
          ),
        ),
      ),
    );
  }
}
