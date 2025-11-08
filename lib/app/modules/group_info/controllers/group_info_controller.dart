import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/widgets/custom_bottom_sheets.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

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

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
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
  Future<void> updateGroupInfo({String? name, String? description}) async {
    try {
      isLoading.value = true;

      // Update local state immediately for better UX
      if (name != null && name.isNotEmpty) {
        groupName.value = name;
      }
      if (description != null) {
        groupDescription.value = description;
      }

      // Update in Firestore if roomId exists
      if (roomId != null) {
        final updateData = <String, dynamic>{};
        if (name != null && name.isNotEmpty) updateData['name'] = name;
        if (description != null) updateData['description'] = description;

        if (updateData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(roomId)
              .update(updateData);
        }
      }
    } catch (e) {
      print("❌ Error updating group info: $e");
      Get.snackbar(
        "Error",
        "Failed to update group information",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
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
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorsManager.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Starred Messages",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(roomId)
                    .collection('chat')
                    .where('isFavorite', isEqualTo: true)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border, size: 64, color: ColorsManager.lightGrey),
                          SizedBox(height: 16),
                          Text("No starred messages", style: TextStyle(fontSize: 16, color: ColorsManager.grey)),
                          SizedBox(height: 8),
                          Text("Tap and hold on a message to star it", style: TextStyle(fontSize: 14, color: ColorsManager.lightGrey)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>;
                      final messageType = message['type'] ?? 'text';
                      final messageContent = message['text'] ?? message['content'] ?? '';

                      return Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                          title: Text(
                            messageType == 'text' ? messageContent : '[$messageType]',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('chat_rooms')
                                  .doc(roomId)
                                  .collection('chat')
                                  .doc(messages[index].id)
                                  .update({'isFavorite': false});
                            },
                          ),
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

    // Navigate to media screen
    Get.dialog(
      AlertDialog(
        title: const Text("Media & Documents"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("View all media, links, and documents shared in this group."),
            SizedBox(height: 16),
            Text("Categories:"),
            Text("• Photos & Videos"),
            Text("• Links"),
            Text("• Documents & Files"),
            Text("• Audio Messages"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Feature In Progress",
                "Media gallery will be shown here",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text("View Gallery"),
          ),
        ],
      ),
    );
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
}
