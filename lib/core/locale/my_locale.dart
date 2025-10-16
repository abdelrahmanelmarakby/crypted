import 'package:crypted_app/core/locale/ar.dart';
import 'package:crypted_app/core/locale/en.dart';
import 'package:get/get_navigation/src/root/internacionalization.dart';

class MyLocale implements Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
        'ar': ar,
      };
}
