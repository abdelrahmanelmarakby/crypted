import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/routes/app_pages.dart';

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

  // Search state
  final RxBool isSearchMode = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Download state
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

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
    searchController.dispose();
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
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
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

  /// Get media list for current tab with optional search filtering
  List<MessageModel> getMediaForType(MediaType type) {
    List<MessageModel> items;
    switch (type) {
      case MediaType.photos:
        items = photos;
        break;
      case MediaType.videos:
        items = videos;
        break;
      case MediaType.files:
        items = files;
        break;
      case MediaType.links:
        items = links;
        break;
      case MediaType.audio:
        items = audio;
        break;
    }

    // Apply search filter if search is active
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      return items.where((item) => _matchesSearch(item, query, type)).toList();
    }

    return items;
  }

  /// Check if a media item matches the search query
  bool _matchesSearch(MessageModel item, String query, MediaType type) {
    // Search by filename
    if (item.fileName?.toLowerCase().contains(query) ?? false) return true;

    // Search by text/caption
    if (item.text?.toLowerCase().contains(query) ?? false) return true;

    // For links, search the URL
    if (type == MediaType.links) {
      final urls = extractLinks(item.text);
      if (urls.any((url) => url.toLowerCase().contains(query))) return true;
    }

    return false;
  }

  /// Toggle search mode
  void toggleSearchMode() {
    isSearchMode.value = !isSearchMode.value;
    if (!isSearchMode.value) {
      clearSearch();
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
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
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages);

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
    } catch (e) {
      log('Error deleting media: $e');
      Get.snackbar('Error', 'Failed to delete media');
    }
  }

  /// Share selected items
  Future<void> shareSelected() async {
    if (selectedIds.isEmpty) return;

    try {
      final currentType = MediaType.values[tabController.index];
      final items = getMediaForType(currentType);
      final selectedItems = items.where(
        (item) => selectedIds.contains(item.messageId),
      ).toList();

      if (selectedItems.isEmpty) return;

      // Collect file URLs to share
      final filesToShare = <XFile>[];

      for (final item in selectedItems) {
        final url = _getMediaUrl(item, currentType);
        if (url == null || url.isEmpty) continue;

        try {
          // Download file to temp directory for sharing
          final tempFile = await _downloadToTemp(url, item.fileName ?? 'media');
          if (tempFile != null) {
            filesToShare.add(XFile(tempFile.path));
          }
        } catch (e) {
          log('Error preparing file for sharing: $e');
        }
      }

      if (filesToShare.isEmpty) {
        Get.snackbar('Error', 'No files available to share');
        return;
      }

      await Share.shareXFiles(
        filesToShare,
        text: selectedItems.length > 1
            ? 'Sharing ${selectedItems.length} files'
            : null,
      );

      // Exit selection mode after sharing
      toggleSelectionMode();
    } catch (e) {
      log('Error sharing media: $e');
      Get.snackbar('Error', 'Failed to share media');
    }
  }

  /// Share a single media item
  Future<void> shareMedia(MessageModel message, MediaType type) async {
    try {
      final url = _getMediaUrl(message, type);
      if (url == null || url.isEmpty) {
        Get.snackbar('Error', 'No media URL available');
        return;
      }

      final tempFile = await _downloadToTemp(url, message.fileName ?? 'media');
      if (tempFile != null) {
        await Share.shareXFiles([XFile(tempFile.path)]);
      }
    } catch (e) {
      log('Error sharing media: $e');
      Get.snackbar('Error', 'Failed to share media');
    }
  }

  /// Get media URL based on type
  String? _getMediaUrl(MessageModel item, MediaType type) {
    switch (type) {
      case MediaType.photos:
        return item.photoUrl;
      case MediaType.videos:
        return item.videoUrl;
      case MediaType.files:
        return item.fileUrl;
      case MediaType.audio:
        return item.audioUrl;
      case MediaType.links:
        final urls = extractLinks(item.text);
        return urls.isNotEmpty ? urls.first : null;
    }
  }

  /// Download file to temp directory
  Future<File?> _downloadToTemp(String url, String filename) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final extension = _getExtensionFromUrl(url) ?? '';
      final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
      final filePath = '${tempDir.path}/$safeName$extension';

      await dio.download(url, filePath);
      return File(filePath);
    } catch (e) {
      log('Error downloading to temp: $e');
    }
    return null;
  }

  /// Get file extension from URL
  String? _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot);
      }
    } catch (e) {
      log('Error getting extension: $e');
    }
    return null;
  }

  /// Download a media item to device storage
  Future<void> downloadMedia(MessageModel message) async {
    final currentType = MediaType.values[tabController.index];
    final url = _getMediaUrl(message, currentType);

    if (url == null || url.isEmpty) {
      Get.snackbar('Error', 'No media URL available');
      return;
    }

    final messageId = message.messageId ?? '';

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            Get.snackbar('Permission Denied', 'Storage permission is required to download files');
            return;
          }
        }
      }

      // Start download with progress tracking
      downloadProgress[messageId] = 0.0;

      // Get download directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getDownloadsDirectory();
      }

      if (downloadDir == null) {
        Get.snackbar('Error', 'Could not access download directory');
        downloadProgress.remove(messageId);
        return;
      }

      // Create file with proper name
      final filename = message.fileName ?? 'media_${DateTime.now().millisecondsSinceEpoch}';
      final extension = _getExtensionFromUrl(url) ?? '';
      final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
      final filePath = '${downloadDir.path}/$safeName$extension';

      // Download with progress using Dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress[messageId] = received / total;
          }
        },
      );

      downloadProgress.remove(messageId);
      Get.snackbar('Downloaded', 'File saved to $filePath');
    } catch (e) {
      log('Error downloading media: $e');
      downloadProgress.remove(messageId);
      Get.snackbar('Error', 'Failed to download file');
    }
  }

  /// Open media in full screen viewer
  void openMediaViewer(MessageModel message, int index) {
    final currentType = MediaType.values[tabController.index];
    final items = getMediaForType(currentType);

    Get.toNamed(
      Routes.MEDIA_VIEWER,
      arguments: {
        'items': items,
        'initialIndex': index,
        'type': currentType,
        'roomName': roomName,
      },
    );
  }

  /// Refresh media list
  @override
  Future<void> refresh() async {
    await _loadAllMedia();
  }
}
