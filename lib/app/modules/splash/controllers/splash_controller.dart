import 'dart:developer';

import 'package:get/get.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';

class SplashController extends GetxController {
  // @override
  // void onInit() {
  //   super.onInit();
  //   navigateUser();
  // }

  void navigateUser() async {
    // await Future.delayed(const Duration(seconds: 2));

    final String? userId = CacheHelper.getUserId;
    log("User ID: $userId");
    if (CacheHelper.getUserId != null) {
      Get.offAllNamed(Routes.NAVBAR);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
