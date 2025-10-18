import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/locale/my_locale.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/services/bindings.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/theme_manager.dart';
import 'package:crypted_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/app.dart';
import 'package:crypted_app/core/locale/constant.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', 'null');
  await initializeDateFormatting('en', 'null');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print(
        'Error initializing Firebase: $e ----------------------------------------------------------------------------');
  }
  await CacheHelper.init();

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  ZegoUIKit().initLog().then((value) async {
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    // محاولة جلب المستخدم الحالي من UserService.currentUser.value أو من FirebaseAuth
    String? userID;
    String? userName;
    if (UserService.currentUser.value != null) {
      userID = UserService.currentUser.value!.uid;
      userName = UserService.currentUser.value!.fullName;
    } else {
      // جلب من FirebaseAuth مباشرة إذا لم يكن موجوداً في UserService
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          userID = firebaseUser.uid;
          userName = firebaseUser.displayName ?? Constants.kUser.tr;
        }
      } catch (e) {
        print('Error getting FirebaseAuth user: $e');
      }
    }

    if (userID != null && userName != null) {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConstants.appID,
        appSign: AppConstants.appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );
      print('ZegoUIKitPrebuiltCallInvitationService initialized for $userID');
    } else {
      print(
          'User not found at startup, ZegoUIKitPrebuiltCallInvitationService will be initialized after login.');
    }

    runApp(FirebaseNotificationsHandler(
        onFcmTokenInitialize: (token) async {
          if (Platform.isIOS) {
            await FirebaseMessaging.instance.getAPNSToken();
          }
        },
        child: CryptedApp(navigatorKey: navigatorKey)));
  });
}

class CryptedApp extends StatelessWidget {
  const CryptedApp({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    Get.put(MyLocaleController());
    Get.put(ChatSessionManager());
    final botToastBuilder = BotToastInit();

    return GetMaterialApp(
      translations: MyLocale(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en'),
      navigatorKey: navigatorKey,
      theme: ThemeManager
          .lightTheme, //ThemeData(fontFamily: "IBM Plex Sans Arabic"),
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      initialBinding: InitialBindings(),
      getPages: AppPages.routes,
      navigatorObservers: [BotToastNavigatorObserver()],
      builder: (context, child) {
        return botToastBuilder(context, child!);
      },
    );
  }
}
