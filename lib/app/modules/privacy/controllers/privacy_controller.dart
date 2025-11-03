import 'dart:developer' as developer;
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
    developer.log(
      'Updating lastSeen to: $value',
      name: 'PrivacyController',
    );
    final lastSeenValue = value == 'Nobody' ? false : value == 'My Contacts' ? true : null;
    privacySettings.value = privacySettings.value.copyWith(
      showLastSeenInOneToOne: lastSeenValue == true ? true : false,
      showLastSeenInGroups: lastSeenValue == true ? true : false,
    );
    _updatePrivacyData();
  }

  void updateProfilePicture(String value) {
    developer.log(
      'Updating profilePicture to: $value',
      name: 'PrivacyController',
    );
    final showToNonContacts = value == 'Everyone' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showProfilePhotoToNonContacts: showToNonContacts,
    );
    _updatePrivacyData();
  }

  void updateAbout(String value) {
    developer.log(
      'Updating about to: $value',
      name: 'PrivacyController',
    );
    final showToContactsOnly = value == 'My Contacts' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showStatusToContactsOnly: showToContactsOnly,
    );
    _updatePrivacyData();
  }

  void updateGroups(String value) {
    developer.log(
      'Updating groups to: $value',
      name: 'PrivacyController',
    );
    final allowInvites = value == 'Everyone' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      allowGroupInvitesFromAnyone: allowInvites,
    );
    _updatePrivacyData();
  }

  void updateStatus(String value) {
    developer.log(
      'Updating status to: $value',
      name: 'PrivacyController',
    );
    final showToContactsOnly = value == 'My Contacts' ? true : false;
    privacySettings.value = privacySettings.value.copyWith(
      showStatusToContactsOnly: showToContactsOnly,
    );
    _updatePrivacyData();
  }

  void updateLiveLocation(String value) {
    developer.log(
      'Updating liveLocation to: $value',
      name: 'PrivacyController',
    );
    // Live location settings can be mapped to allowOnlineStatus
    final allowLocation = value != 'None';
    privacySettings.value = privacySettings.value.copyWith(
      allowOnlineStatus: allowLocation,
    );
    _updatePrivacyData();
  }

  void updateBlocked(String value) {
    developer.log(
      'Updating blocked to: $value',
      name: 'PrivacyController',
    );
    // Blocked level affects allowMessagesFromNonContacts
    final allowMessages = value == 'Everyone';
    privacySettings.value = privacySettings.value.copyWith(
      allowMessagesFromNonContacts: allowMessages,
    );
    _updatePrivacyData();
  }

  void updateDefaultMessageTimer(String value) {
    developer.log(
      'Updating defaultMessageTimer to: $value',
      name: 'PrivacyController',
    );
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
        developer.log(
          'Privacy settings loaded successfully',
          name: 'PrivacyController',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading privacy data',
        name: 'PrivacyController',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
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
          developer.log(
            'Privacy settings saved successfully for user: $currentUserId',
            name: 'PrivacyController',
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error saving privacy data',
        name: 'PrivacyController',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
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
      developer.log(
        'Getting blocked users for current user: ${currentUser?.uid}',
        name: 'PrivacyController',
      );

      if (currentUser == null) {
        developer.log(
          'Current user is null',
          name: 'PrivacyController',
          level: 900,
        );
        return [];
      }

      if (currentUser.blockedUser == null) {
        developer.log(
          'Current user blockedUser list is null',
          name: 'PrivacyController',
          level: 900,
        );
        return [];
      }

      developer.log(
        'Blocked users IDs: ${currentUser.blockedUser}',
        name: 'PrivacyController',
      );

      if (currentUser.blockedUser!.isEmpty) {
        developer.log(
          'No blocked users found',
          name: 'PrivacyController',
        );
        return [];
      }

      final blockedUsers = await UserService().getUsersFromBlockedUsersList(currentUser.blockedUser!);
      developer.log(
        'Retrieved ${blockedUsers.length} blocked users',
        name: 'PrivacyController',
      );

      return blockedUsers;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting blocked users',
        name: 'PrivacyController',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Get list of chats where user is sharing live location
  Future<List<String>> getLiveLocationChats() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        developer.log(
          'No current user found for live location chats',
          name: 'PrivacyController',
          level: 900,
        );
        return [];
      }

      // Query chats where current user is sharing live location
      // This would need to be implemented based on your chat system
      final chats = await _privacyDataSource.getLiveLocationChats();
      developer.log(
        'Retrieved ${chats.length} live location chats',
        name: 'PrivacyController',
      );
      return chats;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting live location chats',
        name: 'PrivacyController',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }
}
