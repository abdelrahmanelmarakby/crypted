import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:get/get.dart';

class ContactInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  // User data
  final Rx<SocialMediaUser?> user = Rx<SocialMediaUser?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final arguments = Get.arguments;
    if (arguments != null && arguments['user'] != null) {
      user.value = arguments['user'] as SocialMediaUser?;
      print("✅ Loaded user data: ${user.value?.fullName}");
    } else {
      print("❌ No user data provided to contact info screen");
    }
  }

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
  }

  // Getters for easy access
  String get userName => user.value?.fullName ?? "Unknown User";
  String get userEmail => user.value?.email ?? "No email";
  String? get userImage => user.value?.imageUrl;
  String get userBio => user.value?.bio ?? "No bio available";
  String get userPhone => user.value?.phoneNumber ?? "No phone number";
}
