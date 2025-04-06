import 'package:flutter/material.dart';

import '../constants/theme/colors_manager.dart';


extension DurationExt on int {
  Duration get seconds => Duration(seconds: this);

  Duration get days => Duration(days: this);

  Duration get hours => Duration(hours: this);

  Duration get minutes => Duration(minutes: this);

  Duration get milliseconds => Duration(milliseconds: this);

  Duration get microseconds => Duration(microseconds: this);

  Duration get ms => milliseconds;

  //Method that takes a
  Color getColorForPasswordStrength() {
    assert(this > 0 && this < 7, "strength must be >0 && < 7");
    if (this <= 3) {
      return ColorsManager.error;
    } else if (this <= 5) {
      return Colors.orange;
    } else {
      return ColorsManager.success;
    }
  }
}
