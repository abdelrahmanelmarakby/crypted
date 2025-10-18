import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

class GroupInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  // Group data
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<String?> groupImageUrl = Rx<String?>(null);
  final Rx<int?> memberCount = Rx<int?>(null);
  final Rx<List<SocialMediaUser>?> members = Rx<List<SocialMediaUser>?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadGroupData();
  }

  void _loadGroupData() {
    final arguments = Get.arguments;
    if (arguments != null) {
      groupName.value = arguments['chatName'] as String?;
      groupDescription.value = arguments['chatDescription'] as String?;
      memberCount.value = arguments['memberCount'] as int?;
      members.value = arguments['members'] as List<SocialMediaUser>?;
      groupImageUrl.value = arguments['groupImageUrl'] as String?;

      print("✅ Loaded group data: ${groupName.value}");
    } else {
      print("❌ No group data provided to group info screen");
    }
  }

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
  }

  // Getters for easy access
  String get displayName => groupName.value ?? "Group Chat";
  String get displayDescription => groupDescription.value ?? "No description";
  String get displayMemberCount => "${memberCount.value ?? 0} members";
  String? get displayImage => groupImageUrl.value;
}
