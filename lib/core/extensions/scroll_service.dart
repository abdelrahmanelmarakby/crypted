import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ScrollService {
  static Future<void> scrollToEnd({
    required ScrollController scrollController,
    bool reversed = false,
    Duration duration = const Duration(milliseconds: 150),
    double? bottom,
    double? top,
  }) async {
    top = top ?? scrollController.position.minScrollExtent;
    bottom = bottom ?? scrollController.position.maxScrollExtent;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        scrollController.animateTo(
          reversed ? top! : bottom!,
          duration: duration,
          curve: Curves.easeOut,
        );
      },
    );
  }
}