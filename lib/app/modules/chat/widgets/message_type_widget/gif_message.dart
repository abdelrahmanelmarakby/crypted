import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/models/messages/gif_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

/// Displays an animated GIF message with Giphy attribution.
///
/// Uses [CachedNetworkImage] for efficient caching. Shows a low-res
/// preview URL (if available) while the full GIF loads.
class GifMessageWidget extends StatelessWidget {
  final GifMessage message;

  const GifMessageWidget({super.key, required this.message});

  static const double _maxWidth = 240.0;

  @override
  Widget build(BuildContext context) {
    // Compute aspect ratio from metadata or fall back to 4:3
    final double aspectRatio =
        (message.width != null && message.height != null && message.height! > 0)
            ? message.width! / message.height!
            : 4 / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // GIF image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CachedNetworkImage(
                imageUrl: message.gifUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(),
                errorWidget: (_, __, ___) => _buildError(),
              ),
            ),
          ),
        ),

        // "GIF" badge + Giphy attribution
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GIF',
                  style: StylesManager.semiBold(
                    fontSize: FontSize.xXSmall,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
              if (message.title != null && message.title!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message.title!,
                    style: StylesManager.regular(
                      fontSize: FontSize.xXSmall,
                      color: ColorsManager.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: ColorsManager.lightGrey.withValues(alpha: 0.2),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: ColorsManager.error.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.gif_box_outlined,
          color: ColorsManager.error,
          size: 32,
        ),
      ),
    );
  }
}
