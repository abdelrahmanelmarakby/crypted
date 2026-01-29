import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:crypted_app/app/core/services/analytics_service.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Register UploadStateManager as a persistent service
    Get.put<UploadStateManager>(
      UploadStateManager(),
      permanent: true,
    );

    // Register AnalyticsService for app-wide analytics tracking
    Get.put<AnalyticsService>(
      AnalyticsService(),
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
