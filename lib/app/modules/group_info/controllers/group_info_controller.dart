import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypted_app/core/locale/constant.dart';

class GroupInfoController extends GetxController {
  // Group data - reactive for real-time updates
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<String?> groupImageUrl = Rx<String?>(null);
  final Rx<int?> memberCount = Rx<int?>(null);
  final Rx<List<SocialMediaUser>?> members = Rx<List<SocialMediaUser>?>(null);

  // Room data
  String? roomId;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isFavorite = false.obs;

  // Data source
  final ChatDataSources _chatDataSources = ChatDataSources();

  // Current user for admin checks
  SocialMediaUser? get currentUser => UserService.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      groupName.value = arguments['chatName'] as String?;
      groupDescription.value = arguments['chatDescription'] as String?;
      memberCount.value = arguments['memberCount'] as int?;
      members.value = arguments['members'] as List<SocialMediaUser>?;
      groupImageUrl.value = arguments['groupImageUrl'] as String?;
      roomId = arguments['roomId'] as String?;

      print("✅ Loaded group data:");
      print("   Name: ${groupName.value}");
      print("   Members: ${memberCount.value}");
      print("   Description: ${groupDescription.value?.isNotEmpty == true ? 'Yes' : 'No'}");

      // Ensure current user is in members list if not present
      _ensureCurrentUserInMembers();

