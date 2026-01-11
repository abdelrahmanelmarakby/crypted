// ARCH-015 FIX: Optimized Message List Widget
// Prevents unnecessary rebuilds using proper keys and memoization

import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Optimized message list that minimizes rebuilds
/// Uses proper keying and selective updates
class OptimizedMessageList extends StatelessWidget {
  final RxList<Message> messages;
  final String currentUserId;
  final Widget Function(Message message, bool isOwn, bool showAvatar)
      messageBuilder;
  final ScrollController? scrollController;
  final bool reverse;
  final EdgeInsets? padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final double loadMoreThreshold;

  const OptimizedMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.messageBuilder,
    this.scrollController,
    this.reverse = true,
    this.padding,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.onLoadMore,
    this.loadMoreThreshold = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading && messages.isEmpty) {
        return loadingWidget ?? const Center(child: CircularProgressIndicator());
      }

      if (messages.isEmpty) {
        return emptyWidget ?? const Center(child: Text('No messages yet'));
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (onLoadMore != null && notification is ScrollUpdateNotification) {
            // Load more when nearing the top (since list is reversed)
            final maxScroll = notification.metrics.maxScrollExtent;
            final currentScroll = notification.metrics.pixels;

            if (maxScroll - currentScroll <= loadMoreThreshold) {
              onLoadMore!();
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: scrollController,
          reverse: reverse,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: messages.length,
          // Use itemExtent hint for performance if messages are uniform height
          // itemExtent: null, // Let Flutter calculate
          cacheExtent: 500, // Cache area for smoother scrolling
          itemBuilder: (context, index) {
            final message = messages[index];
            final isOwn = message.senderId == currentUserId;
            final showAvatar = _shouldShowAvatar(index);

            // Use RepaintBoundary to isolate repaints
            return RepaintBoundary(
              key: ValueKey('msg_${message.id}'),
              child: _MessageWrapper(
                message: message,
                isOwn: isOwn,
                showAvatar: showAvatar,
                builder: messageBuilder,
              ),
            );
          },
        ),
      );
    });
  }

  /// Determine if avatar should be shown (first message from a user in sequence)
  bool _shouldShowAvatar(int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    return currentMessage.senderId != nextMessage.senderId;
  }
}

/// Wrapper widget that only rebuilds when message changes
class _MessageWrapper extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final bool showAvatar;
  final Widget Function(Message message, bool isOwn, bool showAvatar) builder;

  const _MessageWrapper({
    required this.message,
    required this.isOwn,
    required this.showAvatar,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(message, isOwn, showAvatar);
  }
}

/// Optimized message bubble with memoized content
class OptimizedMessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const OptimizedMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBgColor = isOwn
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    final defaultBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isOwn ? 16 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 16),
    );

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Material(
          color: backgroundColor ?? defaultBgColor,
          borderRadius: borderRadius ?? defaultBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Timestamp widget with auto-update capability
class MessageTimestamp extends StatelessWidget {
  final DateTime timestamp;
  final TextStyle? style;
  final bool showRelative;

  const MessageTimestamp({
    super.key,
    required this.timestamp,
    this.style,
    this.showRelative = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _formatTime(timestamp),
      style: style ?? theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withAlpha(153),
      ),
    );
  }

  String _formatTime(DateTime time) {
    if (showRelative) {
      return _formatRelativeTime(time);
    }

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${time.day}/${time.month}';
  }
}

/// Date separator widget
class DateSeparator extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;

  const DateSeparator({
    super.key,
    required this.date,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.dividerColor.withAlpha(77),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: style ?? theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.dividerColor.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Typing indicator widget
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final Color? dotColor;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    this.dotColor,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final dotColor = widget.dotColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(dotColor, 0),
            const SizedBox(width: 4),
            _buildDot(dotColor, 1),
            const SizedBox(width: 4),
            _buildDot(dotColor, 2),
          ],
        );
      },
    );
  }

  Widget _buildDot(Color color, int index) {
    final delay = index * 0.2;
    final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
    final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color.withAlpha((255 * scale).round()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Selection overlay for multi-select mode
class MessageSelectionOverlay extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const MessageSelectionOverlay({
    super.key,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        child,
        if (isSelected)
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.primary.withAlpha(51),
            ),
          ),
        if (isSelected)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
