import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class GroupLoadingView extends StatelessWidget {
  const GroupLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          SizedBox(height: Sizes.size10),
          Text(
            "Loading group information...",
            style: StylesManager.regular(fontSize: FontSize.medium),
          ),
        ],
      ),
    );
  }
}
