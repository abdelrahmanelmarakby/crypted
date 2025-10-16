// ignore_for_file: must_be_immutable, deprecated_member_use
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/attachment_widget.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/modules/groupChat/controllers/group_chat_controller.dart';
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
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class GroupChatView extends GetView<GroupChatController> {
  const GroupChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GroupChatController>(
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
                      Icons.group_off,
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
            print(error);
            print(stackTrace);
            return [];
          },
          builder: (context, child) {
            final messages = Provider.of<List<Message>>(context);
            return Scaffold(
              backgroundColor: ColorsManager.navbarColor,
              extendBodyBehindAppBar: false,
              appBar: _buildGroupAppBar(context),
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
                        // Group info header
                        _buildGroupInfoHeader(),
                        
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
                                itemBuilder: (context, index) => _buildGroupMessageItem(
                                  messages,
                                  index,
                                ),
                              ),
                            ),
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

  PreferredSizeWidget _buildGroupAppBar(BuildContext context) {
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
            Routes.GROUP_INFO, // You'll need to create this route
            arguments: {"groupId": controller.roomId, "members": controller.members},
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group avatar
              _buildGroupAvatar(),
              
              const SizedBox(width: 12),
              
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.groupChatRoom?.name ?? "Group Chat", // You'll need to add this to controller
                      style: StylesManager.bold(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${controller.groupChatRoom?.members?.length} members",
                      style: StylesManager.regular(
                        color: ColorsManager.grey,
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
        // Group call button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showGroupCallOptions();
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ),
        
        // More options
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showGroupOptions();
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatar() {
    return Container(
      width: 44,
      height: 44,
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
      child: Stack(
        children: [
          // Show first 4 members' avatars or group icon
          if (controller.members.length >= 4) ...[
            Positioned(
              top: 2,
              left: 2,
              child: _buildMiniAvatar(controller.members[0], 18),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: _buildMiniAvatar(controller.members[1], 18),
            ),
            Positioned(
              bottom: 2,
              left: 2,
              child: _buildMiniAvatar(controller.members[2], 18),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: _buildMiniAvatar(controller.members[3], 18),
            ),
          ] else if (controller.members.length >= 2) ...[
            Positioned(
              top: 4,
              left: 4,
              child: _buildMiniAvatar(controller.members[0], 16),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: _buildMiniAvatar(controller.members[1], 16),
            ),
            if (controller.members.length >= 3)
              Positioned(
                top: 4,
                right: 4,
                child: _buildMiniAvatar(controller.members[2], 16),
              ),
          ] else
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group,
                  color: ColorsManager.primary,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(dynamic member, double size) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: ColorsManager.lightGrey,
        child: member.imageUrl != null && member.imageUrl!.isNotEmpty
            ? AppCachedNetworkImage(
                imageUrl: member.imageUrl!,
                width: size,
                height: size,
              )
            : Center(
                child: Text(
                  (member.fullName?.isNotEmpty == true 
                      ? member.fullName!.substring(0, 1)
                      : '?').toUpperCase(),
                  style: StylesManager.bold(
                    fontSize: size * 0.4,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGroupInfoHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Active members avatars
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.members.take(5).length,
                itemBuilder: (context, index) {
                  final member = controller.members[index];
                  return Container(
                    margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    child: Stack(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: AppCachedNetworkImage(
                              imageUrl: member.imageUrl ?? '',
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ),
                        // Online indicator
                        if (index < 3) // Show online for first 3 members as example
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (controller.members.length > 5)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+${controller.members.length - 5}',
                  style: StylesManager.medium(
                    fontSize: 10,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupMessageItem(List<Message> messages, int index) {
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
        
        // Message with sender info for group
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Show sender name for group messages (except for own messages)
              if (!isMe && (previousMsg == null || previousMsg.senderId != currentMsg.senderId))
                Padding(
                  padding: const EdgeInsets.only(left: 52, bottom: 4, top: 8),
                  child: Text(
                    controller.groupChatRoom?.members?.firstWhere(
                      (member) => member.uid == currentMsg.senderId,
                      orElse: () => UserService.currentUser.value!,
                    )?.fullName ?? 'Unknown',
                    style: StylesManager.medium(
                      fontSize: 12,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              
              MessageBuilder(
                !isMe,
                messageModel: currentMsg,
                timestamp: currentMsg.timestamp.toIso8601String(),
                senderName: "sender?.fullName",
                senderImage: "sender?.imageUrl",
              ),
            ],
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
            color: ColorsManager.lightGrey.withOpacity(0.3),
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

  void _showGroupCallOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Start Group Call',
              style: StylesManager.bold(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildCallOption(
              icon: Icons.call,
              title: 'Voice Call',
              subtitle: 'Start audio call with all members',
              onTap: () {
                Get.back();
                _startGroupCall(false);
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildCallOption(
              icon: Icons.videocam,
              title: 'Video Call',
              subtitle: 'Start video call with all members',
              onTap: () {
                Get.back();
                _startGroupCall(true);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildCallOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorsManager.lightGrey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: ColorsManager.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StylesManager.medium(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: StylesManager.regular(
                          fontSize: 14,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ColorsManager.lightGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildGroupOption(
              icon: Icons.info_outline,
              title: 'Group Info',
              onTap: () {
                Get.back();
                Get.toNamed(
                  Routes.GROUP_INFO,
                  arguments: {"groupId": controller.roomId, "members": controller.members},
                );
              },
            ),
            
            _buildGroupOption(
              icon: Icons.person_add,
              title: 'Add Members',
              onTap: () {
                Get.back();
                // Handle add members
              },
            ),
            
            _buildGroupOption(
              icon: Icons.photo_library,
              title: 'Media & Files',
              onTap: () {
                Get.back();
                // Handle media view
              },
            ),
            
            _buildGroupOption(
              icon: Icons.search,
              title: 'Search Messages',
              onTap: () {
                Get.back();
                // Handle search
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildGroupOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: ColorsManager.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: StylesManager.medium(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ColorsManager.lightGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGroupCall(bool isVideo) {
    HapticFeedback.lightImpact();
    // Implement group call logic
    print('Starting ${isVideo ? 'video' : 'audio'} group call with ${controller.members.length} members');
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