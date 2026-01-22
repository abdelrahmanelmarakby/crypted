import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// WhatsApp/Telegram-style uploading message widget
/// Shows actual file preview with progress overlay
class UploadingMessageWidget extends StatefulWidget {
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
  State<UploadingMessageWidget> createState() => _UploadingMessageWidgetState();
}

class _UploadingMessageWidgetState extends State<UploadingMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the progress indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = _tryGetUploadState();
    final hasError = uploadState?.status == UploadStatus.failed;

    // Choose the appropriate layout based on file type
    switch (widget.message.uploadType) {
      case 'image':
        return _buildImageUpload(context, uploadState, hasError);
      case 'video':
        return _buildVideoUpload(context, uploadState, hasError);
      case 'audio':
        return _buildAudioUpload(context, uploadState, hasError);
      case 'file':
      default:
        return _buildFileUpload(context, uploadState, hasError);
    }
  }

  /// Image upload - Full preview with circular progress overlay (WhatsApp style)
  Widget _buildImageUpload(BuildContext context, UploadState? uploadState, bool hasError) {
    final file = File(widget.message.filePath);
    final fileExists = file.existsSync();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
        maxHeight: 280,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image preview
            if (fileExists)
              Image.file(
                file,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder('image'),
              )
            else
              _buildPlaceholder('image'),

            // Dark overlay that fades as progress increases
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withValues(
                  alpha: hasError ? 0.6 : 0.4 * (1 - widget.message.progress),
                ),
              ),
            ),

            // Circular progress indicator in center
            Positioned.fill(
              child: Center(
                child: _buildCircularProgress(uploadState, hasError, size: 64),
              ),
            ),

            // Bottom info bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomInfoBar(uploadState, hasError),
            ),

            // Cancel button (top right)
            if (widget.onCancel != null && !hasError)
              Positioned(
                top: 8,
                right: 8,
                child: _buildCancelButton(),
              ),

            // Error overlay
            if (hasError) _buildErrorOverlay(uploadState?.error),
          ],
        ),
      ),
    );
  }

  /// Video upload - Thumbnail with play icon and progress
  Widget _buildVideoUpload(BuildContext context, UploadState? uploadState, bool hasError) {
    final file = File(widget.message.filePath);
    final thumbnailPath = widget.message.thumbnailPath;
    final thumbnailFile = thumbnailPath != null ? File(thumbnailPath) : null;
    final hasThumbnail = thumbnailFile?.existsSync() ?? false;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
        maxHeight: 280,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video thumbnail or placeholder
            if (hasThumbnail)
              Image.file(
                thumbnailFile!,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder('video'),
              )
            else
              _buildPlaceholder('video'),

            // Dark overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(
                  hasError ? 0.6 : 0.5 * (1 - widget.message.progress),
                ),
              ),
            ),

            // Circular progress with play icon
            Positioned.fill(
              child: Center(
                child: _buildCircularProgress(
                  uploadState,
                  hasError,
                  size: 64,
                  showPlayIcon: true,
                ),
              ),
            ),

            // Duration badge (if available)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.video, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Video',
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom info bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomInfoBar(uploadState, hasError),
            ),

            // Cancel button
            if (widget.onCancel != null && !hasError)
              Positioned(
                top: 8,
                right: 8,
                child: _buildCancelButton(),
              ),

            // Error overlay
            if (hasError) _buildErrorOverlay(uploadState?.error),
          ],
        ),
      ),
    );
  }

  /// Audio upload - Waveform style with progress
  Widget _buildAudioUpload(BuildContext context, UploadState? uploadState, bool hasError) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : ColorsManager.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : ColorsManager.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Circular progress with mic icon
          _buildCircularProgress(
            uploadState,
            hasError,
            size: 48,
            icon: Iconsax.microphone_2,
            iconSize: 20,
          ),
          const SizedBox(width: 12),

          // Waveform visualization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated waveform
                _buildWaveform(widget.message.progress, hasError),
                const SizedBox(height: 8),

                // Progress info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasError ? 'Failed' : 'Uploading...',
                      style: StylesManager.medium(
                        fontSize: FontSize.xSmall,
                        color: hasError ? Colors.red : ColorsManager.primary,
                      ),
                    ),
                    if (uploadState != null && !hasError)
                      Text(
                        _formatSpeed(uploadState.bytesPerSecond),
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel/Retry button
          if (hasError && widget.onRetry != null)
            IconButton(
              icon: const Icon(Iconsax.refresh, size: 20),
              color: ColorsManager.primary,
              onPressed: widget.onRetry,
            )
          else if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: ColorsManager.grey,
              onPressed: widget.onCancel,
            ),
        ],
      ),
    );
  }

  /// File upload - File icon with details and progress ring
  Widget _buildFileUpload(BuildContext context, UploadState? uploadState, bool hasError) {
    final fileSize = FirebaseUtils.formatFileSize(widget.message.fileSize);
    final fileName = widget.message.fileName;
    final extension = fileName.split('.').last.toUpperCase();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : ColorsManager.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File icon with progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: hasError ? 0 : widget.message.progress,
                  strokeWidth: 3,
                  backgroundColor: ColorsManager.lightGrey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(
                    hasError ? Colors.red : _getFileColor(extension),
                  ),
                ),
              ),
              // File type badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getFileColor(extension).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getFileIcon(extension),
                      size: 20,
                      color: hasError ? Colors.red : _getFileColor(extension),
                    ),
                    Text(
                      extension.length > 4 ? extension.substring(0, 4) : extension,
                      style: StylesManager.semiBold(
                        fontSize: 8,
                        color: hasError ? Colors.red : _getFileColor(extension),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.small,
                    color: ColorsManager.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      fileSize,
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                    if (!hasError) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: ColorsManager.grey),
                      ),
                      // Show checkmark when complete, percentage otherwise
                      if (widget.message.progress >= 1.0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: StylesManager.medium(
                                fontSize: FontSize.xSmall,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${(widget.message.progress * 100).toInt()}%',
                          style: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.primary,
                          ),
                        ),
                    ],
                  ],
                ),
                if (uploadState != null && !hasError) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatSpeedAndETA(uploadState),
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Cancel/Retry button
          if (hasError && widget.onRetry != null)
            IconButton(
              icon: const Icon(Iconsax.refresh, size: 20),
              color: ColorsManager.primary,
              onPressed: widget.onRetry,
            )
          else if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: ColorsManager.grey,
              onPressed: widget.onCancel,
            ),
        ],
      ),
    );
  }

  /// Circular progress indicator with optional icon
  Widget _buildCircularProgress(
    UploadState? uploadState,
    bool hasError, {
    required double size,
    IconData? icon,
    double iconSize = 24,
    bool showPlayIcon = false,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: hasError ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? Colors.red.withOpacity(0.9)
                  : Colors.black.withOpacity(0.6),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                if (!hasError)
                  SizedBox(
                    width: size - 8,
                    height: size - 8,
                    child: CircularProgressIndicator(
                      value: widget.message.progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),

                // Icon or percentage
                if (hasError)
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 28,
                  )
                else if (widget.message.progress >= 1.0)
                  // Show checkmark when complete
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 28,
                  )
                else if (showPlayIcon && widget.message.progress < 1)
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: iconSize)
                else
                  Text(
                    '${(widget.message.progress * 100).toInt()}%',
                    style: StylesManager.semiBold(
                      fontSize: size > 50 ? FontSize.small : FontSize.xSmall,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom info bar for image/video uploads
  Widget _buildBottomInfoBar(UploadState? uploadState, bool hasError) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // File size
          Text(
            FirebaseUtils.formatFileSize(widget.message.fileSize),
            style: StylesManager.regular(
              fontSize: FontSize.xSmall,
              color: Colors.white70,
            ),
          ),
          // Speed/ETA
          if (uploadState != null && !hasError)
            Text(
              _formatSpeedAndETA(uploadState),
              style: StylesManager.regular(
                fontSize: FontSize.xSmall,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  /// Cancel button
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  /// Error overlay with retry button
  Widget _buildErrorOverlay(String? errorMessage) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload failed',
              style: StylesManager.semiBold(
                fontSize: FontSize.small,
                color: Colors.white,
              ),
            ),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                errorMessage,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onRetry != null)
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Iconsax.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (widget.onRetry != null && widget.onCancel != null)
                  const SizedBox(width: 8),
                if (widget.onCancel != null)
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Animated waveform for audio uploads
  Widget _buildWaveform(double progress, bool hasError) {
    return SizedBox(
      height: 32,
      child: Row(
        children: List.generate(20, (index) {
          final isActive = index / 20 <= progress;
          // Generate pseudo-random heights for waveform effect
          final height = 8.0 + (math.sin(index * 0.8) * 12).abs();

          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: height,
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red.withOpacity(isActive ? 0.8 : 0.3)
                    : ColorsManager.primary.withOpacity(isActive ? 0.8 : 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Placeholder for missing media
  Widget _buildPlaceholder(String type) {
    return Container(
      width: double.infinity,
      height: 280,
      color: ColorsManager.lightGrey.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'image' ? Iconsax.gallery : Iconsax.video,
            size: 48,
            color: ColorsManager.grey,
          ),
          const SizedBox(height: 8),
          Text(
            type == 'image' ? 'Loading image...' : 'Loading video...',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Get upload state from manager
  UploadState? _tryGetUploadState() {
    try {
      final manager = Get.find<UploadStateManager>();
      return manager.getUpload(widget.message.id);
    } catch (e) {
      return null;
    }
  }

  /// Format speed for display
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

  /// Format speed and ETA together
  String _formatSpeedAndETA(UploadState state) {
    final speed = _formatSpeed(state.bytesPerSecond);
    final eta = state.estimatedTimeRemaining;

    if (eta != null && speed.isNotEmpty) {
      final etaStr = eta.inSeconds < 60
          ? '${eta.inSeconds}s'
          : '${eta.inMinutes}m';
      return '$speed • ~$etaStr';
    }
    return speed;
  }

  /// Get color for file type
  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      case 'txt':
        return Colors.grey;
      default:
        return ColorsManager.primary;
    }
  }

  /// Get icon for file type
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Iconsax.document_text;
      case 'doc':
      case 'docx':
        return Iconsax.document_text_1;
      case 'xls':
      case 'xlsx':
        return Iconsax.document_filter;
      case 'ppt':
      case 'pptx':
        return Iconsax.presention_chart;
      case 'zip':
      case 'rar':
      case '7z':
        return Iconsax.archive;
      case 'txt':
        return Iconsax.document;
      default:
        return Iconsax.document_1;
    }
  }
}
