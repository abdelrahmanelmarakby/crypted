import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// UI-004: Discoverable Message Actions
/// Makes message actions visible and accessible without long-press
/// Provides contextual action bar and quick action buttons

/// Quick action button that appears on hover/focus
class MessageQuickActions extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onReact;
  final VoidCallback? onMore;

  const MessageQuickActions({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onCopy,
    this.onForward,
    this.onDelete,
    this.onEdit,
    this.onReact,
    this.onMore,
  });

  @override
  State<MessageQuickActions> createState() => _MessageQuickActionsState();
}

class _MessageQuickActionsState extends State<MessageQuickActions>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onDoubleTap: widget.onReact,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The message content slot
            const SizedBox.shrink(),

            // Quick action bar
            if (_isHovered)
              Positioned(
                top: -40,
                right: widget.isMe ? 0 : null,
                left: widget.isMe ? null : 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _QuickActionBar(
                    isMe: widget.isMe,
                    message: widget.message,
                    onReply: widget.onReply,
                    onCopy: widget.onCopy,
                    onForward: widget.onForward,
                    onDelete: widget.onDelete,
                    onEdit: widget.onEdit,
                    onReact: widget.onReact,
                    onMore: widget.onMore,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  final bool isMe;
  final Message message;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onReact;
  final VoidCallback? onMore;

  const _QuickActionBar({
    required this.isMe,
    required this.message,
    this.onReply,
    this.onCopy,
    this.onForward,
    this.onDelete,
    this.onEdit,
    this.onReact,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.reply,
            tooltip: 'Reply',
            onTap: onReply,
          ),
          if (message is TextMessage)
            _ActionButton(
              icon: Icons.copy,
              tooltip: 'Copy',
              onTap: onCopy,
            ),
          _ActionButton(
            icon: Icons.emoji_emotions_outlined,
            tooltip: 'React',
            onTap: onReact,
          ),
          _ActionButton(
            icon: Icons.forward,
            tooltip: 'Forward',
            onTap: onForward,
          ),
          if (isMe && message is TextMessage)
            _ActionButton(
              icon: Icons.edit,
              tooltip: 'Edit',
              onTap: onEdit,
            ),
          if (isMe)
            _ActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onTap: onDelete,
              color: ColorsManager.error,
            ),
          _ActionButton(
            icon: Icons.more_horiz,
            tooltip: 'More',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: color ?? ColorsManager.darkGrey,
          ),
        ),
      ),
    );
  }
}

/// Inline reaction selector that appears on double-tap
class QuickReactionSelector extends StatelessWidget {
  final void Function(String emoji) onReactionSelected;
  final VoidCallback? onMoreReactions;

  static const List<String> quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  const QuickReactionSelector({
    super.key,
    required this.onReactionSelected,
    this.onMoreReactions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...quickReactions.map((emoji) => _ReactionButton(
                emoji: emoji,
                onTap: () => onReactionSelected(emoji),
              )),
          if (onMoreReactions != null) ...[
            Container(
              height: 24,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: ColorsManager.lightGrey,
            ),
            InkWell(
              onTap: onMoreReactions,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

/// Message context menu shown on long press
class MessageContextMenu extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool canEdit;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onFavorite;
  final VoidCallback? onReport;
  final VoidCallback? onSelect;

  const MessageContextMenu({
    super.key,
    required this.message,
    required this.isMe,
    this.canEdit = false,
    this.onReply,
    this.onCopy,
    this.onForward,
    this.onDelete,
    this.onEdit,
    this.onPin,
    this.onFavorite,
    this.onReport,
    this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required Message message,
    required bool isMe,
    bool canEdit = false,
    VoidCallback? onReply,
    VoidCallback? onCopy,
    VoidCallback? onForward,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
    VoidCallback? onPin,
    VoidCallback? onFavorite,
    VoidCallback? onReport,
    VoidCallback? onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageContextMenu(
        message: message,
        isMe: isMe,
        canEdit: canEdit,
        onReply: onReply,
        onCopy: onCopy,
        onForward: onForward,
        onDelete: onDelete,
        onEdit: onEdit,
        onPin: onPin,
        onFavorite: onFavorite,
        onReport: onReport,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            // Quick reactions row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: QuickReactionSelector(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  // Handle reaction
                },
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Action items
            _MenuItem(
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),

            if (message is TextMessage)
              _MenuItem(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Navigator.pop(context);
                  onCopy?.call();
                },
              ),

            _MenuItem(
              icon: Icons.forward,
              label: 'Forward',
              onTap: () {
                Navigator.pop(context);
                onForward?.call();
              },
            ),

            if (isMe && canEdit && message is TextMessage)
              _MenuItem(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),

            _MenuItem(
              icon: message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              label: message.isPinned ? 'Unpin' : 'Pin',
              onTap: () {
                Navigator.pop(context);
                onPin?.call();
              },
            ),

            _MenuItem(
              icon: message.isFavorite ? Icons.star : Icons.star_outline,
              label: message.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              onTap: () {
                Navigator.pop(context);
                onFavorite?.call();
              },
            ),

            _MenuItem(
              icon: Icons.check_box_outlined,
              label: 'Select',
              onTap: () {
                Navigator.pop(context);
                onSelect?.call();
              },
            ),

            const Divider(height: 1),

            if (isMe)
              _MenuItem(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: ColorsManager.error,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),

            if (!isMe)
              _MenuItem(
                icon: Icons.flag_outlined,
                label: 'Report',
                color: ColorsManager.error,
                onTap: () {
                  Navigator.pop(context);
                  onReport?.call();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color ?? ColorsManager.darkGrey,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: StylesManager.medium(
                fontSize: 16,
                color: color ?? ColorsManager.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hint widget shown for new users
class MessageActionHint extends StatefulWidget {
  final VoidCallback? onDismiss;

  const MessageActionHint({super.key, this.onDismiss});

  @override
  State<MessageActionHint> createState() => _MessageActionHintState();
}

class _MessageActionHintState extends State<MessageActionHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: child,
              );
            },
            child: Icon(
              Icons.swipe,
              color: ColorsManager.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip: Message Actions',
                  style: StylesManager.semiBold(
                    fontSize: 14,
                    color: ColorsManager.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Swipe right to reply, long press for more options, or double tap to react',
                  style: StylesManager.regular(
                    fontSize: 12,
                    color: ColorsManager.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onDismiss,
            color: ColorsManager.grey,
          ),
        ],
      ),
    );
  }
}
