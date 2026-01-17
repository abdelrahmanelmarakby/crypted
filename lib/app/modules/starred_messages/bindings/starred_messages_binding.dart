import 'package:get/get.dart';
import 'package:crypted_app/app/modules/starred_messages/controllers/starred_messages_controller.dart';

/// Binding for StarredMessagesController
class StarredMessagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StarredMessagesController>(
      () => StarredMessagesController(),
    );
  }
}
