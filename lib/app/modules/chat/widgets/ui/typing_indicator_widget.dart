import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

/// UI-006: Typing Indicator Widget
/// Shows animated typing indicator when someone is typing

class TypingIndicatorWidget extends StatefulWidget {
  final bool isTyping;
  final List<SocialMediaUser>? typingUsers;
  final bool showAvatar;
  final bool showName;

  const TypingIndicatorWidget({
    super.key,
    required this.isTyping,
    this.typingUsers,
    this.showAvatar = true,
    this.showName = true,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: widget.isTyping ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Typing user avatars
            if (widget.showAvatar && widget.typingUsers != null)
              _buildTypingAvatars(),

            if (widget.showAvatar && widget.typingUsers != null)
              const SizedBox(width: 8),

            // Animated bubble with dots
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return _buildAnimatedDot(index);
                }),
              ),
            ),

            const SizedBox(width: 8),

            // "typing..." text
            if (widget.showName)
              Text(
                _getTypingText(),
                style: StylesManager.regular(
                  fontSize: 12,
                  color: ColorsManager.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingAvatars() {
    final users = widget.typingUsers ?? [];
    if (users.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 32 + (users.length > 1 ? 10 : 0),
      height: 28,
      child: Stack(
        children: [
          for (int i = 0; i < users.length.clamp(0, 3); i++)
            Positioned(
              left: i * 10.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  image: users[i].imageUrl != null &&
                          users[i].imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(users[i].imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: users[i].imageUrl == null
                      ? ColorsManager.primary.withValues(alpha: 0.2)
                      : null,
                ),
                child: users[i].imageUrl == null
                    ? Center(
                        child: Text(
                          users[i].fullName?.substring(0, 1).toUpperCase() ??
                              '?',
                          style: StylesManager.bold(
                            fontSize: 12,
                            color: ColorsManager.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Staggered animation for each dot
        final delay = index * 0.2;
        final animationValue = ((_controller.value + delay) % 1.0);

        // Calculate bounce effect
        double yOffset;
        if (animationValue < 0.5) {
          yOffset = -6 * (animationValue * 2);
        } else {
          yOffset = -6 * (2 - animationValue * 2);
        }

        return Container(
          margin: EdgeInsets.only(
            left: index > 0 ? 4 : 0,
          ),
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ColorsManager.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTypingText() {
    final users = widget.typingUsers ?? [];

    if (users.isEmpty) {
      return 'typing...';
    } else if (users.length == 1) {
      return '${users[0].fullName ?? 'Someone'} is typing...';
    } else if (users.length == 2) {
      return '${users[0].fullName ?? 'Someone'} and ${users[1].fullName ?? 'someone'} are typing...';
    } else {
      return '${users.length} people are typing...';
    }
  }
}

/// Simple typing dots indicator (inline)
class TypingDots extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const TypingDots({
    super.key,
    this.color,
    this.dotSize = 6,
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
            final delay = index * 0.15;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (value < 0.5 ? value : 1.0 - value) * 2;

            return Container(
              margin: EdgeInsets.only(left: index > 0 ? 3 : 0),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: (widget.color ?? ColorsManager.grey)
                    .withValues(alpha: 0.3 + (opacity * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Typing indicator that appears in the message list
class InlineTypingIndicator extends StatelessWidget {
  final String? userName;
  final String? userImage;

  const InlineTypingIndicator({
    super.key,
    this.userName,
    this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          if (userImage != null || userName != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: userImage != null
                    ? DecorationImage(
                        image: NetworkImage(userImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: ColorsManager.primary.withValues(alpha: 0.2),
              ),
              child: userImage == null
                  ? Center(
                      child: Text(
                        userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: StylesManager.bold(
                          fontSize: 14,
                          color: ColorsManager.primary,
                        ),
                      ),
                    )
                  : null,
            ),

          const SizedBox(width: 8),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: ColorsManager.lightGrey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const TypingDots(),
          ),
        ],
      ),
    );
  }
}
