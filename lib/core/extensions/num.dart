// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'docavia_utills.dart';

final screenSize = ui.window.physicalSize / ui.window.devicePixelRatio;
final screenWidth = screenSize.width;
final screenHeight = screenSize.height;

extension GetNumUtils on num {
  bool isLowerThan(num b) => DocaviaUtils.isLowerThan(this, b);

  bool isGreaterThan(num b) => DocaviaUtils.isGreaterThan(this, b);

  bool isEqual(num b) => DocaviaUtils.isEqual(this, b);
  Future delay([FutureOr Function()? callback]) async =>
      Future.delayed(Duration(milliseconds: (this * 1000).round()), callback);
  Widget get heightSizedBox => SizedBox(height: toDouble());
  Widget percentHeightSizedBox(BuildContext context) =>
      SizedBox(height: context.height * this);
  Widget get widthSizedBox => SizedBox(width: toDouble());
  Widget percentWidthSizedBox(BuildContext context) =>
      SizedBox(width: context.width * this);
}
