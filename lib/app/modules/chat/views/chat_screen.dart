import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/animated_message_item.dart';
import 'package:crypted_app/app/modules/chat/widgets/attachment_widget.dart';
import 'package:crypted_app/app/modules/chat/widgets/blocked_chat_banner.dart';
import 'package:crypted_app/app/modules/chat/widgets/chat_wallpaper_picker.dart';
import 'package:crypted_app/app/modules/chat/widgets/chat_search_bar.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/modules/chat/widgets/ui/swipeable_timestamp.dart';
import 'package:crypted_app/app/modules/chat/widgets/ui/unread_message_divider.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/app/modules/chat/widgets/scheduled_messages_list_sheet.dart';
import 'package:crypted_app/app/data/data_source/scheduled_message_data_source.dart';
import 'package:crypted_app/app/modules/chat/widgets/icebreaker_prompts.dart';
// ARCH-004: Removed provider import - using GetX observables only

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
                      color: ColorsManager.surfaceAdaptive(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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

        // Wait for chatDataSource to be initialized
        if (!controller.isChatDataSourceReady.value) {
          return Scaffold(
            backgroundColor: ColorsManager.navbarColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ARCH-004: Using StreamBuilder with direct Firestore stream for reliable message loading
        // This provides real-time updates directly from Firestore
        return StreamBuilder<List<Message>>(
          stream: controller.chatDataSource
              .getLivePrivateMessage(controller.roomId),
          initialData: const [],
          builder: (context, snapshot) {
            // DEBUG: Log stream state for troubleshooting
            debugPrint(
                "📨 StreamBuilder state: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, connectionState=${snapshot.connectionState}");

            // Handle stream errors gracefully
            if (snapshot.hasError) {
              debugPrint("❌ Error loading messages: ${snapshot.error}");
              debugPrint("❌ Stack trace: ${snapshot.stackTrace}");
            }

            // Get messages from Firestore stream
            final firestoreMessages = snapshot.data ?? [];

            debugPrint(
                "📨 Firestore messages count: ${firestoreMessages.length}, roomId: ${controller.roomId}");

            // OPTIMISTIC UI FIX: Use Obx to react to both Firestore stream AND local message changes
            return Obx(() {
              // Get uploading messages from local controller state (reactive via Obx)
              final localUploadingMessages =
                  controller.messages.whereType<UploadingMessage>().toList();

              // Combine: uploading messages first (they're newest), then Firestore messages
              final messages = [
                ...localUploadingMessages,
                ...firestoreMessages
              ];

              debugPrint(
                  "📨 Total messages: ${messages.length} (${localUploadingMessages.length} uploading + ${firestoreMessages.length} from Firestore)");

              return Scaffold(
                backgroundColor: ColorsManager.navbarColor,
                extendBodyBehindAppBar: false,
                appBar: controller.isSearchMode.value
                    ? null
                    : _buildAppBar(context, _getOtherUserForAppBar()),
                body: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? ColorsManager.darkNavbar
                              : ColorsManager.navbarColor,
                          ColorsManager.surfaceAdaptive(context)
                              .withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.3],
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Column(
                        children: [
                          // Search bar (shown when in search mode)
                          _buildSearchBar(),
                          // UI Migration: Offline status indicator
                          _buildOfflineIndicator(),
                          // Blocked chat banner (for private chats)
                          _buildBlockedChatBanner(),
                          // Messages area
                          Expanded(
                            child: Obx(() {
                              final wallpaper = controller.chatWallpaper.value;
                              final hasGradient =
                                  wallpaper.type == WallpaperType.gradient &&
                                      wallpaper.gradientColors != null &&
                                      wallpaper.gradientColors!.length >= 2;
                              final imageProvider = wallpaper.toImageProvider();
                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: hasGradient || imageProvider != null
                                      ? null
                                      : (wallpaper.type == WallpaperType.color
                                          ? wallpaper.solidColor
                                          : ColorsManager.surfaceAdaptive(
                                              context)),
                                  gradient: hasGradient
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: wallpaper.gradientColors!,
                                        )
                                      : null,
                                  image: imageProvider != null
                                      ? DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: messages.isEmpty
                                      ? IcebreakerPrompts(
                                          otherUserName:
                                              _getOtherUserForAppBar()
                                                  ?.fullName,
                                          isGroupChat:
                                              controller.isGroupChat.value,
                                          onPromptSelected: (text) {
                                            controller.sendQuickTextMessage(
                                                text, controller.roomId);
                                          },
                                        )
                                      : ListView.builder(
                                          // FIX: Attach ScrollController for search navigation
                                          controller: controller
                                              .messageScrollController,
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          reverse: true,
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 20, 16, 8),
                                          itemCount: messages.length,
                                          // PERF-015: Added cache extent for smoother scrolling
                                          cacheExtent: 500,
                                          itemBuilder: (context, index) {
                                            final message = messages[index];
                                            // Register GlobalKey for precise scrolling
                                            final messageKey =
                                                _getOrCreateMessageKey(
                                                    message.id);

                                            // Use RepaintBoundary for performance optimization
                                            return RepaintBoundary(
                                              key: messageKey,
                                              child: _buildMessageItem(
                                                messages,
                                                index,
                                                UserService.currentUser.value,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              );
                            }),
                          ),

                          // Input area - shows blocked input bar if blocked
                          _buildInputArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  // ARCH-004: State management consolidated - removed Provider dependency

  /// Safely get the other user for app bar display
  dynamic _getOtherUserForAppBar() {
    try {
      // Try to find other user from controller members
      if (controller.members.isNotEmpty) {
        final otherUsers = controller.members
            .where((user) => user.uid != UserService.currentUser.value?.uid);
        if (otherUsers.isNotEmpty) {
          return otherUsers.first;
        }
      }

      // Fallback to current user if no other user found
      return UserService.currentUser.value ??
          SocialMediaUser(fullName: "Unknown User");
    } catch (e) {
      print("❌ Error getting other user for app bar: $e");
      return SocialMediaUser(fullName: "Unknown User");
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic otherUser) {
    return AppBar(
      backgroundColor: ColorsManager.surfaceAdaptive(context),
      elevation: 0,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: () => Get.back(),
          tooltip: 'Back',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorsManager.darkSurfaceVariant.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: ColorsManager.textPrimaryAdaptive(context),
              size: 18,
            ),
          ),
        ),
      ),
      title: Semantics(
        label: 'Chat info. Double tap to view details',
        button: true,
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (controller.isGroupChat.value) {
              // Navigate to group info for group chats
              final result = await Get.toNamed(
                Routes.GROUP_INFO,
                arguments: {
                  "chatName": controller.chatName.value,
                  "chatDescription": controller.chatDescription.value,
                  "memberCount": controller.memberCount.value,
                  "members": controller.members,
                  "groupImageUrl": controller.groupImageUrl.value,
                  "roomId": controller.roomId,
                },
              );
              // Handle search request from group info
              if (result is Map && result['openSearch'] == true) {
                controller.openSearch();
              }
            } else {
              // Navigate to contact info for individual chats
              final result = await Get.toNamed(
                Routes.CONTACT_INFO,
                arguments: {
                  "user": otherUser,
                  "roomId": controller.roomId,
                },
              );
              // Handle search request from contact info
              if (result is Map && result['openSearch'] == true) {
                controller.openSearch();
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: ColorsManager.surfaceAdaptive(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: controller.isGroupChat.value
                          ? _buildGroupAvatar()
                          : _buildPrivateAvatar(otherUser),
                    ),
                    // Online status indicator - only for private chats
                    if (!controller.isGroupChat.value)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Semantics(
                          label: 'Offline',
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
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // User/Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.isGroupChat.value
                            ? controller.chatName.value
                            : otherUser.fullName ?? "Unknown User",
                        style: StylesManager.bold(
                          color: ColorsManager.textPrimaryAdaptive(context),
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.isGroupChat.value
                            ? "${controller.memberCount.value} members"
                            : "Offline", // You can make this dynamic
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
      ),
      actions: [
        // Search button - available for all chat types
        IconButton(
          onPressed: () => controller.openSearch(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.search_normal,
              color: ColorsManager.primary,
              size: 20,
            ),
          ),
          tooltip: 'Search messages',
        ),

        // Scheduled messages button
        _buildScheduledMessagesButton(context),

        // Show different actions based on chat type
        if (controller.isGroupChat.value) ...[
          // Group management button
          IconButton(
            onPressed: () => _showGroupManagementMenu(context),
            tooltip: 'Group options',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert,
                color: ColorsManager.primary,
                size: 20,
              ),
            ),
          ),
        ] else ...[
          // Enhanced call buttons for private chats with improved layout
          // Features:
          // - Better visual hierarchy with proper spacing
          // - Container wrapper for consistent margins
          // - Color-coded icons (green for audio, blue for video)
          // - Smooth animations and micro-interactions
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio call button with green accent
                // ARCH-008: Now uses controller's call handler
                _buildCallButton(
                  icon: const Icon(
                    Iconsax.call_add,
                    color: ColorsManager.primary,
                    size: 20,
                  ),
                  onPressed: () =>
                      controller.startAudioCall(otherUser as SocialMediaUser),
                  otherUser: otherUser,
                  tooltip: 'Audio call',
                ),

                const SizedBox(width: 8),

                // Video call button with blue accent
                // ARCH-008: Now uses controller's call handler
                _buildCallButton(
                  icon: const Icon(
                    Iconsax.video,
                    color: ColorsManager.primary,
                    size: 20,
                  ),
                  onPressed: () =>
                      controller.startVideoCall(otherUser as SocialMediaUser),
                  otherUser: otherUser,
                  tooltip: 'Video call',
                ),
              ],
            ),
          ),
        ],

        const SizedBox(width: 8),
      ],
    );
  }

  /// Enhanced call button widget with Apple-style design
  /// Features:
  /// - Clean, minimal design without gradients or shadows
  /// - Distinct colors for audio (green) and video (blue) calls
  /// - Smooth animations and micro-interactions
  /// - Proper spacing and visual hierarchy
  Widget _buildCallButton({
    required Widget icon,
    required VoidCallback onPressed,
    required dynamic otherUser,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }

  /// Scheduled messages button with live badge count.
  /// Tapping opens a list sheet showing all pending scheduled messages
  /// for this chat room, with options to cancel or reschedule.
  Widget _buildScheduledMessagesButton(BuildContext context) {
    return FutureBuilder<int>(
      future: ScheduledMessageDataSource()
          .getPendingCountForRoom(controller.roomId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        // Only show the button if there are pending scheduled messages
        if (count == 0) return const SizedBox.shrink();

        return IconButton(
          onPressed: () => ScheduledMessagesListSheet.show(
            context: context,
            chatRoomId: controller.roomId,
          ),
          tooltip: 'Scheduled messages',
          icon: Badge(
            label: Text(
              '$count',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: ColorsManager.primary,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.clock,
                color: ColorsManager.primary,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get or create a GlobalKey for a message (for precise scroll-to functionality)
  GlobalKey _getOrCreateMessageKey(String messageId) {
    // Check if controller already has a key for this message
    if (controller.messageKeys.containsKey(messageId)) {
      return controller.messageKeys[messageId]!;
    }
    // Create and register a new key
    final key = GlobalKey(debugLabel: 'msg_$messageId');
    controller.registerMessageKey(messageId, key);
    return key;
  }

  Widget _buildMessageItem(
      List<Message> messages, int index, dynamic otherUser) {
    final Message? previousMsg =
        index != messages.length - 1 ? messages[index + 1] : null;
    final Message currentMsg = messages[index];

    final bool isMe = currentMsg.senderId == UserService.currentUser.value?.uid;
    final DateTime currentTime = currentMsg.timestamp;
    final DateTime? previousTime = previousMsg?.timestamp;

    // BUG-003 FIX: Get the actual sender from message.senderId for group chats
    // Instead of using otherUser which only works for 1-on-1 chats
    String? senderName;
    String? senderImage;

    if (isMe) {
      senderName = UserService.currentUser.value?.fullName;
      senderImage = UserService.currentUser.value?.imageUrl;
    } else if (controller.isGroupChat.value) {
      // For group chats, find the actual sender from members list
      final sender = controller.getMemberById(currentMsg.senderId);
      senderName = sender?.fullName ?? 'Unknown';
      senderImage = sender?.imageUrl;
    } else {
      // For 1-on-1 chats, use the other user
      senderName = otherUser?.fullName ?? 'Unknown';
      senderImage = otherUser?.imageUrl;
    }

    // UX-001: Check if this is a new message (for slide-in animation)
    // Messages sent in the last 2 seconds are considered "new"
    final isNewMessage = DateTime.now().difference(currentTime).inSeconds < 2;

    // UX-007: Determine if unread divider should show above this message
    // List is reversed, so we show divider when current is "new" but previous (older in list) is not
    final entryTime = controller.chatEntryTime.value;
    final isCurrentNew = entryTime != null &&
        currentTime.isAfter(entryTime) &&
        !isMe; // Only count received messages as "new"
    final isPreviousOld = previousMsg == null ||
        entryTime == null ||
        !previousMsg.timestamp.isAfter(entryTime) ||
        previousMsg.senderId == UserService.currentUser.value?.uid;
    final showDividerHere =
        controller.showUnreadDivider.value && isCurrentNew && isPreviousOld;

    return Column(
      children: [
        // Date separator
        if (index == messages.length - 1 ||
            (previousTime != null && !_isSameDay(previousTime, currentTime)))
          _buildDateSeparator(currentTime),

        // UX-007: Unread message divider (shows once above first new message)
        if (showDividerHere)
          UnreadMessageDivider(
            onDismiss: () => controller.dismissUnreadDivider(),
          ),

        // UX-006: Swipeable timestamp wrapper + slide-in animation
        SwipeableTimestamp(
          timestamp: currentTime,
          isMe: isMe,
          child: AnimatedMessageItem(
            isMe: isMe,
            isNewMessage: isNewMessage,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: MessageBuilder(
                !isMe,
                messageModel: currentMsg,
                timestamp: currentMsg.timestamp.toIso8601String(),
                senderName: senderName,
                senderImage: senderImage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Builder(
        builder: (context) => Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ColorsManager.darkSurfaceVariant
                        : ColorsManager.offWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
            ));
  }

  // ARCH-008: Call handling methods moved to ChatCallHandler service
  // Now accessed via controller.startAudioCall() and controller.startVideoCall()

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Build search bar for in-conversation search
  Widget _buildSearchBar() {
    return Obx(() {
      if (!controller.isSearchMode.value) {
        return const SizedBox.shrink();
      }

      return ChatSearchBar(
        onSearch: controller.searchMessages,
        onClose: controller.closeSearch,
        onNext: controller.nextSearchResult,
        onPrevious: controller.previousSearchResult,
        resultCount: controller.searchResults.length,
        currentIndex: controller.currentSearchIndex.value,
        onGetHistory: controller.getSearchHistory,
        onRemoveFromHistory: controller.removeFromSearchHistory,
      );
    });
  }

  /// UI Migration: Build offline status indicator
  Widget _buildOfflineIndicator() {
    return StreamBuilder<ConnectionStatus>(
      stream: ConnectivityService().statusStream,
      initialData: ConnectionStatus.online,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.online;

        // Don't show anything when online
        if (status == ConnectionStatus.online) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: status == ConnectionStatus.offline
                ? ColorsManager.error.withValues(alpha: 0.9)
                : Colors.orange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == ConnectionStatus.offline
                    ? Icons.cloud_off
                    : Icons.sync,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                status == ConnectionStatus.offline
                    ? 'You are offline. Messages will be sent when connected.'
                    : 'Reconnecting...',
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build avatar for group chats
  Widget _buildGroupAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.primary.withValues(alpha: 0.1),
      ),
      child: CircleAvatar(
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.2),
        child: Icon(
          Icons.group,
          color: ColorsManager.primary,
          size: 24,
        ),
      ),
    );
  }

  /// Build avatar for private chats
  Widget _buildPrivateAvatar(dynamic otherUser) {
    return ClipOval(
      child: AppCachedNetworkImage(
        imageUrl: otherUser.imageUrl ?? '',
        height: 44,
        width: 44,
      ),
    );
  }

  /// Show group management menu for group chats
  void _showGroupManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsManager.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Group info
              Text(
                controller.chatName.value,
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
              Text(
                "${controller.memberCount.value} members",
                style: StylesManager.regular(
                    fontSize: FontSize.small, color: ColorsManager.grey),
              ),
              const SizedBox(height: 20),

              // Menu options
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.group_add, color: ColorsManager.primary),
                ),
                title: Text("Add Members",
                    style: StylesManager.medium(fontSize: FontSize.medium)),
                onTap: () {
                  Get.back();
                  _showAddMembersDialog();
                },
              ),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: ColorsManager.primary),
                ),
                title: Text("View Members",
                    style: StylesManager.medium(fontSize: FontSize.medium)),
                onTap: () {
                  Get.back();
                  _showMembersList();
                },
              ),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.settings, color: ColorsManager.primary),
                ),
                title: Text("Group Settings",
                    style: StylesManager.medium(fontSize: FontSize.medium)),
                onTap: () {
                  Get.back();
                  _showGroupSettings();
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Show dialog to add new members to group
  void _showAddMembersDialog() {
    Get.toNamed(Routes.HOME, arguments: {'showUserSelection': true});
  }

  /// Show list of current group members as bottom sheet
  void _showMembersList() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ColorsManager.surfaceAdaptive(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorsManager.dividerAdaptive(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Group Members",
                      style: StylesManager.bold(fontSize: FontSize.large),
                    ),
                    const Spacer(),
                    Text(
                      "${controller.members.length} members",
                      style: TextStyle(
                          color: ColorsManager.textSecondaryAdaptive(context),
                          fontSize: FontSize.small),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Members list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: controller.members.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final member = controller.members[index];
                    final isCurrentUser =
                        member.uid == UserService.currentUser.value?.uid;
                    final isAdmin = controller.adminIds.contains(member.uid);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.imageUrl != null &&
                                member.imageUrl!.isNotEmpty
                            ? NetworkImage(member.imageUrl!)
                            : null,
                        backgroundColor:
                            ColorsManager.primary.withValues(alpha: 0.1),
                        child:
                            member.imageUrl == null || member.imageUrl!.isEmpty
                                ? Text(
                                    member.fullName
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: TextStyle(
                                        color: ColorsManager.primary,
                                        fontWeight: FontWeight.w600),
                                  )
                                : null,
                      ),
                      title: Text(
                        member.fullName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        isCurrentUser ? 'You' : (isAdmin ? 'Admin' : 'Member'),
                        style: TextStyle(
                          color: isAdmin
                              ? ColorsManager.primary
                              : ColorsManager.textSecondaryAdaptive(context),
                          fontSize: FontSize.xSmall,
                        ),
                      ),
                      onTap: !isCurrentUser
                          ? () {
                              Navigator.pop(context);
                              controller.showMemberActionsSheet(
                                  context, member);
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show group settings as bottom sheet
  void _showGroupSettings() {
    controller.showGroupManagementSheet(Get.context!);
  }

  /// Show bottom sheet to edit group name
  void _showEditGroupNameDialog() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditFieldSheet(
          title: "Edit Group Name",
          initialValue: controller.chatName.value,
          hint: "Enter group name",
          maxLength: 50,
          onSave: (value) {
            controller.updateGroupInfo(name: value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Show bottom sheet to edit group description
  void _showEditGroupDescriptionDialog() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditFieldSheet(
          title: "Edit Description",
          initialValue: controller.chatDescription.value,
          hint: "Enter group description",
          maxLines: 3,
          maxLength: 200,
          onSave: (value) {
            controller.updateGroupInfo(description: value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Remove a member from the group
  void _removeMember(String userId) {
    controller.removeMemberFromGroup(userId);
  }

  /// Show dialog to change group photo
  void _showChangeGroupPhotoDialog() {
    Get.bottomSheet(
      Builder(
          builder: (context) => Container(
                decoration: BoxDecoration(
                  color: ColorsManager.surfaceAdaptive(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera,
                              color: ColorsManager.primary),
                          const SizedBox(width: 12),
                          Text(
                            "Change Group Photo",
                            style: StylesManager.bold(
                              fontSize: FontSize.large,
                              color: ColorsManager.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Options
                    ListTile(
                      leading: const Icon(Icons.camera_alt,
                          color: ColorsManager.primary),
                      title: const Text("Take Photo"),
                      onTap: () {
                        Get.back();
                        controller.changeGroupPhoto(fromCamera: true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library,
                          color: ColorsManager.primary),
                      title: const Text("Choose from Gallery"),
                      onTap: () {
                        Get.back();
                        controller.changeGroupPhoto(fromCamera: false);
                      },
                    ),
                    if (controller.groupImageUrl.value.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.delete,
                            color: ColorsManager.error),
                        title: const Text("Remove Photo"),
                        onTap: () {
                          Get.back();
                          controller.removeGroupPhoto();
                        },
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              )),
      backgroundColor: Colors.transparent,
    );
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

  /// Build blocked chat banner for private chats
  Widget _buildBlockedChatBanner() {
    // Only show for private chats
    if (controller.isGroupChat.value) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final blockInfo = controller.blockedChatInfo.value;
      if (!blockInfo.isBlocked) {
        return const SizedBox.shrink();
      }

      return BlockedChatBanner(
        blockInfo: blockInfo,
        onUnblock:
            blockInfo.blockedByMe ? () => _showUnblockConfirmation() : null,
      );
    });
  }

  /// Build input area - shows blocked input bar if blocked
  Widget _buildInputArea() {
    return Obx(() {
      final blockInfo = controller.blockedChatInfo.value;

      // Show blocked input bar if blocked
      if (blockInfo.isBlocked) {
        return BlockedChatInputBar(
          blockInfo: blockInfo,
          onUnblock:
              blockInfo.blockedByMe ? () => _showUnblockConfirmation() : null,
        );
      }

      // Show normal input area
      return Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: ColorsManager.surfaceAdaptive(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: AttachmentWidget(),
        ),
      );
    });
  }

  /// Show unblock confirmation dialog
  void _showUnblockConfirmation() async {
    final otherUser = controller.otherUser;
    if (otherUser == null) return;

    final confirmed = await UnblockConfirmationSheet.show(
      context: Get.context!,
      userName: otherUser.fullName ?? 'this user',
      userPhotoUrl: otherUser.imageUrl,
    );

    if (confirmed == true) {
      await controller.unblockUser();
    }
  }
}

/// Private iOS-style edit field bottom sheet for inline group editing
class _EditFieldSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final void Function(String value) onSave;

  const _EditFieldSheet({
    required this.title,
    required this.initialValue,
    required this.onSave,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.darkBottomSheet : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.dividerAdaptive(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: FontSize.large,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textPrimaryAdaptive(context),
            ),
          ),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: ColorsManager.inputBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: ColorsManager.dividerAdaptive(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: ColorsManager.dividerAdaptive(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: ColorsManager.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _controller.clear(),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _handleSave(),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          ColorsManager.textSecondaryAdaptive(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
