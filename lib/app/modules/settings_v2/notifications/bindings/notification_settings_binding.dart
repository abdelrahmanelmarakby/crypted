import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/notification_settings_service.dart';
import '../controllers/notification_settings_controller.dart';

/// Binding for Notification Settings module
class NotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Register the service if not already registered
    if (!Get.isRegistered<NotificationSettingsService>()) {
      Get.put<NotificationSettingsService>(
        NotificationSettingsService(),
        permanent: true,
      );
    }

    // Register the controller
    Get.lazyPut<NotificationSettingsController>(
      () => NotificationSettingsController(),
    );
  }
}
