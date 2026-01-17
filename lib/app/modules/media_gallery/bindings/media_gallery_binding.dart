import 'package:get/get.dart';
import 'package:crypted_app/app/modules/media_gallery/controllers/media_gallery_controller.dart';

/// Binding for MediaGalleryController
class MediaGalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MediaGalleryController>(
      () => MediaGalleryController(),
    );
  }
}
