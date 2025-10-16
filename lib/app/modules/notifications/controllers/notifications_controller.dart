import 'package:crypted_app/app/data/models/notification_model.dart';
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

  // Save notification data
  void _saveNotificationData() {
    // هنا تحط كود لحفظ البيانات في API أو Firebase
    print('Saving notification data: ${notificationData.value.toMap()}');
    // await apiService.updateNotification(notificationData.value.toMap());
  }

  // Load notification data
  Future<void> loadNotificationData() async {
    // هنا تحط كود لتحميل البيانات من API أو Firebase
    // final data = await apiService.getNotification();
    // if (data != null) {
    //   _initializeFromModel(NotificationModel.fromMap(data));
    // }
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
