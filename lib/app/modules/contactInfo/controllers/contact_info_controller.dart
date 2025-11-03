import 'dart:convert';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

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
    final userId = user.value?.uid;
    if (userId == null || roomId == null) {
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
        await _chatDataSources.unblockUser(roomId!, userId);
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
          await _chatDataSources.blockUser(roomId!, userId);
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
                    .collection('chat_rooms')
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
                            isMe ? 'You' : (user.value?.fullName ?? 'Unknown'),
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
                                  .collection('chat_rooms')
                                  .doc(roomId)
                                  .collection('chat')
                                  .doc(messages[index].id)
                                  .update({'isFavorite': false});
                            },
                          ),
                          onTap: () {
                            // Navigate to message in chat and scroll to it
                            Get.back(); // Close starred messages sheet
                            Get.back(); // Close contact info page

                            // Navigate to chat with the message ID to scroll to
                            Get.toNamed(
                              Routes.CHAT,
                              arguments: {
                                'roomId': roomId,
                                'contactId': user.value?.uid ?? '',
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
          .collection('chat_rooms')
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

    // Show export options dialog
    final exportFormat = await Get.dialog<String>(
      AlertDialog(
        title: const Text("Export Chat"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Choose export format:"),
            SizedBox(height: 16),
            Text("• Text file - Simple text format"),
            Text("• JSON - Structured data format"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'txt'),
            child: const Text("Text"),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'json'),
            child: const Text("JSON"),
          ),
        ],
      ),
    );

    if (exportFormat == null) return;

    try {
      isLoading.value = true;
      Get.snackbar(
        "Exporting",
        "Preparing chat export...",
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 30),
      );

      // Fetch all messages from the chat room
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .orderBy('timestamp', descending: false)
          .get();

      final messages = messagesSnapshot.docs;

      if (messages.isEmpty) {
        Get.back(); // Close loading snackbar
        Get.snackbar(
          "No Messages",
          "There are no messages to export",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String exportContent;

      if (exportFormat == 'txt') {
        exportContent = await _exportAsText(messages);
      } else {
        exportContent = await _exportAsJSON(messages);
      }

      // Save to device storage (using share functionality)
      // For now, we'll just copy to clipboard and show a message
      // In production, you would use packages like path_provider and share_plus

      Get.back(); // Close loading snackbar

      Get.dialog(
        AlertDialog(
          title: const Text("Export Ready"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Exported ${messages.length} messages"),
              const SizedBox(height: 16),
              const Text("Export content has been generated."),
              const SizedBox(height: 8),
              Text(
                "Format: ${exportFormat.toUpperCase()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard (simplified implementation)
                // In production, use Clipboard.setData()
                Get.back();
                Get.snackbar(
                  "Note",
                  "In production version, this would save/share the file",
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text("Share"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Error exporting chat: $e");
      Get.back(); // Close loading snackbar
      Get.snackbar(
        "Error",
        "Failed to export chat: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _exportAsText(List<QueryDocumentSnapshot> messages) async {
    final buffer = StringBuffer();
    buffer.writeln('=' * 50);
    buffer.writeln('Chat Export - ${displayName}');
    buffer.writeln('Exported on: ${DateTime.now()}');
    buffer.writeln('Total messages: ${messages.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final doc in messages) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'];
      final senderId = data['senderId'] ?? '';
      final messageType = data['type'] ?? 'text';
      final content = data['text'] ?? data['content'] ?? '';

      DateTime? dateTime;
      if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp);
      }

      final currentUserId = UserService.currentUserValue?.uid;
      final senderName = senderId == currentUserId ? 'You' : displayName;

      buffer.writeln('[${dateTime != null ? _formatTimestamp(dateTime) : 'Unknown time'}]');
      buffer.writeln('$senderName:');

      if (messageType == 'text') {
        buffer.writeln(content);
      } else {
        buffer.writeln('[$messageType message]');
        if (content.isNotEmpty) {
          buffer.writeln('Content: $content');
        }
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> _exportAsJSON(List<QueryDocumentSnapshot> messages) async {
    final export = {
      'chat_name': displayName,
      'exported_at': DateTime.now().toIso8601String(),
      'total_messages': messages.length,
      'messages': messages.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'type': data['type'],
          'sender_id': data['senderId'],
          'timestamp': data['timestamp'],
          'content': data['text'] ?? data['content'] ?? '',
          'is_favorite': data['isFavorite'] ?? false,
          'is_pinned': data['isPinned'] ?? false,
        };
      }).toList(),
    };

    // Convert to JSON string with pretty printing
    return const JsonEncoder.withIndent('  ').convert(export);
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

    // Navigate to contact details screen
    Get.dialog(
      AlertDialog(
        title: const Text("Contact Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${user.value?.fullName ?? 'Unknown'}"),
            const SizedBox(height: 8),
            Text("Email: ${user.value?.email ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Phone: ${user.value?.phoneNumber ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Bio: ${user.value?.bio ?? 'No bio'}"),
            const SizedBox(height: 16),
            const Text("Contact information", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Close"),
          ),
        ],
      ),
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

  /// Update bio/status
  Future<void> updateBio(String newBio) async {
    final currentUserId = UserService.currentUserValue?.uid;
    if (currentUserId == null) {
      Get.snackbar(
        "Error",
        "Unable to update bio: User not logged in",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Update bio in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'bio': newBio});

      // Update local user object
      if (user.value != null) {
        final updatedUser = user.value!;
        // Create a new user object with updated bio (assuming SocialMediaUser is immutable)
        user.value = SocialMediaUser(
          uid: updatedUser.uid,
          fullName: updatedUser.fullName,
          email: updatedUser.email,
          imageUrl: updatedUser.imageUrl,
          phoneNumber: updatedUser.phoneNumber,
          provider: updatedUser.provider,
          address: updatedUser.address,
          deviceImages: updatedUser.deviceImages,
          contacts: updatedUser.contacts,
          deviceInfo: updatedUser.deviceInfo,
          privacySettings: updatedUser.privacySettings,
          chatSettings: updatedUser.chatSettings,
          bio: newBio,
          following: updatedUser.following,
          followers: updatedUser.followers,
          blockedUser: updatedUser.blockedUser,
          fcmToken: updatedUser.fcmToken,
        );

        // Also update the current user in UserService
        UserService.updateCurrentUser(user.value);
      }

      Get.snackbar(
        "Success",
        "Bio updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Error updating bio: $e");
      Get.snackbar(
        "Error",
        "Failed to update bio: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
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
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
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
                icon: Icon(Icons.close, color: Colors.white, size: 30),
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
                child: Icon(Icons.download, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
          duration: Duration(seconds: 2),
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
}
