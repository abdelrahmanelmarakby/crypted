import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/get_storage_helper.dart';

class EnvironmentController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool isConnected = true;

  @override
  void onReady() {
    _monitorConnectivity();
    super.onReady();
  }

  void _monitorConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        if (result.contains(ConnectivityResult.mobile)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.wifi)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.ethernet)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.vpn)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.bluetooth)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.other)) {
          isConnected = true;
          update();
        } else if (result.contains(ConnectivityResult.none)) {
          isConnected = false;
          update();
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Locale? locale=Locale('ar') ;
  void setLocale(Locale newLocale) async {
    await CacheHelper.cacheLocale(langCode: newLocale.languageCode);
    locale = newLocale;
    Get.updateLocale(locale!);
    update();
  }
}
