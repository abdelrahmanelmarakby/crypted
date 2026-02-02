import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/ui/online_status_indicator.dart';
import 'package:crypted_app/app/modules/home/widgets/unread_pulse_badge.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/app/widgets/custom_bottom_sheets.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRow extends StatefulWidget {
  const ChatRow({super.key, required this.chatRoom});
  final ChatRoom? chatRoom;

  @override
  State<ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<ChatRow> {
  final ChatDataSources chatDataSource = ChatDataSources();
  bool _isLoading = false;

  Future<void> _toggleMute() async {
    try {
      await chatDataSource.toggleMuteChat(widget.chatRoom?.id ?? '');
      Get.snackbar(
        Constants.kSuccess.tr,
        widget.chatRoom?.isMuted == true
            ? Constants.kChatUnmutedSnack.tr
            : Constants.kChatMutedSnack.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: ColorsManager.white,
      );
    } catch (e) {
      Get.snackbar(
        Constants.kError.tr,
        '${Constants.kFailedToToggleMute.tr}: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
    }
  }

  Future<void> _togglePin() async {
    try {
      await chatDataSource.togglePinChat(widget.chatRoom?.id ?? '');
      Get.snackbar(
        Constants.kSuccess.tr,
        widget.chatRoom?.isPinned == true
            ? Constants.kChatUnpinnedSnack.tr
            : Constants.kChatPinnedSnack.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: ColorsManager.white,
      );
    } catch (e) {
      Get.snackbar(
        Constants.kError.tr,
        '${Constants.kFailedToTogglePin.tr}: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
    }
  }

  Future<void> _blockUser() async {
    if (_isLoading) return;

    final otherUser = _getChatDisplayUser();
    if (otherUser == null) {
      Get.snackbar(
        Constants.kError.tr,
        Constants.kUserNotFound.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
      return;
    }

    // Show confirmation bottom sheet for blocking
    final confirmResult = await CustomBottomSheets.showConfirmation(
      title: Constants.kBlockUser.tr,
      message:
          '${Constants.kBlockUserConfirmation.tr} ${otherUser.fullName}? ${Constants.kWontReceiveMessages.tr}',
      subtitle: Constants.kThisActionCanBeReversed.tr,
      confirmText: Constants.kBlockUser.tr,
      cancelText: Constants.kCancel.tr,
      icon: Icons.block,
      isDanger: true,
    );

    if (confirmResult != true) return;

    setState(() => _isLoading = true);

    // Show loading bottom sheet
    CustomBottomSheets.showLoading(message: Constants.kBlockingUser.tr);

    try {
      await chatDataSource.blockUser(
          widget.chatRoom?.id ?? '', otherUser.uid ?? '');

      // Close loading
      CustomBottomSheets.closeLoading();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Close loading
      CustomBottomSheets.closeLoading();

      if (mounted) {
        Get.snackbar(
          Constants.kError.tr,
          '${Constants.kFailedToBlockUser.tr}: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 3),
          icon: Icon(Icons.error, color: ColorsManager.white),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await chatDataSource.toggleFavoriteChat(widget.chatRoom?.id ?? '');

      if (mounted) {
        Get.snackbar(
          Constants.kSuccess.tr,
          widget.chatRoom?.isFavorite == true
              ? Constants.kChatRemovedFromFavorites.tr
              : Constants.kChatAddedToFavorites.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 2),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          Constants.kError.tr,
          '${Constants.kFailedToToggleFavorite.tr}: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleArchive() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await chatDataSource.toggleArchiveChat(widget.chatRoom?.id ?? '');

      if (mounted) {
        Get.snackbar(
          Constants.kSuccess.tr,
          widget.chatRoom?.isArchived == true
              ? Constants.kChatUnarchivedSnack.tr
              : Constants.kChatArchivedSnack.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 2),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          Constants.kError.tr,
          '${Constants.kFailedToToggleArchive.tr}: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChat() async {
    if (_isLoading) return;

    // Enhanced confirmation bottom sheet for delete
    final confirmResult = await CustomBottomSheets.showConfirmation(
      title: Constants.kDeleteChat.tr,
      message: Constants.kAllMessagesWillBeDeleted.tr,
      subtitle: Constants.kThisActionCannotBeUndoneWarning.tr,
      confirmText: Constants.kDeleteForever.tr,
      cancelText: Constants.kCancel.tr,
      icon: Icons.delete_forever,
      isDanger: true,
    );

    if (confirmResult != true) return;

    setState(() => _isLoading = true);

    // Show loading bottom sheet
    CustomBottomSheets.showLoading(
      message: widget.chatRoom?.isGroupChat == true
          ? Constants.kDeletingGroupChat.tr
          : Constants.kDeletingChat.tr,
    );

    try {
      print("🔄 Attempting to delete chat room: ${widget.chatRoom?.id}");

      // Delete the chat room and all its messages
      final success =
          await chatDataSource.deleteRoom(widget.chatRoom?.id ?? '');

      // Close loading bottom sheet
      CustomBottomSheets.closeLoading();

      if (!success) {
        throw Exception('Delete operation failed');
      }
      // The chat list will be automatically updated via the stream
    } catch (e) {
      print('❌ Error deleting chat: $e');

      // Close loading bottom sheet if still open
      CustomBottomSheets.closeLoading();

      if (mounted) {
        Get.snackbar(
          Constants.kDeleteFailed.tr,
          Constants.kFailedToDeleteChatTryAgain.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 4),
          icon: Icon(Icons.error, color: ColorsManager.white),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show chat actions bottom sheet
  void _showChatActions() {
    final isGroupChat = widget.chatRoom?.isGroupChat == true;
    final isPinned = widget.chatRoom?.isPinned == true;
    final isMuted = widget.chatRoom?.isMuted == true;
    final isFavorite = widget.chatRoom?.isFavorite == true;
    final isArchived = widget.chatRoom?.isArchived == true;

    List<BottomSheetAction> actions = [];

    // Pin/Unpin action
    actions.add(BottomSheetAction(
      title: isPinned ? Constants.kUnpinChat.tr : Constants.kPinChat.tr,
      icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
      iconColor: ColorsManager.primary,
      onTap: _togglePin,
    ));

    // Mute action (available for all chat types)
    actions.add(BottomSheetAction(
      title: isMuted ? Constants.kUnmuteChat.tr : Constants.kMuteChat.tr,
      icon: isMuted ? Icons.notifications_active : Icons.notifications_off,
      iconColor: ColorsManager.primary,
      onTap: _toggleMute,
    ));

    // Favorite action
    actions.add(BottomSheetAction(
      title: isFavorite
          ? Constants.kRemoveFromFavorites.tr
          : Constants.kAddToFavorites.tr,
      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
      iconColor: ColorsManager.red,
      onTap: _toggleFavorite,
    ));

    // Archive action
    actions.add(BottomSheetAction(
      title:
          isArchived ? Constants.kUnarchiveChat.tr : Constants.kArchiveChat.tr,
      icon: isArchived ? Icons.unarchive : Icons.archive,
      iconColor: ColorsManager.grey,
      onTap: _toggleArchive,
    ));

    // Block action (only for private chats)
    if (!isGroupChat) {
      actions.add(BottomSheetAction(
        title: Constants.kBlockUser.tr,
        icon: Icons.block,
        iconColor: ColorsManager.red,
        onTap: _blockUser,
        isDestructive: true,
      ));
    }

    // Delete action
    actions.add(BottomSheetAction(
      title: Constants.kDeleteChat.tr,
      icon: Icons.delete_forever,
      iconColor: ColorsManager.red,
      onTap: _deleteChat,
      isDestructive: true,
    ));

    CustomBottomSheets.showActionSheet(
      title: isGroupChat ? Constants.kGroupInfo.tr : Constants.kChats.tr,
      subtitle: _getChatDisplayName(),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGroupChat = widget.chatRoom?.isGroupChat == true;
    final isPinned = widget.chatRoom?.isPinned == true;
    final isMuted = widget.chatRoom?.isMuted == true;
    final isFavorite = widget.chatRoom?.isFavorite == true;
    final isArchived = widget.chatRoom?.isArchived == true;

    return CupertinoContextMenu(
        enableHapticFeedback: true,
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _togglePin();
            },
            trailingIcon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            child: Text(
                isPinned ? Constants.kUnpinChat.tr : Constants.kPinChat.tr),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleMute();
            },
            trailingIcon:
                isMuted ? Icons.notifications_active : Icons.notifications_off,
            child: Text(
                isMuted ? Constants.kUnmuteChat.tr : Constants.kMuteChat.tr),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite();
            },
            trailingIcon: isFavorite ? Icons.favorite : Icons.favorite_border,
            child: Text(isFavorite
                ? Constants.kRemoveFromFavorites.tr
                : Constants.kAddToFavorites.tr),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleArchive();
            },
            trailingIcon: isArchived ? Icons.unarchive : Icons.archive,
            child: Text(isArchived
                ? Constants.kUnarchiveChat.tr
                : Constants.kArchiveChat.tr),
          ),
          if (!isGroupChat)
            CupertinoContextMenuAction(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              },
              trailingIcon: Icons.block,
              isDestructiveAction: true,
              child: Text(Constants.kBlockUser.tr),
            ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat();
            },
            trailingIcon: Icons.delete_forever,
            isDestructiveAction: true,
            child: Text(Constants.kDeleteChat.tr),
          ),
        ],
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: ColorsManager.surfaceAdaptive(context),
              child: InkWell(
                onTap: () {
                  Map<String, dynamic> arg = {
                    'members': widget.chatRoom?.members,
                    "blockingUserId": widget.chatRoom?.blockingUserId,
                    "roomId": widget.chatRoom?.id,
                    "isGroupChat": widget.chatRoom?.isGroupChat,
                  };
                  Get.toNamed(Routes.CHAT, arguments: arg);
                },
                child: Container(
                  // Fix #3: Better padding (8→16 horizontal, 12→14 vertical)
                  padding: const EdgeInsets.symmetric(
                    horizontal: Paddings.large,
                    vertical: Paddings.medium,
                  ),
                  // Fix #3: Cleaner bottom divider using theme border color
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: ColorsManager.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar with online status for private chats
                      SizedBox(
                        width: Sizes.size48,
                        height: Sizes.size48,
                        child: widget.chatRoom?.isGroupChat == true
                            ? ClipOval(child: _buildGroupAvatar())
                            : _buildPrivateAvatarWithStatus(),
                      ),
                      const SizedBox(width: Spacing.sm),

                      // Fix #4: Use Expanded instead of ConstrainedBox
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: Name + status icons | Timestamp
                            Row(
                              children: [
                                // Name + icons (flexible)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _getChatDisplayName(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          // Fix #1 & #2: Stronger hierarchy + StylesManager
                                          style: StylesManager.semiBold(
                                            fontSize: FontSize.medium,
                                            color: ColorsManager
                                                .textPrimaryAdaptive(context),
                                          ),
                                        ),
                                      ),
                                      // Mood emoji (Phase 14.5)
                                      if (widget.chatRoom?.isGroupChat != true)
                                        Builder(builder: (_) {
                                          final otherUser =
                                              _getChatDisplayUser();
                                          final mood = otherUser?.mood;
                                          if (mood != null && mood.isNotEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: Spacing.xxs),
                                              child: Text(mood,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }),
                                      // Status icons with consistent spacing
                                      if (widget.chatRoom?.isGroupChat == true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: Spacing.xxs),
                                          child: Icon(
                                            Icons.group,
                                            size: 14,
                                            color: ColorsManager.primary,
                                          ),
                                        ),
                                      if (isPinned)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: Spacing.xxs),
                                          child: Icon(
                                            Icons.push_pin,
                                            size: 12,
                                            color: ColorsManager.primary,
                                          ),
                                        ),
                                      if (isArchived)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: Spacing.xxs),
                                          child: Icon(
                                            Icons.archive,
                                            size: 12,
                                            color: ColorsManager.grey,
                                          ),
                                        ),
                                      if (isFavorite)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: Spacing.xxs),
                                          child: Icon(
                                            Icons.favorite,
                                            size: 12,
                                            color: ColorsManager.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: Spacing.xs),
                                // Fix #1 & #2: Timestamp with better size + StylesManager
                                Text(
                                  timeago.format(_parseDateSafely(
                                          widget.chatRoom?.lastChat) ??
                                      DateTime.now()),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: StylesManager.regular(
                                    fontSize: FontSize.xSmall,
                                    color: ColorsManager.lightGrey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: Spacing.xxs),

                            // Bottom row: Subtitle | Unread badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getChatSubtitle(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    // Fix #1 & #2: Better subtitle contrast + StylesManager
                                    style: StylesManager.regular(
                                      fontSize: FontSize.small,
                                      color: ColorsManager.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.xs),
                                // UX-009: Unread count badge or pulse indicator
                                Builder(builder: (context) {
                                  final myUid =
                                      UserService.currentUser.value?.uid;
                                  final unread = (myUid != null)
                                      ? (widget.chatRoom
                                              ?.unreadCountFor(myUid) ??
                                          0)
                                      : 0;
                                  if (unread > 0) {
                                    return UnreadCountBadge(
                                      count: unread,
                                      showPulse: false,
                                    );
                                  } else if (widget.chatRoom?.lastSender !=
                                      myUid) {
                                    // Fallback: green dot when we don't have counts yet
                                    return const UnreadPulseBadge(
                                      size: 8,
                                      enablePulse: true,
                                    );
                                  }
                                  return const SizedBox(width: Sizes.size20);
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }

  /// Get the appropriate display name for the chat
  String _getChatDisplayName() {
    if (widget.chatRoom?.isGroupChat == true) {
      final groupName = widget.chatRoom?.name;
      if (groupName != null && groupName.trim().isNotEmpty) {
        return groupName;
      }

      final generatedName = _generateGroupName(widget.chatRoom?.members ?? []);
      if (generatedName != null && generatedName.trim().isNotEmpty) {
        return generatedName;
      }

      // Final fallback: show member count or generic group name
      final memberCount = widget.chatRoom?.members?.length ?? 0;
      if (memberCount >= 2) {
        return "Group Chat ($memberCount members)";
      } else {
        return "Group Chat";
      }
    } else {
      // For private chats, show the other user's name
      final otherUser = widget.chatRoom?.members?.firstWhere(
        (user) => user.uid != UserService.currentUser.value?.uid,
        orElse: () => SocialMediaUser(fullName: Constants.kUnknownUser.tr),
      );
      return otherUser?.fullName ?? Constants.kUnknownUser.tr;
    }
  }

  /// Get the appropriate display image for the chat
  String _getChatDisplayImage() {
    if (widget.chatRoom?.isGroupChat == true) {
      // For group chats, use group image URL if available, otherwise fallback to first member's image
      return widget.chatRoom?.groupImageUrl ??
          _getChatDisplayUser()?.imageUrl ??
          "";
    } else {
      // For private chats, show the other user's image
      final displayUser = _getChatDisplayUser();
      return displayUser?.imageUrl ?? "";
    }
  }

  /// Build avatar for group chats
  Widget _buildGroupAvatar() {
    final imageUrl = _getChatDisplayImage();

    return Container(
      width: Sizes.size48,
      height: Sizes.size48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.primary.withValues(alpha: 0.1),
      ),
      child: imageUrl.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: Sizes.size48,
              width: Sizes.size48,
              isCircular: true,
            )
          : CircleAvatar(
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
  Widget _buildPrivateAvatar() {
    final imageUrl = _getChatDisplayImage();
    final displayUser = _getChatDisplayUser();

    return Container(
      width: Sizes.size48,
      height: Sizes.size48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.primary.withValues(alpha: 0.1),
      ),
      child: imageUrl.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: Sizes.size48,
              width: Sizes.size48,
              isCircular: true,
            )
          : CircleAvatar(
              backgroundColor: ColorsManager.primary.withValues(alpha: 0.2),
              child: Text(
                (displayUser?.fullName?.isNotEmpty == true
                    ? displayUser!.fullName!.substring(0, 1).toUpperCase()
                    : '?'),
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: FontSize.medium,
                  fontWeight: FontWeights.bold,
                ),
              ),
            ),
    );
  }

  /// Fix #8: Private avatar wrapped in Stack with LiveOnlineStatus dot
  Widget _buildPrivateAvatarWithStatus() {
    final otherUser = _getChatDisplayUser();
    final otherUserId = otherUser?.uid;

    return Stack(
      children: [
        ClipOval(child: _buildPrivateAvatar()),
        // Online status dot — only if we have the other user's ID
        if (otherUserId != null && otherUserId.isNotEmpty)
          Positioned(
            right: 0,
            bottom: 0,
            child: LiveOnlineStatus(
              userId: otherUserId,
              size: 14,
            ),
          ),
      ],
    );
  }

  /// Get the user to display for this chat (for avatars and interactions)
  SocialMediaUser? _getChatDisplayUser() {
    if (widget.chatRoom?.isGroupChat == true) {
      // For group chats, return the first member (could be enhanced to show group avatar)
      return widget.chatRoom?.members?.isNotEmpty == true
          ? widget.chatRoom!.members!.first
          : null;
    } else {
      // For private chats, return the other user
      return widget.chatRoom?.members?.firstWhere(
        (user) => user.uid != UserService.currentUser.value?.uid,
        orElse: () => SocialMediaUser(fullName: Constants.kUnknownUser.tr),
      );
    }
  }

  /// Generate group name from members (fallback for unnamed groups)
  String? _generateGroupName(List<SocialMediaUser>? members) {
    if (members == null || members.isEmpty) return null;

    // Get current user ID
    final currentUserId = UserService.currentUser.value?.uid;

    // Filter out current user and get other members
    final otherMembers = members
        .where((user) => user.uid != currentUserId)
        .where(
            (user) => user.fullName != null && user.fullName!.trim().isNotEmpty)
        .take(3)
        .map((user) => user.fullName!.trim().split(' ').first)
        .where((name) => name.isNotEmpty)
        .toList();

    if (otherMembers.isEmpty) {
      final allMembers = members
          .where((user) =>
              user.fullName != null && user.fullName!.trim().isNotEmpty)
          .take(3)
          .map((user) => user.fullName!.trim().split(' ').first)
          .where((name) => name.isNotEmpty)
          .toList();

      if (allMembers.isEmpty) return null;

      if (allMembers.length == 1) {
        return allMembers.first;
      } else if (allMembers.length == 2) {
        return '${allMembers[0]}, ${allMembers[1]}';
      } else {
        return '${allMembers[0]}, ${allMembers[1]} and ${allMembers.length - 2} others';
      }
    }

    if (otherMembers.length == 1) {
      return otherMembers.first;
    } else if (otherMembers.length == 2) {
      return '${otherMembers[0]}, ${otherMembers[1]}';
    } else {
      return '${otherMembers[0]}, ${otherMembers[1]} and ${otherMembers.length - 2} others';
    }
  }

  /// Get chat subtitle (last message or member info)
  String _getChatSubtitle() {
    if (widget.chatRoom?.isGroupChat == true) {
      // For group chats, show last message or member count
      if (widget.chatRoom?.lastMsg?.isNotEmpty == true) {
        return widget.chatRoom!.lastMsg!;
      } else {
        return "${_getMemberCount()} members";
      }
    } else {
      // For private chats, show last message or status
      return widget.chatRoom?.lastMsg ?? "Start a conversation";
    }
  }

  /// Get member count for display
  String _getMemberCount() {
    final count = widget.chatRoom?.members?.length ?? 0;
    return count.toString();
  }

  DateTime? _parseDateSafely(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    return DateTime.tryParse(dateStr);
  }
}
