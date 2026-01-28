import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Message sending button with clean, minimal animations
/// States: ready, typing, uploading, sending, sent, error
class MessageSendButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final MessageButtonState state;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? successColor;
  final Color? errorColor;
  final String? uploadProgress; // e.g., "45%"

  const MessageSendButton({
    super.key,
    this.onPressed,
    this.state = MessageButtonState.ready,
    this.size = 44,
    this.activeColor,
    this.inactiveColor,
    this.successColor,
    this.errorColor,
    this.uploadProgress,
  });

  @override
  State<MessageSendButton> createState() => _MessageSendButtonState();
}

class _MessageSendButtonState extends State<MessageSendButton>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _typingController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for sending state
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Typing animation (bounce)
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(MessageSendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    _rotateController.stop();
    _typingController.stop();

    switch (widget.state) {
      case MessageButtonState.ready:
        // No animation
        break;
      case MessageButtonState.typing:
        _typingController.repeat(reverse: true);
        break;
      case MessageButtonState.uploading:
      case MessageButtonState.sending:
        _rotateController.repeat();
        break;
      case MessageButtonState.sent:
      case MessageButtonState.error:
        // One-time animations handled in build
        break;
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.state) {
      case MessageButtonState.ready:
        return widget.activeColor ?? const Color(0xFF31A354);
      case MessageButtonState.typing:
        return widget.inactiveColor ?? Colors.grey.shade400;
      case MessageButtonState.uploading:
      case MessageButtonState.sending:
        return widget.activeColor ?? const Color(0xFF31A354);
      case MessageButtonState.sent:
        return widget.successColor ?? const Color(0xFF31A354);
      case MessageButtonState.error:
        return widget.errorColor ?? Colors.red.shade600;
    }
  }

  Widget _buildIcon() {
    switch (widget.state) {
      case MessageButtonState.ready:
        return Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: widget.size * 0.45,
        );

      case MessageButtonState.typing:
        return AnimatedBuilder(
          animation: _typingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -4 * math.sin(_typingController.value * math.pi)),
              child: child,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (_typingController.value + delay) % 1.0;
                    return Opacity(
                      opacity: 0.3 + (0.7 * math.sin(value * math.pi)),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );

      case MessageButtonState.uploading:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: child,
                  );
                },
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            if (widget.uploadProgress != null)
              Text(
                widget.uploadProgress!,
                style: TextStyle(
                  fontSize: widget.size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        );

      case MessageButtonState.sending:
        return AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            );
          },
          child: Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: widget.size * 0.45,
          ),
        );

      case MessageButtonState.sent:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        );

      case MessageButtonState.error:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.rotate(
                angle: math.sin(value * math.pi) * 0.1,
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.state == MessageButtonState.ready && widget.onPressed != null;

    return GestureDetector(
      onTap: isEnabled ? widget.onPressed : null,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(
          begin: 1.0,
          end: isEnabled ? 1.0 : 0.95,
        ),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _getColor(),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getColor().withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(widget.state),
              alignment: Alignment.center,
              child: _buildIcon(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Message button states
enum MessageButtonState {
  ready,      // Default state, ready to send
  typing,     // User is typing (animated dots)
  uploading,  // Uploading media (with progress)
  sending,    // Sending message (rotating send icon)
  sent,       // Message sent (checkmark)
  error,      // Error occurred (error icon)
}
