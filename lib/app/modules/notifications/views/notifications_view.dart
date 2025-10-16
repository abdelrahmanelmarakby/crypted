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
                onTap: () {
                  // Show confirmation dialog
                  Get.dialog(
                    AlertDialog(
                      title: Text('Reset Notifications'),
                      content: Text(
                          'Are you sure you want to reset all notification settings?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.resetNotificationSettings();
                            Get.back();
                            Get.snackbar(
                              'Success',
                              'Notification settings have been reset',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          child: Text('Reset'),
                        ),
                      ],
                    ),
                  );
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
