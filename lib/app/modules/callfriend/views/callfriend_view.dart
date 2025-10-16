import 'package:crypted_app/app/modules/callfriend/widgets/redios_container.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/callfriend_controller.dart';

class CallfriendView extends GetView<CallfriendController> {
  const CallfriendView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.selection,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/Profile Image111.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: Paddings.xXLarge50,
            bottom: Paddings.xLarge,
            right: Paddings.xLarge,
            left: Paddings.xLarge,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  RediosContainer(
                    image: 'assets/icons/fi_11399453.svg',
                    backgroundColor: ColorsManager.veryLightGrey,
                  ),
                  SizedBox(width: Sizes.size4),
                  RediosContainer(
                    image: 'assets/icons/fi_770444.svg',
                    backgroundColor: ColorsManager.veryLightGrey,
                  ),
                  Spacer(flex: 1),
                  Column(
                    children: [
                      Text(
                        'Nader Ali',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.xLarge,
                          color: ColorsManager.white,
                        ),
                      ),
                      Text(
                        Constants.kRinging.tr,
                        style: StylesManager.medium(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.white,
                        ),
                      ),
                    ],
                  ),
                  Spacer(flex: 2),
                  RediosContainer(
                    image: 'assets/icons/user-add.svg',
                    backgroundColor: ColorsManager.veryLightGrey,
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
              Container(
                decoration: BoxDecoration(
                  color: ColorsManager.veryLightGrey,
                  borderRadius: BorderRadius.circular(Radiuss.normal),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Paddings.small),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RediosContainer(
                            image: 'assets/icons/Component 2.svg',
                            backgroundColor: ColorsManager.lightGrey,
                          ),
                          RediosContainer(
                            image: 'assets/icons/fi_17857009.svg',
                            backgroundColor: ColorsManager.lightGrey,
                          ),
                          RediosContainer(
                            image: 'assets/icons/fi_15307706.svg',
                            backgroundColor: ColorsManager.lightGrey,
                          ),
                          RediosContainer(
                            image: 'assets/icons/fi_8300107.svg',
                            backgroundColor:
                                ColorsManager.backgroundcallContainer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
