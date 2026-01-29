import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_type_widget/link_preview_card.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

/// Text message widget with automatic link preview detection
///
/// **Features:**
/// - Displays text content with edit indicator
/// - Auto-detects URLs and shows rich preview card
/// - Preview includes title, description, image, and favicon
/// - Shimmer loading state while fetching metadata
class TextMessageWidget extends StatelessWidget {
  const TextMessageWidget({super.key, required this.message});

  final TextMessage message;

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
            color: ColorsManager.black,
          ),
        ),

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
}
