import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Upload button with clean, minimal animations
/// States: ready, selecting, uploading, uploaded, error
class UploadProgressButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final UploadButtonState state;
  final double progress; // 0.0 to 1.0
  final String? label;
  final double height;
  final Color? primaryColor;
  final Color? successColor;
  final Color? errorColor;

  const UploadProgressButton({
    super.key,
    this.onPressed,
    this.state = UploadButtonState.ready,
    this.progress = 0.0,
    this.label,
    this.height = 50,
    this.primaryColor,
    this.successColor,
    this.errorColor,
  });

  @override
  State<UploadProgressButton> createState() => _UploadProgressButtonState();
}

class _UploadProgressButtonState extends State<UploadProgressButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _uploadController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for selecting state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Upload animation controller
    _uploadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(UploadProgressButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    _pulseController.stop();
    _uploadController.stop();

    switch (widget.state) {
      case UploadButtonState.ready:
        break;
      case UploadButtonState.selecting:
        _pulseController.repeat(reverse: true);
        break;
      case UploadButtonState.uploading:
        _uploadController.repeat();
        break;
      case UploadButtonState.uploaded:
      case UploadButtonState.error:
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _uploadController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.state) {
      case UploadButtonState.ready:
        return widget.primaryColor ?? const Color(0xFF635BFF);
      case UploadButtonState.selecting:
        return widget.primaryColor ?? const Color(0xFF635BFF);
      case UploadButtonState.uploading:
        return widget.primaryColor ?? const Color(0xFF635BFF);
      case UploadButtonState.uploaded:
        return widget.successColor ?? const Color(0xFF00D924);
      case UploadButtonState.error:
        return widget.errorColor ?? const Color(0xFFDF1B41);
    }
  }

  String _getLabel() {
    if (widget.label != null && widget.state == UploadButtonState.ready) {
      return widget.label!;
    }

    switch (widget.state) {
      case UploadButtonState.ready:
        return 'Choose File';
      case UploadButtonState.selecting:
        return 'Selecting...';
      case UploadButtonState.uploading:
        return 'Uploading ${(widget.progress * 100).toInt()}%';
      case UploadButtonState.uploaded:
        return 'Uploaded';
      case UploadButtonState.error:
        return 'Upload Failed';
    }
  }

  Widget _buildIcon() {
    switch (widget.state) {
      case UploadButtonState.ready:
        return Icon(
          Icons.cloud_upload_outlined,
          color: Colors.white,
          size: 22,
        );

      case UploadButtonState.selecting:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Icon(
            Icons.folder_open_rounded,
            color: Colors.white,
            size: 22,
          ),
        );

      case UploadButtonState.uploading:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: widget.progress,
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            AnimatedBuilder(
              animation: _uploadController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _uploadController.value * 2 * math.pi,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                );
              },
            ),
          ],
        );

      case UploadButtonState.uploaded:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 22,
          ),
        );

      case UploadButtonState.error:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.rotate(
                angle: math.sin(value * math.pi * 2) * 0.1,
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.state == UploadButtonState.ready && widget.onPressed != null;

    return GestureDetector(
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.state == UploadButtonState.selecting
                ? _pulseAnimation.value
                : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: widget.height,
          decoration: BoxDecoration(
            color: _getColor(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getColor().withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress bar background
              if (widget.state == UploadButtonState.uploading)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: widget.height,
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              // Button content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    child: Row(
                      key: ValueKey(widget.state),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIcon(),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _getLabel(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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

/// Upload button states
enum UploadButtonState {
  ready,      // Default state, ready to upload
  selecting,  // Selecting file (animated folder icon)
  uploading,  // Uploading with progress
  uploaded,   // Successfully uploaded (checkmark)
  error,      // Upload failed (error icon)
}
