import 'package:crypted_app/app/modules/calls/widgets/tab_bar_call.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/calls_controller.dart';

class CallsView extends GetView<CallsController> {
  const CallsView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallsController>(
      builder: (controller) => Scaffold(
        backgroundColor: ColorsManager.white,
        body: Column(
          children: [
            Container(
              height: Sizes.size170,
              color: ColorsManager.navbarColor,
              padding: const EdgeInsets.only(
                top: Paddings.xXLarge50,
                left: Paddings.large,
                right: Paddings.large,
                bottom: Paddings.large,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Constants.kCalls.tr,
                    style: StylesManager.semiBold(fontSize: FontSize.xLarge),
                  ),
                  SizedBox(height: Sizes.size10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() => CustomTextField(
                                borderRadius: Radiuss.large,
                                contentPadding: false,
                                height: Sizes.size42,
                                prefixIcon:
                                    Icon(Icons.search, size: Sizes.size20),
                                suffixIcon:
                                    controller.searchQuery.value.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              controller.clearSearch();
                                            },
                                            child: Icon(
                                              Icons.clear,
                                              size: Sizes.size20,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        : null,
                                hint: Constants.kSearch.tr,
                                borderColor: ColorsManager.navbarColor,
                                fillColor: ColorsManager.white,
                                onChange: (value) {
                                  controller.searchCalls(value);
                                },
                              )),
                        ),
                        SizedBox(width: Sizes.size10),
                        GestureDetector(
                          onTap: () {
                            controller.refreshCalls();
                          },
                          child: Container(
                            padding: EdgeInsets.all(Sizes.size8),
                            decoration: BoxDecoration(
                              color: ColorsManager.white,
                              borderRadius:
                                  BorderRadius.circular(Radiuss.large),
                            ),
                            child: Icon(
                              Icons.refresh,
                              size: Sizes.size20,
                              color: ColorsManager.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Sizes.size14),
            Expanded(child: TabBarCall()),
          ],
        ),
      ),
    );
  }
}
