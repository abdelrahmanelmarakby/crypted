import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.navbarColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}
