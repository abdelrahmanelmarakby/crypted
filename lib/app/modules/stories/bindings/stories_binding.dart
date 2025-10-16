import 'package:get/get.dart';

import '../controllers/stories_controller.dart';

class StoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoriesController>(
      () => StoriesController(),
    );
  }
}
