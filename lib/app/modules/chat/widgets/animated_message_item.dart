import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated wrapper for chat messages with slide-in and fade effects
///
/// **Animation Features:**
/// - Slide-in from left (received) or right (sent) messages
/// - Subtle fade-in for smooth appearance
/// - Configurable duration and curve
/// - Auto-triggers on first build (one-shot animation)
class AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final bool isNewMessage;
  final Duration duration;
  final Curve curve;

  const AnimatedMessageItem({
    super.key,
    required this.child,
    required this.isMe,
    this.isNewMessage = true,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Slide from right for sent messages, left for received
    final slideBegin = widget.isMe
        ? const Offset(0.3, 0.0)  // Slide from right
        : const Offset(-0.3, 0.0); // Slide from left

    _slideAnimation = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Only animate new messages, not existing ones loaded from history
    if (widget.isNewMessage) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // Skip animation for existing messages
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated send button with morph effect between mic and send icon
///
/// **Features:**
/// - Smooth rotation + scale transition
/// - Haptic feedback on state change
/// - Customizable icons and colors
class AnimatedSendButton extends StatelessWidget {
  final bool showSend;
  final VoidCallback onSendTap;
  final Widget micWidget;
  final Widget sendIcon;
  final Duration duration;
  final Color backgroundColor;

  const AnimatedSendButton({
    super.key,
    required this.showSend,
    required this.onSendTap,
    required this.micWidget,
    required this.sendIcon,
    this.duration = const Duration(milliseconds: 200),
    this.backgroundColor = const Color(0x8031A354), // primary with alpha
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.125).animate(animation),
            child: child,
          ),
        );
      },
      child: showSend
          ? GestureDetector(
              key: const ValueKey('send'),
              onTap: () {
                HapticFeedback.lightImpact();
                onSendTap();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: backgroundColor,
                ),
                child: sendIcon,
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('mic'),
              child: micWidget,
            ),
    );
  }
}

/// Animated delivery status indicator (single check → double check)
///
/// **States:**
/// - Sending: Clock icon with pulse
/// - Sent: Single check
/// - Delivered: Double check with slide-in animation
/// - Read: Double check (blue)
class AnimatedDeliveryStatus extends StatefulWidget {
  final DeliveryState state;
  final Color color;
  final Color readColor;
  final double size;

  const AnimatedDeliveryStatus({
    super.key,
    required this.state,
    this.color = const Color(0xFF9E9E9E),
    this.readColor = const Color(0xFF2196F3),
    this.size = 16,
  });

  @override
  State<AnimatedDeliveryStatus> createState() => _AnimatedDeliveryStatusState();
}

class _AnimatedDeliveryStatusState extends State<AnimatedDeliveryStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  DeliveryState? _previousState;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _previousState = widget.state;
  }

  @override
  void didUpdateWidget(AnimatedDeliveryStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _previousState = oldWidget.state;
      _controller.forward(from: 0);

      // Haptic feedback on delivery confirmation
      if (widget.state == DeliveryState.delivered ||
          widget.state == DeliveryState.read) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildStatusIcon();
      },
    );
  }

  Widget _buildStatusIcon() {
    final color = widget.state == DeliveryState.read
        ? widget.readColor
        : widget.color;

    switch (widget.state) {
      case DeliveryState.sending:
        return _buildSendingIcon();
      case DeliveryState.sent:
        return Icon(Icons.check, size: widget.size, color: color);
      case DeliveryState.delivered:
      case DeliveryState.read:
        return _buildDoubleCheck(color);
    }
  }

  Widget _buildSendingIcon() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        valueColor: AlwaysStoppedAnimation(widget.color),
      ),
    );
  }

  Widget _buildDoubleCheck(Color color) {
    // Animate the second check sliding in
    final slideValue = _previousState == DeliveryState.sent
        ? _controller.value
        : 1.0;

    return SizedBox(
      width: widget.size + 6,
      height: widget.size,
      child: Stack(
        children: [
          // First check (always visible)
          Positioned(
            left: 0,
            child: Icon(Icons.check, size: widget.size, color: color),
          ),
          // Second check (slides in)
          Positioned(
            left: 6 * slideValue,
            child: Opacity(
              opacity: slideValue,
              child: Icon(Icons.check, size: widget.size, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery state enum
enum DeliveryState {
  sending,
  sent,
  delivered,
  read,
}

/// Animated reaction bubble with pop effect
///
/// **Animation:**
/// - Scale pop when reaction added
/// - Subtle bounce effect
/// - Haptic feedback on tap
class AnimatedReactionBubble extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const AnimatedReactionBubble({
    super.key,
    required this.emoji,
    required this.count,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<AnimatedReactionBubble> createState() => _AnimatedReactionBubbleState();
}

class _AnimatedReactionBubbleState extends State<AnimatedReactionBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedReactionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when count changes
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF31A354).withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(color: const Color(0xFF31A354), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 14)),
              if (widget.count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isSelected
                        ? const Color(0xFF31A354)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
