import 'package:crypted_app/app/data/models/privacy_model.dart';
import 'package:get/get.dart';

class PrivacyController extends GetxController {
  var isReadReceiptsEnabled = false.obs;
  var isCameraEffectsEnabled = false.obs;

  // Observable variables for dropdown items using enums
  var lastSeenValue = PrivacyLevel.nobody.obs;
  var profilePictureValue = ProfilePictureLevel.everyone.obs;
  var aboutValue = PrivacyLevel.everyone.obs;
  var groupsValue = PrivacyLevel.everyone.obs;
  var statusValue = PrivacyLevel.myContacts.obs;
  var liveLocationValue = LiveLocationLevel.none.obs;
  var blockedValue = BlockedLevel.contacts.obs;
  var defaultMessageTimerValue = MessageTimerLevel.off.obs;

  void toggleReadReceipts(bool value) {
    isReadReceiptsEnabled.value = value;
    _updatePrivacyData();
  }

  void toggleCameraEffects(bool value) {
    isCameraEffectsEnabled.value = value;
    _updatePrivacyData();
  }

  // Functions to update dropdown values
  void updateLastSeen(String value) {
    print('Updating lastSeen to: $value'); // للتأكد من أن الدالة تعمل
    lastSeenValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateProfilePicture(String value) {
    print('Updating profilePicture to: $value'); // للتأكد من أن الدالة تعمل
    profilePictureValue.value = ProfilePictureLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateAbout(String value) {
    print('Updating about to: $value'); // للتأكد من أن الدالة تعمل
    aboutValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateGroups(String value) {
    print('Updating groups to: $value'); // للتأكد من أن الدالة تعمل
    groupsValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateStatus(String value) {
    print('Updating status to: $value'); // للتأكد من أن الدالة تعمل
    statusValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateLiveLocation(String value) {
    print('Updating liveLocation to: $value'); // للتأكد من أن الدالة تعمل
    liveLocationValue.value = LiveLocationLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateBlocked(String value) {
    print('Updating blocked to: $value'); // للتأكد من أن الدالة تعمل
    blockedValue.value = BlockedLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateDefaultMessageTimer(String value) {
    print(
        'Updating defaultMessageTimer to: $value'); // للتأكد من أن الدالة تعمل
    defaultMessageTimerValue.value = MessageTimerLevel.fromString(value);
    _updatePrivacyData();
  }

  // Update privacy data model
  void _updatePrivacyData() {
    privacyData.value = privacyData.value.copyWith(
      lastSeen: lastSeenValue.value,
      profilePicture: profilePictureValue.value,
      about: aboutValue.value,
      groups: groupsValue.value,
      status: statusValue.value,
      liveLocation: liveLocationValue.value,
      blocked: blockedValue.value,
      defaultMessageTimer: defaultMessageTimerValue.value,
    );
  }

  // Initialize privacy data from model
  void _initializeFromModel(Privacy privacy) {
    lastSeenValue.value = privacy.lastSeen;
    profilePictureValue.value = privacy.profilePicture;
    aboutValue.value = privacy.about;
    groupsValue.value = privacy.groups;
    statusValue.value = privacy.status;
    liveLocationValue.value = privacy.liveLocation;
    blockedValue.value = privacy.blocked;
    defaultMessageTimerValue.value = privacy.defaultMessageTimer;
    isReadReceiptsEnabled.value = privacy.receipts;
    isCameraEffectsEnabled.value = privacy.allowCamera;
  }

  Rx<Privacy> privacyData = Privacy(
    lastSeen: PrivacyLevel.nobody,
    profilePicture: ProfilePictureLevel.everyone,
    about: PrivacyLevel.everyone,
    groups: PrivacyLevel.everyone,
    status: PrivacyLevel.myContacts,
    liveLocation: LiveLocationLevel.none,
    calls: '',
    blocked: BlockedLevel.contacts,
    timer: false,
    receipts: true,
    appLock: '',
    chatLock: '',
    allowCamera: true,
    advanced: '',
    checkup: '',
    defaultMessageTimer: MessageTimerLevel.off,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFromModel(privacyData.value);
  }

  Future<void> fetchPrivacyData() async {
    // هنا تحط كود API أو Firebase
    // privacyData.value = Privacy.fromMap(apiResponse);
    // _initializeFromModel(privacyData.value);
  }

  Future<void> savePrivacyData() async {
    // هنا تحط كود لحفظ البيانات في API أو Firebase
    // await apiService.updatePrivacy(privacyData.value.toMap());
  }
}
