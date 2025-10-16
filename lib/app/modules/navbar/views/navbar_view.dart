import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:crypted_app/app/modules/calls/views/calls_view.dart';
import 'package:crypted_app/app/modules/home/views/home_view.dart';
import 'package:crypted_app/app/modules/settings/views/settings_view.dart';
import 'package:crypted_app/app/modules/stories/views/stories_view.dart';
import 'package:crypted_app/core/locale/constant.dart';
//import 'package:crypted_app/app/modules/templates/stories2/src/views/main_view.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/navbar_controller.dart';

class NavbarView extends GetView<NavbarController> {
  const NavbarView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> bottomBarPages = [
      const HomeView(),
      const CallsView(),
      const StoriesView(),
      const SettingsView(),
    ];

    return Obx(
      () => Scaffold(
        body: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: bottomBarPages,
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
              inActiveItem: SvgPicture.asset(
                'assets/icons/home-01.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.lightGrey,
                  BlendMode.srcIn,
                ),
              ),
              activeItem: SvgPicture.asset(
                'assets/icons/home-01.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
              itemLabelWidget: Text(
                Constants.kHome.tr,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/call-calling.svg'),
              activeItem: SvgPicture.asset(
                'assets/icons/call-calling.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
              itemLabelWidget: Text(
                Constants.kCalls.tr,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/story.svg'),
              activeItem: SvgPicture.asset(
                'assets/icons/story.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
              itemLabelWidget: Text(
                Constants.kStories.tr,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/setting-2.svg'),
              activeItem: SvgPicture.asset(
                'assets/icons/setting-2.svg',
                colorFilter: ColorFilter.mode(
                  ColorsManager.primary,
                  BlendMode.srcIn,
                ),
              ),
              itemLabelWidget: Text(
                Constants.kSetting.tr,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ],
          onTap: (index) {
            // log('Selected index: $index');
            controller.changePage(index);
          },
        ),
      ),
    );
  }
}
