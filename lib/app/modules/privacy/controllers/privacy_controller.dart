import 'package:crypted_app/app/data/data_source/privacy_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:get/get.dart';

class PrivacyController extends GetxController {
  var isReadReceiptsEnabled = false.obs;
  var isCameraEffectsEnabled = false.obs;

  // Observable variables for privacy settings using the comprehensive PrivacySettings model
  var privacySettings = PrivacySettings.defaultSettings().obs;

  final PrivacyDataSource _privacyDataSource = PrivacyDataSource();

  void toggleReadReceipts(bool value) {
    privacySettings.value = privacySettings.value.copyWith(readReceiptsEnabled: value);
    _updatePrivacyData();
  }

  void toggleCameraEffects(bool value) {
    privacySettings.value = privacySettings.value.copyWith(
      allowCamera: value,
    );
    _updatePrivacyData();
  }

  // Functions to update privacy settings based on the UI dropdowns
  void updateLastSeen(String value) {
    print('Updating lastSeen to: $value');
    final lastSeenValue = value == 'Nobody' ? false : value == 'My Contacts' ? true : null;
    privacySettings.value = privacySettings.value.copyWith(
      showLastSeenInOneToOne: lastSeenValue == true ? true : false,
      showLastSeenInGroups: lastSeenValue == true ? true : false,
    );
    _updatePrivacyData();
  }

  void updateProfilePicture(String value) {
    print('Updating profilePicture to: $value');
    final showToNonContacts = value == 'Everyone' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showProfilePhotoToNonContacts: showToNonContacts,
    );
    _updatePrivacyData();
  }

  void updateAbout(String value) {
    print('Updating about to: $value');
    final showToContactsOnly = value == 'My Contacts' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showStatusToContactsOnly: showToContactsOnly,
    );
    _updatePrivacyData();
  }

  void updateGroups(String value) {
    print('Updating groups to: $value');
    final allowInvites = value == 'Everyone' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      allowGroupInvitesFromAnyone: allowInvites,
    );
    _updatePrivacyData();
  }

  void updateStatus(String value) {
    print('Updating status to: $value');
    final showToContactsOnly = value == 'My Contacts' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showStatusToContactsOnly: showToContactsOnly,
    );
    _updatePrivacyData();
  }

  void updateLiveLocation(String value) {
    print('Updating liveLocation to: $value');
    // Live location settings can be mapped to allowOnlineStatus
    final allowLocation = value != 'None';
    privacySettings.value = privacySettings.value.copyWith(
      allowOnlineStatus: allowLocation,
    );
    _updatePrivacyData();
  }

  void updateBlocked(String value) {
    print('Updating blocked to: $value');
    // Blocked level affects allowMessagesFromNonContacts
    final allowMessages = value == 'Everyone';
    privacySettings.value = privacySettings.value.copyWith(
      allowMessagesFromNonContacts: allowMessages,
    );
    _updatePrivacyData();
  }

  void updateDefaultMessageTimer(String value) {
    print('Updating defaultMessageTimer to: $value');
    // Message timer affects forwarding settings
    final allowForwarding = value == 'Off';
    privacySettings.value = privacySettings.value.copyWith(
      allowForwardingMessages: allowForwarding,
    );
    _updatePrivacyData();
  }

  // Update privacy data and save to Firebase
  void _updatePrivacyData() {
    _savePrivacyData();
  }

  @override
  void onInit() {
    super.onInit();
    _loadPrivacyData();
  }

  /// Load privacy data from Firebase
  Future<void> _loadPrivacyData() async {
    try {
      final currentUser = UserService.currentUserValue;
      if (currentUser != null && currentUser.privacySettings != null) {
        privacySettings.value = currentUser.privacySettings!;
        _syncWithUI();
      }
    } catch (e) {
      print('❌ Error loading privacy data: $e');
    }
  }

  /// Sync privacy settings with UI variables for backward compatibility
  void _syncWithUI() {
    isReadReceiptsEnabled.value = privacySettings.value.readReceiptsEnabled ?? false;
    isCameraEffectsEnabled.value = privacySettings.value.allowCamera ?? false;
  }

  /// Save privacy data to Firebase
  Future<void> _savePrivacyData() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId != null) {
        // Update the current user with new privacy settings
        final updatedUser = UserService.currentUserValue?.copyWith(
          privacySettings: privacySettings.value,
        );

        if (updatedUser != null) {
          await UserService().updateUser(user: updatedUser);
          print('✅ Privacy settings saved successfully');
        }
      }
    } catch (e) {
      print('❌ Error saving privacy data: $e');
    }
  }

  // Getter methods for backward compatibility with the view
  String get lastSeenValue => privacySettings.value.showLastSeenInOneToOne == false
      ? 'Nobody'
      : privacySettings.value.showLastSeenInOneToOne == true
          ? 'My Contacts'
          : 'Everyone';

  String get profilePictureValue => privacySettings.value.showProfilePhotoToNonContacts == true
      ? 'Everyone'
      : 'Nobody';

  String get aboutValue => privacySettings.value.showStatusToContactsOnly == true
      ? 'My Contacts'
      : 'Everyone';

  String get groupsValue => privacySettings.value.allowGroupInvitesFromAnyone == true
      ? 'Everyone'
      : 'My Contacts';

  String get statusValue => privacySettings.value.showStatusToContactsOnly == true
      ? 'My Contacts'
      : 'Everyone';

  String get liveLocationValue => privacySettings.value.allowOnlineStatus == true
      ? 'My Contacts'
      : 'None';

  String get blockedValue => privacySettings.value.allowMessagesFromNonContacts == true
      ? 'Everyone'
      : 'My Contacts';

  String get defaultMessageTimerValue => privacySettings.value.allowForwardingMessages == true
      ? 'Off'
      : '24 Hours';

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
      final currentUser = UserService.currentUserValue;
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
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        return [];
      }

      // Query chats where current user is sharing live location
      // This would need to be implemented based on your chat system
      return await _privacyDataSource.getLiveLocationChats();
    } catch (e) {
      print('❌ Error getting live location chats: $e');
      return [];
    }
  }
}
