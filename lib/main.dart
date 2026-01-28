import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/att_service.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/fcm_service.dart';
import 'package:crypted_app/app/core/services/notification_controller.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/firebase_optimization_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/initialization/app_initializer.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/core/locale/my_locale.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/services/bindings.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/theme_manager.dart';
import 'package:crypted_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Check if user is in China region
/// Used to disable CallKit as required by Chinese MIIT regulations
bool _isUserInChina() {
  try {
    // Check device locale
    final locale = Platform.localeName.toLowerCase();

    // Check for Chinese locales (zh_CN, zh_Hans_CN, etc.)
    if (locale.contains('_cn') || locale.contains('-cn')) {
      return true;
    }

    // Also check the language code for simplified Chinese in mainland China context
    if (locale.startsWith('zh_hans') && !locale.contains('_hk') && !locale.contains('_tw')) {
      return true;
    }

    return false;
  } catch (e) {
    // If we can't determine, assume not in China
    return false;
  }
}

Future<void> main() async {
  
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
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

    // Initialize Awesome Notifications BEFORE FCM Service
    await FCMService.initializeAwesomeNotifications();
    LoggerService.instance.info('Awesome Notifications initialized', context: 'main');

    // Initialize AwesomeNotifications FCM add-on
    await AwesomeNotificationsFcm().initialize(
      onFcmSilentDataHandle: NotificationController.onFcmSilentDataHandle,
      onFcmTokenHandle: NotificationController.onFcmTokenHandle,
      onNativeTokenHandle: NotificationController.onNativeTokenHandle,
      debug: kDebugMode,
    );
    LoggerService.instance.info('AwesomeNotifications FCM initialized', context: 'main');

    // Set up notification listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );
    LoggerService.instance.info('Notification listeners configured', context: 'main');

    // Initialize isolate communication
    await NotificationController.initializeIsolateReceivePort();
    LoggerService.instance.info('Isolate communication initialized', context: 'main');

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

  // Initialize app architecture (repositories, offline queue, migrations)
  try {
    final initResult = await AppInitializer.initialize(
      onProgress: (step) {
        if (kDebugMode) {
          print('[AppInit] $step');
        }
      },
      runMigrations: true,
    );

    if (initResult.success) {
      LoggerService.instance.info(
        'App architecture initialized in ${initResult.duration.inMilliseconds}ms',
        context: 'main',
      );
    } else {
      LoggerService.instance.warning(
        'App initialization had issues: ${initResult.errors.join(", ")}',
        context: 'main',
      );
    }
  } catch (e) {
    LoggerService.instance.logError('App initialization failed', error: e, context: 'main');
  }

  // Start connectivity monitoring
  ConnectivityService().startMonitoring();

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  ZegoUIKit().initLog().then((value) async {
    // Check if user is in China - CallKit must be disabled for China App Store
    final isInChina = _isUserInChina();

    if (!isInChina) {
      // Enable system calling UI (CallKit) only for non-China regions
      ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
        [ZegoUIKitSignalingPlugin()],
      );
    } else {
      LoggerService.instance.info(
        'CallKit disabled for China region',
        context: 'Zego',
      );
    }

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

    runApp(CryptedApp(navigatorKey: navigatorKey));
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

    // Request App Tracking Transparency permission on iOS
    // This must be called BEFORE any tracking/analytics data collection
    _requestTrackingPermission();

    // Set user online when app starts
    _setUserOnline();
  }

  /// Request ATT permission on iOS - required by Apple App Store
  Future<void> _requestTrackingPermission() async {
    if (Platform.isIOS) {
      // Wait for the first frame to be rendered before showing ATT dialog
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final status = await ATTService().requestTrackingPermission();
        LoggerService.instance.info('ATT permission status: $status', context: 'ATT');
      });
    }
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
        // Resume connectivity monitoring
        ConnectivityService().onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background
        _setUserOffline();
        // Pause connectivity monitoring
        ConnectivityService().onAppPaused();
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
