import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class AppProgressButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final double? width;
  final double? height;
  final double? radius;
  final double? elevation;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? progressIndicatorColor;
  final EdgeInsets? padding;
  final bool isBordered;
  final bool isOutlined;
  final Function(AnimationController) onPressed;

  const AppProgressButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.width,
    this.height,
    this.radius,
    this.elevation = 0,
    this.fontSize,
    this.backgroundColor = ColorsManager.black,
    this.textColor,
    this.progressIndicatorColor,
    this.padding,
    this.isBordered = false,
    this.isOutlined = false,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  State<AppProgressButton> createState() => _AppProgressButtonState();
}

class _AppProgressButtonState extends State<AppProgressButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<BorderRadius?> _radiusAnimation;
  late double _buttonHeight;
  double? _initialWidth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buttonHeight = widget.height ?? 45; // Update height here
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(AppProgressButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height ||
        oldWidget.width != widget.width ||
        oldWidget.radius != widget.radius) {
      _buttonHeight = widget.height ?? 45; // Update height here
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    _initialWidth = widget.width ?? MediaQuery.of(context).size.width;

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _sizeAnimation = Tween<double>(
      begin: _initialWidth,
      end: _buttonHeight,
    ).animate(curvedAnimation);

    _radiusAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(widget.radius ?? 8),
      end: BorderRadius.circular(_buttonHeight / 2),
    ).animate(curvedAnimation);
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
      builder:
          (context, child) => Container(
            constraints: BoxConstraints(minWidth: _buttonHeight),
            width: _sizeAnimation.value,
            height: _buttonHeight,
            child: MaterialButton(
              padding:
                  widget.padding ??
                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: widget.elevation,
              shape: _buildButtonShape(),
              color:
                  widget.isOutlined
                      ? Colors.transparent
                      : widget.backgroundColor,
              onPressed:
                  _controller.isCompleted
                      ? null
                      : () => widget.onPressed(_controller),
              child: _buildButtonContent(),
            ),
          ),
    );
  }

  RoundedRectangleBorder _buildButtonShape() {
    return RoundedRectangleBorder(
      borderRadius:
          _radiusAnimation.value ?? BorderRadius.circular(widget.radius ?? 8),
      side: _getBorderSide(),
    );
  }

  BorderSide _getBorderSide() {
    if (widget.isOutlined || widget.isBordered) {
      return BorderSide(
        color: widget.textColor ?? ColorsManager.black,
        width: 1,
      );
    }
    return BorderSide.none;
  }

  Widget _buildButtonContent() {
    if (_controller.isCompleted) {
      return _buildLoadingIndicator();
    }
    return _buildButtonText();
  }

  Widget _buildLoadingIndicator() {
    return OverflowBox(
      maxWidth: _buttonHeight,
      maxHeight: _buttonHeight,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 1,
          backgroundColor: widget.progressIndicatorColor ?? ColorsManager.white,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.textColor ?? ColorsManager.white,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonText() {
    return FittedBox(
      child:
          widget.child ??
          Text(
            widget.text ?? 'Click Me',
            style: StylesManager.regular(
              fontSize: 14,
              color:
                  widget.isOutlined
                      ? widget.textColor ?? ColorsManager.black
                      : widget.textColor ?? ColorsManager.white,
            ),
          ),
    );
  }
}
