import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class SettingsController extends GetxController {
  var switches = false.obs;

  @override
  void onInit() {
    super.onInit();

    // مراقبة التغييرات في UserService.currentUser
    ever(UserService.currentUser, (user) {
      if (user != null) {
        print("🔄 SettingsController: User updated to: ${user.fullName}");
      }
    });
  }

  void toggleSwitch(bool value) {
    switches.value = value;
  }
}
