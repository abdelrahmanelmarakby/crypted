import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/link_preview_card.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

/// Text message widget with automatic link preview detection and inline translation
///
/// **Features:**
/// - Displays text content with edit indicator
/// - Auto-detects URLs and shows rich preview card
/// - Preview includes title, description, image, and favicon
/// - Shimmer loading state while fetching metadata
/// - Inline translation display (Phase 14.2)
class TextMessageWidget extends StatelessWidget {
  const TextMessageWidget({
    super.key,
    required this.message,
    this.translatedText,
    this.translationSourceLang,
    this.isTranslating = false,
  });

  final TextMessage message;

  /// Translated text to show below the original (null if not translated).
  final String? translatedText;

  /// Detected source language code (e.g. "ar", "en").
  final String? translationSourceLang;

  /// Whether translation is currently in progress.
  final bool isTranslating;

  @override
  Widget build(BuildContext context) {
    // UX-008: Detect URL for link preview
    final detectedUrl = UrlDetector.extractFirstUrl(message.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message text
        Text(
          message.text,
          maxLines: 50,
          overflow: TextOverflow.ellipsis,
          style: StylesManager.medium(
            fontSize: FontSize.small,
            color: ColorsManager.textPrimaryAdaptive(context),
          ),
        ),

        // Inline translation (Phase 14.2)
        if (isTranslating) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: ColorsManager.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Translating...',
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ] else if (translatedText != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: ColorsManager.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Translation header
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.translate,
                      size: 10,
                      color: ColorsManager.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      translationSourceLang != null
                          ? 'Translated from ${_languageName(translationSourceLang!)}'
                          : 'Translated',
                      style: StylesManager.regular(
                        fontSize: 10,
                        color: ColorsManager.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Translated text
                Text(
                  translatedText!,
                  maxLines: 50,
                  overflow: TextOverflow.ellipsis,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.textPrimaryAdaptive(context)
                        .withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Edited indicator
        if (message.isEdited) ...[
          SizedBox(height: Paddings.xSmall / 2),
          Text(
            'Edited',
            style: StylesManager.regular(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey.withValues(alpha: 0.7),
            ),
          ),
        ],

        // UX-008: Link preview card (if URL detected)
        if (detectedUrl != null)
          LinkPreviewCard(
            url: detectedUrl,
            // Use compact mode for shorter messages to save space
            compact: message.text.length < 100,
          ),
      ],
    );
  }

  /// Convert language code to human-readable name.
  static String _languageName(String code) {
    const languages = {
      'ar': 'Arabic',
      'en': 'English',
      'fr': 'French',
      'es': 'Spanish',
      'de': 'German',
      'tr': 'Turkish',
      'fa': 'Persian',
      'ur': 'Urdu',
      'hi': 'Hindi',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'it': 'Italian',
      'nl': 'Dutch',
      'he': 'Hebrew',
    };
    return languages[code] ?? code.toUpperCase();
  }
}
