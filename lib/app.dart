// // ignore_for_file: public_member_api_docs, sort_constructors_first, depend_on_referenced_packages
// import 'package:bot_toast/bot_toast.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:get/get.dart';
// import 'package:intouch/app/routes/app_pages.dart';
// import 'package:intouch/core/extensions/build_context.dart';
// import 'package:intouch/core/theme/size_config.dart';
// import 'package:intouch/core/theme/theme_manager.dart';
// import 'package:intouch/l10n/messages.dart' as common_messages;
// import '../../app/modules/environment/controllers/environment_controller.dart';
// import 'app/widgets/error_screen.dart';
// import 'core/services/bindings.dart';
// import 'l10n/messages.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final botToastBuilder = BotToastInit();
//     return GetBuilder<EnvironmentController>(
//       builder: (controller) {
        
//             SizeConfig().init(context);
//             return GetMaterialApp(
//               navigatorObservers: [BotToastNavigatorObserver()],
//               initialRoute: AppPages.INITIAL,
//               onGenerateTitle: (context) => context.translate.appName,
//               debugShowCheckedModeBanner: false,
//               initialBinding: InitialBindings(),
//               getPages: AppPages.routes,
//               theme: ThemeManager.appTheme,
//               themeMode: ThemeMode.light,
//               locale: controller.locale,
//               localizationsDelegates: const [
//                 ...S.localizationsDelegates,
//                 common_messages.S.delegate,
//                 GlobalWidgetsLocalizations.delegate,
//                 GlobalCupertinoLocalizations.delegate,
//                 GlobalMaterialLocalizations.delegate,
//               ],
//               supportedLocales: S.supportedLocales,
//               defaultTransition: Transition.fadeIn,
//               builder: (context, child) {
//                 handelErrorScreen(context);
//                 child = botToastBuilder(context, child!);
//                 return child;
//               },
//             );
          
        
//       },
//     );
//   }
// }
