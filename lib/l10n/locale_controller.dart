import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/get_storage_helper.dart';

class LocaleController extends GetxController {
  Locale locale = Locale(CacheHelper.getLocale);

  void setLocale(Locale newLocale) async {
    await CacheHelper.cacheLocale(langCode: newLocale.languageCode);
    locale = newLocale;
    Get.updateLocale(locale);
    update();
  }
}
