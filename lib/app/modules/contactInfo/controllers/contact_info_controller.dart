import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:flutter/material.dart';

class ContactInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  // Contact data - can be either user or group
  final Rx<SocialMediaUser?> user = Rx<SocialMediaUser?>(null);

  // Group data (for when this is a group contact)
  final Rx<String?> groupName = Rx<String?>(null);
  final Rx<String?> groupDescription = Rx<String?>(null);
  final Rx<int?> groupMemberCount = Rx<int?>(null);
  final Rx<bool?> isGroup = Rx<bool?>(null);

  // Room data
  String? roomId;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isBlocked = false.obs;
  final RxBool isFavorite = false.obs;
  final RxBool isArchived = false.obs;

  // Data source
  final ChatDataSources _chatDataSources = ChatDataSources();

  @override
  void onInit() {
    super.onInit();
    _loadContactData();
  }

  Future<void> _loadContactData() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      // Get room ID
      roomId = arguments['roomId'] as String?;

      // Check if this is a group or individual user
      if (arguments['isGroup'] == true) {
        // Group contact
        isGroup.value = true;
        groupName.value = arguments['chatName'] as String?;
        groupDescription.value = arguments['chatDescription'] as String?;
        groupMemberCount.value = arguments['memberCount'] as int?;
        print("✅ Loaded group contact data: ${groupName.value}");
      } else {
        // Individual user contact
        isGroup.value = false;
        user.value = arguments['user'] as SocialMediaUser?;
        print("✅ Loaded user contact data: ${user.value?.fullName}");

        // Load blocked status if we have a user ID
        if (user.value?.uid != null) {
          await _checkBlockedStatus();
        }
      }

      // Load favorite and archived status if we have a room ID
      if (roomId != null) {
        await _loadChatStatus();
      }
    } else {
      print("❌ No contact data provided to contact info screen");
      isLoading.value = false;
    }
  }

  /// Check if user is blocked
  Future<void> _checkBlockedStatus() async {
    if (user.value?.uid == null || roomId == null) return;

    try {
      final chatRoom = await _chatDataSources.getChatRoomById(roomId!);
      if (chatRoom != null) {
        final blockedList = chatRoom.blockedUsers ?? [];
        isBlocked.value = blockedList.contains(user.value!.uid);
      }
    } catch (e) {
      print("❌ Error checking blocked status: $e");
    }
  }

  /// Load chat status (favorite, archived)
  Future<void> _loadChatStatus() async {
    if (roomId == null) return;

    try {
      final chatRoom = await _chatDataSources.getChatRoomById(roomId!);
      if (chatRoom != null) {
        isFavorite.value = chatRoom.isFavorite ?? false;
        isArchived.value = chatRoom.isArchived ?? false;

        // Also check blocked status here if we haven't already
        if (user.value?.uid != null) {
          final blockedList = chatRoom.blockedUsers ?? [];
          isBlocked.value = blockedList.contains(user.value!.uid);
        }
      }
    } catch (e) {
      print("❌ Error loading chat status: $e");
    }
  }

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
  }

  /// Refresh contact data
  Future<void> refreshContactData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      // In a real implementation, this would fetch fresh data from the server
      // For now, we'll just reload from current data
      await _loadContactData();
    } catch (e) {
      print("❌ Error refreshing contact data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Block or unblock user
  Future<void> toggleBlockUser() async {
    if (user.value?.uid == null || roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot block user: No user or room data available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      if (isBlocked.value) {
        // Unblock user
        await _chatDataSources.unblockUser(roomId!, user.value!.uid);
        isBlocked.value = false;
        Get.snackbar(
          "Success",
          "User unblocked successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      } else {
        // Block user - show confirmation dialog
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text("Block User"),
            content: Text("Are you sure you want to block ${user.value!.fullName}?"),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text("Block", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _chatDataSources.blockUser(roomId!, user.value!.uid);
          isBlocked.value = true;
          Get.snackbar(
            "Success",
            "User blocked successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print("❌ Error toggling block status: $e");
      Get.snackbar(
        "Error",
        "Failed to update block status: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear chat with confirmation
  Future<void> clearChat() async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot clear chat: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Clear Chat"),
        content: const Text(
          "Are you sure you want to clear all messages in this chat? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;
      await _chatDataSources.clearChat(roomId!);

      Get.snackbar(
        "Success",
        "Chat cleared successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );

      // Go back to chat list
      Get.back();
    } catch (e) {
      print("❌ Error clearing chat: $e");
      Get.snackbar(
        "Error",
        "Failed to clear chat: ${e.toString()}",
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

    // TODO: Navigate to starred messages screen
    Get.snackbar(
      "Coming Soon",
      "Starred messages view will be implemented",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
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

    // TODO: Navigate to media screen
    Get.snackbar(
      "Coming Soon",
      "Media/Links/Documents view will be implemented",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  /// Export chat
  Future<void> exportChat() async {
    if (roomId == null) {
      Get.snackbar(
        "Error",
        "Cannot export chat: No room ID available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // TODO: Implement chat export functionality
    Get.snackbar(
      "Coming Soon",
      "Chat export will be implemented",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  /// View contact details
  void viewContactDetails() {
    if (user.value == null && !isGroupContact) {
      Get.snackbar(
        "Error",
        "No contact details available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // TODO: Navigate to contact details screen
    Get.snackbar(
      "Coming Soon",
      "Contact details view will be implemented",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  // Getters for easy access - User data
  String get userName => user.value?.fullName ?? "Unknown User";
  String get userEmail => user.value?.email ?? "No email";
  String? get userImage => user.value?.imageUrl;
  String get userBio => user.value?.bio ?? "No bio available";
  String get userPhone => user.value?.phoneNumber ?? "No phone number";

  // Getters for easy access - Group data
  String get groupDisplayName => groupName.value ?? "Group Chat";
  String get groupDisplayDescription => groupDescription.value ?? "No description";
  String get groupDisplayMemberCount => "${groupMemberCount.value ?? 0} ${groupMemberCount.value == 1 ? 'member' : 'members'}";

  // Check if this is a group contact
  bool get isGroupContact => isGroup.value == true;

  // Get the display name (user or group)
  String get displayName => isGroupContact ? groupDisplayName : userName;

  // Get the subtitle (for user status or group member count)
  String get displaySubtitle => isGroupContact ? groupDisplayMemberCount : userBio;

  // Get the image (user or group)
  String? get displayImage => isGroupContact ? null : userImage; // Groups use different image handling
}
