import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/theme/colors_manager.dart';
import '../../core/constants/theme/styles_manager.dart';
import '../../core/extensions/string.dart';

class AppProgressButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? progressIndicatorColor;
  final bool? isBordered;
  final bool? isOutlined; // Added property for outline button
  final Color? textColor;
  final double? fontSize;
  final double? radius;
  final double? elevation;
  final EdgeInsets? padding;
  final Function(AnimationController animationController) onPressed;

  const AppProgressButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.isBordered,
    this.isOutlined, // Initialize isOutlined property
    this.height = 50,
    this.progressIndicatorColor,
    this.radius = 10,
    this.elevation,
    this.padding,
  });

  @override
  State<AppProgressButton> createState() => AppProgressButtonState();
}

class AppProgressButtonState extends State<AppProgressButton>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> sizeAnimation;
  late Animation<BorderRadiusGeometry?> radiusAnimation;

  double buttonHeight = 35;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buttonHeight = widget.height ?? 35;

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    sizeAnimation = Tween<double>(
      begin: widget.width ?? context.width,
      end: buttonHeight,
    ).animate(curvedAnimation);

    radiusAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(widget.radius ?? 8.0),
      end: BorderRadius.circular(50),
    ).animate(curvedAnimation);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Container(
        constraints: BoxConstraints(minWidth: buttonHeight),
        width: sizeAnimation.value,
        height: buttonHeight,
        child: MaterialButton(
          padding: widget.padding ??
              const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
          elevation: widget.elevation ?? 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: radiusAnimation.value!,
            side: widget.isOutlined ?? false
                ? BorderSide(
                    color: widget.textColor ?? ColorsManager.primary1000,
                    width: 1.0, // Define border width for outlined button
                  )
                : !(widget.isBordered ?? false)
                    ? BorderSide.none
                    : BorderSide(
                        color: widget.textColor ?? ColorsManager.primary1000,
                        width: 1.0, // Define border width for bordered button
                      ),
          ),
          color: widget.isOutlined ?? false
              ? Colors
                  .transparent // Outline buttons usually have a transparent background
              : widget.backgroundColor ?? ColorsManager.primary1000,
          onPressed: () async {
            if (controller.isCompleted) return;
            widget.onPressed(controller);
          },
          child: controller.isCompleted
              ? OverflowBox(
                  maxWidth: buttonHeight,
                  maxHeight: buttonHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 1,
                      backgroundColor:
                          widget.progressIndicatorColor ?? ColorsManager.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.textColor ?? ColorsManager.white,
                      ),
                    ),
                  ),
                )
              : FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.child ??
                          Text(
                            cfl(widget.text ?? 'Click Me'),
                            style: StylesManager.bold(
                              color: widget.isOutlined ?? false
                                  ? widget.textColor ??
                                      ColorsManager.primary1000
                                  : widget.textColor ?? ColorsManager.white,
                              fontSize: widget.fontSize ?? 16,
                            ),
                          ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
