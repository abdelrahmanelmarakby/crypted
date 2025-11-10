import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/fcm_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/firebase_optimization_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/core/locale/my_locale.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/services/bindings.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/theme_manager.dart';
import 'package:crypted_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('ar', 'null');
  await initializeDateFormatting('en', 'null');

  // Initialize Logger Service (must be first for logging other initializations)
  LoggerService.instance.initialize(
    minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
    console: true,
    remote: !kDebugMode, // Enable remote logging in production
  );

  LoggerService.instance.info('App starting...', context: 'main');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerService.instance.info('Firebase initialized successfully', context: 'main');

    // Initialize Firebase Optimization Service
    FirebaseOptimizationService.initializeFirebase();

    // Initialize FCM Service
    await FCMService().initialize();

    // Initialize Presence Service
    await PresenceService().initialize();

    LoggerService.instance.info('All services initialized successfully', context: 'main');
  } catch (e, stackTrace) {
    ErrorHandlerService.instance.handleError(
      e,
      stackTrace: stackTrace,
      context: 'main.initializeFirebase',
      showToUser: false, // Don't show to user during startup
    );
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

class CryptedApp extends StatefulWidget {
  const CryptedApp({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<CryptedApp> createState() => _CryptedAppState();
}

class _CryptedAppState extends State<CryptedApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set user online when app starts
    _setUserOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background
        _setUserOffline();
        break;
    }
  }

  void _setUserOnline() {
    // Only set online if user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      PresenceService().goOnline();
    }
  }

  void _setUserOffline() {
    // Only set offline if user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      PresenceService().goOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MyLocaleController());
    Get.put(ChatSessionManager());
    final botToastBuilder = BotToastInit();

    return GetMaterialApp(
      translations: MyLocale(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en'),
      navigatorKey: widget.navigatorKey,
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
