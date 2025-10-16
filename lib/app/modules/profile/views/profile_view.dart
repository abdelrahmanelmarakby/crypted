// ignore_for_file: sort_child_properties_last

import 'package:crypted_app/app/widgets/app_progress_button.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: ColorsManager.white,
        forceMaterialTransparency: true,
        automaticallyImplyLeading: true,
        backgroundColor: ColorsManager.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          Constants.kProfile.tr,
          style: StylesManager.regular(
            fontSize: Sizes.size20,
            color: ColorsManager.white,
          ),
        ),
      ),
      backgroundColor: ColorsManager.primary,
      body: Obx(() {
        // مراقبة التغييرات في UserService.currentUser
        final currentUser =
            UserService.currentUser.value ?? controller.currentUser;

        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.white,
            ),
          );
        }

        if (currentUser == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: ColorsManager.white,
                ),
                SizedBox(height: Sizes.size16),
                Text(
                  'User not found',
                  style: StylesManager.regular(
                    fontSize: FontSize.medium,
                    color: ColorsManager.white,
                  ),
                ),
              ],
            ),
          );
        }

        final user = currentUser;

        return Stack(
          children: [
            Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/icons/background_setting_image.jpg',
                height: Sizes.size300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: Sizes.size150),
                  Expanded(
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      decoration: BoxDecoration(
                        color: ColorsManager.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Radiuss.xXLarge40),
                          topRight: Radius.circular(Radiuss.xXLarge40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Paddings.xXLarge),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: Sizes.size42),
                              Text(
                                user.fullName ?? Constants.kUser.tr,
                                style: StylesManager.regular(
                                  fontSize: FontSize.medium,
                                ),
                              ),
                              SizedBox(height: Sizes.size4),
                              Text(
                                user.email ?? '',
                                style: StylesManager.medium(
                                  fontSize: FontSize.small,
                                ),
                              ),
                              SizedBox(height: Sizes.size24),
                              Obx(
                                () => CustomTextField(
                                  controller: controller.fullNameController,
                                  isEnabled: controller.isEditing.value,
                                  prefixIcon: Padding(
                                    padding:
                                        const EdgeInsets.all(Paddings.normal),
                                    child: SvgPicture.asset(
                                      'assets/icons/profile.svg',
                                    ),
                                  ),
                                  name: Constants.kFullName.tr,
                                  hint: Constants.kEnteryourfullname.tr,
                                  borderColor: ColorsManager.borderColor,
                                ),
                              ),
                              SizedBox(height: Sizes.size14),
                              Obx(
                                () => CustomTextField(
                                  controller: controller.emailController,
                                  isEnabled: controller.isEditing.value,
                                  prefixIcon: Padding(
                                    padding:
                                        const EdgeInsets.all(Paddings.normal),
                                    child: SvgPicture.asset(
                                        'assets/icons/sms.svg'),
                                  ),
                                  name: Constants.kEmail.tr,
                                  hint: Constants.kEnteryouremail.tr,
                                  borderColor: ColorsManager.borderColor,
                                ),
                              ),
                              SizedBox(height: Sizes.size14),
                              Obx(
                                () => CustomTextField(
                                  controller: controller.bioController,
                                  isEnabled: controller.isEditing.value,
                                  name: Constants.kStatus.tr,
                                  hint: Constants.kEnteryourmessage.tr,
                                  borderColor: ColorsManager.borderColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Column(
                children: [
                  Divider(color: ColorsManager.navbarColor, thickness: 2),
                  SizedBox(height: Sizes.size10),
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(
                        right: Paddings.large,
                        left: Paddings.large,
                        bottom: Paddings.large,
                      ),
                      child: AppProgressButton(
                        onPressed: (anim) {
                          if (controller.isEditing.value) {
                            controller.saveChanges();
                          } else {
                            controller.toggleEditMode();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              controller.isEditing.value
                                  ? 'assets/icons/lock.svg'
                                  : 'assets/icons/edit-2.svg',
                            ),
                            SizedBox(width: Sizes.size10),
                            Text(
                              controller.isEditing.value
                                  ? Constants.kSave.tr
                                  : Constants.kEdit.tr,
                              style: StylesManager.black(
                                fontSize: FontSize.medium,
                                color: ColorsManager.white,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: ColorsManager.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 100,
              right: 0,
              left: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: controller.pickProfileImage,
                    child: Stack(
                      children: [
                        Obx(() {
                          // Show selected image if available
                          if (controller.selectedImage.value != null) {
                            return CircleAvatar(
                              backgroundImage:
                                  FileImage(controller.selectedImage.value!),
                              radius: Radiuss.xXLarge50,
                            );
                          }

                          // Show user's profile image or default
                          if (user.imageUrl != null &&
                              user.imageUrl!.isNotEmpty) {
                            return AppCachedNetworkImage(
                              imageUrl: user.imageUrl!,
                              height: Radiuss.xXLarge50 * 2,
                              width: Radiuss.xXLarge50 * 2,
                              isCircular: true,
                              fit: BoxFit.cover,
                            );
                          }

                          return CircleAvatar(
                            backgroundImage: const AssetImage(
                                'assets/images/Profile Image111.png'),
                            radius: Radiuss.xXLarge50,
                          );
                        }),
                        // Loading indicator overlay
                        Obx(() {
                          if (controller.isUploadingImage.value) {
                            return Container(
                              width: Radiuss.xXLarge50 * 2,
                              height: Radiuss.xXLarge50 * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: ColorsManager.white,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        // Edit icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ColorsManager.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorsManager.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: ColorsManager.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
