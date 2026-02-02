import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// A compact bottom sheet with nudge presets.
/// Returns the selected nudge as a (emoji, text) record, or null if dismissed.
class NudgePickerSheet extends StatelessWidget {
  const NudgePickerSheet({super.key});

  static const _nudges = [
    ('💭', 'Thinking of you'),
    ('👋', 'Hey! Just checking in'),
    ('😊', 'Hope you\'re having a great day'),
    ('❤️', 'Sending you good vibes'),
    ('🌟', 'You\'re awesome, just saying'),
    ('☕', 'Coffee time? Let\'s catch up'),
    ('🎉', 'Let\'s celebrate something!'),
    ('🤗', 'Sending a virtual hug'),
  ];

  static Future<(String, String)?> show(BuildContext context) {
    return showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const NudgePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Text(
              'Send a Nudge',
              style: StylesManager.semiBold(
                fontSize: FontSize.xLarge,
                color: ColorsManager.textPrimaryAdaptive(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Let them know you\'re thinking of them',
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Nudge grid
            ...List.generate(_nudges.length, (i) {
              final (emoji, text) = _nudges[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop((emoji, text));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withAlpha(8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: FontSize.medium,
                              color: ColorsManager.textPrimaryAdaptive(context),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: ColorsManager.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
