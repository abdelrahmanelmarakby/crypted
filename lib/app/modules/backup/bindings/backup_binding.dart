import 'package:get/get.dart';
import '../controllers/backup_controller.dart';

/// BackupBinding with permanent controller
///
/// The controller is marked as PERMANENT because:
/// - Backups need to survive user navigation
/// - Progress tracking must continue even if user leaves the backup page
/// - Stream subscriptions should remain active for real-time updates
class BackupBinding extends Bindings {
  @override
  void dependencies() {
    // Use permanent: true to ensure controller survives navigation
    // The backup will continue running even if user leaves the page
    if (!Get.isRegistered<BackupController>()) {
      Get.put<BackupController>(
        BackupController(),
        permanent: true, // CRITICAL: Survives navigation
      );
    }
  }
}
