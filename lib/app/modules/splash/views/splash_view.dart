import 'package:crypted_app/app/modules/splash/controllers/splash_controller.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate after delay
    Future.delayed(
      const Duration(seconds: 2),
      () {
        controller.navigateUser(); // or whatever your next route is
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              'assets/icons/logoSplashImage.png',
              width: Sizes.size300,
              height: Sizes.size300,
              fit: BoxFit.fill,
              // color: ColorsManager.primary,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: Sizes.size150,
              height: Sizes.size150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
