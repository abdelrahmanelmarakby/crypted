import 'dart:developer';

import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import '../../../../core/themes/color_manager.dart';
import '../../../../core/themes/font_manager.dart';
import '../../../data/data_source/user_services.dart';
import '../../../data/models/chat/chat_room_model.dart';
import '../../../routes/app_pages.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/network_image.dart';
import '../../../data/data_source/chat/chat_data_sources.dart';
import '../../../data/data_source/chat/chat_services_parameters.dart';

class ChatRow extends StatelessWidget {
  const ChatRow({super.key, required this.chatRoom});
  final ChatRoom? chatRoom;

  Future<void> _deleteChat() async {
    try {
      print("🔍 Chat Room Debug:");
      print("   ID: ${chatRoom?.id}");
      print("   Sender: ${chatRoom?.sender?.fullName}");
      print("   Receiver: ${chatRoom?.receiver?.fullName}");

      // عرض dialog للتأكيد
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text(
            Constants.kDeleteChatConfirmation.tr,
            style: TextStyle(
              fontSize: FontSize.medium,
              fontWeight: FontWeights.bold,
            ),
          ),
          content: Text(
            Constants.kAreYouSureToDeleteThisChat.tr,
            style: TextStyle(
              fontSize: FontSize.small,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                Constants.kCancel.tr,
                style: TextStyle(
                  color: ColorsManager.grey,
                  fontSize: FontSize.small,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(
                Constants.kDelete.tr,
                style: TextStyle(
                  color: ColorsManager.red,
                  fontSize: FontSize.small,
                  fontWeight: FontWeights.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (result == true) {
        // حذف الشات
        print("🔄 Attempting to delete chat room: ${chatRoom?.id}");

        final chatDataSources = ChatDataSources(
          chatServicesParameters: ChatServicesParameters(
            myId: int.tryParse(UserService.currentUser.value?.uid ?? '0') ?? 0,
            myUser: UserService.currentUser.value,
          ),
        );

        final success = await chatDataSources.deleteRoom(chatRoom?.id ?? '');
        print("✅ Delete result: $success");

        if (success) {
          Get.snackbar(
            Constants.kChatDeletedSuccessfully.tr,
            Constants.kChatDeletedSuccessfully.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ColorsManager.primary,
            colorText: ColorsManager.white,
          );
        } else {
          Get.snackbar(
            Constants.kError.tr,
            Constants.kFailedToDeleteChat.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ColorsManager.red,
            colorText: ColorsManager.white,
          );
        }
      }
    } catch (e) {
      print('Error deleting chat: $e');
      Get.snackbar(
        Constants.kError.tr,
        Constants.kFailedToDeleteChat.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final myId = UserService.currentUser.value?.uid ??
            FirebaseAuth.instance.currentUser?.uid;
        final other = chatRoom?.sender?.uid == myId
            ? chatRoom?.receiver
            : chatRoom?.sender;
        Map<String, dynamic> arg = {
          "sender": UserService.currentUser.value,
          "receiver": other,
          "blockingUserId": chatRoom?.blockingUserId,
        };
        log("Chat Args $arg");
        Get.toNamed(Routes.CHAT, arguments: arg);
      },
      onLongPress: () {
        // تأثير الاهتزاز
        HapticFeedback.heavyImpact();
        _deleteChat();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Paddings.xSmall, vertical: Paddings.normal),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          border: Border(
            top: BorderSide(color: Colors.grey[400]!, width: .2),
            bottom: BorderSide(color: Colors.grey[400]!, width: .2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(
                        Routes.CHAT,
                        arguments: {
                          "user": UserService.currentUser.value?.uid ==
                                  chatRoom?.receiver?.uid
                              ? chatRoom?.sender
                              : chatRoom?.receiver,
                        },
                      );
                    },
                    child: ClipOval(
                      child: AppCachedNetworkImage(
                        imageUrl: chatRoom?.sender?.uid !=
                                UserService.currentUser.value?.uid
                            ? chatRoom?.sender?.imageUrl ?? ""
                            : chatRoom?.receiver?.imageUrl ?? "",
                        fit: BoxFit.cover,
                        height: Sizes.size48,
                        width: Sizes.size48,
                        isCircular: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatRoom?.sender?.uid !=
                                  UserService.currentUser.value?.uid
                              ? chatRoom?.sender?.fullName ?? ""
                              : chatRoom?.receiver?.fullName ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: FontSize.small,
                            color: ColorsManager.black,
                            fontWeight: FontWeights.regular,
                          ),
                        ),
                        // SizedBox(height: 8),
                        Text(
                          chatRoom?.lastMsg ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: FontSize.small,
                            fontWeight: FontWeights.medium,
                            color: ColorsManager.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeago.format(
                      _parseDateSafely(chatRoom?.lastChat) ?? DateTime.now()),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: FontSize.xXSmall,
                    color: ColorsManager.lightGrey,
                    fontWeight: FontWeights.medium,
                  ),
                ),
                SizedBox(height: 8),
                chatRoom?.lastSender != UserService.currentUser.value?.uid
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Constants.kNewMessage.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorsManager.primary,
                            fontWeight: FontWeights.medium,
                          ),
                        ),
                      )
                    : const Text(
                        "",
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorsManager.primary,
                          fontWeight: FontWeights.medium,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDateSafely(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    return DateTime.tryParse(dateStr);
  }
}
