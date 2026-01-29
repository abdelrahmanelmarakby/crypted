import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Animated unread message badge with pulse effect
///
/// **Features:**
/// - Subtle breathing/pulse animation
/// - Outer glow that fades in/out
/// - Configurable size and color
/// - Lightweight - uses single AnimationController
class UnreadPulseBadge extends StatefulWidget {
  final double size;
  final Color color;
  final bool enablePulse;

  const UnreadPulseBadge({
    super.key,
    this.size = 8.0,
    this.color = ColorsManager.primary,
    this.enablePulse = true,
  });

  @override
  State<UnreadPulseBadge> createState() => _UnreadPulseBadgeState();
}

class _UnreadPulseBadgeState extends State<UnreadPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Subtle scale pulse: 1.0 -> 1.2 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Glow opacity: 0.2 -> 0.6 -> 0.2
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 0.2)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.enablePulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(UnreadPulseBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enablePulse != oldWidget.enablePulse) {
      if (widget.enablePulse) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
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
    if (!widget.enablePulse) {
      // Static badge without animation
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          // Extra space for the glow effect
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Transform.scale(
                  scale: _scaleAnimation.value * 1.5,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: _glowAnimation.value * 0.3),
                    ),
                  ),
                ),
                // Middle glow ring
                Transform.scale(
                  scale: _scaleAnimation.value * 1.2,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: _glowAnimation.value * 0.5),
                    ),
                  ),
                ),
                // Core dot
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: _glowAnimation.value),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact unread count badge with number
///
/// Shows the actual count of unread messages with optional pulse
class UnreadCountBadge extends StatelessWidget {
  final int count;
  final bool showPulse;

  const UnreadCountBadge({
    super.key,
    required this.count,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse effect behind badge
        if (showPulse)
          UnreadPulseBadge(
            size: 18,
            enablePulse: true,
          ),
        // Count badge
        Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: ColorsManager.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
