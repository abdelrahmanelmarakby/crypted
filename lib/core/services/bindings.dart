import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Register UploadStateManager as a persistent service
    Get.put<UploadStateManager>(
      UploadStateManager(),
      permanent: true,
    );
    Get.put<HomeController>(
      HomeController(),
    );
    Get.put<CallsController>(
      CallsController(),
    );
  }
}
