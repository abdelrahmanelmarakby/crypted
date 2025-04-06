import 'package:get_storage/get_storage.dart';

class CacheHelper {
  //========================================================
  static final GetStorage _appBox = GetStorage();

  static Future<void> init() async => await GetStorage.init();

  //========================================================
  static Future<void> cacheToken({
    required String token,
  }) async {
    await _cacheUserToken(token);
  }

  static Future<void> _cacheUserToken(String uid) async => await _appBox.write('token', uid);

  static String? get getUserToken => _appBox.read('token');
  //========================================================
  static Future<void> cacheUserId({
    required int id,
  }) async {
    await _cacheUserId(id);
  }

  static Future<void> _cacheUserId(int uid) async => await _appBox.write('id', uid);

  static int? get getUserId => _appBox.read('id');
  
     //========================================================
  static Future<int> getUserIdInt() async {
    final id = _appBox.read('id');
    return id ?? 0;
  }

  static Future<void> cacheStoreId({
    required int id,
  }) async {
    await _cacheStoreId(id);
  }

  static Future<void> _cacheStoreId(int uid) async => await _appBox.write('store_id', uid);

  static int? get getStoreId => _appBox.read('store_id');
  

  //========================================================
  static Future<int> getStoreIdInt() async {
    final id = _appBox.read('store_id');
    return id ?? 0;
  }

//=========================================================
  static Future<void> cacheLocale({
    required String langCode,
  }) async {
    await _cacheLocale(langCode);
  }

  static Future<void> _cacheLocale(String langCode) async =>
      await _appBox.write('langCode', langCode);

  static String get getLocale => _appBox.read('langCode') ??'ar'/*  Get.deviceLocale!.languageCode */;
  static Future<void> eraseLocale() async => _appBox.erase();

  static Future<void> logout() async {
    await _appBox.remove("token");
    await _appBox.remove("id");
    await _appBox.remove("store_id");
  }

//========================================================
}
