import 'package:crypted_app/app/modules/group_info/widgets/group_media_controlls.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_media_item.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_permissions_editor.dart';
import 'package:crypted_app/app/modules/group_info/widgets/group_invite_link_manager.dart';
import 'package:crypted_app/app/widgets/custom_bottom_sheets.dart';
import 'package:crypted_app/app/core/utils/file_download_helper.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypted_app/app/modules/media_gallery/views/video_player_view.dart';

enum MediaType { image, video, file, audio ,}

class GroupInfoController extends GetxController {
  // Group data - reactive for real-time updates
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<String?> groupImageUrl = Rx<String?>(null);
  final Rx<int?> memberCount = Rx<int?>(null);
  final Rx<List<SocialMediaUser>?> members = Rx<List<SocialMediaUser>?>(null);

  // Admin tracking
  final RxList<String> adminIds = <String>[].obs;
  final Rx<String?> createdBy = Rx<String?>(null);

  // Room data
  String? roomId;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isFavorite = false.obs;

  // Member search
  final RxString memberSearchQuery = ''.obs;
  final TextEditingController memberSearchController = TextEditingController();

  // Group permissions
  final Rx<GroupPermissions> permissions = const GroupPermissions().obs;

  // Invite link state
  final Rx<GroupInviteLink?> primaryInviteLink = Rx<GroupInviteLink?>(null);
  final RxBool hasInviteLink = false.obs;

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

      // Load admin info from arguments if available
      if (arguments['adminIds'] != null) {
        adminIds.value = List<String>.from(arguments['adminIds'] as List);
      }
      if (arguments['createdBy'] != null) {
        createdBy.value = arguments['createdBy'] as String?;
      }

      print("✅ Loaded group data:");
      print("   Name: ${groupName.value}");
      print("   Members: ${memberCount.value}");
      print("   Admins: ${adminIds.length}");
      print("   Description: ${groupDescription.value?.isNotEmpty == true ? 'Yes' : 'No'}");

      // Ensure current user is in members list if not present
      _ensureCurrentUserInMembers();

