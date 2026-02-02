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
export 'package:crypted_app/app/modules/home/controllers/message_search_controller.dart'
    show MessageTypeFilter;
import 'package:crypted_app/app/modules/home/widgets/search_result_items.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

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
        backgroundColor: ColorsManager.scaffoldBg(context),
        body: Container(
          color: ColorsManager.scaffoldBg(context),
          child: Column(
            children: [
              // Enhanced Search Header
              Container(
                margin: const EdgeInsets.only(
                    top: 50, left: 20, right: 20, bottom: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: ColorsManager.surfaceAdaptive(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: ColorsManager.dividerAdaptive(context),
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
                          controller.searchQuery.isNotEmpty
                              ? Iconsax.search_status_1
                              : Iconsax.search_normal,
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
                        borderColor: ColorsManager.dividerAdaptive(context),
                        hintColor: ColorsManager.grey,
                        textColor: ColorsManager.textPrimaryAdaptive(context),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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

              // Filter Chips (shown when there are search results)
              Obx(() {
                if (controller.searchQuery.isNotEmpty &&
                    !controller.isSearching) {
                  return _buildFilterChips(controller);
                }
                return const SizedBox.shrink();
              }),

              // Search Results
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: ColorsManager.surfaceAdaptive(context),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Obx(() {
                    if (controller.isSearching) {
                      return const CustomLoading();
                    }

                    if (controller.searchQuery.isEmpty) {
                      return _buildRecentSearches(controller);
                    }

                    if (controller.searchResults.isEmpty &&
                        controller.userResults.isEmpty) {
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

  static Widget _buildFilterChips(MessageSearchController controller) {
    final filters = [
      {'type': MessageTypeFilter.all, 'label': 'All', 'icon': Iconsax.message},
      {
        'type': MessageTypeFilter.text,
        'label': 'Text',
        'icon': Iconsax.message_text
      },
      {
        'type': MessageTypeFilter.photo,
        'label': 'Photos',
        'icon': Iconsax.gallery
      },
      {
        'type': MessageTypeFilter.video,
        'label': 'Videos',
        'icon': Iconsax.video_play
      },
      {
        'type': MessageTypeFilter.audio,
        'label': 'Audio',
        'icon': Iconsax.music
      },
      {
        'type': MessageTypeFilter.file,
        'label': 'Files',
        'icon': Iconsax.document_text
      },
      {'type': MessageTypeFilter.poll, 'label': 'Polls', 'icon': Iconsax.chart},
      {'type': MessageTypeFilter.call, 'label': 'Calls', 'icon': Iconsax.call},
      {
        'type': MessageTypeFilter.contact,
        'label': 'Contacts',
        'icon': Iconsax.user
      },
      {
        'type': MessageTypeFilter.location,
        'label': 'Location',
        'icon': Iconsax.location
      },
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(() {
              final filter = filters[index];
              final filterType = filter['type'] as MessageTypeFilter;
              final isSelected = controller.selectedFilter == filterType;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 18,
                        color:
                            isSelected ? Colors.white : ColorsManager.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['label'] as String,
                        style: StylesManager.semiBold(
                          fontSize: FontSize.small,
                          color: isSelected
                              ? Colors.white
                              : ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                    ],
                  ),
                  onSelected: (_) => controller.selectFilter(filterType),
                  backgroundColor: ColorsManager.surfaceAdaptive(context),
                  selectedColor: ColorsManager.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? ColorsManager.primary
                          : ColorsManager.dividerAdaptive(context),
                      width: 2,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  showCheckmark: false,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  static Widget _buildRecentSearches(MessageSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(Paddings.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: StylesManager.bold(
                  fontSize: FontSize.xLarge,
                  color: ColorsManager.primary,
                ),
              ),
              if (controller.recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () => controller.clearRecentSearches(),
                  child: Text(
                    'Clear',
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Sizes.size16),
          Expanded(
            child: Obx(() {
              if (controller.recentSearches.isEmpty) {
                return _buildSearchSuggestions(controller);
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.recentSearches.length,
                itemBuilder: (context, index) {
                  final search = controller.recentSearches[index];
                  return _buildRecentSearchItem(search, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  static Widget _buildRecentSearchItem(
      String search, MessageSearchController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.size8),
      decoration: BoxDecoration(
        color: ColorsManager.offWhite,
        borderRadius: BorderRadius.circular(Radiuss.normal),
        border: Border.all(
          color: ColorsManager.navbarColor,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Radiuss.small),
          ),
          child: Icon(
            Iconsax.clock,
            color: ColorsManager.grey,
            size: 20,
          ),
        ),
        title: Text(
          search,
          style: StylesManager.medium(
            fontSize: FontSize.medium,
            color: ColorsManager.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          color: ColorsManager.primary,
          size: 18,
        ),
        onTap: () => controller.searchFromRecent(search),
      ),
    );
  }

  static Widget _buildSearchSuggestions(MessageSearchController controller) {
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
                _buildSuggestionItem(
                  Iconsax.message_text_1,
                  'Recent messages',
                  'Find your latest conversations',
                  onTap: () => controller.browseByType(MessageTypeFilter.text),
                ),
                _buildSuggestionItem(
                  Iconsax.gallery,
                  'Photos',
                  'Search through shared images',
                  onTap: () => controller.browseByType(MessageTypeFilter.photo),
                ),
                _buildSuggestionItem(
                  Iconsax.video_play,
                  'Videos',
                  'Find video messages and clips',
                  onTap: () => controller.browseByType(MessageTypeFilter.video),
                ),
                _buildSuggestionItem(
                  Iconsax.document_text,
                  'Documents',
                  'Locate files and documents',
                  onTap: () => controller.browseByType(MessageTypeFilter.file),
                ),
                _buildSuggestionItem(
                  Iconsax.music,
                  'Audio',
                  'Find voice messages and audio files',
                  onTap: () => controller.browseByType(MessageTypeFilter.audio),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSuggestionItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
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
        onTap: onTap,
      ),
    );
  }

  static Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with background
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: const ValueKey('no-results'),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Iconsax.search_status_1,
                  size: Sizes.size60,
                  color: ColorsManager.primary,
                ),
              ),
            ),
            const SizedBox(height: Sizes.size32),

            // Title
            Text(
              'No results found',
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: ColorsManager.black,
              ),
            ),
            const SizedBox(height: Sizes.size12),

            // Subtitle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Try using different keywords or check your spelling',
                style: StylesManager.regular(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Sizes.size24),

            // Suggestions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorsManager.offWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorsManager.navbarColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.information,
                        size: 20,
                        color: ColorsManager.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search Tips',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: ColorsManager.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Use filters to narrow your search'),
                  _buildTipItem('Search by message type'),
                  _buildTipItem('Try shorter or more general keywords'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ColorsManager.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSearchResults(MessageSearchController controller) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 16),

        // Message Results
        if (controller.searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Paddings.large, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: StylesManager.bold(fontSize: FontSize.large),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.searchResults.length}',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.small,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...controller.searchResults
              .map((message) => _buildMessageResultItem(message)),
        ],

        // User Results
        if (controller.userResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Paddings.large, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Users',
                  style: StylesManager.bold(fontSize: FontSize.large),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.userResults.length}',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.small,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...controller.userResults
              .map((user) => UserSearchResultItem(user: user)),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  static Widget _buildMessageResultItem(Message message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorsManager.navbarColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to chat - this will be handled by the MessageSearchResultItem
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Chat name, type badge, and time
              Row(
                children: [
                  // Chat avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          _getMessageTypeColor(message).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getMessageTypeIcon(message),
                      color: _getMessageTypeColor(message),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Chat name and type badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getChatNameForMessage(message),
                          style: StylesManager.semiBold(
                            fontSize: FontSize.medium,
                            color: ColorsManager.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getMessageTypeColor(message)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getMessageTypeLabel(message),
                            style: StylesManager.medium(
                              fontSize: FontSize.xSmall,
                              color: _getMessageTypeColor(message),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp ?? DateTime.now()),
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Iconsax.arrow_right_3,
                        color: ColorsManager.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
      ),
    );
  }

  static IconData _getMessageTypeIcon(Message message) {
    if (message is TextMessage) {
      return Iconsax.message_text;
    } else if (message is PhotoMessage) {
      return Iconsax.gallery;
    } else if (message is VideoMessage) {
      return Iconsax.video_play;
    } else if (message is AudioMessage) {
      return Iconsax.music;
    } else if (message is FileMessage) {
      return Iconsax.document_text;
    } else if (message is ContactMessage) {
      return Iconsax.user;
    } else if (message is LocationMessage) {
      return Iconsax.location;
    } else if (message is PollMessage) {
      return Iconsax.chart;
    } else if (message is CallMessage) {
      return Iconsax.call;
    } else {
      return Iconsax.message;
    }
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
      return message.callModel.callType == CallType.video
          ? 'Video Call'
          : 'Voice Call';
    } else {
      return 'Message';
    }
  }

  static String _getChatNameForMessage(Message message) {
    try {
      // Get chat room data to resolve proper chat name
      final chatDataSource = ChatDataSources();
      final currentUserId = UserService.currentUserValue?.uid ?? '';

      // For immediate display, try to get cached data first
      // In a production app, you'd want to cache this data
      _resolveChatName(chatDataSource, message.roomId, currentUserId)
          .then((chatName) {
        // Update the UI with the resolved name
        // This would require state management, so for now we'll use a placeholder
        return chatName;
      }).catchError((e) {
        print('Error resolving chat name: $e');
        return _getFallbackChatName(message.roomId);
      });

      // Return fallback name immediately for UI responsiveness
      return _getFallbackChatName(message.roomId);
    } catch (e) {
      print('Error in chat name resolution: $e');
      return _getFallbackChatName(message.roomId);
    }
  }

  static Future<String> _resolveChatName(ChatDataSources chatDataSource,
      String roomId, String currentUserId) async {
    try {
      final chatRoom = await chatDataSource.getChatRoomById(roomId);

      if (chatRoom == null) {
        return _getFallbackChatName(roomId);
      }

      // Handle group chats
      if (chatRoom.isGroupChat == true &&
          chatRoom.name != null &&
          chatRoom.name!.isNotEmpty) {
        return chatRoom.name!;
      }

      // Handle private chats (1-on-1)
      if (chatRoom.membersIds != null && chatRoom.membersIds!.length == 2) {
        // Find the other user (not current user)
        final otherUserId =
            chatRoom.membersIds!.firstWhere((id) => id != currentUserId);
        if (otherUserId.isNotEmpty) {
          // Get the other user's profile
          final otherUser = await UserService().getProfile(otherUserId);
          if (otherUser != null &&
              otherUser.fullName != null &&
              otherUser.fullName!.isNotEmpty) {
            return otherUser.fullName!;
          }
        }
      }

      // Fallback to group name if available
      if (chatRoom.name != null && chatRoom.name!.isNotEmpty) {
        return chatRoom.name!;
      }

      // Final fallback
      return _getFallbackChatName(roomId);
    } catch (e) {
      print('Error resolving chat name: $e');
      return _getFallbackChatName(roomId);
    }
  }

  static String _getFallbackChatName(String roomId) {
    return roomId.isNotEmpty
        ? 'Chat ${roomId.substring(0, 8)}...'
        : 'Unknown Chat';
  }
}
