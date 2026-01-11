import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/app/core/constants/chat_constants.dart';

/// UI-005: Swipe Actions for Messages
/// Implements swipe-to-reply and swipe-to-delete functionality

class SwipeMessageAction extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final bool canDelete;
  final bool canReply;
  final bool canForward;

  const SwipeMessageAction({
    super.key,
    required this.child,
    required this.isMe,
    this.onReply,
    this.onDelete,
    this.onForward,
    this.canDelete = true,
    this.canReply = true,
    this.canForward = true,
  });

  @override
  State<SwipeMessageAction> createState() => _SwipeMessageActionState();
}

class _SwipeMessageActionState extends State<SwipeMessageAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _isPastThreshold = false;
  SwipeDirection? _swipeDirection;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _swipeDirection = null;
    _isPastThreshold = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;

    // Determine swipe direction
    if (_swipeDirection == null && delta.abs() > 5) {
      _swipeDirection = delta > 0 ? SwipeDirection.right : SwipeDirection.left;
    }

    // For sent messages (isMe=true): swipe left to reply
    // For received messages (isMe=false): swipe right to reply
    final canSwipe = widget.isMe
        ? _swipeDirection == SwipeDirection.left
        : _swipeDirection == SwipeDirection.right;

    if (!canSwipe) return;

    setState(() {
      _dragExtent = (_dragExtent + delta).clamp(
        -ChatConstants.maxSwipeDistance,
        ChatConstants.maxSwipeDistance,
      );

      final isPastThreshold =
          _dragExtent.abs() >= ChatConstants.swipeActionThreshold;

      if (isPastThreshold && !_isPastThreshold) {
        HapticFeedback.lightImpact();
      }

      _isPastThreshold = isPastThreshold;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isPastThreshold) {
      // Trigger action based on direction
      if (widget.isMe && _swipeDirection == SwipeDirection.left) {
        widget.onReply?.call();
      } else if (!widget.isMe && _swipeDirection == SwipeDirection.right) {
        widget.onReply?.call();
      }
    }

    // Animate back
    _animateBack();
  }

  void _animateBack() {
    final startValue = _dragExtent;
    _controller.reset();

    _controller.addListener(() {
      setState(() {
        _dragExtent = startValue * (1 - _controller.value);
      });
    });

    _controller.forward().whenComplete(() {
      setState(() {
        _dragExtent = 0;
        _swipeDirection = null;
        _isPastThreshold = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Action indicator (behind message)
          if (_dragExtent != 0) _buildActionIndicator(),

          // Message content
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildActionIndicator() {
    final isReplyAction = (widget.isMe && _swipeDirection == SwipeDirection.left) ||
        (!widget.isMe && _swipeDirection == SwipeDirection.right);

    return Positioned.fill(
      child: Row(
        mainAxisAlignment:
            _dragExtent > 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (_dragExtent > 0) const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isPastThreshold
                  ? ColorsManager.primary
                  : ColorsManager.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReplyAction ? Icons.reply : Icons.delete_outline,
              color: _isPastThreshold ? Colors.white : ColorsManager.primary,
              size: 20,
            ),
          ),
          if (_dragExtent < 0) const SizedBox(width: 16),
        ],
      ),
    );
  }
}

enum SwipeDirection {
  left,
  right,
}

/// Dismissible message wrapper with more actions
class DismissibleMessage extends StatelessWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final bool canDelete;

  const DismissibleMessage({
    super.key,
    required this.child,
    required this.isMe,
    this.onReply,
    this.onDelete,
    this.onArchive,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: isMe
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();

        if (isMe && direction == DismissDirection.endToStart) {
          // Swipe left on sent message = reply
          onReply?.call();
        } else if (!isMe && direction == DismissDirection.startToEnd) {
          // Swipe right on received message = reply
          onReply?.call();
        }

        // Don't actually dismiss, just trigger action
        return false;
      },
      background: _buildBackground(false),
      secondaryBackground: _buildBackground(true),
      child: child,
    );
  }

  Widget _buildBackground(bool isSecondary) {
    return Container(
      alignment: isSecondary ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.reply,
          color: ColorsManager.primary,
        ),
      ),
    );
  }
}

/// Animated reply preview that appears when swiping
class SwipeReplyPreview extends StatelessWidget {
  final double progress;
  final bool isVisible;

  const SwipeReplyPreview({
    super.key,
    required this.progress,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: progress.clamp(0, 1),
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply,
              size: 16,
              color: ColorsManager.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Reply',
              style: TextStyle(
                fontSize: 12,
                color: ColorsManager.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
