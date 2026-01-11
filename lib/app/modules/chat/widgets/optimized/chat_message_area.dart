// ARCH-015 FIX: Optimized Chat Message Area
// Drop-in replacement for message list with better performance

import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/modules/chat/widgets/optimized/optimized_message_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Optimized chat message area that can be used as a drop-in replacement
/// for the existing message list in chat_screen.dart
class OptimizedChatMessageArea extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final bool isGroupChat;
  final List<SocialMediaUser> members;
  final ScrollController? scrollController;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Widget? pinnedMessageWidget;

  const OptimizedChatMessageArea({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.isGroupChat,
    required this.members,
    this.scrollController,
    this.onMessageTap,
    this.onMessageLongPress,
    this.pinnedMessageWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pinned message at top
        if (pinnedMessageWidget != null) pinnedMessageWidget!,

        // Message list
        Expanded(
          child: _buildMessageList(context),
        ),
      ],
    );
  }

  Widget _buildMessageList(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: messages.length + _getDateSeparatorCount(),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return _buildMessageItem(context, index);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    // Get actual message index accounting for date separators
    final messageIndex = _getActualMessageIndex(index);
    if (messageIndex < 0 || messageIndex >= messages.length) {
      return const SizedBox.shrink();
    }

    final message = messages[messageIndex];
    final isOwn = message.senderId == currentUserId;
    final showAvatar = _shouldShowAvatar(messageIndex);
    final showDateSeparator = _shouldShowDateSeparator(messageIndex);

    return Column(
      children: [
        // Date separator
        if (showDateSeparator)
          DateSeparator(date: message.timestamp),

        // Message with repaint boundary for performance
        RepaintBoundary(
          key: ValueKey('msg_${message.id}'),
          child: GestureDetector(
            onTap: onMessageTap != null ? () => onMessageTap!(message) : null,
            onLongPress: onMessageLongPress != null
                ? () => onMessageLongPress!(message)
                : null,
            child: _buildMessageBubble(context, message, isOwn, showAvatar),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message,
    bool isOwn,
    bool showAvatar,
  ) {
    // Get sender info for group chats
    String? senderName;
    String? senderImage;

    if (isGroupChat && !isOwn) {
      final sender = members.firstWhereOrNull((m) => m.uid == message.senderId);
      senderName = sender?.fullName ?? 'Unknown';
      senderImage = sender?.imageUrl;
    }

    // Use the existing MsgBuilder for compatibility
    // This ensures existing styling and logic is preserved
    return MsgBuilder(
      message: message,
      isSameUser: !showAvatar,
      senderName: senderName,
      senderImage: senderImage,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline.withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowAvatar(int index) {
    if (index == messages.length - 1) return true;
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    return currentMessage.senderId != nextMessage.senderId;
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );

    final nextDate = DateTime(
      nextMessage.timestamp.year,
      nextMessage.timestamp.month,
      nextMessage.timestamp.day,
    );

    return currentDate != nextDate;
  }

  int _getDateSeparatorCount() {
    // For simplicity, we're not adding extra items for separators
    // Separators are rendered inline with messages
    return 0;
  }

  int _getActualMessageIndex(int index) {
    return index;
  }
}

/// Pinned message banner widget
class PinnedMessageBanner extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PinnedMessageBanner({
    super.key,
    required this.message,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(179),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(77),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinned Message',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getMessagePreview(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMessagePreview() {
    // Get preview based on message type
    final type = message.runtimeType.toString();
    if (type.contains('TextMessage')) {
      return (message as dynamic).text ?? 'Message';
    }
    return type.replaceAll('Message', '');
  }
}

/// Typing indicator banner
class TypingIndicatorBanner extends StatelessWidget {
  final List<String> typingUsers;

  const TypingIndicatorBanner({
    super.key,
    required this.typingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final text = _formatTypingText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          TypingIndicator(
            typingUsers: typingUsers,
            dotColor: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTypingText() {
    if (typingUsers.isEmpty) return '';
    if (typingUsers.length == 1) return '${typingUsers.first} is typing...';
    if (typingUsers.length == 2) {
      return '${typingUsers[0]} and ${typingUsers[1]} are typing...';
    }
    return '${typingUsers[0]} and ${typingUsers.length - 1} others are typing...';
  }
}

/// Extension to help with controller access
extension ChatMessageAreaExtension on ChatController {
  /// Build optimized message area using current controller state
  Widget buildOptimizedMessageArea({
    required List<Message> messages,
    ScrollController? scrollController,
  }) {
    final pinnedMessages = messages.where((m) => m.isPinned).toList();

    return OptimizedChatMessageArea(
      messages: messages,
      currentUserId: currentUser?.uid ?? '',
      isGroupChat: isGroupChat.value,
      members: members,
      scrollController: scrollController,
      onMessageLongPress: handleMessageLongPress,
      pinnedMessageWidget: pinnedMessages.isNotEmpty
          ? PinnedMessageBanner(
              message: pinnedMessages.first,
              onTap: () {
                // Scroll to pinned message
              },
            )
          : null,
    );
  }
}
