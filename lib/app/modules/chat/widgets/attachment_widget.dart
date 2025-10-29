// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable, use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use

import 'package:crypted_app/app/data/data_source/user_services.dart';

import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/event_buttom_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/poll_buttom_sheet.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as native_contact;
import 'package:image_picker/image_picker.dart';

class AttachmentWidget extends GetView<ChatController> {
  const AttachmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (controller) {
        return Container(
          padding: EdgeInsets.only(
            bottom: context.height * .02,
            left: Paddings.small,
            right: Paddings.small,
          ),
          decoration: BoxDecoration(
            color: ColorsManager.white,
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!controller.isRecording.value)
                  Expanded(
                    child: CustomTextField(
                      height: Sizes.size50,
                      fillColor: ColorsManager.navbarColor,
                      borderRadius: Sizes.size10,
                      suffixIcon: GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          _showCustomMenu(context, details.globalPosition);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Paddings.xLarge),
                          child: SvgPicture.asset(
                            'assets/icons/Group.svg',
                          ),
                        ),
                      ),
                      inputAction: TextInputAction.newline,
                      onSubmit: (value) {
                        if (controller.messageController.text.isNotEmpty) {
                          controller.sendQuickTextMessage(
                              controller.messageController.text,
                              controller.roomId);
                        }
                      },
                      hint: Constants.kSendamessage.tr,
                      textColor: ColorsManager.black,
                      controller: controller.messageController,
                      onChange: controller.onMessageTextChanged,
                    ),
                  ),
                if (!controller.isRecording.value)
                  const SizedBox(width: Sizes.size4),
                if (controller.isRecording.value ||
                    controller.messageController.text.isEmpty)
                  Flexible(
                    flex: controller.isRecording.value ? 10 : 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        child: SocialMediaRecorder(
                          backGroundColor: ColorsManager.primary.withAlpha(50),
                          recordIconBackGroundColor:
                              ColorsManager.primary.withAlpha(50),
                          recordIcon: Icon(
                            Iconsax.microphone,
                            color: ColorsManager.primary,
                            size: Sizes.size24,
                          ),
                          initRecordPackageWidth: Sizes.size48,
                          counterBackGroundColor: Colors.transparent,
                          counterTextStyle: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                          slideToCancelTextStyle: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                          cancelTextStyle: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                          recordIconWhenLockBackGroundColor:
                              ColorsManager.primary.withAlpha(50),
                          cancelTextBackGroundColor:
                              ColorsManager.primary.withAlpha(50),
                          radius: BorderRadius.circular(Radiuss.small),
                          startRecording: () {
                            controller.onChangeRec(true);
                          },
                          stopRecording: (time) {
                            controller.onChangeRec(false);
                          },
                          sendRequestFunction: (soundFile, time) async {
                            controller.onChangeRec(false);
                            try {
                              final audioMessage =
                                  await FirebaseUtils.uploadAudio(
                                      soundFile.path,
                                      controller.roomId,
                                      time);
                              if (audioMessage != null) {
                                await controller.sendMessage(audioMessage);
                              } else {
                                throw Exception("Failed to upload audio");
                              }
                            } catch (e) {
                              Get.snackbar(
                                "Error",
                                "Failed to send audio message",
                                backgroundColor: Colors.red.withOpacity(0.8),
                                colorText: Colors.white,
                              );
                            }
                            controller.onChangeRec(false);
                          },
                          encode: AudioEncoderType.AAC,
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      if (controller.messageController.text.isNotEmpty) {
                        controller.sendQuickTextMessage(
                            controller.messageController.text,
                            controller.roomId);
                      }
                    },
                    child: Container(
                      width: Sizes.size50,
                      height: Sizes.size50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radiuss.small),
                        color: ColorsManager.primary.withAlpha(50),
                      ),
                      child: const Icon(
                        Iconsax.send_2,
                        color: ColorsManager.primary,
                        size: Sizes.size20,
                      ),
                    ),
                  )
              ],
            ),
          ]),
        );
      },
    );
  }

  void _showCustomMenu(BuildContext context, Offset offset) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset localOffset = overlay.globalToLocal(offset);
    final double menuHeight = 200;
    final double adjustedY = localOffset.dy - menuHeight - 10;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          localOffset.dx - 100,
          localOffset.dy + 80,
          200,
          menuHeight,
        ),
        Offset.zero & overlay.size,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radiuss.xLarge),
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Paddings.large,
              vertical: Paddings.xSmall,
            ),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: Sizes.size155,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMenuItem(
                        context,
                        'assets/icons/fi_833281.svg',
                        Constants.kPhotos.tr,
                        () async {
                          Get.back();
                          final result = await FilePicker.platform
                              .pickFiles(type: FileType.image);
                          if (result == null || result.files.isEmpty) return;
                          final path = result.files.single.path;
                          if (path == null) return;

                          // استخدم uploadImage بدلاً من uploadFile
                          final photoMessage = await FirebaseUtils.uploadImage(
                            path,
                            controller.roomId,
                          );
                          if (photoMessage != null) {
                            await controller.sendMessage(photoMessage);
                          }
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'assets/icons/Icon (7).svg',
                        Constants.kCamera.tr,
                        () async {
                          Get.back();
                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(
                              source: ImageSource.camera);
                          if (photo != null) {
                            final photoMessage =
                                await FirebaseUtils.uploadImage(
                              photo.path,
                              controller.roomId,
                            );
                            if (photoMessage != null) {
                              await controller.sendMessage(photoMessage);
                            }
                          }
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'assets/icons/fi_10892268.svg',
                        Constants.kLocation.tr,
                        () async {
                          try {
                            Get.back();
                            // اطلب الإذن
                            LocationPermission permission =
                                await Geolocator.requestPermission();
                            if (permission == LocationPermission.denied ||
                                permission ==
                                    LocationPermission.deniedForever) {
                              Get.snackbar("خطأ",
                                  "يجب السماح بالوصول للموقع لإرسال الموقع الجغرافي");
                              return;
                            }

                            // احصل على الموقع الحالي
                            Position position =
                                await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high);

                            // أرسل رسالة الموقع (تأكد من وجود دالة sendLocationMessage أو استخدم sendMessage مع موديل مناسب)
                            await controller.sendMessage(LocationMessage(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              roomId: controller.roomId,
                              senderId: UserService.currentUser.value?.uid ?? "",
                              timestamp: DateTime.now(),
                              latitude: position.latitude,
                              longitude: position.longitude,
                            ));
                          } catch (e) {
                            print(e.toString());
                            Get.snackbar("خطأ", "فشل في تحديد الموقع: $e");
                          }
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'assets/icons/Icon (6).svg',
                        Constants.kPoll.tr,
                        () async {
                          Get.back();

                          // عرض poll bottom sheet
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            isDismissible: true,
                            enableDrag: true,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.85,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder: (context, scrollController) =>
                                  PollBottomSheet(
                                controller: controller,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.size14),
                  Row(
                    children: [
                      _buildMenuItem(
                        context,
                        'assets/icons/fi_1946429.svg',
                        Constants.kContact.tr,
                        () async {
                          try {
                            Get.back();
                            final contactPicker =
                                native_contact.FlutterNativeContactPicker();
                            final contact = await contactPicker.selectContact();

                            if (contact != null &&
                                contact.phoneNumbers != null &&
                                contact.phoneNumbers!.isNotEmpty) {
                              await controller.sendMessage(ContactMessage(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                roomId: controller.roomId,
                                senderId: UserService.currentUser.value?.uid??"",
                                timestamp: DateTime.now(),
                                name: contact.fullName ?? 'Unknown Contact',
                                phoneNumber: contact.phoneNumbers!.first,
                              ));
                            }
                          } catch (e) {
                            Get.snackbar(
                              "خطأ",
                              " ${e.toString()} فشل في اختيار جهة الاتصال",
                              backgroundColor: Colors.red.withOpacity(0.8),
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: Sizes.size10),
                      _buildMenuItem(
                        context,
                        'assets/icons/fi_2258853.svg',
                        Constants.kDocument.tr,
                        () async {
                          Get.back();
                          final result = await FilePicker.platform.pickFiles();
                          if (result == null || result.files.isEmpty) return;
                          final path = result.files.single.path;
                          if (path == null) return;

                          // استخدم uploadFile وأرسل الرسالة الناتجة
                          final fileMessage = await FirebaseUtils.uploadFile(
                            path,
                            controller.roomId,
                          );
                          if (fileMessage != null) {
                            await controller.sendMessage(fileMessage);
                          }
                        },
                      ),
                      const SizedBox(width: Sizes.size10),
                      _buildMenuItem(
                        context,
                        'assets/icons/fi_3861532.svg',
                        Constants.kEvent.tr,
                        () async {
                          Get.back();
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.85,
                              child: EventBottomSheet(controller: controller),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String iconPath, String label,
      void Function()? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: ColorsManager.backgroundIconSetting,
            radius: Radiuss.xXLarge,
            child: SvgPicture.asset(
              iconPath,
              colorFilter: const ColorFilter.mode(
                ColorsManager.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: Sizes.size4),
          FittedBox(
            child: Text(
              label,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
