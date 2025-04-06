import 'package:get/get.dart';
import '../../extensions/build_context.dart';
import '../../../app/data/models/language_model.dart';
import '../../../gen/assets.gen.dart';

class AppConstants {
  static const String online = 'online';
  static const String cash = 'cash';
  static const String ar = 'ar';
  static const String en = 'en';
  static const String dateFormate = 'yyyy-MM-dd';
  static const String timeFormate = 'HH:mm';
  static const String dateOfBirthFormate = 'yyyy-MM-dd HH:mm';
  static const String relationMy = 'my';
  static const String appPhoneKey = '966';
  static const String appCountryKey = 'SA';
  static const String paymentIdNotAvailable = 'PAYMENT_ID NOT AVAILABLE';
  String getAppCurrency() {
    return Get.context!.translate.currency;
  }

  List<String> getGenderList() {
    return [
      Get.context!.translate.male,
      Get.context!.translate.female,
    ];
  }

  List<LanguageModel> getLanguageList() {
    return [
      LanguageModel(
        imagePath: Assets.countries.usSvg.path,
        name: Get.context!.translate.english_language,
        code: en,
      ),
      LanguageModel(
        imagePath: Assets.countries.arSvg.path,
        name: Get.context!.translate.arabic_language,
        code: ar,
      ),
    ];
  }
}
