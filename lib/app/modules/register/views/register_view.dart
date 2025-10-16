import 'package:crypted_app/app/modules/login/widgets/auth_footer.dart';
import 'package:crypted_app/app/widgets/app_progress_button.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

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
                child: Form(
                  key: controller.formKey,
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
                        Constants.kSignUpToCrypted.tr,
                        style: StylesManager.semiBold(
                          fontSize: FontSize.xXlarge,
                        ),
                      ),
                      SizedBox(height: Sizes.size34),
                      Obx(() {
                        final image = controller.selectedImage.value;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: controller.pickImage,
                              child: CircleAvatar(
                                radius: Radiuss.xXLarge60,
                                backgroundImage: image != null
                                    ? FileImage(image)
                                    : const AssetImage(
                                        'assets/images/Profile Image111.png',
                                      ) as ImageProvider,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: controller.pickImage,
                                child: CircleAvatar(
                                  backgroundColor: ColorsManager.offWhite,
                                  radius: Radiuss.xLarge18,
                                  child: SvgPicture.asset(
                                    'assets/icons/Add Profile Image Icon.svg',
                                    height: Sizes.size30,
                                    width: Sizes.size30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      SizedBox(height: Sizes.size14),
                      CustomTextField(
                        controller: controller.fullNameController,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(Paddings.normal),
                          child: SvgPicture.asset('assets/icons/profile.svg'),
                        ),
                        name: Constants.kFullName.tr,
                        hint: Constants.kEnteryourfullname.tr,
                        borderColor: ColorsManager.borderColor,
                        validate: (value) {
                          if (value == null || value.isEmpty) {
                            return Constants.kFullNameisrequired.tr;
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: Sizes.size12),
                      CustomTextField(
                        controller: controller.emailController,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(Paddings.normal),
                          child: SvgPicture.asset('assets/icons/profile.svg'),
                        ),
                        name: Constants.kEmail.tr,
                        hint: Constants.kEnteryouremail.tr,
                        borderColor: ColorsManager.borderColor,
                        validate: (value) {
                          if (value == null || value.isEmpty) {
                            return Constants.kEmailisrequired.tr;
                          }
                          if (!GetUtils.isEmail(value)) {
                            return Constants.kEnteravalidemail.tr;
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
                      SizedBox(height: Sizes.size20),
                      AppProgressButton(
                        onPressed: (anim) {
                          controller.register();
                        },
                        text: Constants.kSignUp.tr,
                        backgroundColor: ColorsManager.primary,
                      ),
                      SizedBox(height: Sizes.size10),
                      AuthFooter(
                        title: Constants.kAlreadyHaveAnAccount.tr,
                        subTitle: Constants.kLogin.tr,
                        onTap: () {
                          Get.back();
                        },
                      ),
                      SizedBox(height: Sizes.size100),
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
