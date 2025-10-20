import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/settings/widgets/item_out_side_setting.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    MyLocaleController myLocaleController = Get.find<MyLocaleController>();
    final SettingsController controller = Get.put(SettingsController());
    return Scaffold(
      backgroundColor: ColorsManager.primary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        forceMaterialTransparency: true,
        centerTitle: false,
        title: Text(
          Constants.kSetting.tr,
          style: StylesManager.black(
            fontSize: FontSize.xLarge,
            color: ColorsManager.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.2,
            child: Image.asset(
              'assets/icons/background_setting_image.jpg',
              height: Sizes.size300,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: Paddings.large,
                    left: Paddings.large,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Obx(() {
                            final user = UserService.currentUser.value;
                            if (user?.imageUrl != null &&
                                user!.imageUrl!.isNotEmpty) {
                              return ClipOval(
                                child: AppCachedNetworkImage(
                                  imageUrl: user.imageUrl!,
                                  fit: BoxFit.cover,
                                  height: Radiuss.xXLarge25 * 2,
                                  width: Radiuss.xXLarge25 * 2,
                                  isCircular: true,
                                ),
                              );
                            } else {
                              return CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/images/Profile Image111.png',
                                ),
                                radius: Radiuss.xXLarge25,
                              );
                            }
                          }),
                          SizedBox(width: Sizes.size10),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: Paddings.xLarge),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text(
                                      UserService.currentUser.value?.fullName ??
                                          Constants.kUser.tr,
                                      style: StylesManager.regular(
                                        fontSize: FontSize.medium,
                                        color: ColorsManager.white,
                                      ),
                                    )),
                                SizedBox(height: Sizes.size4),
                                Obx(() => Text(
                                      UserService.currentUser.value?.email ??
                                          '',
                                      style: StylesManager.medium(
                                        fontSize: FontSize.small,
                                        color: ColorsManager.white,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Sizes.size24),
                Expanded(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      color: ColorsManager.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Radiuss.xXLarge40),
                        topRight: Radius.circular(Radiuss.xXLarge40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        Paddings.xXLarge,
                      ),
                      child: Obx(
                        () => ListView(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ItemOutSideSetting(
                              onTap: () => Get.toNamed(Routes.PROFILE),
                              title: Constants.kProfile.tr,
                              icon: 'assets/icons/fi_13193798.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () => Get.toNamed(Routes.PRIVACY),
                              title: Constants.kPrivacy.tr,
                              icon: 'assets/icons/fi_10252078.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
                              title: Constants.kNotifications.tr,
                              icon: 'assets/icons/notification-bing.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () {},
                              title: Constants.kBackup.tr,
                              icon: 'assets/icons/fi_10402480.svg',
                              isSwitched: controller.switches.value,
                              onChanged: (value) =>
                                  controller.toggleSwitch(value),
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () => Get.toNamed(Routes.HELP),
                              title: Constants.kHelp.tr,
                              icon: 'assets/icons/fi_545674.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () => Get.toNamed(Routes.INVITE_FRIEND),
                              title: Constants.kInviteFriend.tr,
                              icon: 'assets/icons/fi_8763531.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () {
                                CallDataSources callDataSources =
                                    CallDataSources();
                                // callDataSources.onUserLogout();

                                CacheHelper.logout();
                                Get.offAllNamed(Routes.LOGIN);
                              },
                              title: Constants.kLogout.tr,
                              icon: 'assets/icons/logout-svgrepo-com.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () {
                                myLocaleController.changeLocale('ar');
                                //  Get.updateLocale(const Locale('ar'));
                              },
                              title: Constants.kArabic.tr,
                              icon: 'assets/icons/icons8-language.svg',
                            ),
                            Divider(color: ColorsManager.navbarColor),
                            ItemOutSideSetting(
                              onTap: () {
                                myLocaleController.changeLocale('en');
                                //  Get.updateLocale(const Locale('en'));
                              },
                              title: Constants.kEnglish.tr,
                              icon: 'assets/icons/icons8-language.svg',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
