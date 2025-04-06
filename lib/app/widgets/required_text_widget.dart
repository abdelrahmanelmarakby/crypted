// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/theme/colors_manager.dart';
import '../../core/constants/theme/styles_manager.dart';

class RequiredTextWidget extends StatelessWidget {
  const RequiredTextWidget({
    super.key,
    this.isRequired = true,
    this.isAnotherHintRequired = false,
    required this.text,
    this.anotherHint,
  });
  final bool isRequired;
  final bool isAnotherHintRequired;

  final String text;
  final String? anotherHint;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: "$text ",
                style: StylesManager.bold(
                  color: ColorsManager.black,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: isRequired ? "* " : "",
                style: StylesManager.bold(
                  color: ColorsManager.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        if (anotherHint != null) SizedBox(height: 4.h),
        if (anotherHint != null)
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: "$anotherHint ",
                  style: StylesManager.light(
                    color: ColorsManager.grey,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: isAnotherHintRequired ? "* " : "",
                  style: StylesManager.light(
                    color: ColorsManager.error,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
