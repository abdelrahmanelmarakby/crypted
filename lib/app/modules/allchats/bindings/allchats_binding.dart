import 'package:get/get.dart';

import '../controllers/allchats_controller.dart';

class AllchatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllchatsController>(
      () => AllchatsController(),
    );
  }
}
