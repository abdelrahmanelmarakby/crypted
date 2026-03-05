import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageSearchResultItem extends StatelessWidget {
  final Message message;
  final String chatName;

  const MessageSearchResultItem({
    super.key,
    required this.message,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToChat(context),
      borderRadius: BorderRadius.circular(Radiuss.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chatName,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatMessageTime(message.timestamp ?? DateTime.now()),
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size4),
            Text(
              _getMessageContent(message),
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.textPrimaryAdaptive(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Sizes.size8),
            Divider(
              height: 1,
              color: ColorsManager.navbarColor,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    try {
      // Check if roomId is empty
      if (message.roomId.isEmpty) {
        print('❌ Error: message.roomId is empty');
        Get.snackbar(
          'Error',
          'Cannot navigate to chat - invalid room ID',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.error,
          colorText: Colors.white,
        );
        return;
      }

      // Navigate to the chat screen with the message's roomId
      Get.toNamed('/chat', arguments: {
        'roomId': message.roomId,
        'useSessionManager': false, // Use legacy mode for now
      });

      print('🔍 Navigating to chat: ${message.roomId}');
    } catch (e) {
      print('❌ Error navigating to chat: $e');
      // Fallback to basic navigation
      try {
        if (message.roomId.isNotEmpty) {
          Get.toNamed('/chat', arguments: {
            'roomId': message.roomId,
          });
        } else {
          Get.snackbar(
            'Error',
            'Cannot navigate to chat - invalid room ID',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ColorsManager.error,
            colorText: Colors.white,
          );
        }
      } catch (fallbackError) {
        print('❌ Fallback navigation also failed: $fallbackError');
        Get.snackbar(
          'Error',
          'Failed to navigate to chat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.error,
          colorText: Colors.white,
        );
      }
    }
  }

  String _getMessageContent(Message message) {
    // Handle different message types
    if (message is TextMessage) {
      return message.text;
    } else if (message is PhotoMessage) {
      return '📷 Photo';
    } else if (message is VideoMessage) {
      return '🎥 Video';
    } else if (message is AudioMessage) {
      return '🎵 Audio';
    } else if (message is FileMessage) {
      return '📄 File: ${message.fileName}';
    } else if (message is ContactMessage) {
      return '👤 Contact';
    } else if (message is LocationMessage) {
      return '📍 Location';
    } else if (message is PollMessage) {
      return '📊 Poll';
    } else if (message is CallMessage) {
      return '📞 ${message.callModel.callType == CallType.video ? 'Video' : 'Voice'} Call';
    } else {
      return 'Message';
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

class UserSearchResultItem extends StatelessWidget {
  final SocialMediaUser user;

  const UserSearchResultItem({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _startNewConversation(context),
      borderRadius: BorderRadius.circular(Radiuss.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.small,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: Radiuss.small,
              backgroundImage:
                  user.imageUrl != null && user.imageUrl!.isNotEmpty
                      ? NetworkImage(user.imageUrl!)
                      : null,
              child: user.imageUrl == null || user.imageUrl!.isEmpty
                  ? Text(
                      user.fullName?.substring(0, 1).toUpperCase() ?? '?',
                      style: StylesManager.medium(fontSize: FontSize.medium),
                    )
                  : null,
            ),
            const SizedBox(width: Sizes.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? 'Unknown User',
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color: ColorsManager.textPrimaryAdaptive(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Sizes.size2),
                  Text(
                    'Start new conversation',
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: Sizes.size16,
              color: ColorsManager.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _startNewConversation(BuildContext context) async {
    try {
      print('🔍 Starting conversation with: ${user.fullName} (${user.uid})');

      // Get the HomeController to create a new chat
      final homeController = Get.find<HomeController>();

      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        barrierDismissible: false,
      );

      // Create a new private chat room with this user
      await homeController.createNewPrivateChatRoom(user);

      // Close the loading dialog
      Get.back();

      print('✅ Successfully navigated to chat with: ${user.fullName}');
    } catch (e) {
      print('❌ Error starting conversation: $e');

      // Close loading dialog if it's open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to start conversation. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: Colors.white,
      );
    }
  }
}
