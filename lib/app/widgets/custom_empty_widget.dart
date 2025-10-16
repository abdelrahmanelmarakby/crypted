// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class CustomEmptyWidget extends StatelessWidget {
//   const CustomEmptyWidget({
//     super.key,
//     this.message,
//     this.usingMaterial = false,
//   });
//   final String? message;
//   final bool usingMaterial;
//   @override
//   Widget build(BuildContext context) {
//     if (usingMaterial) {
//       return Material(child: _buildEmptyWidget(context));
//     }
//     return _buildEmptyWidget(context);
//   }

//   Widget _buildEmptyWidget(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Spacer(),
//         Expanded(child: Assets.images.empty.image(width: context.width)),
//         Text(
//           message ?? context.translate.no_data,
//           style: TextStyles.black16,
//           textAlign: TextAlign.center,
//         ),
//         Spacer(),
//       ],
//     );
//   }
// }
