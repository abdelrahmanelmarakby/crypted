import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// UI-002: Loading States for Messages
/// Provides shimmer loading and skeleton screens for chat

class ChatLoadingWidget extends StatelessWidget {
  final int itemCount;

  const ChatLoadingWidget({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: itemCount,
      reverse: true,
      itemBuilder: (context, index) {
        // Alternate between sent and received message styles
        final isMe = index % 3 != 0;
        return _MessageSkeleton(isMe: isMe);
      },
    );
  }
}

/// Skeleton for a single message
class _MessageSkeleton extends StatefulWidget {
  final bool isMe;

  const _MessageSkeleton({required this.isMe});

  @override
  State<_MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<_MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                // Avatar skeleton
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ColorsManager.lightGrey.withValues(alpha: _animation.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Message bubble skeleton
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? ColorsManager.primary.withValues(alpha: _animation.value * 0.5)
                      : ColorsManager.lightGrey.withValues(alpha: _animation.value),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: widget.isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: widget.isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text lines skeleton
                    _buildTextLine(context, 0.9),
                    const SizedBox(height: 6),
                    _buildTextLine(context, 0.6),
                    const SizedBox(height: 8),
                    // Time skeleton
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 40,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isMe) ...[
                const SizedBox(width: 8),
                // Avatar skeleton for sent messages
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ColorsManager.lightGrey.withValues(alpha: _animation.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextLine(BuildContext context, double widthFactor) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65 * widthFactor - 32,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Circular loading indicator for chat actions
class ChatActionLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const ChatActionLoader({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? ColorsManager.primary,
        ),
      ),
    );
  }
}

/// Full-screen loading overlay
class ChatLoadingOverlay extends StatelessWidget {
  final String? message;

  const ChatLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ChatActionLoader(size: 40),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorsManager.grey,
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

/// Inline loading indicator (for sending messages)
class MessageSendingIndicator extends StatefulWidget {
  const MessageSendingIndicator({super.key});

  @override
  State<MessageSendingIndicator> createState() => _MessageSendingIndicatorState();
}

class _MessageSendingIndicatorState extends State<MessageSendingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (value < 0.5 ? value : 1.0 - value) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.3 + (opacity * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
