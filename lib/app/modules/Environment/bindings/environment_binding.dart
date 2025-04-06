import 'package:get/get.dart';

import '../controllers/environment_controller.dart';

class EnvironmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EnvironmentController>(
      () => EnvironmentController(),
    );
  }
}
