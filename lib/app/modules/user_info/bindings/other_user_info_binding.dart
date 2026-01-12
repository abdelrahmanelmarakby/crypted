import 'package:get/get.dart';
import 'package:crypted_app/app/modules/user_info/controllers/other_user_info_controller.dart';

class OtherUserInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtherUserInfoController>(() => OtherUserInfoController());
  }
}
