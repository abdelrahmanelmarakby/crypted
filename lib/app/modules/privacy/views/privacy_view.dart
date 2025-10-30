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

  /// Show blocked users dialog
  void _showBlockedUsers() {
    Get.dialog(
      Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Blocked Users",
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<SocialMediaUser>>(
                  future: controller.getBlockedUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading blocked users',
                          style: StylesManager.regular(color: ColorsManager.error),
                        ),
                      );
                    }

                    final blockedUsers = snapshot.data ?? [];

                    if (blockedUsers.isEmpty) {
                      return Center(
                        child: Text(
                          'No blocked users',
                          style: StylesManager.regular(color: ColorsManager.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: blockedUsers.length,
                      itemBuilder: (context, index) {
                        final user = blockedUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
                                ? NetworkImage(user.imageUrl!)
                                : null,
                            child: user.imageUrl == null || user.imageUrl!.isEmpty
                                ? Text(user.fullName?.substring(0, 1).toUpperCase() ?? '?')
                                : null,
                          ),
                          title: Text(user.fullName ?? 'Unknown'),
                          subtitle: Text(user.uid ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show live location chats dialog
  void _showLiveLocationChats() {
    Get.dialog(
      Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Live Location Sharing",
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: controller.getLiveLocationChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading live location chats',
                          style: StylesManager.regular(color: ColorsManager.error),
                        ),
                      );
                    }

                    final chatIds = snapshot.data ?? [];

                    if (chatIds.isEmpty) {
                      return Center(
                        child: Text(
                          'No live location sharing active',
                          style: StylesManager.regular(color: ColorsManager.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: chatIds.length,
                      itemBuilder: (context, index) {
                        final chatId = chatIds[index];
                        return ListTile(
                          leading: Icon(Icons.location_on, color: ColorsManager.primary),
                          title: Text('Chat ID: $chatId'),
                          subtitle: Text('Sharing live location'),
                        );
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
