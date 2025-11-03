import 'package:crypted_app/app/data/models/privacy_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/notifications/widgets/reactive_switch_item.dart';
import 'package:crypted_app/app/modules/privacy/widgets/privacy_cover.dart';
import 'package:crypted_app/app/modules/privacy/widgets/privacy_item.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kPrivacy.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Paddings.large),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrivacyCover([
                // Last Seen - يستخدم القائمة الافتراضية
                Obx(() => PrivacyItem(
                      title: Constants.kLastSeenOnline.tr,
                      type: controller.lastSeenValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected lastSeen: $value');
                        controller.updateLastSeen(value);
                      },
                    )),
                Divider(color: ColorsManager.lightGrey, thickness: 0.5),
                // Profile Picture - يستخدم قائمة مخصصة
                Obx(() => PrivacyItem(
                      title: Constants.kProfilePicture.tr,
                      type: controller.profilePictureValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected profilePicture: $value');
                        controller.updateProfilePicture(value);
                      },
                      dropdownItems: ProfilePictureLevel.values
                          .map((level) => DropdownItem(
                                value: level.value,
                                label: level.value,
                              ))
                          .toList(),
                    )),
                Divider(color: ColorsManager.lightGrey, thickness: 0.5),
                // About - يستخدم قائمة مخصصة
                Obx(() => PrivacyItem(
                      title: Constants.kAbout.tr,
                      type: controller.aboutValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected about: $value');
                        controller.updateAbout(value);
                      },
                      dropdownItems: PrivacyLevel.values
                          .map((level) => DropdownItem(
                                value: level.value,
                                label: level.value,
                              ))
                          .toList(),
                    )),
                Divider(color: ColorsManager.lightGrey, thickness: 0.5),
                // Groups - يستخدم القائمة الافتراضية
                Obx(() => PrivacyItem(
                      title: Constants.kGroups.tr,
                      type: controller.groupsValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected groups: $value');
                        controller.updateGroups(value);
                      },
                    )),
                Divider(color: ColorsManager.lightGrey, thickness: 0.5),
                // Status - يستخدم القائمة الافتراضية
                Obx(() => PrivacyItem(
                      title: Constants.kStatus.tr,
                      type: controller.statusValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected status: $value');
                        controller.updateStatus(value);
                      },
                    )),
              ]),
              SizedBox(height: Sizes.size16),
              PrivacyCover([
                // Blocked - يستخدم قائمة مخصصة
                GestureDetector(
                  onTap: () => _showBlockedUsers(),
                  child: Obx(() => PrivacyItem(
                        title: Constants.kBlocked.tr,
                        type: controller.blockedValue,
                        showDropdown: true,
                        onTypeChanged: (value) {
                          print('Selected blocked: $value');
                          controller.updateBlocked(value);
                        },
                        dropdownItems: BlockedLevel.values
                            .map((level) => DropdownItem(
                                  value: level.value,
                                  label: level.value,
                                ))
                            .toList(),
                      )),
                ),
              ]),
              _buildSmallText(Constants.kListofcontactsyouhaveblocked.tr),
              SizedBox(height: Sizes.size16),
              PrivacyCover([
                // Live Location - يستخدم قائمة مخصصة
                GestureDetector(
                  onTap: () => _showLiveLocationChats(),
                  child: Obx(() => PrivacyItem(
                        title: Constants.kLiveLocation.tr,
                        type: controller.liveLocationValue,
                        showDropdown: true,
                        onTypeChanged: (value) {
                          print('Selected liveLocation: $value');
                          controller.updateLiveLocation(value);
                        },
                        dropdownItems: LiveLocationLevel.values
                            .map((level) => DropdownItem(
                                  value: level.value,
                                  label: level.value,
                                ))
                            .toList(),
                      )),
                ),
              ]),
              _buildSmallText(
                Constants.kListofchatswhereyouaresharingyourlivelocation.tr,
              ),
              SizedBox(height: Sizes.size16),
              Padding(
                padding: EdgeInsets.only(bottom: Paddings.xXSmall),
                child: Text(
                  Constants.kDisappearingMessages.tr,
                  style: StylesManager.medium(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
              PrivacyCover([
                // Default Message Timer - يستخدم قائمة مخصصة
                Obx(() => PrivacyItem(
                      title: Constants.kDefaultMessageTimer.tr,
                      type: controller.defaultMessageTimerValue,
                      showDropdown: true,
                      onTypeChanged: (value) {
                        print('Selected defaultMessageTimer: $value');
                        controller.updateDefaultMessageTimer(value);
                      },
                      dropdownItems: MessageTimerLevel.values
                          .map((level) => DropdownItem(
                                value: level.value,
                                label: level.value,
                              ))
                          .toList(),
                    )),
              ]),
              _buildSmallText(
                Constants
                    .kStartnewchatwithdisappearingmessagessettoyourtimer.tr,
              ),
              SizedBox(height: Sizes.size16),
              PrivacyCover([PrivacyItem(title: Constants.kCalls.tr)]),
              SizedBox(height: Sizes.size16),
              ReactiveSwitchItem(
                title: Constants.kReadReceipts.tr,
                switchValue: controller.isReadReceiptsEnabled,
                onChanged: controller.toggleReadReceipts,
              ),
              _buildSmallText(Constants
                  .kIfyouturnoffreadreceiptsyouwontbeabletoseereadreceiptsfromotherpeople
                  .tr),
              SizedBox(height: Sizes.size16),
              PrivacyCover([PrivacyItem(title: Constants.kAppLock.tr)]),
              _buildSmallText(Constants.kRequireFaceIDtounlockCrypted.tr),
              SizedBox(height: Sizes.size16),
              PrivacyCover([PrivacyItem(title: Constants.kChatLock.tr)]),
              SizedBox(height: Sizes.size16),
              ReactiveSwitchItem(
                title: Constants.kAllowCameraEffects.tr,
                switchValue: controller.isCameraEffectsEnabled,
                onChanged: controller.toggleCameraEffects,
              ),
              SizedBox(height: Sizes.size4),
              Row(
                children: [
                  Text(
                    Constants.kUseeffectsinthecameraandvideocalls.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                  Text(
                    Constants.kLearnmore.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Sizes.size16),
              PrivacyCover([PrivacyItem(title: Constants.kAdvanced.tr)]),
              SizedBox(height: Sizes.size16),
              PrivacyCover([PrivacyItem(title: Constants.kPrivacyCheckup.tr)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallText(String text) {
    return Padding(
      padding: EdgeInsets.only(top: Paddings.xXSmall),
      child: Text(
        text,
        style: StylesManager.medium(
          fontSize: FontSize.xSmall,
          color: ColorsManager.grey,
        ),
      ),
    );
  }

  /// Show blocked users bottom sheet
  void _showBlockedUsers() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: Sizes.size12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Blocked Users",
                              style: StylesManager.bold(fontSize: FontSize.large),
                            ),
                            Text(
                              "Users you have blocked",
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Content
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
                ),
                child: FutureBuilder<List<SocialMediaUser>>(
                  future: controller.getBlockedUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 200,
                        child: const Center(child: CircularProgressIndicator.adaptive()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                size: 48,
                                color: ColorsManager.error),
                              SizedBox(height: Sizes.size12),
                              Text(
                                'Error loading blocked users',
                                style: StylesManager.regular(color: ColorsManager.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final blockedUsers = snapshot.data ?? [];

                    if (blockedUsers.isEmpty) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: ColorsManager.grey,
                              ),
                              SizedBox(height: Sizes.size12),
                              Text(
                                'No blocked users',
                                style: StylesManager.medium(
                                  fontSize: FontSize.medium,
                                  color: ColorsManager.grey,
                                ),
                              ),
                              SizedBox(height: Sizes.size4),
                              Text(
                                'You haven\'t blocked anyone',
                                style: StylesManager.regular(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: Paddings.small),
                      shrinkWrap: true,
                      itemCount: blockedUsers.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final user = blockedUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Paddings.large,
                            vertical: Paddings.small,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: ColorsManager.primary.withOpacity(0.1),
                            backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
                                ? NetworkImage(user.imageUrl!)
                                : null,
                            child: user.imageUrl == null || user.imageUrl!.isEmpty
                                ? Text(
                                    user.fullName?.substring(0, 1).toUpperCase() ?? '?',
                                    style: StylesManager.semiBold(
                                      fontSize: FontSize.large,
                                      color: ColorsManager.primary,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            user.fullName ?? 'Unknown',
                            style: StylesManager.medium(fontSize: FontSize.medium),
                          ),
                          subtitle: Text(
                            user.phoneNumber ?? user.uid ?? '',
                            style: StylesManager.regular(
                              fontSize: FontSize.small,
                              color: ColorsManager.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              // TODO: Implement unblock functionality
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  /// Show live location chats bottom sheet
  void _showLiveLocationChats() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: Sizes.size16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: ColorsManager.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: Sizes.size12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Live Location Sharing",
                              style: StylesManager.bold(fontSize: FontSize.large),
                            ),
                            Text(
                              "Active location shares",
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Content
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
                ),
                child: FutureBuilder<List<String>>(
                  future: controller.getLiveLocationChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 200,
                        child: const Center(child: CircularProgressIndicator.adaptive()),
                      );
                    }

                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                size: 48,
                                color: ColorsManager.error),
                              SizedBox(height: Sizes.size12),
                              Text(
                                'Error loading live location chats',
                                style: StylesManager.regular(color: ColorsManager.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final chatIds = snapshot.data ?? [];

                    if (chatIds.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: ColorsManager.grey,
                              ),
                              SizedBox(height: Sizes.size12),
                              Text(
                                'No live location sharing active',
                                style: StylesManager.medium(
                                  fontSize: FontSize.medium,
                                  color: ColorsManager.grey,
                                ),
                              ),
                              SizedBox(height: Sizes.size4),
                              Text(
                                'Share your location in a chat to see it here',
                                style: StylesManager.regular(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: Paddings.small),
                      shrinkWrap: true,
                      itemCount: chatIds.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final chatId = chatIds[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Paddings.large,
                            vertical: Paddings.small,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorsManager.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: ColorsManager.primary,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            'Chat ID: $chatId',
                            style: StylesManager.medium(fontSize: FontSize.medium),
                          ),
                          subtitle: Text(
                            'Sharing live location',
                            style: StylesManager.regular(
                              fontSize: FontSize.small,
                              color: ColorsManager.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.stop_circle, color: Colors.orange),
                            onPressed: () {
                              // TODO: Implement stop sharing functionality
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }
}
