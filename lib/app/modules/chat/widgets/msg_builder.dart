import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart'
    as image;
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/audio_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/call_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/contact_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/event_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/file_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/image_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/location_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/poll_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/text_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/video_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/uploading_message.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_reactions_display.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class MessageBuilder extends GetView<ChatController> {
  const MessageBuilder(
    this.senderType, {
    super.key,
    required this.messageModel,
    this.senderName,
    this.timestamp,
    this.senderImage,
  });
  final Message messageModel;
  final bool senderType;
  final String? timestamp;
  final String? senderName;
  final String? senderImage;
  @override
  Widget build(BuildContext context) {
    // Safely parse timestamp with explicit empty string check
    DateTime time;
    if (timestamp != null && timestamp!.isNotEmpty) {
      time = DateTime.tryParse(timestamp!) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }
    int hour = time.hour;
    String amPm = '';
    if (time.hour == 0) {
      hour = 12;
      amPm = 'AM';
    } else if (time.hour == 12) {
      amPm = 'PM';
    } else if (time.hour > 12) {
      hour = time.hour - 12;
      amPm = 'PM';
    } else {
      amPm = 'AM';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Paddings.xSmall,
        vertical: Paddings.xXSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (senderType)
            Container(
              width: Sizes.size32,
              height: Sizes.size32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorsManager.primary,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radiuss.xXLarge50),
                child: AppCachedNetworkImage(
                  imageUrl: senderImage ?? '',
                  isCircular: true,
                ),
              ),
            ),
          const SizedBox(width: Sizes.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: senderType == true
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (senderType)
                  Text(
                    senderName ?? '',
                    style: StylesManager.regular(fontSize: FontSize.xSmall),
                  ),
                const SizedBox(height: Sizes.size4),
                Obx(() {
                  // Search result highlighting
                  final isCurrentResult = controller.isCurrentSearchResult(messageModel);
                  final isAnyResult = controller.isSearchResult(messageModel);

                  return GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      controller.handleMessageLongPress(messageModel);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: senderType == true
                            ? ColorsManager.messFriendColor
                            : ColorsManager.navbarColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Sizes.size16),
                          topRight: Radius.circular(Sizes.size16),
                          bottomLeft: senderType == false
                              ? Radius.circular(Sizes.size16)
                              : Radius.circular(0),
                          bottomRight: senderType == false
                              ? Radius.circular(0)
                              : Radius.circular(Sizes.size16),
                        ),
                        // Search result highlighting
                        border: isCurrentResult
                            ? Border.all(
                                color: ColorsManager.primary,
                                width: 2.0,
                              )
                            : isAnyResult
                                ? Border.all(
                                    color: ColorsManager.primary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  )
                                : null,
                        // Add subtle glow for current search result
                        boxShadow: isCurrentResult
                            ? [
                                BoxShadow(
                                  color: ColorsManager.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(Sizes.size12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Forwarded message indicator
                        if (messageModel.isForwarded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Sizes.size8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forward_rounded,
                                  size: Sizes.size14,
                                  color: ColorsManager.grey.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: Sizes.size4),
                                Text(
                                  'Forwarded',
                                  style: StylesManager.regular(
                                    fontSize: FontSize.xSmall,
                                    color: ColorsManager.grey.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        buildMessageContent(context, messageModel),

                        // Message reactions display
                        if (messageModel.reactions.isNotEmpty)
                          MessageReactionsDisplay(
                            reactions: messageModel.reactions,
                            currentUserId: UserService.currentUser.value?.uid ?? '',
                            onReactionTap: (emoji) {
                              controller.toggleReaction(messageModel, emoji);
                            },
                            onShowDetails: () {
                              // Show details handled by long press on reaction
                            },
                          ),

                        const SizedBox(height: Sizes.size4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          //  mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (!senderType)
                              const Icon(
                                Icons.done,
                                color: ColorsManager.grey,
                                size: Sizes.size18,
                              ),
                            const SizedBox(width: Sizes.size4),
                            Text(
                              '$hour:${time.minute.toString().padLeft(2, '0')} $amPm',
                              style: StylesManager.regular(
                                fontSize: FontSize.xSmall,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageContent(BuildContext context, Message msg) {
    // Handle deleted messages
    if (msg.isDeleted) {
      // Only show deleted messages to the sender for restore option
      if (msg.senderId != UserService.currentUser.value?.uid) {
        return const SizedBox(); // Hide deleted messages from other users
      }

      // Show deleted message with restore option for the sender
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => controller.restoreMessage(msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Restore',
                  style: TextStyle(
                    color: ColorsManager.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Handle non-deleted messages normally
    // DEBUG: Log message type for troubleshooting
    debugPrint("🔍 Building message widget: type=${msg.runtimeType}, id=${msg.id}");

    try {
      switch (msg) {
        case AudioMessage():
          return AudioMessageWidget(
            key: ValueKey(msg.id),
            message: msg,
          );
        case CallMessage():
          return CallMessageWidget(
            message: msg,
          );

        case FileMessage():
          return FileMessageWidget(
            message: msg,
          );

        case LocationMessage():
          return LocationMessageWidget(
            message: msg,
          );

        case TextMessage():
          return TextMessageWidget(
            message: msg,
          );

        case image.PhotoMessage():
          return ImageMessageWidget(
            message: msg,
          );

        case VideoMessage():
          return VideoMessageWidget(
            message: msg,
          );

        case ContactMessage():
          return ContactMessageWidget(
            message: msg,
          );

        case PollMessage():
          return PollMessageWidget(
            message: msg,
          );

        case EventMessage():
          return EventMessageWidget(
            eventMessage: msg,
            isMe: msg.senderId == UserService.currentUser.value?.uid,
          );

        case UploadingMessage():
          return UploadingMessageWidget(
            message: msg,
            onCancel: () => controller.cancelUpload(msg.id),
            onRetry: () => controller.retryUpload(msg.id),
          );

        default:
          debugPrint("⚠️ Unknown message type: ${msg.runtimeType}");
          return const SizedBox();
      }
    } catch (e, stack) {
      debugPrint("❌ Error building message widget: $e");
      debugPrint("❌ Stack trace: $stack");
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error loading message: ${msg.runtimeType}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }
}
