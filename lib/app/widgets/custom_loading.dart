import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Sizes.size48,
      width: Sizes.size48,
      child: Center(
        child: Lottie.asset(
          'assets/lottie/lHYYjmp41x (1).json',
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }
}

void showLoading() {
  BotToast.showCustomLoading(
    toastBuilder: (cancelFunc) {
      return const CustomLoading();
    },
  );
}
