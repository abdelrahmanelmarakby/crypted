// ignore_for_file: must_be_immutable, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/attachment_widget.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/extensions/string.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (controller) {
        if (controller.sender == null || controller.receiver == null) {
          return Scaffold(
            body: Center(child: Text(Constants.kInvalidchatparameters.tr)),
          );
        }
        return StreamProvider<List<Message>>.value(
          value: ChatDataSources(
            chatServicesParameters: ChatServicesParameters(
              myId: controller.sender?.uid?.encryptTextToNumbers(),
              hisId: controller.receiver?.uid?.encryptTextToNumbers(),
              myUser: controller.sender,
              hisUser: controller.receiver,
            ),
          ).getLivePrivateMessage,
          initialData: const [],
          catchError: (error, stackTrace) {
            print(error);
            print(stackTrace);
            throw Exception(error.toString() + stackTrace.toString());
            return [];
          },
          builder: (context, child) {
            final getFluffs = Provider.of<List<Message>>(context);
            return Scaffold(
              appBar: AppBar(
                backgroundColor: ColorsManager.navbarColor,
                centerTitle: false,
                leading: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: Sizes.size20,
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    ///Check if i am the sender and the reciver and then go to other user profile
                    Get.toNamed(
                      Routes.CONTACT_INFO,
                      arguments: {
                        "user": UserService.currentUser.value?.uid ==
                                controller.receiver?.uid
                            ? controller.sender
                            : controller.receiver,
                      },
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: AppCachedNetworkImage(
                          imageUrl: (UserService.currentUser.value?.uid ==
                                      controller.receiver?.uid
                                  ? controller.sender?.imageUrl
                                  : controller.receiver?.imageUrl) ??
                              '',
                          height: Sizes.size38,
                          width: Sizes.size38,
                        ),
                      ),
                      SizedBox(width: Sizes.size10),
                      Text(
                        UserService.currentUser.value?.uid ==
                                controller.receiver?.uid
                            ? UserService.currentUser.value?.fullName ?? ""
                            : controller.receiver?.fullName ?? "",
                        overflow: TextOverflow.fade,
                        style: StylesManager.semiBold(
                          color: ColorsManager.black,
                          fontSize: FontSize.large,
                        ),
                      ),
                      Expanded(child: SizedBox()),
                      // Always show call buttons, even if chatting with self
                      ZegoSendCallInvitationButton(
                        buttonSize: Size(Sizes.size38, Sizes.size38),
                        padding: EdgeInsets.all(0),
                        iconSize: Size.fromHeight(Sizes.size20),
                        icon: ButtonIcon(
                          icon: SvgPicture.asset(
                            'assets/icons/call-calling.svg',
                            color: ColorsManager.black,
                            height: Sizes.size20,
                            width: Sizes.size20,
                          ),
                        ),
                        onPressed: (code, message, p2) async {
                          // إنشاء CallModel للمكالمة
                          CallModel callModel = CallModel(
                            callType: CallType.audio,
                            callStatus: CallStatus.outgoing,
                            calleeId: controller.receiver?.uid ?? "",
                            calleeImage: controller.receiver?.imageUrl ?? "",
                            calleeUserName: controller.receiver?.fullName ?? "",
                            callerId: controller.sender?.uid ?? "",
                            callerImage: controller.sender?.imageUrl ?? "",
                            callerUserName: controller.sender?.fullName ?? "",
                            time: DateTime.now(),
                          );

                          // حفظ المكالمة في Firestore
                          CallDataSources callDataSource = CallDataSources();
                          print(
                              '📞 ChatScreen: Storing audio call to Firestore');
                          print('📞 Call details: ${callModel.toMap()}');
                          final success =
                              await callDataSource.storeCall(callModel);
                          if (success) {
                            print(
                                '📞 ChatScreen: Audio call stored successfully');
                            // تحديث صفحة المكالمات
                            Get.find<CallsController>().refreshCalls();
                          } else {
                            print('❌ ChatScreen: Failed to store audio call');
                          }

                          // إرسال رسالة المكالمة في الشات
                          await controller.sendMessage(CallMessage(
                            id: "${Timestamp.now().toDate()}",
                            roomId: ChatDataSources.getRoomId(
                              controller.sender?.uid ?? "",
                              controller.receiver?.uid ?? "",
                            ),
                            senderId: controller.sender?.uid ?? "",
                            timestamp: Timestamp.now().toDate(),
                            callModel: callModel,
                          ));
                        },
                        isVideoCall: false,
                        resourceID: "crypted",
                        invitees: [
                          ZegoUIKitUser(
                            id: controller.receiver?.uid ?? "",
                            name: controller.receiver?.fullName ?? "",
                          ),
                        ],
                      ),
                      ZegoSendCallInvitationButton(
                        buttonSize: Size(Sizes.size38, Sizes.size38),
                        icon: ButtonIcon(icon: Icon(Icons.videocam_outlined)),
                        padding: EdgeInsets.all(0),
                        iconSize: Size.fromHeight(Sizes.size30),
                        isVideoCall: true,
                        resourceID: "crypted",
                        onPressed: (code, message, p2) async {
                          // إنشاء CallModel للمكالمة
                          CallModel callModel = CallModel(
                            callType: CallType.video,
                            callStatus: CallStatus.outgoing,
                            calleeId: controller.receiver?.uid ?? "",
                            calleeImage: controller.receiver?.imageUrl ?? "",
                            calleeUserName: controller.receiver?.fullName ?? "",
                            callerId: controller.sender?.uid ?? "",
                            callerImage: controller.sender?.imageUrl ?? "",
                            callerUserName: controller.sender?.fullName ?? "",
                            time: DateTime.now(),
                          );

                          // حفظ المكالمة في Firestore
                          CallDataSources callDataSource = CallDataSources();
                          print(
                              '📞 ChatScreen: Storing video call to Firestore');
                          print('📞 Call details: ${callModel.toMap()}');
                          final success =
                              await callDataSource.storeCall(callModel);
                          if (success) {
                            print(
                                '📞 ChatScreen: Video call stored successfully');
                            // تحديث صفحة المكالمات
                            Get.find<CallsController>().refreshCalls();
                          } else {
                            print('❌ ChatScreen: Failed to store video call');
                          }

                          // إرسال رسالة المكالمة في الشات
                          await controller.sendMessage(CallMessage(
                            id: "${Timestamp.now().toDate()}",
                            roomId: ChatDataSources.getRoomId(
                              controller.sender?.uid ?? "",
                              controller.receiver?.uid ?? "",
                            ),
                            senderId: controller.sender?.uid ?? "",
                            timestamp: Timestamp.now().toDate(),
                            callModel: callModel,
                          ));
                        },
                        invitees: [
                          ZegoUIKitUser(
                            id: controller.receiver?.uid ?? "",
                            name: controller.receiver?.fullName ?? "",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              body: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    // إخفاء لوحة المفاتيح عند الضغط على مكان فارغ
                    FocusScope.of(context).unfocus();
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          reverse: true,
                          itemCount: getFluffs.length,
                          itemBuilder: (context, index) {
                            final Message? old = index != getFluffs.length - 1
                                ? getFluffs[index + 1]
                                : null;
                            DateTime oldTime;
                            if (old?.timestamp != null) {
                              oldTime = old!.timestamp;
                            } else {
                              oldTime = DateTime.now();
                            }
                            final Message msg = getFluffs[index];

                            // تحديد ما إذا كانت الرسالة من المستخدم الحالي أم لا
                            bool isMe = msg.senderId ==
                                UserService.currentUser.value?.uid;
                            print("📱 Building message widget:");
                            print("   Message senderId: ${msg.senderId}");
                            print(
                                "   Current user UID: ${UserService.currentUser.value?.uid}");
                            print("   Is me: $isMe");
                            print(
                                "   SenderType (for MessageBuilder): ${!isMe}");
                            print(
                                "   Message will appear on: ${isMe ? 'RIGHT (as sender)' : 'LEFT (as receiver)'}");
                            DateTime newTime;
                            newTime = msg.timestamp;

                            return Column(
                              children: [
                                if (index == getFluffs.length - 1 ||
                                    !_isSameDay(oldTime, newTime))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: Paddings.small,
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Paddings.small,
                                          vertical: Paddings.xSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorsManager.navbarColor,
                                          borderRadius: BorderRadius.circular(
                                              Sizes.size16),
                                        ),
                                        child: Text(
                                          _formatDate(newTime),
                                          style: const TextStyle(
                                            color: ColorsManager.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: Sizes.size12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                MessageBuilder(
                                  !isMe, // عكس القيمة لأن senderType = true يعني الرسالة من شخص آخر
                                  messageModel: msg,
                                  timestamp: msg.timestamp.toIso8601String(),
                                  senderName: isMe
                                      ? UserService.currentUser.value?.fullName
                                      : controller.receiver?.fullName,
                                  senderImage: isMe
                                      ? UserService.currentUser.value?.imageUrl
                                      : controller.receiver?.imageUrl,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (controller.blockingUserId == null)
                        const AttachmentWidget()
                      else
                        const SizedBox(height: Sizes.size20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return Constants.kToday.tr;
    } else if (messageDate == yesterday) {
      return Constants.kYesterday.tr;
    } else {
      final monthNames = [
        Constants.kJan.tr,
        Constants.kfep.tr,
        Constants.kmar.tr,
        Constants.kApr.tr,
        Constants.kMay.tr,
        Constants.kJun.tr,
        Constants.kjul.tr,
        Constants.kAug.tr,
        Constants.kSep.tr,
        Constants.kOct.tr,
        Constants.kNov.tr,
        Constants.kDec.tr
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    }
  }

  String _getValidImageUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return 'https://i2.wp.com/ui-avatars.com/api/%D8%B3%D9%85%D9%8A%D8%B1%20%D8%A7%D8%AD%D9%85%D8%B1/128?ssl=1';
  }
}
