import 'package:crypted_app/app/modules/login/widgets/auth_footer.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/app_progress_button.dart';
import 'package:crypted_app/app/widgets/pin_code_fields.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/otp_controller.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});
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
                      Constants.kEnterOTP.tr,
                      style: StylesManager.semiBold(fontSize: FontSize.xXlarge),
                    ),
                    SizedBox(height: Sizes.size34),
                    PinCodeFields(
                      onChanged: (value) {
                        controller.onChangeOtp(value);
                      },
                    ),
                    Text(
                      '00:59',
                      style: StylesManager.regular(fontSize: FontSize.medium),
                    ),
                    SizedBox(height: Sizes.size20),
                    AppProgressButton(
                      onPressed: (anim) {
                        Get.toNamed(Routes.RESET_PASSWORD);
                      },
                      text: Constants.ksend.tr,
                      backgroundColor: ColorsManager.primary,
                    ),
                    SizedBox(height: Sizes.size10),
                    AuthFooter(
                      title: Constants.kDidntreceivecode.tr,
                      subTitle: Constants.kResend.tr,
                      onTap: () {
                        Get.toNamed(Routes.LOGIN);
                      },
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
