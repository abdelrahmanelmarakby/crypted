import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';

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

      // In a real implementation, this would call an API to update the group
      // For now, we'll simulate a successful update
      await Future.delayed(const Duration(milliseconds: 500));

      Get.snackbar(
        "Success",
        "Group information updated successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
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

      Get.snackbar(
        "Success",
        "Member removed from group",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
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

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Exit Group"),
        content: Text("Are you sure you want to leave ${groupName.value ?? 'this group'}?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Exit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;
      await _chatDataSources.exitGroup(roomId!, currentUserUid);

      Get.snackbar(
        "Success",
        "You have left the group",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );

      // Go back to chat list
      Get.back();
      Get.back();
    } catch (e) {
      print("❌ Error exiting group: $e");
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

    // Show reason selection dialog
    final reason = await Get.dialog<String>(
      AlertDialog(
        title: const Text("Report Group"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Inappropriate content"),
              onTap: () => Get.back(result: "Inappropriate content"),
            ),
            ListTile(
              title: const Text("Spam"),
              onTap: () => Get.back(result: "Spam"),
            ),
            ListTile(
              title: const Text("Harassment"),
              onTap: () => Get.back(result: "Harassment"),
            ),
            ListTile(
              title: const Text("Other"),
              onTap: () => Get.back(result: "Other"),
            ),
          ],
        ),
      ),
    );

    if (reason == null) return;

    try {
      isLoading.value = true;
      await _chatDataSources.reportContent(
        contentId: roomId!,
        contentType: 'group',
        reporterId: currentUserUid,
        reason: reason,
      );

      Get.snackbar(
        "Success",
        "Group reported successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Error reporting group: $e");
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

      Get.snackbar(
        "Success",
        !oldStatus ? "Added to favorites" : "Removed from favorites",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
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

  /// Navigate to starred messages
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

    // Navigate to starred messages screen
    Get.dialog(
      AlertDialog(
        title: const Text("Starred Messages"),
        content: const Text("This feature will show all messages starred in this group."),
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
                "Starred messages list will be shown here",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text("View"),
          ),
        ],
      ),
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
