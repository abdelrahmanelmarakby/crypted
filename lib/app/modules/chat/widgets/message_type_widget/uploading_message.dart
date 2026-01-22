import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class UploadingMessageWidget extends StatelessWidget {
  final UploadingMessage message;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const UploadingMessageWidget({
    super.key,
    required this.message,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (message.progress * 100).toInt();
    final fileSize = FirebaseUtils.formatFileSize(message.fileSize);

    // Try to get upload state from UploadStateManager for speed/ETA
    final uploadState = _tryGetUploadState();

    // Check for error state
    final hasError = uploadState?.status == UploadStatus.failed;
    final errorMessage = uploadState?.error;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
        minWidth: 240,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.withValues(alpha: 0.3)
              : ColorsManager.primary.withValues(alpha: 0.2),
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
              // File type icon (red if error)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasError
                      ? Colors.red.withValues(alpha: 0.1)
                      : _getTypeColor(message.uploadType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasError ? Iconsax.warning_2 : _getTypeIcon(message.uploadType),
                  color: hasError ? Colors.red : _getTypeColor(message.uploadType),
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

              // Speed and ETA display
              if (uploadState != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upload speed
                    Text(
                      _formatSpeed(uploadState.bytesPerSecond),
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                    // ETA
                    if (uploadState.estimatedTimeRemaining != null)
                      Text(
                        _formatETA(uploadState.estimatedTimeRemaining!),
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                  ],
                ),
              ],
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

          // Error handling UI
          if (hasError) ...[
            const SizedBox(height: 12),
            _buildErrorUI(errorMessage),
          ],
        ],
      ),
    );
  }

  /// Build error UI with retry option
  Widget _buildErrorUI(String? errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upload failed',
                  style: StylesManager.medium(
                    fontSize: FontSize.small,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              errorMessage,
              style: StylesManager.regular(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              // Retry button
              if (onRetry != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Iconsax.refresh, size: 16),
                    label: Text(
                      'Retry',
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (onRetry != null && onCancel != null)
                const SizedBox(width: 8),
              // Cancel button
              if (onCancel != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: ColorsManager.grey,
                    ),
                    label: Text(
                      'Cancel',
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsManager.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: ColorsManager.grey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
            child: Stack(
              children: [
                // Image with grayscale filter that reveals to color
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(_getRevealingColorMatrix(message.progress)),
                  child: Image.file(
                    File(message.filePath),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
                // Progress overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4 * (1 - message.progress)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      }
    }
    return [];
  }

  /// Try to get upload state from UploadStateManager
  UploadState? _tryGetUploadState() {
    try {
      final manager = Get.find<UploadStateManager>();
      return manager.getUpload(message.id);
    } catch (e) {
      // UploadStateManager might not be registered yet
      return null;
    }
  }

  /// Format upload speed for display
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '';
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Format estimated time remaining for display
  String _formatETA(Duration duration) {
    if (duration.inSeconds < 60) {
      return '~${duration.inSeconds}s remaining';
    } else if (duration.inMinutes < 60) {
      return '~${duration.inMinutes}m remaining';
    } else {
      return '~${duration.inHours}h remaining';
    }
  }

  /// Generate color matrix for revealing animation (grayscale to color)
  List<double> _getRevealingColorMatrix(double progress) {
    // Interpolate between grayscale and full color
    final saturation = progress.clamp(0.0, 1.0);
    final invSat = 1 - saturation;
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    return [
      lumR * invSat + saturation, lumG * invSat, lumB * invSat, 0, 0,
      lumR * invSat, lumG * invSat + saturation, lumB * invSat, 0, 0,
      lumR * invSat, lumG * invSat, lumB * invSat + saturation, 0, 0,
      0, 0, 0, 1, 0,
    ];
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
