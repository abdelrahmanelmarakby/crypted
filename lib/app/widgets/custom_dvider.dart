import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';

Divider buildDivider() {
  return Divider(
    color: ColorsManager.lightGrey,
    thickness: 0.5,
    indent: 15,
    endIndent: 15,
  );
}