      // Load favorite status and admin info if we have a room ID
      if (roomId != null) {
        await _loadGroupStatus();
      }
    } else {
      print("❌ No group data provided to group info screen");
      isLoading.value = false;
    }
  }

  /// Load group status (favorite) and admin info
  Future<void> _loadGroupStatus() async {
    if (roomId == null) return;

    try {
      final chatRoom = await _chatDataSources.getChatRoomById(roomId!);
      if (chatRoom != null) {
        isFavorite.value = chatRoom.isFavorite ?? false;

        // Load admin info from ChatRoom if not already loaded
        if (adminIds.isEmpty && chatRoom.adminIds != null) {
          adminIds.value = chatRoom.adminIds!;
        }
        if (createdBy.value == null && chatRoom.createdBy != null) {
          createdBy.value = chatRoom.createdBy;
        }

        // Fallback: if no adminIds, set first member as admin and update Firestore
        if (adminIds.isEmpty && members.value != null && members.value!.isNotEmpty) {
          final firstMemberId = members.value!.first.uid;
          if (firstMemberId != null) {
            adminIds.add(firstMemberId);
            // Optionally update Firestore to persist this
            _migrateAdminIds(firstMemberId);
          }
        }
      }

      // Load permissions from Firestore directly
      final roomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .get();

      if (roomDoc.exists) {
        final data = roomDoc.data();
        if (data != null && data['permissions'] != null) {
          permissions.value = GroupPermissions.fromMap(
            Map<String, dynamic>.from(data['permissions']),
          );
        }
      }

      // Load invite link
      await loadInviteLink();
    } catch (e) {
      print("❌ Error loading group status: $e");
    }
  }

  /// Migrate legacy groups to use adminIds field
  Future<void> _migrateAdminIds(String adminId) async {
    if (roomId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .update({
        'adminIds': [adminId],
        'createdBy': adminId,
      });
      print("✅ Migrated adminIds for group $roomId");
    } catch (e) {
      print("⚠️ Could not migrate adminIds: $e");
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
          backgroundColor: Colors.green.withValues(alpha: 0.9),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
          backgroundColor: Colors.red.withValues(alpha: 0.8),
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
          backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
          backgroundColor: Colors.red.withValues(alpha: 0.8),
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
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
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
          backgroundColor: Colors.green.withValues(alpha: 0.9),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
                    _buildMediaGrid(MediaType.image),
                    _buildMediaGrid(MediaType.video),
                    _buildMediaGrid(MediaType.file),
                    _buildMediaGrid(MediaType.audio),
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

  Widget _buildMediaGrid(MediaType mediaType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .collection('chat')
          .where('type', isEqualTo: mediaType.name)
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
                  "No ${mediaType.name}s shared yet",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (mediaType.name == 'image' || mediaType.name == 'video') {
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

  IconData _getIconForType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Iconsax.image_copy;
      case MediaType.video:
        return Iconsax.video_circle;
      case MediaType.file:
        return Iconsax.document_1;
      case MediaType.audio:
        return Iconsax.audio_square;
      default:
        return Iconsax.document;
    }
  }

  /// Open full screen viewer for media (images/videos)
  void _openFullScreenViewer(
    List<QueryDocumentSnapshot> items,
    int initialIndex,
    MediaType mediaType,
  ) {
    final mediaItems = items.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'url': data['url'] ?? data['fileUrl'] ?? '',
        'type': mediaType.name,
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

                if (mediaType.name == MediaType.image.name) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(mediaUrl),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                    heroAttributes: PhotoViewHeroAttributes(tag: mediaUrl),
                  );
                } else {
                  // For videos, show play button that opens video player
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTap: () {
                        // Close the gallery and open video player
                        Get.back();
                        Get.to(
                          () => VideoPlayerView(
                            videoUrl: mediaUrl,
                            title: 'Video',
                          ),
                          transition: Transition.fadeIn,
                        );
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 50,
                                color: ColorsManager.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to play video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
      // isScrollControlled: true,
    );
  }

  /// Build media tab content
  Widget _buildMediaTab(MediaType mediaType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .where('type', isEqualTo: mediaType.name)
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
                Icon(_getIconForType(mediaType), size: 64, color: ColorsManager.lightGrey),
                SizedBox(height: 16),
                Text("No ${mediaType.name}s shared", style: TextStyle(fontSize: 16, color: ColorsManager.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: mediaType.name == 'image' || mediaType.name == 'video' ? 3 : 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: mediaType.name == 'image' || mediaType.name == 'video' ? 1.0 : 3.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            return GroupMediaItem(
              mediaType: mediaType,
              mediaUrl: data['url'] ?? data['fileUrl'] ?? '',
              heroTag: data['url'] ?? data['fileUrl'] ?? '',
              title: data['caption'] ?? '',
              thumbnailUrl: data['thumbnailUrl'] ?? '',
              subtitle: data['caption'] ?? '',
              timestampLabel: data['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(data['timestamp']).toString() : null,
              fileSizeLabel: data['fileSize'] != null ? '${data['fileSize']} bytes' : null,
              durationLabel: data['duration'] != null ? '${data['duration']} seconds' : null,
              onPreview: () => MediaPreview.previewMedia(context, mediaType, data),
              onOpenExternally: () => MediaPreview.openExternally(context, data['url']),
              onDownload: () => _downloadFile(data['url'] ?? data['fileUrl'] ?? '', 'media_${DateTime.now().millisecondsSinceEpoch}'),
              // onOpenExternally: () => _openExternally(data['url'] ?? data['fileUrl'] ?? ''),
              onShare: ()async => await Share.share(data['url'] ?? data['fileUrl'] ?? ''),
            );
          },
        );
      },
    );
  }

  /// Download file from URL to device (platform-aware)
  Future<void> _downloadFile(String url, String fileName) async {
    FileDownloadHelper.showDownloadProgress(fileName);

    final result = await FileDownloadHelper.downloadFile(
      url: url,
      fileName: fileName,
      onProgress: (progress) {
        print('Download progress: $progress%');
      },
    );

    if (result.success) {
      FileDownloadHelper.showDownloadComplete(fileName, result.filePath!);
    } else {
      FileDownloadHelper.showDownloadError(result.errorMessage ?? 'Download failed');
    }
  }

  /// Check if current user is an admin
  bool get isCurrentUserAdmin {
    if (currentUser == null) return false;
    final userId = currentUser!.uid;
    if (userId == null) return false;

    // Check adminIds list first
    if (adminIds.contains(userId)) {
      return true;
    }

    // Check if user is the creator
    if (createdBy.value != null && createdBy.value == userId) {
      return true;
    }

    // Legacy fallback: first member is admin (only if no adminIds set)
    if (adminIds.isEmpty && members.value != null && members.value!.isNotEmpty) {
      return members.value!.first.uid == userId;
    }

    return false;
  }

  /// Check if a specific user is an admin
  bool isUserAdmin(String userId) {
    if (adminIds.contains(userId)) return true;
    if (createdBy.value != null && createdBy.value == userId) return true;
    if (adminIds.isEmpty && members.value != null && members.value!.isNotEmpty) {
      return members.value!.first.uid == userId;
    }
    return false;
  }

  /// Check if a specific user is the creator
  bool isUserCreator(String userId) {
    return createdBy.value != null && createdBy.value == userId;
  }

  /// Make a user an admin
  Future<void> makeAdmin(String userId) async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot make admin: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (!isCurrentUserAdmin) {
      Get.snackbar(
        "Error",
        "Only admins can make other members admin",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (adminIds.contains(userId)) {
      Get.snackbar(
        "Info",
        "This user is already an admin",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });

      // Update local state
      adminIds.add(userId);

      // Get member name for snackbar
      final member = members.value?.firstWhere(
        (m) => m.uid == userId,
        orElse: () => SocialMediaUser(uid: userId, fullName: 'User'),
      );

      Get.snackbar(
        "Success",
        "${member?.fullName ?? 'User'} is now a group admin",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Error making admin: $e");
      Get.snackbar(
        "Error",
        "Failed to make admin: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove admin privileges from a user
  Future<void> removeAdmin(String userId) async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot remove admin: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (!isCurrentUserAdmin) {
      Get.snackbar(
        "Error",
        "Only admins can remove admin privileges",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Cannot remove creator's admin status
    if (isUserCreator(userId)) {
      Get.snackbar(
        "Error",
        "Cannot remove admin privileges from the group creator",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Cannot remove yourself if you're the only admin
    if (userId == currentUser?.uid && adminIds.length <= 1) {
      Get.snackbar(
        "Error",
        "You cannot remove yourself as the only admin. Make someone else admin first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .update({
        'adminIds': FieldValue.arrayRemove([userId]),
      });

      // Update local state
      adminIds.remove(userId);

      // Get member name for snackbar
      final member = members.value?.firstWhere(
        (m) => m.uid == userId,
        orElse: () => SocialMediaUser(uid: userId, fullName: 'User'),
      );

      Get.snackbar(
        "Success",
        "${member?.fullName ?? 'User'} is no longer an admin",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Error removing admin: $e");
      Get.snackbar(
        "Error",
        "Failed to remove admin: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update group permissions
  Future<void> updatePermissions(GroupPermissions newPermissions) async {
    permissions.value = newPermissions;
  }

  /// Check if user can perform action based on permissions
  bool canEditGroupInfo() {
    if (permissions.value.editGroupInfo == PermissionLevel.everyone) return true;
    return isCurrentUserAdmin;
  }

  bool canSendMessages() {
    if (permissions.value.sendMessages == PermissionLevel.everyone) return true;
    return isCurrentUserAdmin;
  }

  bool canAddMembers() {
    if (permissions.value.addMembers == PermissionLevel.everyone) return true;
    return isCurrentUserAdmin;
  }

  /// Get non-admin members (for removal options)
  List<SocialMediaUser> get removableMembers {
    if (members.value == null || !isCurrentUserAdmin) return [];
    return members.value!.where((member) {
      final uid = member.uid;
      if (uid == null) return false;
      // Exclude current user and other admins
      if (uid == currentUser?.uid) return false;
      if (isUserAdmin(uid)) return false;
      return true;
    }).toList();
  }

  // Getters for easy access
  String get displayName => groupName.value ?? "Group Chat";
  String get displayDescription => groupDescription.value ?? "No description";
  String get displayMemberCount => "${memberCount.value ?? 0} ${memberCount.value == 1 ? 'member' : 'members'}";
  String? get displayImage => groupImageUrl.value;

  // Check if group has description
  bool get hasDescription => groupDescription.value != null && groupDescription.value!.isNotEmpty;

  /// Get filtered members based on search query
  List<SocialMediaUser> get filteredMembers {
    if (members.value == null) return [];
    if (memberSearchQuery.value.isEmpty) return members.value!;

    final query = memberSearchQuery.value.toLowerCase();
    return members.value!.where((member) {
      final name = member.fullName?.toLowerCase() ?? '';
      final bio = member.bio?.toLowerCase() ?? '';
      return name.contains(query) || bio.contains(query);
    }).toList();
  }

  /// Update member search query
  void updateMemberSearch(String query) {
    memberSearchQuery.value = query;
  }

  /// Clear member search
  void clearMemberSearch() {
    memberSearchQuery.value = '';
    memberSearchController.clear();
  }

  // ===========================================================================
  // INVITE LINK MANAGEMENT
  // ===========================================================================

  /// Load primary invite link for the group
  Future<void> loadInviteLink() async {
    if (roomId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('group_invite_links')
          .where('groupId', isEqualTo: roomId)
          .where('isRevoked', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final link = GroupInviteLink.fromMap(doc.id, doc.data());
        if (link.isValid) {
          primaryInviteLink.value = link;
          hasInviteLink.value = true;
        }
      }
    } catch (e) {
      print('❌ Error loading invite link: $e');
    }
  }

  /// Open invite link manager
  Future<void> openInviteLinkManager(BuildContext context) async {
    if (roomId == null) {
      Get.snackbar(
        'Error',
        'Cannot manage invite links: No room ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    await GroupInviteLinkManager.show(
      context: context,
      groupId: roomId!,
      groupName: displayName,
      isAdmin: isCurrentUserAdmin,
    );

    // Reload invite link after manager closes
    await loadInviteLink();
  }

  /// Copy invite link to clipboard
  void copyInviteLink() {
    if (primaryInviteLink.value == null) {
      Get.snackbar(
        'No Link',
        'Create an invite link first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: primaryInviteLink.value!.fullLink));
    HapticFeedback.lightImpact();

    Get.snackbar(
      'Copied',
      'Invite link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Share invite link
  void shareInviteLink() {
    if (primaryInviteLink.value == null) {
      Get.snackbar(
        'No Link',
        'Create an invite link first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    Share.share(
      'Join $displayName on Crypted!\n\n${primaryInviteLink.value!.fullLink}',
      subject: 'Join $displayName',
    );
  }

  @override
  void onClose() {
    memberSearchController.dispose();
    super.onClose();
  }
}
