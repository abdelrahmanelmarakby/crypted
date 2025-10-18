// ignore_for_file: must_be_immutable, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';

class PrivateChatScreen extends GetView<ChatController> {
  const PrivateChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (controller) {
        if (controller.members.isEmpty || controller.roomId.isEmpty) {
          return Scaffold(
            backgroundColor: ColorsManager.navbarColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: ColorsManager.grey,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    Constants.kInvalidchatparameters.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }


        return StreamProvider<List<Message>>.value(
          value: ChatDataSources(
            chatConfiguration: ChatConfiguration(
              members: controller.members,
            ),
          ).getLivePrivateMessage(controller.roomId),
          initialData: const [],
          catchError: (error, stackTrace) {
            print("Error in Members: ${controller.members}");
            print(error);
            print(stackTrace);
            return [];
          },
          builder: (context, child) {
            print("members ${controller.members}");
            print("Is group chat ? ${controller.isGroupChat.value} ${controller.isGroup}");
            final messages = Provider.of<List<Message>>(context);
            return Scaffold(
              backgroundColor: ColorsManager.navbarColor,
              extendBodyBehindAppBar: false,
              appBar: _buildAppBar(context, _getOtherUserForAppBar()),
              body: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ColorsManager.navbarColor,
                        Colors.white.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      children: [
                        // Messages area
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: ListView.builder(
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                reverse: true,
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                itemCount: messages.length,
                                itemBuilder: (context, index) => _buildMessageItem(
                                  messages,
                                  index,
                                  UserService.currentUser.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Input area
                        if (controller.blockingUserId == null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: const SafeArea(
                              child: AttachmentWidget(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Safely get the other user for app bar display
  dynamic _getOtherUserForAppBar() {
    try {
      // Try to find other user from controller members
      if (controller.members.isNotEmpty) {
        final otherUsers = controller.members.where((user) => user.uid != UserService.currentUser.value?.uid);
        if (otherUsers.isNotEmpty) {
          return otherUsers.first;
        }
      }

      // Fallback to current user if no other user found
      return UserService.currentUser.value ?? SocialMediaUser(fullName: "Unknown User");
    } catch (e) {
      print("❌ Error getting other user for app bar: $e");
      return SocialMediaUser(fullName: "Unknown User");
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic otherUser) {
    return AppBar(
      backgroundColor: ColorsManager.navbarColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18,
            ),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(
            Routes.CONTACT_INFO,
            arguments: {"user": otherUser},
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User avatar with online status
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AppCachedNetworkImage(
                        imageUrl: otherUser.imageUrl ?? '',
                        height: 44,
                        width: 44,
                      ),
                    ),
                  ),
                  // Online status indicator
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: ColorsManager.darkGrey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorsManager.navbarColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherUser.fullName ?? "Unknown User",
                      style: StylesManager.bold(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Offline", // You can make this dynamic
                      style: StylesManager.regular(
                        color: ColorsManager.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Call buttons with modern design
        _buildCallButton(
          icon: SvgPicture.asset(
            'assets/icons/call-calling.svg',
            color: Colors.black,
            height: 20,
            width: 20,
          ),
          onPressed: () => _handleAudioCall(otherUser),
          isVideoCall: false,
          otherUser: otherUser,
        ),
        
        const SizedBox(width: 8),
        
        _buildCallButton(
          icon: const Icon(
            Iconsax.video_copy,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => _handleVideoCall(otherUser),
          isVideoCall: true,
          otherUser: otherUser,
        ),
        
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCallButton({
    required Widget icon,
    required VoidCallback onPressed,
    required bool isVideoCall,
    required dynamic otherUser,
  }) {
    return ZegoSendCallInvitationButton(
      buttonSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      iconSize: const Size.fromHeight(24),
      icon: ButtonIcon(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: icon,
        ),
      ),
      onPressed: (code, message, p2) => onPressed(),
      isVideoCall: isVideoCall,
      resourceID: "crypted",
      invitees: [
        ZegoUIKitUser(
          id: otherUser.uid ?? "",
          name: otherUser.fullName ?? "",
        ),
      ],
    );
  }

  Widget _buildMessageItem(List<Message> messages, int index, dynamic otherUser) {
    final Message? previousMsg = index != messages.length - 1 ? messages[index + 1] : null;
    final Message currentMsg = messages[index];
    
    final bool isMe = currentMsg.senderId == UserService.currentUser.value?.uid;
    final DateTime currentTime = currentMsg.timestamp!;
    final DateTime? previousTime = previousMsg?.timestamp;

    return Column(
      children: [
        // Date separator
        if (index == messages.length - 1 || 
            (previousTime != null && !_isSameDay(previousTime, currentTime)))
          _buildDateSeparator(currentTime),
        
        // Message
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: MessageBuilder(
            !isMe,
            messageModel: currentMsg,
            timestamp: currentMsg.timestamp.toIso8601String(),
            senderName: isMe 
                ? UserService.currentUser.value?.fullName
                : otherUser.fullName,
            senderImage: isMe 
                ? UserService.currentUser.value?.imageUrl
                : otherUser.imageUrl,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: ColorsManager.offWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _formatDate(date),
            style: StylesManager.medium(
              color: ColorsManager.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAudioCall(dynamic otherUser) async {
    HapticFeedback.lightImpact();
    
    final callModel = CallModel(
      callType: CallType.audio,
      callStatus: CallStatus.outgoing,
      calleeId: otherUser.uid ?? "",
      calleeImage: otherUser.imageUrl ?? "",
      calleeUserName: otherUser.fullName ?? "",
      callerId: UserService.currentUser.value?.uid ?? "",
      callerImage: UserService.currentUser.value?.imageUrl ?? "",
      callerUserName: UserService.currentUser.value?.fullName ?? "",
      time: DateTime.now(),
    );

    await _storeCallAndSendMessage(callModel);
  }

  Future<void> _handleVideoCall(dynamic otherUser) async {
    HapticFeedback.lightImpact();
    
    final callModel = CallModel(
      callType: CallType.video,
      callStatus: CallStatus.outgoing,
      calleeId: otherUser.uid ?? "",
      calleeImage: otherUser.imageUrl ?? "",
      calleeUserName: otherUser.fullName ?? "",
      callerId: UserService.currentUser.value?.uid ?? "",
      callerImage: UserService.currentUser.value?.imageUrl ?? "",
      callerUserName: UserService.currentUser.value?.fullName ?? "",
      time: DateTime.now(),
    );

    await _storeCallAndSendMessage(callModel);
  }

  Future<void> _storeCallAndSendMessage(CallModel callModel) async {
    try {
      final callDataSource = CallDataSources();
      final success = await callDataSource.storeCall(callModel);
      
      if (success) {
        Get.find<CallsController>().refreshCalls();
        
        await controller.sendMessage(CallMessage(
          id: "${Timestamp.now().toDate()}",
          roomId: controller.roomId,
          senderId: UserService.currentUser.value?.uid ?? "",
          timestamp: Timestamp.now().toDate(),
          callModel: callModel,
        ));
      }
    } catch (e) {
      print('❌ Error handling call: $e');
    }
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
}