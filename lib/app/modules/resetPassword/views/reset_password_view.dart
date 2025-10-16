import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/app_progress_button.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';

import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                'assets/icons/logoSplashImage.png',
                width: Sizes.size300,
                height: Sizes.size300,
                fit: BoxFit.fill,
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
                child: Column(
                  children: [
                    SizedBox(height: Sizes.size48),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: Icon(
                            Icons.chevron_left_outlined,
                            size: Sizes.size30,
                          ),
                        ),
                        Spacer(),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.1,
                          width: Sizes.size100,
                          child: Center(
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ),
                        Spacer(),
                        SizedBox(width: Sizes.size42),
                      ],
                    ),
                    SizedBox(height: Sizes.size20),
                    Text(
                      Constants.kResetPassword.tr,
                      style: StylesManager.semiBold(fontSize: FontSize.xXlarge),
                    ),
                    SizedBox(height: Sizes.size34),
                    CustomTextField(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(Paddings.normal),
                        child: SvgPicture.asset('assets/icons/lock.svg'),
                      ),
                      name: Constants.kNewPassword.tr,
                      hint: Constants.kEnteryourpassword.tr,
                      borderColor: ColorsManager.borderColor,
                    ),
                    SizedBox(height: Sizes.size20),
                    CustomTextField(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(Paddings.normal),
                        child: SvgPicture.asset('assets/icons/lock.svg'),
                      ),
                      name: Constants.kReEnterpaswword.tr,
                      hint: Constants.kEnteryourpassword.tr,
                      borderColor: ColorsManager.borderColor,
                    ),
                    SizedBox(height: Sizes.size20),
                    AppProgressButton(
                      onPressed: (anim) {
                        Get.offAllNamed(Routes.LOGIN);
                      },
                      text: Constants.kSave,
                      backgroundColor: ColorsManager.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
