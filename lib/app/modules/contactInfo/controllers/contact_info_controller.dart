import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

class ContactInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  // Contact data - can be either user or group
  final Rx<SocialMediaUser?> user = Rx<SocialMediaUser?>(null);

  // Group data (for when this is a group contact)
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<int?> groupMemberCount = Rx<int?>(null);
  final Rx<bool?> isGroup = Rx<bool?>(null);

  // Loading states
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadContactData();
  }

  void _loadContactData() {
    final arguments = Get.arguments;
    if (arguments != null) {
      // Check if this is a group or individual user
      if (arguments['isGroup'] == true) {
        // Group contact
        isGroup.value = true;
        groupName.value = arguments['chatName'] as String?;
        groupDescription.value = arguments['chatDescription'] as String?;
        groupMemberCount.value = arguments['memberCount'] as int?;
        print("✅ Loaded group contact data: ${groupName.value}");
      } else {
        // Individual user contact
        isGroup.value = false;
        user.value = arguments['user'] as SocialMediaUser?;
        print("✅ Loaded user contact data: ${user.value?.fullName}");
      }
    } else {
      print("❌ No contact data provided to contact info screen");
      isLoading.value = false;
    }
  }

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
  }

  /// Refresh contact data
  Future<void> refreshContactData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      // In a real implementation, this would fetch fresh data from the server
      // For now, we'll just reload from current data
      _loadContactData();
    } catch (e) {
      print("❌ Error refreshing contact data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Getters for easy access - User data
  String get userName => user.value?.fullName ?? "Unknown User";
  String get userEmail => user.value?.email ?? "No email";
  String? get userImage => user.value?.imageUrl;
  String get userBio => user.value?.bio ?? "No bio available";
  String get userPhone => user.value?.phoneNumber ?? "No phone number";

  // Getters for easy access - Group data
  String get groupDisplayName => groupName.value ?? "Group Chat";
  String get groupDisplayDescription => groupDescription.value ?? "No description";
  String get groupDisplayMemberCount => "${groupMemberCount.value ?? 0} ${groupMemberCount.value == 1 ? 'member' : 'members'}";

  // Check if this is a group contact
  bool get isGroupContact => isGroup.value == true;

  // Get the display name (user or group)
  String get displayName => isGroupContact ? groupDisplayName : userName;

  // Get the subtitle (for user status or group member count)
  String get displaySubtitle => isGroupContact ? groupDisplayMemberCount : userBio;

  // Get the image (user or group)
  String? get displayImage => isGroupContact ? null : userImage; // Groups use different image handling
}
