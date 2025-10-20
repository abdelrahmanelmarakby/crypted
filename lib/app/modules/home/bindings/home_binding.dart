import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/modules/home/controllers/message_search_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MessageSearchController>(() => MessageSearchController());
  }
}
