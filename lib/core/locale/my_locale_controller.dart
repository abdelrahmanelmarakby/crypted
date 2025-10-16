import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class MyLocaleController extends GetxController {
  Rx<Locale> locale = (Get.deviceLocale ?? const Locale('en')).obs;

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  // تحميل اللغة المحفوظة
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('languageCode');

      if (savedLanguageCode != null) {
        locale.value = Locale(savedLanguageCode);
        Get.updateLocale(locale.value);
      }
    } catch (e) {
      print('Error loading locale: $e');
    }
  }

  // تغيير اللغة
  Future<void> changeLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', languageCode);

      locale.value = Locale(languageCode);
      Get.updateLocale(locale.value);
    } catch (e) {
      print('Error saving locale: $e');
    }
  }

  // الحصول على اللغة الحالية
  String get currentLanguageCode => locale.value.languageCode;
}
