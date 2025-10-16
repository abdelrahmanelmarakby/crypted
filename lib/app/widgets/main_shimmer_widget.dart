// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MainShimmerWidget extends StatelessWidget {
  const MainShimmerWidget({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: ColorsManager.grey.withValues(alpha: .2),
      child: child,
    );
  }
}
