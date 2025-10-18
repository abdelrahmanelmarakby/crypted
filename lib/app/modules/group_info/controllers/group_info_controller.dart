import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class GroupInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  // Group data - reactive for real-time updates
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<String?> groupImageUrl = Rx<String?>(null);
  final Rx<int?> memberCount = Rx<int?>(null);
  final Rx<List<SocialMediaUser>?> members = Rx<List<SocialMediaUser>?>(null);

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Current user for admin checks
  SocialMediaUser? get currentUser => UserService.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadGroupData();
  }

  void _loadGroupData() {
    final arguments = Get.arguments;
    if (arguments != null) {
      groupName.value = arguments['chatName'] as String?;
      groupDescription.value = arguments['chatDescription'] as String?;
      memberCount.value = arguments['memberCount'] as int?;
      members.value = arguments['members'] as List<SocialMediaUser>?;
      groupImageUrl.value = arguments['groupImageUrl'] as String?;

      print("✅ Loaded group data:");
      print("   Name: ${groupName.value}");
      print("   Members: ${memberCount.value}");
      print("   Description: ${groupDescription.value?.isNotEmpty == true ? 'Yes' : 'No'}");

      // Ensure current user is in members list if not present
      _ensureCurrentUserInMembers();
    } else {
      print("❌ No group data provided to group info screen");
      isLoading.value = false;
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
    try {
      if (members.value == null) return;

      // Don't allow removing yourself
      if (userId == currentUser?.uid) {
        Get.snackbar(
          "Error",
          "You cannot remove yourself from the group",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      // Remove member from local list
      members.value = members.value!.where((member) => member.uid != userId).toList();
      memberCount.value = members.value!.length;

      // In a real implementation, this would call an API to remove the member
      // For now, we'll simulate a successful removal
      await Future.delayed(const Duration(milliseconds: 300));

      Get.snackbar(
        "Success",
        "Member removed from group",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("❌ Error removing member: $e");
      Get.snackbar(
        "Error",
        "Failed to remove member",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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
}
