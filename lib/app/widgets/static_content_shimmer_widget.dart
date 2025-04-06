import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crypted/app/widgets/custom_shimmer.dart';

class StaticContentShimmerWidget extends StatelessWidget {
  const StaticContentShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.symmetric(
        horizontal: 20.sp,
        vertical: 10.sp,
      ),
      itemBuilder: (context, index) {
        return MainShimmerWidget(
          child: Container(margin: 
            EdgeInsets.symmetric(
              vertical: 10.sp,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10.sp),
            ),
            width: double.infinity,
            height: 100.sp,
          ),
        );
      },
    );
  }
}
