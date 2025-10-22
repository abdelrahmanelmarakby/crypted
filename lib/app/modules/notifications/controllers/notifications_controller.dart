import 'package:crypted_app/app/data/models/notification_model.dart';
import 'package:crypted_app/app/data/data_source/notification_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  // Observable notification model
  Rx<NotificationModel> notificationData = NotificationModel(
    showMessageNotification: true,
    soundMessage: 'Note',
    reactionMessageNotification: true,
    showGroupNotification: true,
    soundGroup: 'Note',
    reactionGroupNotification: true,
    soundStatus: 'Note',
    reactionStatusNotification: true,
    reminderNotification: true,
    showPreviewNotification: true,
  ).obs;

  final NotificationDataSource _notificationDataSource = NotificationDataSource();

  // Getters for reactive UI - return RxBool that react to notificationData changes
  RxBool get isShowNotificationEnabled =>
      RxBool(notificationData.value.showMessageNotification);
  RxBool get isReactionNotificationEnabled =>
      RxBool(notificationData.value.reactionMessageNotification);
  RxBool get isShowGroupNotificationEnabled =>
      RxBool(notificationData.value.showGroupNotification);
  RxBool get isReactionGroupNotificationEnabled =>
      RxBool(notificationData.value.reactionGroupNotification);
  RxBool get isReactionStatusNotificationEnabled =>
      RxBool(notificationData.value.reactionStatusNotification);
  RxBool get isRemindersNotificationEnabled =>
      RxBool(notificationData.value.reminderNotification);
  RxBool get isShowPreviewEnabled =>
      RxBool(notificationData.value.showPreviewNotification);

  // String getters for sound settings
  String get soundMessage => notificationData.value.soundMessage;
  String get soundGroup => notificationData.value.soundGroup;
  String get soundStatus => notificationData.value.soundStatus;

  // Functions to update notification values
  void toggleShowNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      showMessageNotification: value,
    );
    _saveNotificationData();
  }

  void toggleReactionNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      reactionMessageNotification: value,
    );
    _saveNotificationData();
  }

  void toggleShowGroupNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      showGroupNotification: value,
    );
    _saveNotificationData();
  }

  void toggleReactionGroupNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      reactionGroupNotification: value,
    );
    _saveNotificationData();
  }

  void toggleReactionStatusNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      reactionStatusNotification: value,
    );
    _saveNotificationData();
  }

  void toggleRemindersNotification(bool value) {
    notificationData.value = notificationData.value.copyWith(
      reminderNotification: value,
    );
    _saveNotificationData();
  }

  void toggleShowPreview(bool value) {
    notificationData.value = notificationData.value.copyWith(
      showPreviewNotification: value,
    );
    _saveNotificationData();
  }

  // Update sound settings
  void updateSoundMessage(String sound) {
    notificationData.value = notificationData.value.copyWith(
      soundMessage: sound,
    );
    _saveNotificationData();
  }

  void updateSoundGroup(String sound) {
    notificationData.value = notificationData.value.copyWith(
      soundGroup: sound,
    );
    _saveNotificationData();
  }

  void updateSoundStatus(String sound) {
    notificationData.value = notificationData.value.copyWith(
      soundStatus: sound,
    );
    _saveNotificationData();
  }

  // Initialize notification data
  void _initializeFromModel(NotificationModel model) {
    notificationData.value = model;
  }

  // Save notification data to Firebase
  Future<void> _saveNotificationData() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId != null) {
        // Update the current user with new notification settings
        final updatedUser = UserService.currentUserValue?.copyWith(
          notificationSettings: notificationData.value,
        );

        if (updatedUser != null) {
          await UserService().updateUser(user: updatedUser);
          print('✅ Notification settings saved successfully');
        }
      }
    } catch (e) {
      print('❌ Error saving notification data: $e');
    }
  }

  // Load notification data from Firebase
  Future<void> loadNotificationData() async {
    try {
      final currentUser = UserService.currentUserValue;
      if (currentUser != null && currentUser.notificationSettings != null) {
        notificationData.value = currentUser.notificationSettings!;
        print('✅ Notification settings loaded successfully');
      } else {
        // Use default settings if none exist
        notificationData.value = NotificationModel(
          showMessageNotification: true,
          soundMessage: 'Note',
          reactionMessageNotification: true,
          showGroupNotification: true,
          soundGroup: 'Note',
          reactionGroupNotification: true,
          soundStatus: 'Note',
          reactionStatusNotification: true,
          reminderNotification: true,
          showPreviewNotification: true,
        );
        print('ℹ️ Using default notification settings');
      }
    } catch (e) {
      print('❌ Error loading notification data: $e');
    }
  }

  // Reset all notification settings
  void resetNotificationSettings() {
    notificationData.value = NotificationModel(
      showMessageNotification: true,
      soundMessage: 'Note',
      reactionMessageNotification: true,
      showGroupNotification: true,
      soundGroup: 'Note',
      reactionGroupNotification: true,
      soundStatus: 'Note',
      reactionStatusNotification: true,
      reminderNotification: true,
      showPreviewNotification: true,
    );
    _saveNotificationData();
  }

  @override
  void onInit() {
    super.onInit();
    loadNotificationData();
  }
}
