import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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

import 'package:crypted_app/app/modules/home/controllers/message_search_controller.dart';
import 'package:crypted_app/app/modules/home/widgets/search_result_items.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller if it doesn't exist
    if (!Get.isRegistered<MessageSearchController>()) {
      Get.put(MessageSearchController());
    }

    return GetBuilder<MessageSearchController>(
      builder: (controller) => Scaffold(
        backgroundColor: ColorsManager.white,
        body: Container(
          color: ColorsManager.navbarColor,
          child: Column(
            children: [
              // Enhanced Search Header
              Container(
                margin: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: ColorsManager.navbarColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Search icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          controller.searchQuery.isNotEmpty ? Iconsax.search_status_1 : Iconsax.search_normal,
                          key: ValueKey(controller.searchQuery.isNotEmpty),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Search box
                    Expanded(
                      child: CustomTextField(
                        borderRadius: Radiuss.large,
                        contentPadding: false,
                        height: Sizes.size48,
                        prefixIcon: null,
                        hint: Constants.kSearch.tr,
                        fillColor: ColorsManager.offWhite,
                        borderColor: ColorsManager.navbarColor,
                        hintColor: ColorsManager.grey,
                        textColor: ColorsManager.black,
                        onChange: (value) {
                          controller.searchMessages(value);
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cancel button
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          Constants.kCancel.tr,
                          style: StylesManager.semiBold(
                            fontSize: FontSize.small,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Results
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Obx(() {
                    if (controller.isSearching) {
                      return const CustomLoading();
                    }

                    if (controller.searchQuery.isEmpty) {
                      return _buildSearchSuggestions();
                    }

                    if (controller.searchResults.isEmpty && controller.userResults.isEmpty) {
                      return _buildNoResults();
                    }

                    return _buildSearchResults(controller);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSearchSuggestions() {
    return Container(
      padding: const EdgeInsets.all(Paddings.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Suggestions',
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.primary,
            ),
          ),
          const SizedBox(height: Sizes.size24),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSuggestionItem(Iconsax.message_text_1, 'Recent messages', 'Find your latest conversations'),
                _buildSuggestionItem(Iconsax.gallery, 'Photos', 'Search through shared images'),
                _buildSuggestionItem(Iconsax.video_play, 'Videos', 'Find video messages and clips'),
                _buildSuggestionItem(Iconsax.document_text, 'Documents', 'Locate files and documents'),
                _buildSuggestionItem(Iconsax.music, 'Audio', 'Find voice messages and audio files'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSuggestionItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.size12),
      decoration: BoxDecoration(
        color: ColorsManager.offWhite,
        borderRadius: BorderRadius.circular(Radiuss.large),
        border: Border.all(
          color: ColorsManager.navbarColor,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorsManager.primary,
            borderRadius: BorderRadius.circular(Radiuss.small),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: StylesManager.semiBold(
            fontSize: FontSize.medium,
            color: ColorsManager.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: ColorsManager.grey,
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          color: ColorsManager.primary,
          size: 20,
        ),
        onTap: () {
          // TODO: Implement suggestion tap functionality
        },
      ),
    );
  }

  static Widget _buildNoResults() {
    return Container(
      color: ColorsManager.offWhite,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Icon(
                Iconsax.search_status_1,
                key: const ValueKey('no-results'),
                size: Sizes.size70,
                color: ColorsManager.grey,
              ),
            ),
            const SizedBox(height: Sizes.size20),
            Text(
              'No results found',
              style: StylesManager.semiBold(
                fontSize: FontSize.large,
                color: ColorsManager.grey,
              ),
            ),
            const SizedBox(height: Sizes.size8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Try searching for messages, users, photos, videos, or documents',
                style: StylesManager.regular(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSearchResults(MessageSearchController controller) {
    return ListView(
      children: [
        // Message Results
        if (controller.searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Text(
              'Messages',
              style: StylesManager.semiBold(fontSize: FontSize.large),
            ),
          ),
          ...controller.searchResults.map((message) => _buildMessageResultItem(message)),
        ],

        // User Results
        if (controller.userResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(Paddings.large),
            child: Text(
              'Users',
              style: StylesManager.semiBold(fontSize: FontSize.large),
            ),
          ),
          ...controller.userResults.map((user) => UserSearchResultItem(user: user)),
        ],
      ],
    );
  }

  static Widget _buildMessageResultItem(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.navbarColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to chat - this will be handled by the MessageSearchResultItem
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Chat avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Iconsax.message_text_1,
                  color: ColorsManager.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat name and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getChatNameForMessage(message),
                            style: StylesManager.semiBold(
                              fontSize: FontSize.medium,
                              color: ColorsManager.black,
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

                    const SizedBox(height: 4),

                    // Message preview
                    Text(
                      _getMessageContent(message),
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow icon
              Icon(
                Iconsax.arrow_right_3,
                color: ColorsManager.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMessageTime(DateTime time) {
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

  static String _getMessageContent(Message message) {
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

  static Color _getMessageTypeColor(Message message) {
    if (message is TextMessage) {
      return ColorsManager.primary;
    } else if (message is PhotoMessage) {
      return Colors.green;
    } else if (message is VideoMessage) {
      return Colors.purple;
    } else if (message is AudioMessage) {
      return Colors.orange;
    } else if (message is FileMessage) {
      return Colors.blue;
    } else if (message is ContactMessage) {
      return Colors.teal;
    } else if (message is LocationMessage) {
      return Colors.red;
    } else if (message is PollMessage) {
      return Colors.amber;
    } else if (message is CallMessage) {
      return Colors.indigo;
    } else {
      return ColorsManager.grey;
    }
  }

  static String _getMessageTypeLabel(Message message) {
    if (message is TextMessage) {
      return 'Text';
    } else if (message is PhotoMessage) {
      return 'Photo';
    } else if (message is VideoMessage) {
      return 'Video';
    } else if (message is AudioMessage) {
      return 'Audio';
    } else if (message is FileMessage) {
      return 'File';
    } else if (message is ContactMessage) {
      return 'Contact';
    } else if (message is LocationMessage) {
      return 'Location';
    } else if (message is PollMessage) {
      return 'Poll';
    } else if (message is CallMessage) {
      return message.callModel.callType == CallType.video ? 'Video Call' : 'Voice Call';
    } else {
      return 'Message';
    }
  }

  static String _getChatNameForMessage(Message message) {
    // TODO: Implement proper chat name resolution
    // For now, return a generic name based on the room ID
    // In a real implementation, you'd want to:
    // 1. Query the chat room data using the roomId
    // 2. Get the chat name from the chat room
    // 3. Handle both group chats and private chats

    return message.roomId.isNotEmpty ? 'Chat ${message.roomId.substring(0, 8)}...' : 'Unknown Chat';
  }
}
