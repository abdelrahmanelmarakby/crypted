import 'package:get_storage/get_storage.dart';

class CacheHelper {
  static final GetStorage _appBox = GetStorage();

  static Future<void> init() async => await GetStorage.init();
  static Future<void> cacheToken({required String token}) async {
    await _cacheUserToken(token);
  }

  static Future<void> _cacheUserToken(String token) async =>
      await _appBox.write('token', token);

  static String? get getUserToken => _appBox.read('token');

  static Future<void> cacheUserId({required String id}) async {
    await _cacheUserId(id);
  }

  static Future<void> _cacheUserId(String id) async =>
      await _appBox.write('user_id', id);

  static String? get getUserId => _appBox.read('user_id');

  static Future<void> cacheLocale({required String langCode}) async {
    await _cacheLocale(langCode);
  }

  static Future<void> _cacheLocale(String langCode) async =>
      await _appBox.write('langCode', langCode);

  static String get getLocale => _appBox.read('langCode') ?? "ar";
  static Future<void> cacheFirstTime({required bool isFirst}) async {
    await _cacheFirstTime(isFirst);
  }

  static Future<void> _cacheFirstTime(bool isFirst) async =>
      await _appBox.write('isFirst', isFirst);

  static bool get getIsFirstTime => _appBox.read('isFirst') ?? true;
  static Future<void> eraseCache() async => _appBox.erase();

  static Future<void> logout() async {
    Future.wait([_appBox.remove('token'), _appBox.remove('user_id')]);
  }
}
