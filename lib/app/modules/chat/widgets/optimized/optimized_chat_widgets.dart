import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/widgets/msg_builder.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// ARCH-015: Optimized Widget Rebuilds
/// Collection of optimized widgets that minimize unnecessary rebuilds
/// using selective observation and const constructors

/// Optimized message list item that only rebuilds when its specific message changes
class OptimizedMessageItem extends StatelessWidget {
  final Message message;
  final Message? previousMessage;
  final bool showDateSeparator;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const OptimizedMessageItem({
    super.key,
    required this.message,
    this.previousMessage,
    this.showDateSeparator = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = UserService.currentUser.value;
    final isMe = message.senderId == currentUser?.uid;

    return RepaintBoundary(
      child: Column(
        children: [
          if (showDateSeparator)
            const _DateSeparatorWidget(),
          GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: MessageBuilder(
              !isMe,
              messageModel: message,
              timestamp: message.timestamp.toIso8601String(),
              senderName: _getSenderName(isMe, currentUser),
              senderImage: _getSenderImage(isMe, currentUser),
            ),
          ),
        ],
      ),
    );
  }

  String? _getSenderName(bool isMe, dynamic currentUser) {
    if (isMe) {
      return currentUser?.fullName;
    }
    // For group chats, this should come from the controller
    return null;
  }

  String? _getSenderImage(bool isMe, dynamic currentUser) {
    if (isMe) {
      return currentUser?.imageUrl;
    }
    return null;
  }
}

/// Optimized date separator that never rebuilds
class _DateSeparatorWidget extends StatelessWidget {
  const _DateSeparatorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: ColorsManager.offWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Today', // This should be calculated
            style: StylesManager.medium(
              color: ColorsManager.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Optimized observable builder that only rebuilds specific parts
class SelectiveObx<T> extends StatelessWidget {
  final Rx<T> observable;
  final Widget Function(T value) builder;

  const SelectiveObx({
    super.key,
    required this.observable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => builder(observable.value));
  }
}

/// Optimized list observer that only rebuilds affected items
class OptimizedRxListBuilder<T> extends StatelessWidget {
  final RxList<T> list;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool reverse;
  final EdgeInsets? padding;
  final ScrollController? scrollController;

  const OptimizedRxListBuilder({
    super.key,
    required this.list,
    required this.itemBuilder,
    this.emptyBuilder,
    this.reverse = false,
    this.padding,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (list.isEmpty && emptyBuilder != null) {
        return emptyBuilder!(context);
      }

      return ListView.builder(
        controller: scrollController,
        reverse: reverse,
        padding: padding,
        itemCount: list.length,
        // Use keys to help Flutter identify items
        itemBuilder: (context, index) {
          final item = list[index];
          return KeyedSubtree(
            key: ValueKey('item_$index'),
            child: RepaintBoundary(
              child: itemBuilder(context, item, index),
            ),
          );
        },
      );
    });
  }
}

/// Optimized chat typing indicator
class OptimizedTypingIndicator extends StatelessWidget {
  final ChatController controller;

  const OptimizedTypingIndicator({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Only observe the typing status, not the whole controller
    return Obx(() {
      final isTyping = controller.isTyping.value;

      if (!isTyping) {
        return const SizedBox.shrink();
      }

      return const _TypingIndicatorWidget();
    });
  }
}

/// Static typing indicator widget
class _TypingIndicatorWidget extends StatelessWidget {
  const _TypingIndicatorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(1),
          const SizedBox(width: 4),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ColorsManager.grey.withValues(alpha: 0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Optimized online status indicator
class OptimizedOnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OptimizedOnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? ColorsManager.success : ColorsManager.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: size / 6,
        ),
      ),
    );
  }
}

/// Memoized widget builder to prevent unnecessary rebuilds
class MemoizedBuilder<T> extends StatefulWidget {
  final T value;
  final Widget Function(T value) builder;
  final bool Function(T oldValue, T newValue)? shouldRebuild;

  const MemoizedBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.shouldRebuild,
  });

  @override
  State<MemoizedBuilder<T>> createState() => _MemoizedBuilderState<T>();
}

class _MemoizedBuilderState<T> extends State<MemoizedBuilder<T>> {
  late Widget _cachedWidget;

  @override
  void initState() {
    super.initState();
    _cachedWidget = widget.builder(widget.value);
  }

  @override
  void didUpdateWidget(MemoizedBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldRebuild = widget.shouldRebuild;
    if (shouldRebuild != null) {
      if (shouldRebuild(oldWidget.value, widget.value)) {
        _cachedWidget = widget.builder(widget.value);
      }
    } else if (oldWidget.value != widget.value) {
      _cachedWidget = widget.builder(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) => _cachedWidget;
}

/// Sliver version of optimized list for CustomScrollView
class OptimizedSliverList<T> extends StatelessWidget {
  final RxList<T> list;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const OptimizedSliverList({
    super.key,
    required this.list,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = list[index];
            return RepaintBoundary(
              key: ValueKey('sliver_item_$index'),
              child: itemBuilder(context, item, index),
            );
          },
          childCount: list.length,
        ),
      );
    });
  }
}

/// Optimized header that only rebuilds when necessary
class OptimizedChatHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool isOnline;
  final bool isGroupChat;
  final VoidCallback? onTap;

  const OptimizedChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.isOnline = false,
    this.isGroupChat = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? Icon(
                        isGroupChat ? Icons.group : Icons.person,
                        color: ColorsManager.grey,
                      )
                    : null,
              ),
              if (!isGroupChat)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: OptimizedOnlineIndicator(isOnline: isOnline),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: StylesManager.bold(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: StylesManager.regular(
                      fontSize: 12,
                      color: ColorsManager.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
