import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:lottie/lottie.dart';

/// Production-grade loading states with micro-interactions
/// Designed for 1M+ users with optimal performance
class LoadingStates {
  /// Shimmer loading effect for lists
  static Widget shimmerList({
    required int itemCount,
    double itemHeight = 80.0,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _ShimmerItem(height: itemHeight),
    );
  }

  /// Shimmer loading for chat messages
  static Widget chatMessageShimmer({int count = 5}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _ShimmerItem(
              width: 200 + (index % 3) * 50,
              height: 60,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  /// Circular progress with percentage
  static Widget circularProgress({
    required double progress,
    String? label,
    double size = 100,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator.adaptive(
              value: progress,
              strokeWidth: 8,
              backgroundColor: ColorsManager.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? ColorsManager.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: color ?? ColorsManager.primary,
                ),
              ),
              if (label != null)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    color: ColorsManager.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Linear progress with label
  static Widget linearProgress({
    required double progress,
    String? label,
    String? subtitle,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color ?? ColorsManager.primary,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: ColorsManager.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? ColorsManager.primary,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: ColorsManager.grey,
              ),
            ),
          ),
      ],
    );
  }

  /// Skeleton loader for cards
  static Widget skeletonCard({
    double? width,
    double height = 200,
    BorderRadius? borderRadius,
  }) {
    return _ShimmerItem(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
    );
  }

  /// Pulsing dot indicator
  static Widget pulsingDot({
    double size = 12,
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: size * value,
            height: size * value,
            decoration: BoxDecoration(
              color: color ?? ColorsManager.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
      },
    );
  }

  /// Typing indicator (three dots)
  static Widget typingIndicator({Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(
            left: index > 0 ? 4 : 0,
          ),
          child: _AnimatedDot(
            delay: Duration(milliseconds: index * 200),
            color: color ?? ColorsManager.grey,
          ),
        );
      }),
    );
  }

  /// Lottie animation loader
  static Widget lottieLoader({
    required String assetPath,
    double size = 150,
    String? message,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            assetPath,
            fit: BoxFit.contain,
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Refresh indicator
  static Widget refreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? ColorsManager.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      child: child,
    );
  }

  /// Empty state with illustration
  static Widget emptyState({
    required String title,
    String? subtitle,
    IconData? icon,
    String? illustrationPath,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustrationPath != null)
              Image.asset(
                illustrationPath,
                width: 200,
                height: 200,
              )
            else if (icon != null)
              Icon(
                icon,
                size: 80,
                color: ColorsManager.grey.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Error state with retry
  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ColorsManager.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer effect item
class _ShimmerItem extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerItem({
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
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
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                ColorsManager.borderColor,
                ColorsManager.offWhite,
                ColorsManager.borderColor,
              ],
              stops: [
                0.0,
                _animation.value.clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated dot for typing indicator
class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _AnimatedDot({
    required this.delay,
    required this.color,
  });

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
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
          offset: Offset(0, -8 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
