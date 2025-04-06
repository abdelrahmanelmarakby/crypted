import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_notifications_handler/firebase_notifications_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'core/services/get_storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CacheHelper.init();
  log(CacheHelper.getUserToken.toString());
  log(CacheHelper.getLocale.toString());
  // Get.put<EnvironmentController>(EnvironmentController());
  runApp(
    FirebaseNotificationsHandler(
      onFcmTokenInitialize: (token) {
        if (Platform.isIOS) {
          FirebaseMessaging.instance.getAPNSToken();
        }
        log(token.toString());
      },
      child: const MyApp(),
    ),
  );
}
