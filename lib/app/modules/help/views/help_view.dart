// ignore_for_file: sort_child_properties_last

import 'package:crypted_app/app/modules/help/widgets/help_icon.dart';
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

import '../controllers/help_controller.dart';

class HelpView extends GetView<HelpController> {
  const HelpView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kHelp.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorsManager.navbarColor,
                      borderRadius: BorderRadius.circular(Radiuss.normal),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Paddings.normal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.ksocialmedia.tr,
                            style: StylesManager.regular(
                              fontSize: FontSize.medium,
                            ),
                          ),
                          SizedBox(height: Sizes.size16),
                          Row(
                            children: [
                              HelpIcon('assets/icons/Vector.svg'),
                              SizedBox(width: Sizes.size16),
                              HelpIcon('assets/icons/fi_2111678.svg'),
                              SizedBox(width: Sizes.size16),
                              HelpIcon('assets/icons/fi_1077042.svg'),
                              SizedBox(width: Sizes.size16),
                              HelpIcon('assets/icons/fi_20837.svg'),
                              SizedBox(width: Sizes.size16),
                              HelpIcon('assets/icons/X.svg'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Sizes.size16),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorsManager.navbarColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Paddings.normal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.kcontactus.tr,
                            style: StylesManager.regular(
                              fontSize: FontSize.medium,
                            ),
                          ),
                          SizedBox(height: Sizes.size16),
                          CustomTextField(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(Paddings.normal),
                              child: SvgPicture.asset(
                                'assets/icons/profile.svg',
                              ),
                            ),
                            name: Constants.kFullName.tr,
                            hint: Constants.kEnteryourfullname.tr,
                            borderColor: ColorsManager.borderColor,
                          ),
                          SizedBox(height: Sizes.size16),
                          // Email Field
                          CustomTextField(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(Paddings.normal),
                              child: SvgPicture.asset('assets/icons/sms.svg'),
                            ),
                            name: Constants.kEmail.tr,
                            hint: Constants.kEnteryouremail.tr,
                            borderColor: ColorsManager.borderColor,
                          ),
                          SizedBox(height: Sizes.size16),

                          CustomTextField(
                            maxLines: 5,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(top: Paddings.small),
                              child: Align(
                                alignment: Alignment.topCenter,
                                widthFactor: 1.0,
                                heightFactor: 5.5,
                                child: SvgPicture.asset(
                                  'assets/icons/message.svg',
                                  width: Sizes.size20,
                                  height: Sizes.size20,
                                ),
                              ),
                            ),
                            name: Constants.kMessage.tr,
                            hint: Constants.kEnteryourmessage.tr,
                            borderColor: ColorsManager.borderColor,
                          ),
                          SizedBox(height: Sizes.size30),

                          AppProgressButton(
                            width: Sizes.size111,
                            onPressed: (anim) {
                              // Example Navigation
                              // Get.offAllNamed(Routes.NAVBAR);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/Password Icon.svg',
                                ),
                                SizedBox(width: Sizes.size10),
                                Text(
                                  Constants.ksend.tr,
                                  style: StylesManager.black(
                                    fontSize: FontSize.medium,
                                    color: ColorsManager.white,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: ColorsManager.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
