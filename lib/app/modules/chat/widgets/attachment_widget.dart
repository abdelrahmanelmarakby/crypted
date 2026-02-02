// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable, use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use

import 'dart:io';

import 'package:crypted_app/app/data/data_source/user_services.dart';

import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/event_buttom_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/poll_buttom_sheet.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/app/core/security/input_sanitizer.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as native_contact;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:crypted_app/app/data/models/messages/sticker_message_model.dart';
import 'package:crypted_app/app/data/models/messages/gif_message_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/giphy_picker_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/schedule_message_sheet.dart';

class AttachmentWidget extends GetView<ChatController> {
  const AttachmentWidget({super.key});

  // UI Migration: Input sanitizer for message validation
  static final InputSanitizer _sanitizer = InputSanitizer();

  /// Validate and send message with sanitization
  void _sendSanitizedMessage(ChatController controller) {
    final text = controller.messageController.text;
    if (text.isEmpty) return;

    // Validate and sanitize the message
    final result = _sanitizer.validateMessage(text);
    if (!result.isValid) {
      Get.snackbar(
        'Invalid Message',
        result.error ?? 'Message contains invalid content',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Send the sanitized message
    controller.sendQuickTextMessage(result.sanitized, controller.roomId);
  }

  /// Open the schedule-message sheet (triggered by long-pressing send button).
  void _showScheduleSheet(ChatController controller) {
    final text = controller.messageController.text;
    if (text.isEmpty) return;

    // Validate the message first
    final result = _sanitizer.validateMessage(text);
    if (!result.isValid) {
      Get.snackbar(
        'Invalid Message',
        result.error ?? 'Message contains invalid content',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Serialize members for the scheduled message document
    final members = controller.members
        .map((m) => m.toMap())
        .toList()
        .cast<Map<String, dynamic>>();

    ScheduleMessageSheet.show(
      context: Get.context!,
      messageText: result.sanitized,
      chatRoomId: controller.roomId,
      members: members,
    ).then((scheduled) {
      if (scheduled) {
        controller.messageController.clear();
        controller.update(); // Refresh GetBuilder to toggle mic/send
      }
    });
  }

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
            color: ColorsManager.surfaceAdaptive(context),
          ),
          child: Column(children: [
            // FIX: Reply Preview UI
            Obx(() {
              if (!controller.isReplying) return const SizedBox.shrink();
              return _buildReplyPreview(controller);
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!controller.isRecording.value)
                  Expanded(
                    child: CustomTextField(
                      height: Sizes.size50,
                      fillColor: ColorsManager.inputBg(context),
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
                        // UI Migration: Use sanitized message sending
                        _sendSanitizedMessage(controller);
                      },
                      hint: Constants.kSendamessage.tr,
                      textColor: ColorsManager.textPrimaryAdaptive(context),
                      controller: controller.messageController,
                      onChange: controller.onMessageTextChanged,
                    ),
                  ),
                if (!controller.isRecording.value)
                  const SizedBox(width: Sizes.size4),
                // UX-002: Animated send button morph (mic ↔ send)
                // Uses Stack with animated visibility to prevent SocialMediaRecorder disposal issues
                // The recorder stays mounted to avoid "used after disposed" errors
                if (controller.isRecording.value)
                  // Recording mode: Show full recorder widget (expanded)
                  Flexible(
                    flex: 10,
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
                              print(
                                  "🎤 ========== AUDIO DEBUG START ==========");
                              print("🎤 Sending audio message...");
                              print("  File path: ${soundFile.path}");
                              print("  Duration: $time");
                              print("  Room ID: ${controller.roomId}");

                              // Debug: Check file details
                              final file = File(soundFile.path);
                              final exists = await file.exists();
                              print("  File exists: $exists");

                              if (exists) {
                                final fileSize = await file.length();
                                print(
                                    "  File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)");

                                // Read first few bytes to check format
                                final bytes = await file.openRead(0, 12).first;
                                print(
                                    "  First bytes (hex): ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}");

                                if (fileSize == 0) {
                                  print(
                                      "❌ ERROR: Audio file is EMPTY (0 bytes)!");
                                  Get.snackbar(
                                    "Recording Error",
                                    "Audio file is empty. Please check microphone permissions.",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (fileSize < 1000) {
                                  print(
                                      "⚠️ WARNING: Audio file is very small ($fileSize bytes)");
                                }
                              } else {
                                print("❌ ERROR: Audio file does not exist!");
                                Get.snackbar(
                                  "Recording Error",
                                  "Audio file was not created",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              print(
                                  "🎤 ========================================");

                              // Test: Try to play locally to verify audio content
                              print("🔊 Testing local playback...");
                              try {
                                final testPlayer = AudioPlayer();
                                await testPlayer.setFilePath(soundFile.path);
                                final duration = testPlayer.duration;
                                print("  Local duration detected: $duration");
                                await testPlayer.dispose();
                                print("✅ Local audio file is playable");
                              } catch (e) {
                                print("❌ Local playback test FAILED: $e");
                              }

                              final audioMessage =
                                  await FirebaseUtils.uploadAudio(
                                      soundFile.path, controller.roomId, time);

                              if (audioMessage != null) {
                                print(
                                    "✅ Audio message created, sending to chat...");
                                await controller.sendMessage(audioMessage);
                                print("✅ Audio message sent successfully");
                              } else {
                                print(
                                    "❌ Failed to upload audio to Firebase Storage");
                                throw Exception(
                                    "Failed to upload audio to Firebase Storage");
                              }
                            } catch (e, stackTrace) {
                              print("❌ Error sending audio message: $e");
                              print("Stack trace: $stackTrace");

                              Get.snackbar(
                                "Error",
                                "Failed to send audio message: ${e.toString()}",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.8),
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                                margin: const EdgeInsets.all(16),
                              );
                            } finally {
                              controller.onChangeRec(false);
                            }
                          },
                          encode: AudioEncoderType.AAC,
                        ),
                      ),
                    ),
                  )
                else
                  // Not recording: Show mic/send with Stack-based animation
                  // Stack keeps both widgets mounted, avoiding disposal issues
                  SizedBox(
                    width: Sizes.size50,
                    height: Sizes.size50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Mic button (always mounted, animated visibility)
                        AnimatedScale(
                          scale: controller.messageController.text.isEmpty
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: controller.messageController.text.isEmpty
                                ? 1.0
                                : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring:
                                  controller.messageController.text.isNotEmpty,
                              child: SocialMediaRecorder(
                                backGroundColor:
                                    ColorsManager.primary.withAlpha(50),
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
                                    final file = File(soundFile.path);
                                    final exists = await file.exists();
                                    if (!exists) return;

                                    final audioMessage =
                                        await FirebaseUtils.uploadAudio(
                                      soundFile.path,
                                      controller.roomId,
                                      time,
                                    );
                                    if (audioMessage != null) {
                                      await controller
                                          .sendMessage(audioMessage);
                                    }
                                  } catch (e) {
                                    Get.snackbar(
                                      "Error",
                                      "Failed to send audio message",
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor:
                                          Colors.red.withValues(alpha: 0.8),
                                      colorText: Colors.white,
                                    );
                                  } finally {
                                    controller.onChangeRec(false);
                                  }
                                },
                                encode: AudioEncoderType.AAC,
                              ),
                            ),
                          ),
                        ),
                        // Send button (always mounted, animated visibility)
                        AnimatedScale(
                          scale: controller.messageController.text.isNotEmpty
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity:
                                controller.messageController.text.isNotEmpty
                                    ? 1.0
                                    : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring:
                                  controller.messageController.text.isEmpty,
                              child: GestureDetector(
                                onTap: () {
                                  // UX-003: Haptic feedback on send
                                  HapticFeedback.lightImpact();
                                  _sendSanitizedMessage(controller);
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showScheduleSheet(controller);
                                },
                                child: Container(
                                  width: Sizes.size50,
                                  height: Sizes.size50,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(Radiuss.small),
                                    color: ColorsManager.primary.withAlpha(50),
                                  ),
                                  child: const Icon(
                                    Iconsax.send_2,
                                    color: ColorsManager.primary,
                                    size: Sizes.size20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ]),
        );
      },
    );
  }

  /// Build reply preview widget
  Widget _buildReplyPreview(ChatController controller) {
    final replyingTo = controller.replyingTo;
    if (replyingTo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: Paddings.small),
      padding: const EdgeInsets.symmetric(
        horizontal: Paddings.medium,
        vertical: Paddings.small,
      ),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radiuss.small),
        border: Border(
          left: BorderSide(
            color: ColorsManager.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying',
                  style: StylesManager.medium(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.replyToText.value,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.darkGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.clearReply(),
            icon: Icon(
              Icons.close,
              color: ColorsManager.grey,
              size: Sizes.size20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
      color: ColorsManager.surfaceAdaptive(context),
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
                          debugPrint("📷 Photos picker starting...");
                          try {
                            final result = await FilePicker.platform
                                .pickFiles(type: FileType.image);
                            if (result == null || result.files.isEmpty) {
                              debugPrint("📷 No file selected");
                              return;
                            }
                            final path = result.files.single.path;
                            if (path == null) {
                              debugPrint("📷 File path is null");
                              return;
                            }

                            debugPrint("📷 File selected: $path");

                            // Get file info
                            final file = File(path);
                            final fileName =
                                path.split(Platform.pathSeparator).last;
                            final fileSize = await file.length();
                            final uploadId = FirebaseUtils.generateUniqueId(
                                'image', controller.roomId);

                            debugPrint(
                                "📷 Starting upload: $fileName ($fileSize bytes)");

                            // Start upload tracking
                            controller.startUpload(
                              uploadId: uploadId,
                              filePath: path,
                              fileName: fileName,
                              fileSize: fileSize,
                              uploadType: 'image',
                              thumbnailPath:
                                  path, // Use original image as thumbnail
                            );

                            // Upload with progress tracking
                            final photoMessage =
                                await FirebaseUtils.uploadImage(
                              path,
                              controller.roomId,
                              onProgress: (progress) {
                                debugPrint(
                                    "📷 Upload progress: ${(progress * 100).toStringAsFixed(0)}%");
                                controller.updateUploadProgress(
                                    uploadId, progress);
                              },
                            );

                            if (photoMessage != null) {
                              debugPrint(
                                  "📷 Upload complete, sending message...");
                              // Complete upload (replace uploading message with actual message)
                              await controller.sendMessage(photoMessage);
                              controller.completeUpload(uploadId, photoMessage);
                              debugPrint("📷 Photo message sent successfully!");
                            } else {
                              debugPrint(
                                  "❌ Upload failed - photoMessage is null");
                              // Upload failed, remove uploading message
                              controller.cancelUpload(uploadId);
                            }
                          } catch (e, stackTrace) {
                            debugPrint("❌ Error in photo upload: $e");
                            debugPrint("❌ Stack trace: $stackTrace");
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
                          debugPrint("📸 Camera picker starting...");
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera);
                            if (photo != null) {
                              debugPrint("📸 Photo captured: ${photo.path}");

                              // Get file info
                              final file = File(photo.path);
                              final fileName =
                                  photo.path.split(Platform.pathSeparator).last;
                              final fileSize = await file.length();
                              final uploadId = FirebaseUtils.generateUniqueId(
                                  'image', controller.roomId);

                              debugPrint(
                                  "📸 Starting upload: $fileName ($fileSize bytes)");

                              // Start upload tracking
                              controller.startUpload(
                                uploadId: uploadId,
                                filePath: photo.path,
                                fileName: fileName,
                                fileSize: fileSize,
                                uploadType: 'image',
                                thumbnailPath: photo.path,
                              );

                              // Upload with progress tracking
                              final photoMessage =
                                  await FirebaseUtils.uploadImage(
                                photo.path,
                                controller.roomId,
                                onProgress: (progress) {
                                  debugPrint(
                                      "📸 Upload progress: ${(progress * 100).toStringAsFixed(0)}%");
                                  controller.updateUploadProgress(
                                      uploadId, progress);
                                },
                              );

                              if (photoMessage != null) {
                                debugPrint(
                                    "📸 Upload complete, sending message...");
                                await controller.sendMessage(photoMessage);
                                controller.completeUpload(
                                    uploadId, photoMessage);
                                debugPrint(
                                    "📸 Camera photo sent successfully!");
                              } else {
                                debugPrint(
                                    "❌ Camera upload failed - photoMessage is null");
                                controller.cancelUpload(uploadId);
                              }
                            } else {
                              debugPrint("📸 No photo captured");
                            }
                          } catch (e, stackTrace) {
                            debugPrint("❌ Error in camera upload: $e");
                            debugPrint("❌ Stack trace: $stackTrace");
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
                              senderId:
                                  UserService.currentUser.value?.uid ?? "",
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
                                senderId:
                                    UserService.currentUser.value?.uid ?? "",
                                timestamp: DateTime.now(),
                                name: contact.fullName ?? 'Unknown Contact',
                                phoneNumber: contact.phoneNumbers!.first,
                              ));
                            }
                          } catch (e) {
                            Get.snackbar(
                              "خطأ",
                              " ${e.toString()} فشل في اختيار جهة الاتصال",
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.8),
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

                          // Get file info
                          final file = File(path);
                          final fileName =
                              path.split(Platform.pathSeparator).last;
                          final fileSize = await file.length();
                          final uploadId = FirebaseUtils.generateUniqueId(
                              'file', controller.roomId);

                          // Start upload tracking
                          controller.startUpload(
                            uploadId: uploadId,
                            filePath: path,
                            fileName: fileName,
                            fileSize: fileSize,
                            uploadType: 'file',
                          );

                          // Upload with progress tracking
                          final fileMessage = await FirebaseUtils.uploadFile(
                            path,
                            controller.roomId,
                            onProgress: (progress) {
                              controller.updateUploadProgress(
                                  uploadId, progress);
                            },
                          );

                          if (fileMessage != null) {
                            await controller.sendMessage(fileMessage);
                            controller.completeUpload(uploadId, fileMessage);
                          } else {
                            controller.cancelUpload(uploadId);
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
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'assets/icons/ico-24-sticker.svg',
                        'GIF',
                        () async {
                          Get.back();
                          final result = await GiphyPickerSheet.show(context);
                          if (result == null) return;

                          if (result.type == 'gif') {
                            await controller.sendMessage(GifMessage(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              roomId: controller.roomId,
                              senderId:
                                  UserService.currentUser.value?.uid ?? '',
                              timestamp: DateTime.now(),
                              gifUrl: result.url,
                              previewUrl: result.previewUrl,
                              giphyId: result.giphyId,
                              title: result.title,
                              width: result.width,
                              height: result.height,
                            ));
                          } else {
                            await controller.sendMessage(StickerMessage(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              roomId: controller.roomId,
                              senderId:
                                  UserService.currentUser.value?.uid ?? '',
                              timestamp: DateTime.now(),
                              stickerUrl: result.url,
                              width: result.width,
                              height: result.height,
                            ));
                          }
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
                color: ColorsManager.textPrimaryAdaptive(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
