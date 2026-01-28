import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Stripe-style payment button with smooth animations
/// Clean, minimal design with payment-specific states
class StripePaymentButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PaymentButtonState state;
  final double height;
  final Color? primaryColor;
  final Color? successColor;
  final Color? errorColor;

  const StripePaymentButton({
    super.key,
    this.label = 'Pay',
    this.onPressed,
    this.state = PaymentButtonState.ready,
    this.height = 56,
    this.primaryColor,
    this.successColor,
    this.errorColor,
  });

  @override
  State<StripePaymentButton> createState() => _StripePaymentButtonState();
}

class _StripePaymentButtonState extends State<StripePaymentButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Press animation controller
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Shimmer animation for loading state
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    if (widget.state == PaymentButtonState.processing) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(StripePaymentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PaymentButtonState.processing &&
        oldWidget.state != PaymentButtonState.processing) {
      _shimmerController.repeat();
    } else if (widget.state != PaymentButtonState.processing) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case PaymentButtonState.ready:
        return widget.primaryColor ?? const Color(0xFF635BFF); // Stripe purple
      case PaymentButtonState.disabled:
        return Colors.grey.shade400;
      case PaymentButtonState.processing:
        return widget.primaryColor ?? const Color(0xFF635BFF);
      case PaymentButtonState.success:
        return widget.successColor ?? const Color(0xFF00D924);
      case PaymentButtonState.error:
        return widget.errorColor ?? const Color(0xFFDF1B41);
    }
  }

  Widget _buildContent() {
    switch (widget.state) {
      case PaymentButtonState.ready:
      case PaymentButtonState.disabled:
        return _buildReadyContent();
      case PaymentButtonState.processing:
        return _buildProcessingContent();
      case PaymentButtonState.success:
        return _buildSuccessContent();
      case PaymentButtonState.error:
        return _buildErrorContent();
    }
  }

  Widget _buildReadyContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Processing...',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Payment Complete',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Payment Failed',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.state == PaymentButtonState.ready && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _pressController.forward() : null,
      onTapUp: isEnabled
          ? (_) {
              _pressController.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: widget.height,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor().withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect for processing state
              if (widget.state == PaymentButtonState.processing)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ShimmerPainter(
                          shimmerAnimation: _shimmerAnimation,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ),
              // Button content
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(widget.state),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for shimmer effect
class _ShimmerPainter extends CustomPainter {
  final Animation<double> shimmerAnimation;

  _ShimmerPainter({required this.shimmerAnimation})
      : super(repaint: shimmerAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(shimmerAnimation.value * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => true;
}

/// Payment button states
enum PaymentButtonState {
  ready,
  disabled,
  processing,
  success,
  error,
}
