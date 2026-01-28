import 'package:flutter/material.dart';

/// Base animated progress button with smooth state transitions
/// Clean, minimal design inspired by modern UI patterns
class AnimatedProgressButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AnimatedButtonState state;
  final Color? primaryColor;
  final Color? disabledColor;
  final Color? errorColor;
  final Color? successColor;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final bool expandOnLoading;

  const AnimatedProgressButton({
    super.key,
    required this.label,
    this.onPressed,
    this.state = AnimatedButtonState.ready,
    this.primaryColor,
    this.disabledColor,
    this.errorColor,
    this.successColor,
    this.textColor,
    this.height = 56,
    this.borderRadius = 12,
    this.icon,
    this.expandOnLoading = false,
  });

  @override
  State<AnimatedProgressButton> createState() => _AnimatedProgressButtonState();
}

class _AnimatedProgressButtonState extends State<AnimatedProgressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    final theme = Theme.of(context);
    switch (widget.state) {
      case AnimatedButtonState.ready:
        return widget.primaryColor ?? theme.primaryColor;
      case AnimatedButtonState.disabled:
        return widget.disabledColor ?? Colors.grey.shade300;
      case AnimatedButtonState.loading:
        return widget.primaryColor ?? theme.primaryColor;
      case AnimatedButtonState.error:
        return widget.errorColor ?? Colors.red.shade600;
      case AnimatedButtonState.success:
        return widget.successColor ?? Colors.green.shade600;
    }
  }

  Color _getTextColor() {
    return widget.textColor ?? Colors.white;
  }

  Widget _buildContent() {
    switch (widget.state) {
      case AnimatedButtonState.ready:
        return _buildReadyState();
      case AnimatedButtonState.disabled:
        return _buildReadyState();
      case AnimatedButtonState.loading:
        return _buildLoadingState();
      case AnimatedButtonState.error:
        return _buildErrorState();
      case AnimatedButtonState.success:
        return _buildSuccessState();
    }
  }

  Widget _buildReadyState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: _getTextColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
      ),
    );
  }

  Widget _buildErrorState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: _getTextColor(),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Error',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: _getTextColor(),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Success',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.state == AnimatedButtonState.ready && widget.onPressed != null
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.state == AnimatedButtonState.ready && widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: widget.height,
          width: widget.state == AnimatedButtonState.loading && !widget.expandOnLoading
              ? widget.height
              : double.infinity,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(
              widget.state == AnimatedButtonState.loading && !widget.expandOnLoading
                  ? widget.height / 2
                  : widget.borderRadius,
            ),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor().withValues(alpha: 0.3),
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
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(widget.state),
              alignment: Alignment.center,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Button states for animated progress button
enum AnimatedButtonState {
  ready,
  disabled,
  loading,
  error,
  success,
}
