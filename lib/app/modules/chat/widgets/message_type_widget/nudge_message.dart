import 'package:flutter/material.dart';

import 'package:crypted_app/app/data/models/messages/nudge_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Displays a "Nudge / Thinking of you" special message as an animated card.
class NudgeMessageWidget extends StatefulWidget {
  final NudgeMessage message;

  const NudgeMessageWidget({super.key, required this.message});

  @override
  State<NudgeMessageWidget> createState() => _NudgeMessageWidgetState();
}

class _NudgeMessageWidgetState extends State<NudgeMessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _bounceAnimation = Tween<double>(begin: -6.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    _controller.forward();
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
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorsManager.primary.withAlpha(20),
              ColorsManager.primary.withAlpha(8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.primary.withAlpha(40),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message.nudgeEmoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message.nudgeText,
              textAlign: TextAlign.center,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
