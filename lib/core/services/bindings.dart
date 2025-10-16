import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(
      HomeController(),
    );
    Get.put<CallsController>(
      CallsController(),
    );
  }
}
