import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/starred_messages/controllers/starred_messages_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:intl/intl.dart';

/// Starred Messages View - displays all starred/favorite messages
class StarredMessagesView extends GetView<StarredMessagesController> {
  const StarredMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.starredMessages.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: _buildMessagesList(),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.isSelectionMode.value) return const SizedBox.shrink();
        return _buildSelectionActions();
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        if (controller.isSelectionMode.value) {
          return Text('${controller.selectedIds.length} selected');
        }
        return Text(
          controller.showAllRooms
              ? 'Starred Messages'
              : controller.roomName ?? 'Starred Messages',
        );
      }),
      actions: [
        Obx(() {
          if (controller.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.toggleSelectionMode,
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: controller.starredMessages.length,
      itemBuilder: (context, index) {
        final item = controller.starredMessages[index];
        return _buildMessageCard(item);
      },
    );
  }

  Widget _buildMessageCard(StarredMessageItem item) {
    final isSelected = controller.isSelected(item.message.messageId ?? '');

    return GestureDetector(
      onTap: () {
        if (controller.isSelectionMode.value) {
          controller.toggleSelection(item.message.messageId ?? '');
        } else {
          controller.goToMessage(item);
        }
      },
      onLongPress: () {
        if (!controller.isSelectionMode.value) {
          controller.isSelectionMode.value = true;
        }
        controller.toggleSelection(item.message.messageId ?? '');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : ColorsManager.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with room name and time
            if (controller.showAllRooms || item.roomName != null)
              _buildMessageHeader(item, isSelected),

            // Message content
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildMessageContent(item),
            ),

            // Actions
            if (!controller.isSelectionMode.value)
              _buildMessageActions(item),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageHeader(StarredMessageItem item, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorsManager.primary.withValues(alpha: 0.15)
            : ColorsManager.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: ColorsManager.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.roomName ?? 'Chat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorsManager.darkGrey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatDate(item.message.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: ColorsManager.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(StarredMessageItem item) {
    final message = item.message;

    // Different display based on message type
    if (message.type == 'photo') {
      return _buildPhotoMessage(message);
    } else if (message.type == 'video') {
      return _buildVideoMessage(message);
    } else if (message.type == 'audio') {
      return _buildAudioMessage(message);
    } else if (message.type == 'file') {
      return _buildFileMessage(message);
    } else {
      return _buildTextMessage(message);
    }
  }

  Widget _buildTextMessage(message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender info
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: ColorsManager.primary.withValues(alpha: 0.2),
              child: Text(
                (message.senderName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message.senderName ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Message text
        Text(
          message.text ?? '',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildPhotoMessage(message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo, size: 20, color: ColorsManager.primary),
            const SizedBox(width: 8),
            Text(
              message.senderName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorsManager.veryLightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: message.photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                )
              : Icon(Icons.photo, size: 48, color: ColorsManager.lightGrey),
        ),
        if (message.text?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(message.text!, style: const TextStyle(fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildVideoMessage(message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.videocam, size: 20, color: ColorsManager.primary),
            const SizedBox(width: 8),
            Text(
              message.senderName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorsManager.veryDarkGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.play_circle_fill, size: 48, color: ColorsManager.white),
        ),
      ],
    );
  }

  Widget _buildAudioMessage(message) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.mic, color: ColorsManager.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Voice message ${message.audioDuration ?? ''}',
                style: TextStyle(fontSize: 13, color: ColorsManager.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage(message) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorsManager.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.insert_drive_file, color: ColorsManager.info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'File',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                message.fileSize ?? 'Unknown size',
                style: TextStyle(fontSize: 12, color: ColorsManager.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageActions(StarredMessageItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorsManager.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => controller.goToMessage(item),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Go to message'),
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.primary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: ColorsManager.divider,
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => controller.unstarMessage(item),
              icon: const Icon(Icons.star_border, size: 18),
              label: const Text('Unstar'),
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 80,
              color: ColorsManager.veryLightGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'No starred messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorsManager.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap and hold on any message, then tap the star icon to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorsManager.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ColorsManager.lightGrey),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColorsManager.textSecondary),
                )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: controller.forwardSelected,
              icon: const Icon(Icons.forward),
              label: const Text('Forward'),
            ),
            TextButton.icon(
              onPressed: controller.unstarSelected,
              icon: const Icon(Icons.star_border),
              label: const Text('Unstar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = timestamp;
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return DateFormat.jm().format(date);
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return DateFormat.E().format(date);
      } else {
        return DateFormat.MMMd().format(date);
      }
    } catch (_) {
      return '';
    }
  }
}
