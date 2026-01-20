import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/media_gallery/views/video_player_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMessageWidget extends StatefulWidget {
  const VideoMessageWidget({super.key, required this.message});

  final VideoMessage message;

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _localThumbnailPath;
  bool _isGeneratingThumbnail = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate thumbnail for local videos
    if (_isLocalFile) {
      _generateLocalThumbnail();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Check if this is a local file (optimistic/uploading state)
  bool get _isLocalFile {
    final url = widget.message.video;
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains('/data/') ||
        url.contains('/cache/');
  }

  /// Get local file if it exists
  File? get _localFile {
    if (!_isLocalFile) return null;
    final path = widget.message.video.replaceFirst('file://', '');
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Generate thumbnail from local video file
  Future<void> _generateLocalThumbnail() async {
    if (_isGeneratingThumbnail) return;
    _isGeneratingThumbnail = true;

    try {
      final localFile = _localFile;
      if (localFile != null) {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: localFile.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 300,
          quality: 75,
        );

        if (mounted && thumbnailPath != null) {
          setState(() {
            _localThumbnailPath = thumbnailPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: Sizes.size200,
        height: Sizes.size150,
        decoration: BoxDecoration(
          color: ColorsManager.lightGrey,
          borderRadius: BorderRadius.circular(Radiuss.normal),
          border: _isLocalFile
              ? Border.all(
                  color: ColorsManager.primary.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              _isLocalFile ? Radiuss.normal - 2 : Radiuss.normal),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video thumbnail
              _buildThumbnail(),

              // Dark overlay for better visibility
              if (!_isLocalFile)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),

              // Upload overlay for local files
              if (_isLocalFile) _buildUploadingOverlay(),

              // Play button or upload indicator
              if (!_isLocalFile) _buildPlayButton(),

              // Video indicator label
              _buildVideoLabel(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (_isLocalFile) {
      // Show uploading message
      Get.snackbar(
        'Uploading',
        'Video is being uploaded...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Navigate to full-screen video player
    Get.to(
      () => VideoPlayerView(videoUrl: widget.message.video),
      transition: Transition.fadeIn,
    );
  }

  Widget _buildThumbnail() {
    // For local files, try to show the generated thumbnail
    if (_isLocalFile) {
      if (_localThumbnailPath != null) {
        return Image.file(
          File(_localThumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder(showLoading: true);
    }

    // For remote files, try to get network thumbnail
    final thumbnailUrl = _getThumbnailUrl(widget.message.video);

    if (thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      color: ColorsManager.lightGrey,
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.grey.withValues(alpha: 0.5),
                  ),
                ),
              )
            : Icon(
                Icons.movie_outlined,
                size: Sizes.size48,
                color: ColorsManager.grey.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.4 + (_pulseController.value * 0.2);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: opacity * 0.5),
                Colors.black.withValues(alpha: opacity),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing upload indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.1);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorsManager.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Upload status text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Uploading video...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton() {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          size: 36,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildVideoLabel() {
    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isLocalFile
              ? ColorsManager.primary.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLocalFile ? Icons.cloud_upload_outlined : Icons.videocam_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _isLocalFile ? 'Sending...' : 'Video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Try to get thumbnail URL from video URL patterns
  String? _getThumbnailUrl(String videoUrl) {
    // Firebase Storage pattern: replace video extension with _thumb.jpg
    if (videoUrl.contains('firebasestorage.googleapis.com')) {
      // Extract base URL without query params
      final uri = Uri.parse(videoUrl);
      final path = uri.path;

      // Check for common video extensions
      for (final ext in ['.mp4', '.mov', '.avi', '.webm', '.mkv']) {
        if (path.toLowerCase().contains(ext)) {
          // Try to get thumbnail by replacing extension
          final thumbPath = path.replaceAll(
              RegExp(r'\.(mp4|mov|avi|webm|mkv)', caseSensitive: false),
              '_thumb.jpg');
          return '${uri.scheme}://${uri.host}$thumbPath?${uri.query}';
        }
      }
    }

    return null;
  }
}
