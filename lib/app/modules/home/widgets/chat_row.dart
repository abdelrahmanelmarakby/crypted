import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
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
        'Success',
        widget.chatRoom?.isMuted == true ? 'Chat unmuted' : 'Chat muted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: ColorsManager.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to toggle mute: ${e.toString()}',
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
        'Success',
        widget.chatRoom?.isPinned == true ? 'Chat unpinned' : 'Chat pinned',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: ColorsManager.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to toggle pin: ${e.toString()}',
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
        'Error',
        'User not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.red,
        colorText: ColorsManager.white,
      );
      return;
    }

    // Show confirmation dialog for blocking
    final confirmResult = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Block User',
          style: TextStyle(
            fontSize: FontSize.medium,
            fontWeight: FontWeights.bold,
            color: ColorsManager.red,
          ),
        ),
        content: Text(
          'Are you sure you want to block ${otherUser.fullName}? You won\'t receive messages from this user anymore.',
          style: TextStyle(
            fontSize: FontSize.small,
            color: ColorsManager.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ColorsManager.grey,
                fontSize: FontSize.small,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Block',
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

    if (confirmResult != true) return;

    setState(() => _isLoading = true);
    try {
      await chatDataSource.blockUser(widget.chatRoom?.id ?? '', otherUser.uid ?? '');

      if (mounted) {
        Get.snackbar(
          'User Blocked',
          '${otherUser.fullName} has been blocked. You won\'t receive messages from this user.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 3),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to block user: ${e.toString()}',
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

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await chatDataSource.toggleFavoriteChat(widget.chatRoom?.id ?? '');

      if (mounted) {
        Get.snackbar(
          'Success',
          widget.chatRoom?.isFavorite == true ? 'Chat removed from favorites' : 'Chat added to favorites',
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
          'Error',
          'Failed to toggle favorite: ${e.toString()}',
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
          'Success',
          widget.chatRoom?.isArchived == true ? 'Chat unarchived' : 'Chat archived',
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
          'Error',
          'Failed to toggle archive: ${e.toString()}',
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

    // Enhanced confirmation dialog for delete
    final confirmResult = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Delete Chat',
          style: TextStyle(
            fontSize: FontSize.medium,
            fontWeight: FontWeights.bold,
            color: ColorsManager.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: FontSize.small,
                fontWeight: FontWeights.bold,
                color: ColorsManager.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this chat? All messages will be permanently removed.',
              style: TextStyle(
                fontSize: FontSize.small,
                color: ColorsManager.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ColorsManager.grey,
                fontSize: FontSize.small,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Delete Forever',
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

    if (confirmResult != true) return;

    setState(() => _isLoading = true);
    try {
      print("🔄 Attempting to delete chat room: ${widget.chatRoom?.id}");

      // Show loading indicator
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting chat...',
                  style: TextStyle(
                    fontSize: FontSize.small,
                    color: ColorsManager.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Delete the chat room and all its messages
      final success = await chatDataSource.deleteRoom(widget.chatRoom?.id ?? '');

      // Close loading dialog
      Get.back();

      if (success) {
        if (mounted) {
          Get.snackbar(
            'Chat Deleted',
            widget.chatRoom?.isGroupChat == true
                ? 'Group chat deleted successfully'
                : 'Chat deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ColorsManager.primary,
            colorText: ColorsManager.white,
            duration: const Duration(seconds: 3),
          );
          // The chat list will be automatically updated via the stream
          // No need to manually refresh
        }
      } else {
        throw Exception('Delete operation failed');
      }
    } catch (e) {
      print('Error deleting chat: $e');

      // Close loading dialog if it's still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (mounted) {
        Get.snackbar(
          'Delete Failed',
          'Failed to delete chat: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.red,
          colorText: ColorsManager.white,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoContextMenu(
        actions: <Widget>[
          
          if (widget.chatRoom?.isGroupChat == true)
            CupertinoContextMenuAction(
              onPressed: () {
                Navigator.pop(context);
                _toggleMute();
              },
              child: Text('Mute'),
            ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _togglePin();
            },
            child: Text('Pin'),
          ),
          if (widget.chatRoom?.isGroupChat != true)
            CupertinoContextMenuAction(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              },
              child: Text('Block'),
            ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite();
            },
            child: Text('Favorite'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleArchive();
            },
            child: Text('Archive'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: ColorsManager.red),
            ),
          ),
        ],
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
          child: Material(
            child: GestureDetector(
              onTap: () {
                Map<String, dynamic> arg = {
                  'members': widget.chatRoom?.members,
                  "blockingUserId": widget.chatRoom?.blockingUserId,
                  "roomId": widget.chatRoom?.id,
                  "isGroupChat": widget.chatRoom?.isGroupChat,
                };
                Get.toNamed(Routes.CHAT, arguments: arg);
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed(
                          Routes.CHAT,
                          arguments: {
                            "user": _getChatDisplayUser(),
                            "roomId": widget.chatRoom?.id,
                            "members": widget.chatRoom?.members,
                            "isGroupChat": widget.chatRoom?.isGroupChat,
                          },
                        );
                      },
                      child: ClipOval(
                        child: widget.chatRoom?.isGroupChat == true
                            ? _buildGroupAvatar()
                            : _buildPrivateAvatar(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 100,
                      maxWidth: context.width * .8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getChatDisplayName(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.black,
                                  fontWeight: FontWeights.regular,
                                ),
                              ),
                            ),
                            if (widget.chatRoom?.isGroupChat == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.group,
                                  size: 14,
                                  color: ColorsManager.primary,
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            if (widget.chatRoom?.isPinned == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 12,
                                  color: ColorsManager.primary,
                                ),
                              ),
                            if (widget.chatRoom?.isArchived == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.archive,
                                  size: 12,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            if (widget.chatRoom?.isFavorite == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: ColorsManager.red,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          _getChatSubtitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: FontSize.xSmall,
                            fontWeight: FontWeights.medium,
                            color: ColorsManager.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(
                              _parseDateSafely(widget.chatRoom?.lastChat) ?? DateTime.now()),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: FontSize.xXSmall,
                            color: ColorsManager.lightGrey,
                            fontWeight: FontWeights.medium,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Show unread indicator for current user
                        if (widget.chatRoom?.lastSender != UserService.currentUser.value?.uid)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ColorsManager.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get the appropriate display name for the chat
  String _getChatDisplayName() {
    if (widget.chatRoom?.isGroupChat == true) {
      // For group chats, show group name or fallback to member names
      final groupName = widget.chatRoom?.name;
      if (groupName != null && groupName.trim().isNotEmpty) {
        return groupName;
      }

      // Try to generate group name from members
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
      return widget.chatRoom?.groupImageUrl ?? _getChatDisplayUser()?.imageUrl ?? "";
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
        color: ColorsManager.primary.withOpacity(0.1),
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
              backgroundColor: ColorsManager.primary.withOpacity(0.2),
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
        color: ColorsManager.primary.withOpacity(0.1),
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
              backgroundColor: ColorsManager.primary.withOpacity(0.2),
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

  /// Get the user to display for this chat (for avatars and interactions)
  SocialMediaUser? _getChatDisplayUser() {
    if (widget.chatRoom?.isGroupChat == true) {
      // For group chats, return the first member (could be enhanced to show group avatar)
      return widget.chatRoom?.members?.isNotEmpty == true ? widget.chatRoom!.members!.first : null;
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
        .where((user) => user.fullName != null && user.fullName!.trim().isNotEmpty)
        .take(3)
        .map((user) => user.fullName!.trim().split(' ').first)
        .where((name) => name.isNotEmpty)
        .toList();

    if (otherMembers.isEmpty) {
      // If no other members found, use all members (including current user)
      final allMembers = members
          .where((user) => user.fullName != null && user.fullName!.trim().isNotEmpty)
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
