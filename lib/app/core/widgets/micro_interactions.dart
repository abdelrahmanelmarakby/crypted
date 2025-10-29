import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Production-grade micro-interactions for 1M+ users
/// Apple-style smooth animations and feedback
class MicroInteractions {
  /// Bounce animation on tap
  static Widget bounceTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _BounceWrapper(
      onTap: onTap,
      scale: scale,
      duration: duration,
      child: child,
    );
  }

  /// Scale animation on tap with haptic feedback
  static Widget scaleTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.97,
    bool enableHaptic = true,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (enableHaptic) {
          HapticFeedback.lightImpact();
        }
      },
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  /// Slide in from bottom animation
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * value),
          child: Opacity(
            opacity: 1.0 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Shimmer effect for loading
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _ShimmerEffect(
      baseColor: baseColor ?? ColorsManager.borderColor,
      highlightColor: highlightColor ?? ColorsManager.offWhite,
      child: child,
    );
  }

  /// Ripple effect on tap
  static Widget rippleTap({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        splashColor: (rippleColor ?? ColorsManager.primary).withOpacity(0.1),
        highlightColor: (rippleColor ?? ColorsManager.primary).withOpacity(0.05),
        child: child,
      ),
    );
  }

  /// Animated container with smooth transitions
  static Widget animatedContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Color? color,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxShadow? shadow,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: shadow != null ? [shadow] : null,
      ),
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    Duration staggerDuration = const Duration(milliseconds: 100),
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      physics: physics,
      padding: padding,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(
            milliseconds: 300 + (index * staggerDuration.inMilliseconds),
          ),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return _PulseAnimation(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  /// Rotate animation
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    bool repeat = false,
  }) {
    return _RotateAnimation(
      duration: duration,
      repeat: repeat,
      child: child,
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double size = 60,
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: (color ?? ColorsManager.success).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: size * 0.6,
              color: color ?? ColorsManager.success,
            ),
          ),
        );
      },
    );
  }

  /// Error shake animation
  static Widget errorShake({
    required Widget child,
    bool trigger = false,
  }) {
    return _ShakeAnimation(
      trigger: trigger,
      child: child,
    );
  }

  /// Floating action button with animation
  static Widget floatingButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? label,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        icon: Icon(icon),
        label: label != null ? Text(label) : const SizedBox.shrink(),
        backgroundColor: backgroundColor ?? ColorsManager.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 4,
      ),
    );
  }

  /// Skeleton loader with shimmer
  static Widget skeletonLoader({
    double? width,
    double height = 20,
    BorderRadius? borderRadius,
  }) {
    return _ShimmerEffect(
      baseColor: ColorsManager.borderColor,
      highlightColor: ColorsManager.offWhite,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ColorsManager.borderColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Progress indicator with animation
  static Widget progressIndicator({
    required double progress,
    double size = 50,
    Color? color,
    double strokeWidth = 4,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: ColorsManager.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? ColorsManager.primary,
            ),
          ),
        );
      },
    );
  }

  /// Slide transition
  static Widget slideTransition({
    required Widget child,
    required Animation<Offset> position,
  }) {
    return SlideTransition(
      position: position,
      child: child,
    );
  }

  /// Hero animation wrapper
  static Widget hero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }
}

/// Bounce wrapper widget
class _BounceWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;

  const _BounceWrapper({
    required this.child,
    required this.onTap,
    required this.scale,
    required this.duration,
  });

  @override
  State<_BounceWrapper> createState() => _BounceWrapperState();
}

class _BounceWrapperState extends State<_BounceWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer effect widget
class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pulse animation widget
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Rotate animation widget
class _RotateAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool repeat;

  const _RotateAnimation({
    required this.child,
    required this.duration,
    required this.repeat,
  });

  @override
  State<_RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<_RotateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

/// Shake animation widget
class _ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const _ShakeAnimation({
    required this.child,
    required this.trigger,
  });

  @override
  State<_ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<_ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void didUpdateWidget(_ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
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
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * ((_controller.value * 4) % 2 == 0 ? 1 : -1), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
