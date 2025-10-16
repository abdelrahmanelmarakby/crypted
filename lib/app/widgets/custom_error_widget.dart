// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../core/extensions/build_context.dart';


// import 'app_spacer.dart';


// class CustomErrorWidget extends StatelessWidget {
//   const CustomErrorWidget({
//     super.key,
//     required this.error,
//     this.onPressed,
//     this.usingMaterial = false,
//   });
//   final String error;
//   final Function()? onPressed;
//   final bool usingMaterial;
//   @override
//   Widget build(BuildContext context) {
//     if (usingMaterial) {
//       return Scaffold(appBar: AppBar(), body: _buildErrorWidget(context));
//     }
//     return _buildErrorWidget(context);
//   }

//   Widget _buildErrorWidget(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Spacer(),
//         Expanded(child: Assets.images.systemUpdate.svg()),
//         AppSpacer(heightRatio: .5),
//         Text(context.translate.try_again_please, style: TextStyles.bold20),
//         if (kDebugMode)
//           Text(
//             error,
//             textAlign: TextAlign.center,
//             style: TextStyles.regular14.copyWith(color: Colors.red),
//           ),
//         AppSpacer(heightRatio: .5),
//         AppProgressButton(
//           onPressed: (val) {
//             if (onPressed != null) {
//               onPressed!();
//             }
//           },
//           text: context.translate.try_again_please,
//         ),
//         Spacer(),
//       ],
//     ).paddingAll(20);
//   }
// }