      // Load favorite status if we have a room ID
      if (roomId != null) {
        await _loadGroupStatus();
      }
    } else {
      print("❌ No group data provided to group info screen");
      isLoading.value = false;
    }
  }

  /// Load group status (favorite)
  Future<void> _loadGroupStatus() async {
    if (roomId == null) return;

    try {
      final chatRoom = await _chatDataSources.getChatRoomById(roomId!);
      if (chatRoom != null) {
        isFavorite.value = chatRoom.isFavorite ?? false;
      }
    } catch (e) {
      print("❌ Error loading group status: $e");
    }
  }

  void _ensureCurrentUserInMembers() {
    if (currentUser == null || members.value == null) return;

    final currentUserInMembers = members.value!.any((member) => member.uid == currentUser!.uid);
    if (!currentUserInMembers) {
      members.value = [currentUser!, ...members.value!];
      memberCount.value = members.value!.length;
    }
  }

  /// Refresh group data from server
  Future<void> refreshGroupData() async {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    try {
      // In a real implementation, this would fetch fresh data from the server
      // For now, we'll just reload from current data
      _loadGroupData();
    } catch (e) {
      print("❌ Error refreshing group data: $e");
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Update group description/status
  Future<void> updateStatus(String status) async {
    await updateGroupInfo(description: status);
  }

  /// Update group information
  Future<void> updateGroupInfo({String? name, String? description, String? imageUrl}) async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot update group: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Update in Firebase
      final success = await _chatDataSources.updateChatRoomInfo(
        roomId: roomId!,
        groupName: name,
        groupDescription: description,
        groupImageUrl: imageUrl,
      );

      if (success) {
        // Update local state after successful Firebase update
        if (name != null && name.isNotEmpty) {
          groupName.value = name;
        }
        if (description != null) {
          groupDescription.value = description;
        }
        if (imageUrl != null) {
          groupImageUrl.value = imageUrl;
        }

        Get.snackbar(
          "Success",
          "Group information updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      } else {
        throw Exception("Failed to update group information in Firebase");
      }
    } catch (e) {
      print("❌ Error updating group info: $e");
      Get.snackbar(
        "Error",
        "Failed to update group information: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove a member from the group
  Future<void> removeMember(String userId) async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot remove member: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (members.value == null) return;

      // Don't allow removing yourself
      if (userId == currentUser?.uid) {
        Get.snackbar(
          "Error",
          "You cannot remove yourself from the group",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Check if current user is admin
      if (!isCurrentUserAdmin) {
        Get.snackbar(
          "Error",
          "Only admins can remove members",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      final currentUserUid = currentUser?.uid;
      if (currentUserUid == null) return;

      isLoading.value = true;

      // Remove member using data source
      await _chatDataSources.removeMemberFromGroup(roomId!, userId, currentUserUid);

      // Remove member from local list
      members.value = members.value!.where((member) => member.uid != userId).toList();
      memberCount.value = members.value!.length;
    } catch (e) {
      print("❌ Error removing member: $e");
      Get.snackbar(
        "Error",
        "Failed to remove member: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a member to the group
  Future<void> addMember(SocialMediaUser newMember) async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot add member: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check if current user is admin
      if (!isCurrentUserAdmin) {
        Get.snackbar(
          "Error",
          "Only admins can add members",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Check if member already exists
      if (members.value?.any((member) => member.uid == newMember.uid) == true) {
        Get.snackbar(
          "Info",
          "${newMember.fullName} is already a member of this group",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      // Add member using data source
      final success = await _chatDataSources.addMemberToChat(
        roomId: roomId!,
        newMember: newMember,
      );

      if (success) {
        // Add member to local list
        members.value = [...members.value ?? [], newMember];
        memberCount.value = members.value!.length;

        Get.snackbar(
          "Success",
          "${newMember.fullName} added to group",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      } else {
        throw Exception("Failed to add member to group");
      }
    } catch (e) {
      print("❌ Error adding member: $e");
      Get.snackbar(
        "Error",
        "Failed to add member: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Exit group
  Future<void> exitGroup() async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot exit group: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final currentUserUid = currentUser?.uid;
    if (currentUserUid == null) {
      Get.snackbar(
        "Error",
        "Cannot exit group: No user ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation bottom sheet
    final confirmed = await CustomBottomSheets.showConfirmation(
      title: 'Exit Group',
      message: 'Are you sure you want to leave ${groupName.value ?? 'this group'}?',
      subtitle: 'You will no longer receive messages from this group',
      confirmText: 'Exit Group',
      cancelText: 'Cancel',
      icon: Icons.exit_to_app,
      isDanger: true,
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;

      // Show loading
      CustomBottomSheets.showLoading(message: 'Leaving group...');

      await _chatDataSources.exitGroup(roomId!, currentUserUid);

      // Close loading
      CustomBottomSheets.closeLoading();

      // Go back to chat list
      Get.back();
      Get.back();
    } catch (e) {
      print("❌ Error exiting group: $e");

      // Close loading
      CustomBottomSheets.closeLoading();

      Get.snackbar(
        "Error",
        "Failed to exit group: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Report group
  Future<void> reportGroup() async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot report group: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final currentUserUid = currentUser?.uid;
    if (currentUserUid == null) {
      Get.snackbar(
        "Error",
        "Cannot report group: No user ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Show reason selection bottom sheet
    final reason = await CustomBottomSheets.showSelection<String>(
      title: 'Report Group',
      subtitle: 'Select a reason for reporting this group',
      options: [
        SelectionOption<String>(
          title: 'Inappropriate Content',
          subtitle: 'Offensive or inappropriate material',
          icon: Icons.warning,
          iconColor: Colors.orange,
          value: 'Inappropriate content',
        ),
        SelectionOption<String>(
          title: 'Spam',
          subtitle: 'Unwanted or repetitive content',
          icon: Icons.report,
          iconColor: Colors.red,
          value: 'Spam',
        ),
        SelectionOption<String>(
          title: 'Harassment',
          subtitle: 'Bullying or harassment',
          icon: Icons.block,
          iconColor: Colors.red,
          value: 'Harassment',
        ),
        SelectionOption<String>(
          title: 'Other',
          subtitle: 'Other reason',
          icon: Icons.more_horiz,
          iconColor: ColorsManager.grey,
          value: 'Other',
        ),
      ],
    );

    if (reason == null) return;

    try {
      isLoading.value = true;

      // Show loading
      CustomBottomSheets.showLoading(message: 'Reporting group...');

      await _chatDataSources.reportContent(
        contentId: roomId!,
        contentType: 'group',
        reporterId: currentUserUid,
        reason: reason,
      );

      // Close loading
      CustomBottomSheets.closeLoading();
    } catch (e) {
      print("❌ Error reporting group: $e");

      // Close loading
      CustomBottomSheets.closeLoading();

      Get.snackbar(
        "Error",
        "Failed to report group: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite() async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot update favorite: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final oldStatus = isFavorite.value;
      await _chatDataSources.toggleFavoriteChat(roomId!);
      isFavorite.value = !oldStatus;
    } catch (e) {
      print("❌ Error toggling favorite: $e");
      Get.snackbar(
        "Error",
        "Failed to update favorite status: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to starred messages (same implementation as contact_info)
  void viewStarredMessages() {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot view starred messages: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Navigate to starred messages screen with bottom sheet
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    "Starred Messages",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(roomId)
                    .collection('chat')
                    .where('isFavorite', isEqualTo: true)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No starred messages",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap and hold on a message to star it",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>;
                      final messageType = message['type'] ?? 'text';
                      final messageContent = message['text'] ?? message['content'] ?? '';
                      final timestamp = message['timestamp'];
                      final senderId = message['senderId'] ?? '';
                      final currentUserId = UserService.currentUserValue?.uid;
                      final isMe = senderId == currentUserId;

                      // Get sender name from members list
                      String senderName = 'Unknown';
                      if (isMe) {
                        senderName = 'You';
                      } else {
                        final sender = members.value?.firstWhere(
                          (member) => member.uid == senderId,
                          orElse: () => SocialMediaUser(uid: senderId, fullName: 'Unknown'),
                        );
                        senderName = sender?.fullName ?? 'Unknown';
                      }

                      DateTime? dateTime;
                      if (timestamp is String) {
                        dateTime = DateTime.tryParse(timestamp);
                      }

                      return Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: const Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                          title: Text(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                messageType == 'text' ? messageContent : '[$messageType]',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (dateTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(dateTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () async {
                              // Unstar message
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(roomId)
                                  .collection('chat')
                                  .doc(messages[index].id)
                                  .update({'isFavorite': false});
                            },
                          ),
                          onTap: () {
                            // Navigate to message in chat and scroll to it
                            Get.back(); // Close starred messages sheet
                            Get.back(); // Close group info page

                            // Navigate to chat with the message ID to scroll to
                            Get.toNamed(
                              Routes.CHAT,
                              arguments: {
                                'roomId': roomId,
                                'scrollToMessageId': messages[index].id,
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Navigate to media/links/documents
  void viewMediaLinksDocuments() {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot view media: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Navigate to media screen with tabs
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Media & Documents",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: "Photos"),
                  Tab(text: "Videos"),
                  Tab(text: "Files"),
                  Tab(text: "Audio"),
                ],
              ),
              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMediaGrid('photo'),
                    _buildMediaGrid('video'),
                    _buildMediaGrid('file'),
                    _buildMediaGrid('audio'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMediaGrid(String mediaType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .collection('chat')
          .where('type', isEqualTo: mediaType)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final items = snapshot.data?.docs ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForType(mediaType),
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No ${mediaType}s shared yet",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (mediaType == 'photo' || mediaType == 'video') {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final url = data['url'] ?? data['fileUrl'] ?? '';
              final thumbnail = data['thumbnailUrl'] ?? url;

              return GestureDetector(
                onTap: () {
                  // Open full screen viewer for images and videos
                  _openFullScreenViewer(items, index, mediaType);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getIconForType(mediaType),
                                color: Colors.grey.shade400,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _getIconForType(mediaType),
                          color: Colors.grey.shade400,
                        ),
                ),
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final fileName = data['fileName'] ?? data['name'] ?? 'Unknown file';
              final fileSize = data['fileSize'] ?? '';
              final timestamp = data['timestamp'];

              DateTime? dateTime;
              if (timestamp is String) {
                dateTime = DateTime.tryParse(timestamp);
              }

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(_getIconForType(mediaType), color: Colors.blue),
                  ),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileSize.isNotEmpty)
                        Text(
                          fileSize,
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (dateTime != null)
                        Text(
                          _formatTimestamp(dateTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: () async {
                      // Download file
                      final data = items[index].data() as Map<String, dynamic>;
                      final url = data['url'] ?? data['fileUrl'] ?? '';
                      final fileName = data['fileName'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}';

                      if (url.isNotEmpty) {
                        await _downloadFile(url, fileName);
                      }
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'photo':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'file':
        return Icons.insert_drive_file;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Open full screen viewer for media (images/videos)
  void _openFullScreenViewer(
    List<QueryDocumentSnapshot> items,
    int initialIndex,
    String mediaType,
  ) {
    final mediaItems = items.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'url': data['url'] ?? data['fileUrl'] ?? '',
        'type': mediaType,
        'timestamp': data['timestamp'],
      };
    }).toList();

    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Photo Gallery Viewer
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final mediaUrl = mediaItems[index]['url'] as String;

                if (mediaType == 'photo') {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(mediaUrl),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                    heroAttributes: PhotoViewHeroAttributes(tag: mediaUrl),
                  );
                } else {
                  // For videos, show a thumbnail with play button
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.play_circle_outline,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Video playback coming soon',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                  );
                }
              },
              itemCount: mediaItems.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
                ),
              ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: PageController(initialPage: initialIndex),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),

            // Download button
            Positioned(
              bottom: 40,
              right: 16,
              child: FloatingActionButton(
                onPressed: () async {
                  final currentIndex = initialIndex;
                  final url = mediaItems[currentIndex]['url'] as String;
                  await _downloadFile(url, 'media_${DateTime.now().millisecondsSinceEpoch}');
                },
                backgroundColor: ColorsManager.primary,
                child: const Icon(Icons.download, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Build media tab content
  Widget _buildMediaTab(String mediaType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .where('type', isEqualTo: mediaType)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data?.docs ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getMediaIcon(mediaType), size: 64, color: ColorsManager.lightGrey),
                SizedBox(height: 16),
                Text("No ${mediaType}s shared", style: TextStyle(fontSize: 16, color: ColorsManager.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: mediaType == 'image' || mediaType == 'video' ? 3 : 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: mediaType == 'image' || mediaType == 'video' ? 1.0 : 3.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            return _buildMediaItem(mediaType, data);
          },
        );
      },
    );
  }

  /// Download file from URL to device
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();

      if (status.isGranted || status.isLimited) {
        Get.snackbar(
          Constants.kBackup.tr,
          'Downloading $fileName...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Use Dio to download the file
        final dio = Dio();
        final appDir = '/storage/emulated/0/Download'; // Android Downloads folder

        // Create the download path
        final savePath = '$appDir/$fileName';

        // Download file
        await dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(0);
              print('Download progress: $progress%');
            }
          },
        );

        Get.snackbar(
          Constants.kSuccess.tr,
          'File downloaded successfully to Downloads folder',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (status.isPermanentlyDenied) {
        Get.snackbar(
          Constants.kError.tr,
          'Storage permission is required. Please enable it in settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        await openAppSettings();
      } else {
        Get.snackbar(
          Constants.kError.tr,
          'Storage permission denied',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        Constants.kError.tr,
        'Failed to download file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Check if current user is an admin (first member or creator)
  bool get isCurrentUserAdmin {
    if (members.value == null || members.value!.isEmpty || currentUser == null) return false;
    return members.value!.first.uid == currentUser!.uid;
  }

  /// Get non-admin members (for removal options)
  List<SocialMediaUser> get removableMembers {
    if (members.value == null || !isCurrentUserAdmin) return [];
    return members.value!.where((member) => member.uid != currentUser?.uid).toList();
  }

  // Getters for easy access
  String get displayName => groupName.value ?? "Group Chat";
  String get displayDescription => groupDescription.value ?? "No description";
  String get displayMemberCount => "${memberCount.value ?? 0} ${memberCount.value == 1 ? 'member' : 'members'}";
  String? get displayImage => groupImageUrl.value;

  // Check if group has description
  bool get hasDescription => groupDescription.value != null && groupDescription.value!.isNotEmpty;

  /// Get icon for media type
  IconData _getMediaIcon(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'image':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'file':
        return Icons.insert_drive_file;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.attachment;
    }
  }

  /// Build media item widget based on type
  Widget _buildMediaItem(String mediaType, Map<String, dynamic> data) {
    final messageId = data['messageId'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
        : '';

    switch (mediaType.toLowerCase()) {
      case 'image':
        final imageUrl = data['imageUrl'] ?? data['url'] ?? '';
        return GestureDetector(
          onTap: () => viewFullPhoto(imageUrl, messageId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: ColorsManager.lightGrey,
                      child: Icon(Icons.broken_image, color: ColorsManager.grey),
                    ),
                  )
                : Container(
                    color: ColorsManager.lightGrey,
                    child: Icon(Icons.image, color: ColorsManager.grey),
                  ),
          ),
        );

      case 'video':
        final videoUrl = data['videoUrl'] ?? data['url'] ?? '';
        final thumbnailUrl = data['thumbnailUrl'] ?? '';
        return GestureDetector(
          onTap: () {
            if (videoUrl.isNotEmpty) {
              Get.snackbar('Video', 'Opening video: $videoUrl');
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumbnailUrl.isNotEmpty)
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: ColorsManager.lightGrey,
                      child: Icon(Icons.video_library, color: ColorsManager.grey, size: 48),
                    ),
                  )
                else
                  Container(
                    color: ColorsManager.lightGrey,
                    child: Icon(Icons.video_library, color: ColorsManager.grey, size: 48),
                  ),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'file':
        final fileName = data['fileName'] ?? 'Unknown File';
        final fileUrl = data['fileUrl'] ?? data['url'] ?? '';
        final fileSize = data['fileSize'] ?? '';
        return InkWell(
          onTap: () {
            if (fileUrl.isNotEmpty) {
              _downloadFile(fileUrl, fileName);
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsManager.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsManager.lightGrey),
            ),
            child: Row(
              children: [
                Icon(_getMediaIcon('file'), color: ColorsManager.primary, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fileName,
                        style: StylesManager.medium(fontSize: FontSize.small),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fileSize.isNotEmpty)
                        Text(
                          fileSize,
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.download, color: ColorsManager.primary),
              ],
            ),
          ),
        );

      case 'audio':
        final audioUrl = data['audioUrl'] ?? data['url'] ?? '';
        final duration = data['duration'] ?? '';
        return InkWell(
          onTap: () {
            if (audioUrl.isNotEmpty) {
              Get.snackbar('Audio', 'Playing audio: $audioUrl');
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsManager.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsManager.lightGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.audiotrack, color: ColorsManager.primary, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Voice Message',
                        style: StylesManager.medium(fontSize: FontSize.small),
                      ),
                      if (duration.isNotEmpty)
                        Text(
                          duration,
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle, color: ColorsManager.primary, size: 32),
              ],
            ),
          ),
        );

      default:
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorsManager.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Unknown media type: $mediaType',
              style: StylesManager.regular(fontSize: FontSize.small),
            ),
          ),
        );
    }
  }
}
