import 'dart:io';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ImageMessageWidget extends StatefulWidget {
  const ImageMessageWidget({super.key, required this.message});

  final PhotoMessage message;

  @override
  State<ImageMessageWidget> createState() => _ImageMessageWidgetState();
}

class _ImageMessageWidgetState extends State<ImageMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Check if this is a local file (optimistic/uploading state)
  bool get _isLocalFile {
    final url = widget.message.imageUrl;
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains('/data/') ||
        url.contains('/cache/');
  }

  /// Get the local file if it exists
  File? get _localFile {
    if (!_isLocalFile) return null;
    final path = widget.message.imageUrl.replaceFirst('file://', '');
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(
        width: Sizes.size200,
        height: Sizes.size150,
        decoration: BoxDecoration(
          color: ColorsManager.lightGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Radiuss.normal),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radiuss.normal),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image content
              _buildImageContent(),

              // Loading overlay for local files (uploading state)
              if (_isLocalFile) _buildUploadingOverlay(),

              // Error overlay
              if (_hasError && !_isLocalFile) _buildErrorOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final localFile = _localFile;

    // Local file (optimistic UI - show immediately)
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    // Network image with loading states
    return Image.network(
      widget.message.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isLoading = false);
            });
          }
          return child;
        }

        // Loading progress
        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null;

        return _buildLoadingPlaceholder(progress);
      },
      errorBuilder: (context, error, stackTrace) {
        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hasError = true);
          });
        }
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder(double? progress) {
    return Shimmer.fromColors(
      baseColor: ColorsManager.lightGrey.withValues(alpha: 0.4),
      highlightColor: ColorsManager.lightGrey.withValues(alpha: 0.2),
      child: Container(
        color: ColorsManager.lightGrey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.primary.withValues(alpha: 0.7),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: ColorsManager.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.3 + (_pulseController.value * 0.2);
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
                // Pulsing upload icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ColorsManager.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorsManager.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sending...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 32,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: ColorsManager.lightGrey.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: ColorsManager.grey.withValues(alpha: 0.5),
          size: 40,
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    final localFile = _localFile;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dismiss on tap background
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black.withValues(alpha: 0.9)),
            ),
            // Image viewer
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: localFile != null
                    ? Image.file(localFile, fit: BoxFit.contain)
                    : Image.network(
                        widget.message.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
