import 'package:get/get.dart';

import '../controllers/callfriend_controller.dart';

class CallfriendBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CallfriendController>(
      () => CallfriendController(),
    );
  }
}
