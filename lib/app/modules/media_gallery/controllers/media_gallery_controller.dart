import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';

/// Types of media that can be displayed in the gallery
enum MediaType { photos, videos, files, links, audio }

/// Arguments for navigating to the media gallery
class MediaGalleryArguments {
  final String roomId;
  final String? roomName;
  final MediaType initialTab;

  MediaGalleryArguments({
    required this.roomId,
    this.roomName,
    this.initialTab = MediaType.photos,
  });
}

/// Controller for the media gallery view
class MediaGalleryController extends GetxController
    with GetTickerProviderStateMixin {
  late final TabController tabController;

  // Arguments
  late final String roomId;
  late final String? roomName;
  late final MediaType initialTab;

  // State
  final RxBool isLoading = true.obs;
  final RxString? errorMessage = RxString('');

  // Media lists
  final RxList<MessageModel> photos = <MessageModel>[].obs;
  final RxList<MessageModel> videos = <MessageModel>[].obs;
  final RxList<MessageModel> files = <MessageModel>[].obs;
  final RxList<MessageModel> links = <MessageModel>[].obs;
  final RxList<MessageModel> audio = <MessageModel>[].obs;

  // Selected items for multi-select
  final RxSet<String> selectedIds = <String>{}.obs;
  final RxBool isSelectionMode = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Get arguments
    final args = Get.arguments;
    if (args is MediaGalleryArguments) {
      roomId = args.roomId;
      roomName = args.roomName;
      initialTab = args.initialTab;
    } else if (args is Map<String, dynamic>) {
      roomId = args['roomId'] ?? '';
      roomName = args['roomName'];
      initialTab = MediaType.photos;
    } else {
      roomId = '';
      roomName = null;
      initialTab = MediaType.photos;
    }

    // Initialize tab controller
    tabController = TabController(
      length: MediaType.values.length,
      vsync: this,
      initialIndex: initialTab.index,
    );

    // Load media
    _loadAllMedia();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// Load all media types from the chat room
  Future<void> _loadAllMedia() async {
    if (roomId.isEmpty) {
      errorMessage?.value = 'Invalid room ID';
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage?.value = '';

      final messagesRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .orderBy('timestamp', descending: true);

      // Load all messages and filter by type
      final snapshot = await messagesRef.get();

      final allMessages = snapshot.docs
          .map((doc) => MessageModel.fromQuery(doc))
          .toList();

      // Filter by type
      photos.value = allMessages.where((m) => m.type == 'photo').toList();
      videos.value = allMessages.where((m) => m.type == 'video').toList();
      files.value = allMessages.where((m) => m.type == 'file').toList();
      links.value = allMessages.where((m) => _hasLinks(m.text)).toList();
      audio.value = allMessages.where((m) => m.type == 'audio').toList();

      isLoading.value = false;
    } catch (e) {
      log('Error loading media: $e');
      errorMessage?.value = 'Failed to load media';
      isLoading.value = false;
    }
  }

  /// Check if text contains links
  bool _hasLinks(String? text) {
    if (text == null || text.isEmpty) return false;
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  /// Extract links from text
  List<String> extractLinks(String? text) {
    if (text == null || text.isEmpty) return [];
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    return urlPattern.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Get media list for current tab
  List<MessageModel> getMediaForType(MediaType type) {
    switch (type) {
      case MediaType.photos:
        return photos;
      case MediaType.videos:
        return videos;
      case MediaType.files:
        return files;
      case MediaType.links:
        return links;
      case MediaType.audio:
        return audio;
    }
  }

  /// Get count for a media type
  int getCountForType(MediaType type) {
    return getMediaForType(type).length;
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

    // Exit selection mode if no items selected
    if (selectedIds.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  /// Check if item is selected
  bool isSelected(String messageId) {
    return selectedIds.contains(messageId);
  }

  /// Select all items in current tab
  void selectAll() {
    final currentType = MediaType.values[tabController.index];
    final items = getMediaForType(currentType);
    selectedIds.addAll(items.map((m) => m.messageId ?? '').where((id) => id.isNotEmpty));
  }

  /// Delete selected items
  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Delete ${selectedIds.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final messagesRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat');

      for (final id in selectedIds) {
        batch.delete(messagesRef.doc(id));
      }

      await batch.commit();

      // Remove from local lists
      photos.removeWhere((m) => selectedIds.contains(m.messageId));
      videos.removeWhere((m) => selectedIds.contains(m.messageId));
      files.removeWhere((m) => selectedIds.contains(m.messageId));
      links.removeWhere((m) => selectedIds.contains(m.messageId));
      audio.removeWhere((m) => selectedIds.contains(m.messageId));

      selectedIds.clear();
      isSelectionMode.value = false;

      Get.snackbar('Success', 'Media deleted successfully');
    } catch (e) {
      log('Error deleting media: $e');
      Get.snackbar('Error', 'Failed to delete media');
    }
  }

  /// Share selected items
  Future<void> shareSelected() async {
    // TODO: Implement share functionality
    Get.snackbar('Info', 'Share functionality coming soon');
  }

  /// Download a media item
  Future<void> downloadMedia(MessageModel message) async {
    // TODO: Implement download with platform-aware path handling
    Get.snackbar('Info', 'Download functionality coming soon');
  }

  /// Open media in full screen viewer
  void openMediaViewer(MessageModel message, int index) {
    // Navigate to full screen media viewer
    // This could open PhotoView for images or video player for videos
    Get.snackbar('Info', 'Full screen viewer coming soon');
  }

  /// Refresh media list
  Future<void> refresh() async {
    await _loadAllMedia();
  }
}
