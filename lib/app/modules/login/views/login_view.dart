import 'package:crypted_app/app/modules/login/controllers/login_controller.dart';
import 'package:crypted_app/app/modules/login/widgets/auth_footer.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/core/widgets/stripe_payment_button.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
              child: Form(
                key: controller.formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Paddings.large,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: Sizes.size48),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.1,
                        width: double.infinity,
                        child: Center(
                          child: Image.asset('assets/images/logo.png'),
                        ),
                      ),
                      SizedBox(height: Sizes.size20),
                      Text(
                        Constants.kLogInToCrypted.tr,
                        style: StylesManager.semiBold(
                          fontSize: FontSize.xXlarge,
                        ),
                      ),
                      SizedBox(height: Sizes.size34),
                      CustomTextField(
                        controller: controller.emailController,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(Paddings.normal),
                          child: SvgPicture.asset('assets/icons/sms.svg'),
                        ),
                        name: Constants.kEmail.tr,
                        hint: Constants.kEnteryouremail.tr,
                        borderColor: ColorsManager.borderColor,
                        validate: (value) {
                          if (value == null || value.isEmpty) {
                            return Constants.kEmailisrequired.tr;
                          }
                          if (!GetUtils.isEmail(value)) {
                            return Constants.kEnteravalidemailaddress.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: Sizes.size12),
                      CustomTextField(
                        isPassword: true,
                        controller: controller.passwordController,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(Paddings.normal),
                          child: SvgPicture.asset('assets/icons/lock.svg'),
                        ),
                        name: Constants.kPassword.tr,
                        hint: Constants.kEnteryourpassword.tr,
                        borderColor: ColorsManager.borderColor,
                        validate: (value) {
                          if (value == null || value.isEmpty) {
                            return Constants.kPasswordisrequired.tr;
                          }
                          if (value.length < 6) {
                            return Constants
                                .kPasswordmustbeatleast6characters.tr;
                          }
                          return null;
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Get.toNamed(Routes.FORGET_PASSWORD);
                            },
                            child: Text(
                              Constants.kForgetPassword.tr,
                              style: StylesManager.medium(
                                fontSize: FontSize.xSmall,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Sizes.size20),
                      Obx(() => StripePaymentButton(
                            label: Constants.kLogin.tr,
                            state: controller.isLoading.value
                                ? PaymentButtonState.processing
                                : PaymentButtonState.ready,
                            onPressed: () {
                              if (controller.formKey.currentState!.validate()) {
                                controller.login();
                              }
                            },
                            primaryColor: ColorsManager.primary,
                            height: 56,
                          )),
                      SizedBox(height: Sizes.size10),
                      AuthFooter(
                        title: Constants.kDontHaveAnAccount.tr,
                        subTitle: Constants.kCreateAccount.tr,
                        onTap: () {
                          Get.toNamed(Routes.REGISTER);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
