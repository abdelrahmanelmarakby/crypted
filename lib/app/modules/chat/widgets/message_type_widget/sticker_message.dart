import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/models/messages/sticker_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';

/// Displays a sticker message as a borderless, transparent image.
///
/// Stickers render without the standard message bubble background so they
/// feel like native chat stickers (WhatsApp / Telegram style).
class StickerMessageWidget extends StatelessWidget {
  final StickerMessage message;

  const StickerMessageWidget({super.key, required this.message});

  static const double _maxSize = 160.0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: _maxSize,
        maxHeight: _maxSize,
      ),
      child: CachedNetworkImage(
        imageUrl: message.stickerUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(
          width: _maxSize * 0.6,
          height: _maxSize * 0.6,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorsManager.primary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: _maxSize * 0.6,
          height: _maxSize * 0.6,
          decoration: BoxDecoration(
            color: ColorsManager.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.broken_image_outlined,
            color: ColorsManager.error,
            size: 32,
          ),
        ),
      ),
    );
  }
}
