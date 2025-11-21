import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class UploadingMessageWidget extends StatelessWidget {
  final UploadingMessage message;
  final VoidCallback? onCancel;

  const UploadingMessageWidget({
    super.key,
    required this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (message.progress * 100).toInt();
    final fileSize = FirebaseUtils.formatFileSize(message.fileSize);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
        minWidth: 240,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and file info
          Row(
            children: [
              // File type icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(message.uploadType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(message.uploadType),
                  color: _getTypeColor(message.uploadType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.small,
                        color: ColorsManager.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileSize,
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Cancel button
              if (onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: ColorsManager.grey,
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uploading...',
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.primary,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar with animation
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: ColorsManager.lightGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Progress
                    FractionallySizedBox(
                      widthFactor: message.progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorsManager.primary,
                              ColorsManager.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Preview thumbnail for images/videos
          if (message.uploadType == 'image' || message.uploadType == 'video')
            ..._buildThumbnail(),
        ],
      ),
    );
  }

  List<Widget> _buildThumbnail() {
    if (message.thumbnailPath == null && message.uploadType == 'image') {
      // Try to use the original file as thumbnail for images
      if (File(message.filePath).existsSync()) {
        return [
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(message.filePath),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ];
      }
    }
    return [];
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Iconsax.gallery;
      case 'video':
        return Iconsax.video;
      case 'audio':
        return Iconsax.microphone_2;
      case 'file':
      default:
        return Iconsax.document;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.purple;
      case 'audio':
        return Colors.orange;
      case 'file':
      default:
        return ColorsManager.primary;
    }
  }
}
