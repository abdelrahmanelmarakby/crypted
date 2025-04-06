import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crypted/core/extensions/build_context.dart';

import '../../../gen/assets.gen.dart';

class EmptyWidget extends StatelessWidget {
  final String? text;
  const EmptyWidget({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Assets.images.empty.svg(),
          SizedBox(),
          Text(
           text??context.translate.no_content,
            style: TextStyle(fontSize: 20.sp),
          )
        ],
      ),
    );
  }
}
