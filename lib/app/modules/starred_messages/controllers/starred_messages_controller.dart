import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/routes/app_pages.dart';

/// Arguments for navigating to starred messages
class StarredMessagesArguments {
  final String? roomId;
  final String? roomName;
  final bool showAllRooms;

  StarredMessagesArguments({
    this.roomId,
    this.roomName,
    this.showAllRooms = false,
  });
}

/// Model for starred message with room context
class StarredMessageItem {
  final MessageModel message;
  final String roomId;
  final String? roomName;
  final DateTime? starredAt;

  StarredMessageItem({
    required this.message,
    required this.roomId,
    this.roomName,
    this.starredAt,
  });
}

/// Controller for starred messages view
class StarredMessagesController extends GetxController {
  // Arguments
  String? roomId;
  String? roomName;
  bool showAllRooms = false;

  // State
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<StarredMessageItem> starredMessages = <StarredMessageItem>[].obs;

  // Selection
  final RxSet<String> selectedIds = <String>{}.obs;
  final RxBool isSelectionMode = false.obs;

  // Current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();

    // Get arguments
    final args = Get.arguments;
    if (args is StarredMessagesArguments) {
      roomId = args.roomId;
      roomName = args.roomName;
      showAllRooms = args.showAllRooms;
    } else if (args is Map<String, dynamic>) {
      roomId = args['roomId'];
      roomName = args['roomName'];
      showAllRooms = args['showAllRooms'] ?? false;
    }

    // Load starred messages
    _loadStarredMessages();
  }

  /// Load starred messages from Firestore
  Future<void> _loadStarredMessages() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (showAllRooms || roomId == null) {
        // Load from all rooms user is a member of
        await _loadAllRoomsStarred();
      } else {
        // Load from specific room
        await _loadRoomStarred(roomId!);
      }

      isLoading.value = false;
    } catch (e) {
      log('Error loading starred messages: $e');
      errorMessage.value = 'Failed to load starred messages';
      isLoading.value = false;
    }
  }

  /// Load starred messages from a specific room
  Future<void> _loadRoomStarred(String roomId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(roomId)
        .collection('chat')
        .where('isFavorite', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    starredMessages.value = snapshot.docs.map((doc) {
      return StarredMessageItem(
        message: MessageModel.fromQuery(doc),
        roomId: roomId,
        roomName: roomName,
      );
    }).toList();
  }

  /// Load starred messages from all rooms
  Future<void> _loadAllRoomsStarred() async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    // Get all rooms user is a member of
    final roomsSnapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('membersIds', arrayContains: userId)
        .get();

    final allStarred = <StarredMessageItem>[];

    for (final roomDoc in roomsSnapshot.docs) {
      final roomData = roomDoc.data();
      final roomName = roomData['name'] as String?;

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomDoc.id)
          .collection('chat')
          .where('isFavorite', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        allStarred.add(StarredMessageItem(
          message: MessageModel.fromQuery(messageDoc),
          roomId: roomDoc.id,
          roomName: roomName ?? _getOtherUserName(roomData, userId),
        ));
      }
    }

    // Sort by timestamp
    allStarred.sort((a, b) {
      final aTime = a.message.timestamp;
      final bTime = b.message.timestamp;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    starredMessages.value = allStarred;
  }

  /// Get other user's name for private chats
  String _getOtherUserName(Map<String, dynamic> roomData, String currentUserId) {
    final members = roomData['members'] as List<dynamic>?;
    if (members == null) return 'Chat';

    for (final member in members) {
      if (member is Map<String, dynamic>) {
        final uid = member['uid'] as String?;
        if (uid != null && uid != currentUserId) {
          return member['fullName'] as String? ?? 'Chat';
        }
      }
    }
    return 'Chat';
  }

  /// Unstar a message
  Future<void> unstarMessage(StarredMessageItem item) async {
    final messageId = item.message.messageId;
    if (messageId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(item.roomId)
          .collection('chat')
          .doc(messageId)
          .update({'isFavorite': false});

      starredMessages.removeWhere((m) => m.message.messageId == messageId);

      Get.snackbar(
        'Unstarred',
        'Message removed from starred',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      log('Error unstarring message: $e');
      Get.snackbar('Error', 'Failed to unstar message');
    }
  }

  /// Unstar selected messages
  Future<void> unstarSelected() async {
    if (selectedIds.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Unstar Messages'),
        content: Text('Unstar ${selectedIds.length} message(s)?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Unstar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final id in selectedIds) {
        final item = starredMessages.firstWhereOrNull(
          (m) => m.message.messageId == id,
        );
        if (item != null) {
          await FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(item.roomId)
              .collection('chat')
              .doc(id)
              .update({'isFavorite': false});
        }
      }

      starredMessages.removeWhere(
        (m) => selectedIds.contains(m.message.messageId),
      );
      selectedIds.clear();
      isSelectionMode.value = false;

      Get.snackbar('Success', 'Messages unstarred');
    } catch (e) {
      log('Error unstarring messages: $e');
      Get.snackbar('Error', 'Failed to unstar some messages');
    }
  }

  /// Navigate to message in chat
  void goToMessage(StarredMessageItem item) {
    Get.toNamed(
      Routes.CHAT,
      arguments: {
        'roomId': item.roomId,
        'scrollToMessageId': item.message.messageId,
      },
    );
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedIds.clear();
    }
  }

  /// Toggle item selection
  void toggleSelection(String messageId) {
    if (selectedIds.contains(messageId)) {
      selectedIds.remove(messageId);
    } else {
      selectedIds.add(messageId);
    }

    if (selectedIds.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  /// Check if item is selected
  bool isSelected(String messageId) {
    return selectedIds.contains(messageId);
  }

  /// Refresh starred messages
  Future<void> refresh() async {
    await _loadStarredMessages();
  }

  /// Forward selected messages
  Future<void> forwardSelected() async {
    // TODO: Implement forward functionality
    Get.snackbar('Info', 'Forward functionality coming soon');
  }
}
