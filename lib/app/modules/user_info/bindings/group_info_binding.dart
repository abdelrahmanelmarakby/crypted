import 'package:get/get.dart';
import 'package:crypted_app/app/modules/user_info/controllers/enhanced_group_info_controller.dart';
import 'package:crypted_app/app/modules/user_info/repositories/group_info_repository.dart';

/// Binding for EnhancedGroupInfoController
class GroupInfoBinding extends Bindings {
  @override
  void dependencies() {
    // Register repository
    Get.lazyPut<GroupInfoRepository>(
      () => FirestoreGroupInfoRepository(),
    );

    // Register controller with repository injection
    Get.lazyPut<EnhancedGroupInfoController>(
      () => EnhancedGroupInfoController(
        repository: Get.find<GroupInfoRepository>(),
      ),
    );
  }
}
