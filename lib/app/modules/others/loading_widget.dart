// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:crypted/gen/assets.gen.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.withMaterial = false,
  });
  final bool withMaterial;
  @override
  Widget build(BuildContext context) {
    if (withMaterial) {
      return Material(
        child: Center(
          child: Lottie.asset(
            height: 50,
            width: 50,
            Assets.images.loading.path,
          ),
        ),
      );
    }
    return Center(
      child: Lottie.asset(
        height: 50,
        width: 50,
        Assets.images.loading.path,
      ),
    );
  }
}

void showLoading() {
  BotToast.showCustomLoading(
    toastBuilder: (cancelFunc) {
      return const LoadingWidget(withMaterial: false);
    },
  );
}

void hideLoading() {
  BotToast.closeAllLoading();
}
