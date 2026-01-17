import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';
import '../controllers/privacy_settings_controller.dart';

/// Binding for Privacy Settings module
class PrivacySettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Register the service if not already registered
    if (!Get.isRegistered<PrivacySettingsService>()) {
      Get.put<PrivacySettingsService>(
        PrivacySettingsService(),
        permanent: true,
      );
    }

    // Register the controller
    Get.lazyPut<PrivacySettingsController>(
      () => PrivacySettingsController(),
    );
  }
}
