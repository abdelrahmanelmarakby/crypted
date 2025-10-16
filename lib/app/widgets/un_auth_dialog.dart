// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';

// import '../routes/app_pages.dart';

// class UnAuthDialog extends StatelessWidget {
//   const UnAuthDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoAlertDialog(
//       title: Text(context.translate.unauth_title),
//       content: Text(context.translate.unauth_hint),
//       actions: [
//         CupertinoDialogAction(
//           isDefaultAction: true,
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: Text(
//             context.translate.cancel,
//             style: const TextStyle(color: CupertinoColors.systemBlue),
//           ),
//         ),
//         CupertinoDialogAction(
//           isDestructiveAction: true,
//           onPressed: () {
//             Navigator.of(context).pop();
//             Get.toNamed(Routes.LOGIN);
//           },
//           child: Text(context.translate.login),
//         ),
//       ],
//     );
//   }
// }
