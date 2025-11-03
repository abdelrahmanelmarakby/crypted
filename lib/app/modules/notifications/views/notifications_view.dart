import 'package:crypted_app/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:crypted_app/app/modules/notifications/widgets/notification_cover.dart';
import 'package:crypted_app/app/modules/notifications/widgets/notification_item.dart';
import 'package:crypted_app/app/modules/notifications/widgets/reactive_switch_item.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        centerTitle: false,
        title: Text(
          Constants.kNotifications.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Paddings.large),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Constants.kMessagenotification.tr,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: Sizes.size4),
              NotificationCover([
                Obx(() => ReactiveSwitchItem(
                      title: Constants.kLastSeenOnline.tr,
                      switchValue: controller.isShowNotificationEnabled,
                      onChanged: controller.toggleShowNotification,
                    )),
                Divider(
                  color: ColorsManager.lightGrey,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 15,
                ),
                Obx(() => NotificationItem(
                    title: Constants.kSound.tr, type: controller.soundMessage)),
                Divider(
                  color: ColorsManager.lightGrey,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 15,
                ),
                Obx(() => ReactiveSwitchItem(
                      title: Constants.kReactionNotification.tr,
                      switchValue: controller.isReactionNotificationEnabled,
                      onChanged: controller.toggleReactionNotification,
                    )),
              ]),
              SizedBox(height: Sizes.size16),
              Text(
                Constants.kGroupnotification.tr,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: Sizes.size4),
              NotificationCover([
                Obx(() => ReactiveSwitchItem(
                      title: Constants.kLastSeenOnline.tr,
                      switchValue: controller.isShowGroupNotificationEnabled,
                      onChanged: controller.toggleShowGroupNotification,
                    )),
                Divider(
                  color: ColorsManager.lightGrey,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 15,
                ),
                Obx(() => NotificationItem(
                    title: Constants.kSound.tr, type: controller.soundGroup)),
                Divider(
                  color: ColorsManager.lightGrey,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 15,
                ),
                Obx(() => ReactiveSwitchItem(
                      title: Constants.kReactionNotification.tr,
                      switchValue:
                          controller.isReactionGroupNotificationEnabled,
                      onChanged: controller.toggleReactionGroupNotification,
                    )),
              ]),
              SizedBox(height: Sizes.size16),
              Text(
                Constants.kStatusnotification.tr,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: Sizes.size4),
              NotificationCover([
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Obx(() => NotificationItem(
                      title: Constants.kSound.tr,
                      type: controller.soundStatus)),
                ),
                Divider(
                  color: ColorsManager.lightGrey,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 15,
                ),
                Obx(() => ReactiveSwitchItem(
                      title: Constants.kReactionNotification.tr,
                      switchValue:
                          controller.isReactionStatusNotificationEnabled,
                      onChanged: controller.toggleReactionStatusNotification,
                    )),
              ]),
              SizedBox(height: Sizes.size16),
              Obx(() => ReactiveSwitchItem(
                    title: Constants.kReminders.tr,
                    switchValue: controller.isRemindersNotificationEnabled,
                    onChanged: controller.toggleRemindersNotification,
                  )),
              Padding(
                padding: EdgeInsets.only(top: Paddings.xXSmall),
                child: Text(
                  Constants
                      .kGetoccasionalremindersaboutmessageorstatusupdatesyouhaventseen
                      .tr,
                  style: StylesManager.medium(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
              SizedBox(height: Sizes.size16),
              Text(
                Constants.khomescreennotification.tr,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: Sizes.size4),
              Obx(() => ReactiveSwitchItem(
                    title: Constants.kShowPreview.tr,
                    switchValue: controller.isShowPreviewEnabled,
                    onChanged: controller.toggleShowPreview,
                  )),
              SizedBox(height: Sizes.size16),
              GestureDetector(
                onTap: () async {
                  // Show confirmation bottom sheet
                  final confirmed = await Get.bottomSheet<bool>(
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(Radiuss.xLarge),
                        ),
                      ),
                      padding: const EdgeInsets.all(Paddings.xLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: Sizes.size24),

                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restart_alt,
                              size: 48,
                              color: Colors.orange,
                            ),
                          ),

                          SizedBox(height: Sizes.size20),

                          // Title
                          Text(
                            'Reset Notifications',
                            style: StylesManager.bold(
                              fontSize: FontSize.xLarge,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Sizes.size12),

                          // Message
                          Text(
                            'Are you sure you want to reset all notification settings to default? This action cannot be undone.',
                            style: StylesManager.regular(
                              fontSize: FontSize.medium,
                              color: ColorsManager.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Sizes.size32),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Get.back(result: false),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    Constants.kCancel.tr,
                                    style: StylesManager.semiBold(
                                      fontSize: FontSize.medium,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: Sizes.size12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Get.back(result: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Reset',
                                    style: StylesManager.semiBold(
                                      fontSize: FontSize.medium,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.size16),
                        ],
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    isDismissible: true,
                    enableDrag: true,
                  );

                  if (confirmed == true) {
                    controller.resetNotificationSettings();
                    Get.snackbar(
                      'Success',
                      'Notification settings have been reset',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: ColorsManager.primary,
                      colorText: Colors.white,
                    );
                  }
                },
                child: Container(
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    color: ColorsManager.backgroundIconSetting,
                    borderRadius: BorderRadius.circular(Radiuss.xSmall),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Paddings.normal),
                    child: Text(
                      Constants.kresetnotificationsetting.tr,
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Sizes.size16),
              Padding(
                padding: EdgeInsets.only(top: Paddings.xXSmall),
                child: Text(
                  Constants
                      .kResetallnotificationsettingsincludingcustomnotificationsettingsforyourchats
                      .tr,
                  style: StylesManager.medium(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
