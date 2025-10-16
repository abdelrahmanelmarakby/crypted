import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';

class PrivacyCover extends StatelessWidget {
  const PrivacyCover(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.navbarColor,
        borderRadius: BorderRadius.circular(Radiuss.xSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Paddings.normal),
        child: Column(children: children),
      ),
    );
  }
}
