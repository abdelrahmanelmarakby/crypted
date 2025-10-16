import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/modules/home/widgets/search.dart';
import 'package:crypted_app/app/modules/home/widgets/tabs_chat.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Obx(() {
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
                  SizedBox(width: Sizes.size12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Constants.kHello.tr,
                        style: StylesManager.medium(fontSize: FontSize.small),
                      ),
                      Obx(() => Text(
                            controller.myUser.value?.fullName ??
                                UserService.currentUser.value?.fullName ??
                                Constants.kUser.tr,
                            style: StylesManager.regular(
                                fontSize: FontSize.medium),
                          )),
                    ],
                  ),
                  Spacer(),
                  CircleAvatar(
                    radius: Radiuss.xLarge22,
                    backgroundColor: ColorsManager.navbarColor,
                    child: CircleAvatar(
                      radius: Radiuss.xLarge,
                      backgroundColor: ColorsManager.white,
                      child: IconButton(
                        onPressed: () {
                          Get.to(() => Search());
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/search-normal.svg',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Sizes.size14),
              Expanded(child: TabsChat()),
            ],
          ),
        ),
      ),
    );
  }
}
