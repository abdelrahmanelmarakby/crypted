import 'package:crypted_app/app/data/models/privacy_model.dart';
import 'package:crypted_app/app/data/data_source/privacy_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
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

  final PrivacyDataSource _privacyDataSource = PrivacyDataSource();

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
    print('Updating lastSeen to: $value');
    lastSeenValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateProfilePicture(String value) {
    print('Updating profilePicture to: $value');
    profilePictureValue.value = ProfilePictureLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateAbout(String value) {
    print('Updating about to: $value');
    aboutValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateGroups(String value) {
    print('Updating groups to: $value');
    groupsValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateStatus(String value) {
    print('Updating status to: $value');
    statusValue.value = PrivacyLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateLiveLocation(String value) {
    print('Updating liveLocation to: $value');
    liveLocationValue.value = LiveLocationLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateBlocked(String value) {
    print('Updating blocked to: $value');
    blockedValue.value = BlockedLevel.fromString(value);
    _updatePrivacyData();
  }

  void updateDefaultMessageTimer(String value) {
    print('Updating defaultMessageTimer to: $value');
    defaultMessageTimerValue.value = MessageTimerLevel.fromString(value);
    _updatePrivacyData();
  }

  // Update privacy data model and save to Firebase
  void _updatePrivacyData() {
    final updatedPrivacy = privacyData.value.copyWith(
      lastSeen: lastSeenValue.value,
      profilePicture: profilePictureValue.value,
      about: aboutValue.value,
      groups: groupsValue.value,
      status: statusValue.value,
      liveLocation: liveLocationValue.value,
      blocked: blockedValue.value,
      defaultMessageTimer: defaultMessageTimerValue.value,
      receipts: isReadReceiptsEnabled.value,
      allowCamera: isCameraEffectsEnabled.value,
    );

    privacyData.value = updatedPrivacy;
    _savePrivacyData();
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
    _loadPrivacyData();
  }

  /// Load privacy data from Firebase
  Future<void> _loadPrivacyData() async {
    try {
      final privacy = await _privacyDataSource.getPrivacySettings();
      if (privacy != null) {
        _initializeFromModel(privacy);
        privacyData.value = privacy;
      }
    } catch (e) {
      print('❌ Error loading privacy data: $e');
    }
  }

  /// Save privacy data to Firebase
  Future<void> _savePrivacyData() async {
    try {
      await _privacyDataSource.savePrivacySettings(privacyData.value);
    } catch (e) {
      print('❌ Error saving privacy data: $e');
    }
  }

  /// Public method to refresh privacy data
  Future<void> refreshPrivacyData() async {
    await _loadPrivacyData();
  }

  /// Public method to save current privacy data
  Future<void> saveCurrentPrivacyData() async {
    await _savePrivacyData();
  }

  /// Get list of blocked users
  Future<List<SocialMediaUser>> getBlockedUsers() async {
    try {
      // Ensure current user data is fresh
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId != null) {
        await UserService().getProfile(currentUserId);
      }

      final currentUser = UserService.currentUser.value;
      print('🔍 Getting blocked users for current user: ${currentUser?.uid}');

      if (currentUser == null) {
        print('❌ Current user is null');
        return [];
      }

      if (currentUser.blockedUser == null) {
        print('❌ Current user blockedUser list is null');
        return [];
      }

      print('📋 Blocked users IDs: ${currentUser.blockedUser}');

      if (currentUser.blockedUser!.isEmpty) {
        print('ℹ️ No blocked users found');
        return [];
      }

      final blockedUsers = await UserService().getUsersFromBlockedUsersList(currentUser.blockedUser!);
      print('✅ Retrieved ${blockedUsers.length} blocked users');

      return blockedUsers;
    } catch (e) {
      print('❌ Error getting blocked users: $e');
      return [];
    }
  }

  /// Get list of chats where user is sharing live location
  Future<List<String>> getLiveLocationChats() async {
    try {
      return await _privacyDataSource.getLiveLocationChats();
    } catch (e) {
      print('❌ Error getting live location chats: $e');
      return [];
    }
  }
}
