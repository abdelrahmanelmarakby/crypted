import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/attachment_widget.dart';
import 'package:crypted_app/app/modules/chat/widgets/blocked_chat_banner.dart';
import 'package:crypted_app/app/core/services/chat_privacy_helper.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/modules/chat/widgets/optimized/optimized_message_list.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
                      color: Colors.white,
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


        // ARCH-004: Replaced StreamProvider with StreamBuilder to consolidate state management
        // Using pure Flutter StreamBuilder instead of mixing GetX with Provider
        return StreamBuilder<List<Message>>(
          stream: controller.chatDataSource.getLivePrivateMessage(controller.roomId),
          initialData: const [],
          builder: (context, snapshot) {
            // Handle errors gracefully
            if (snapshot.hasError) {
              debugPrint("Error loading messages: ${snapshot.error}");
            }

            final messages = snapshot.data ?? [];
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
                        Colors.white.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      children: [
                        // UI Migration: Offline status indicator
                        _buildOfflineIndicator(),
                        // Blocked chat banner (for private chats)
                        _buildBlockedChatBanner(),
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
                              // PERF-001: Added scroll-based pagination for better performance
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    // Load more when scrolling near the top (bottom in reverse)
                                    final maxScroll = notification.metrics.maxScrollExtent;
                                    final currentScroll = notification.metrics.pixels;

                                    if (maxScroll - currentScroll <= 200) {
                                      // TODO: Implement pagination loading
                                      // controller.loadMoreMessages();
                                    }
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                  reverse: true,
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                  itemCount: messages.length,
                                  // PERF-015: Added cache extent for smoother scrolling
                                  cacheExtent: 500,
                                  itemBuilder: (context, index) {
                                    // Use RepaintBoundary for performance optimization
                                    return RepaintBoundary(
                                      key: ValueKey('msg_${messages[index].id}'),
                                      child: _buildMessageItem(
                                        messages,
                                        index,
                                        UserService.currentUser.value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Input area - shows blocked input bar if blocked
                        _buildInputArea(),
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

  // ARCH-004: State management consolidated - removed Provider dependency

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
              color: Colors.white.withValues(alpha: 0.2),
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
          if (controller.isGroupChat.value) {
            // Navigate to group info for group chats
            Get.toNamed(
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
          } else {
            // Navigate to contact info for individual chats
            Get.toNamed(
              Routes.CONTACT_INFO,
              arguments: {
                "user": otherUser,
                "roomId": controller.roomId,
              },
            );
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
                      color: Colors.white,
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
                        color: Colors.black,
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
      actions: [
        // Show different actions based on chat type
        if (controller.isGroupChat.value) ...[
          // Group management button
          IconButton(
            onPressed: () => _showGroupManagementMenu(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.black,
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
                  icon: SvgPicture.asset(
                    'assets/icons/call-calling.svg',
                    color: ColorsManager.success,
                    height: 20,
                    width: 20,
                  ),
                  onPressed: () => controller.startAudioCall(otherUser as SocialMediaUser),
                  isVideoCall: false,
                  otherUser: otherUser,
                ),

                const SizedBox(width: 8),

                // Video call button with blue accent
                // ARCH-008: Now uses controller's call handler
                _buildCallButton(
                  icon: const Icon(
                    Iconsax.video_copy,
                    color: ColorsManager.primary,
                    size: 20,
                  ),
                  onPressed: () => controller.startVideoCall(otherUser as SocialMediaUser),
                  isVideoCall: true,
                  otherUser: otherUser,
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
    required bool isVideoCall,
    required dynamic otherUser,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isVideoCall
                ? ColorsManager.primary.withValues(alpha: 0.1)
                : ColorsManager.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isVideoCall
                  ? ColorsManager.primary.withValues(alpha: 0.3)
                  : ColorsManager.success.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isVideoCall
                  ? ColorsManager.primary.withValues(alpha: 0.15)
                  : ColorsManager.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(List<Message> messages, int index, dynamic otherUser) {
    final Message? previousMsg = index != messages.length - 1 ? messages[index + 1] : null;
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
            senderName: senderName,
            senderImage: senderImage,
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
    );
  }

  // ARCH-008: Call handling methods moved to ChatCallHandler service
  // Now accessed via controller.startAudioCall() and controller.startVideoCall()

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
                style: StylesManager.regular(fontSize: FontSize.small, color: ColorsManager.grey),
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
                  child: const Icon(Icons.group_add, color: ColorsManager.primary),
                ),
                title: Text("Add Members", style: StylesManager.medium(fontSize: FontSize.medium)),
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
                title: Text("View Members", style: StylesManager.medium(fontSize: FontSize.medium)),
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
                  child: const Icon(Icons.settings, color: ColorsManager.primary),
                ),
                title: Text("Group Settings", style: StylesManager.medium(fontSize: FontSize.medium)),
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

  /// Show list of current group members
  void _showMembersList() {
    // Navigate to a members list view or show in a dialog
    Get.dialog(
      Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Group Members",
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.members.length,
                  itemBuilder: (context, index) {
                    final member = controller.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty
                            ? NetworkImage(member.imageUrl!)
                            : null,
                        child: member.imageUrl == null || member.imageUrl!.isEmpty
                            ? Text(member.fullName?.substring(0, 1).toUpperCase() ?? '?')
                            : null,
                      ),
                      title: Text(member.fullName ?? 'Unknown'),
                      subtitle: Text(member.uid == UserService.currentUser.value?.uid ? 'You' : 'Member'),
                      trailing: member.uid != UserService.currentUser.value?.uid
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: ColorsManager.error),
                              onPressed: () {
                                _removeMember(member.uid!);
                                Get.back();
                              },
                            )
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

  /// Show group settings dialog
  void _showGroupSettings() {
    Get.dialog(
      Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Group Settings",
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
              const SizedBox(height: 20),

              // Group name setting
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text("Edit Group Name"),
                subtitle: Text(controller.chatName.value),
                onTap: () {
                  Get.back();
                  _showEditGroupNameDialog();
                },
              ),

              // Group description setting
              ListTile(
                leading: const Icon(Icons.description),
                title: Text("Edit Description"),
                subtitle: Text(controller.chatDescription.value.isEmpty ? "No description" : controller.chatDescription.value),
                onTap: () {
                  Get.back();
                  _showEditGroupDescriptionDialog();
                },
              ),

              // Change group photo
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text("Change Group Photo"),
                onTap: () {
                  Get.back();
                  _showChangeGroupPhotoDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to edit group name
  void _showEditGroupNameDialog() {
    final TextEditingController nameController = TextEditingController(text: controller.chatName.value);

    Get.dialog(
      AlertDialog(
        title: Text("Edit Group Name"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Enter group name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.updateGroupInfo(name: nameController.text.trim());
                Get.back();
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit group description
  void _showEditGroupDescriptionDialog() {
    final TextEditingController descController = TextEditingController(text: controller.chatDescription.value);

    Get.dialog(
      AlertDialog(
        title: Text("Edit Group Description"),
        content: TextField(
          controller: descController,
          decoration: InputDecoration(
            hintText: "Enter group description",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.updateGroupInfo(description: descController.text.trim());
              Get.back();
            },
            child: Text("Save"),
          ),
        ],
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
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                  const Icon(Icons.photo_camera, color: ColorsManager.primary),
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
              leading: const Icon(Icons.camera_alt, color: ColorsManager.primary),
              title: const Text("Take Photo"),
              onTap: () {
                Get.back();
                controller.changeGroupPhoto(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: ColorsManager.primary),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Get.back();
                controller.changeGroupPhoto(fromCamera: false);
              },
            ),
            if (controller.groupImageUrl.value.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: ColorsManager.error),
                title: const Text("Remove Photo"),
                onTap: () {
                  Get.back();
                  controller.removeGroupPhoto();
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
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
        onUnblock: blockInfo.blockedByMe ? () => _showUnblockConfirmation() : null,
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
          onUnblock: blockInfo.blockedByMe ? () => _showUnblockConfirmation() : null,
        );
      }

      // Show normal input area
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: AttachmentWidget(),
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