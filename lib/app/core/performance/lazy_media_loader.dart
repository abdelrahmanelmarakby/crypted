// PERF-004 FIX: Lazy Loading for Media Attachments
// Defers loading of images/videos until they're visible

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Configuration for lazy media loading
class LazyMediaConfig {
  final int preloadDistance;
  final Duration fadeInDuration;
  final bool showPlaceholder;
  final bool enableMemoryCache;
  final int maxCacheWidth;
  final int maxCacheHeight;

  const LazyMediaConfig({
    this.preloadDistance = 2,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.showPlaceholder = true,
    this.enableMemoryCache = true,
    this.maxCacheWidth = 800,
    this.maxCacheHeight = 800,
  });
}

/// Lazy loading image widget with visibility detection
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final LazyMediaConfig config;
  final VoidCallback? onLoaded;
  final BorderRadius? borderRadius;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.config = const LazyMediaConfig(),
    this.onLoaded,
    this.borderRadius,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isVisible = false;
  bool _hasLoaded = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (visible) {
        if (visible && !_isVisible) {
          setState(() => _isVisible = true);
        }
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: _isVisible ? _buildImage() : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.config.enableMemoryCache ? widget.config.maxCacheWidth : null,
      memCacheHeight: widget.config.enableMemoryCache ? widget.config.maxCacheHeight : null,
      fadeInDuration: widget.config.fadeInDuration,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) =>
          widget.errorWidget ?? _buildErrorWidget(),
      imageBuilder: (context, imageProvider) {
        if (!_hasLoaded) {
          _hasLoaded = true;
          widget.onLoaded?.call();
        }
        return Image(
          image: imageProvider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.image,
              color: Colors.grey,
              size: 32,
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

/// Simple visibility detector widget
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final _key = GlobalKey();
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;

    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject == null) return;

    final viewport = RenderAbstractViewport.of(renderObject);

    final offsetToReveal = viewport.getOffsetToReveal(renderObject, 0.0);
    final isVisible = offsetToReveal.offset >= 0;

    if (isVisible != _wasVisible) {
      _wasVisible = isVisible;
      widget.onVisibilityChanged(isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }
}

/// Lazy video thumbnail with play button overlay
class LazyVideoThumbnail extends StatefulWidget {
  final String thumbnailUrl;
  final String? videoUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Duration? duration;
  final BorderRadius? borderRadius;

  const LazyVideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    this.videoUrl,
    this.width,
    this.height,
    this.onTap,
    this.duration,
    this.borderRadius,
  });

  @override
  State<LazyVideoThumbnail> createState() => _LazyVideoThumbnailState();
}

class _LazyVideoThumbnailState extends State<LazyVideoThumbnail> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LazyImage(
            imageUrl: widget.thumbnailUrl,
            width: widget.width,
            height: widget.height,
            borderRadius: widget.borderRadius,
          ),
          // Play button overlay
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          // Duration badge
          if (widget.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(widget.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Media grid with lazy loading
class LazyMediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  final int crossAxisCount;
  final double spacing;
  final double? itemHeight;
  final void Function(int index)? onItemTap;
  final BorderRadius? itemBorderRadius;

  const LazyMediaGrid({
    super.key,
    required this.mediaUrls,
    this.crossAxisCount = 3,
    this.spacing = 2,
    this.itemHeight,
    this.onItemTap,
    this.itemBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: mediaUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onItemTap?.call(index),
          child: LazyImage(
            imageUrl: mediaUrls[index],
            fit: BoxFit.cover,
            borderRadius: itemBorderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// Progressive image loader (loads low-res first, then high-res)
class ProgressiveImage extends StatefulWidget {
  final String lowResUrl;
  final String highResUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProgressiveImage({
    super.key,
    required this.lowResUrl,
    required this.highResUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<ProgressiveImage> {
  bool _highResLoaded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Low-res image (always loaded first)
          CachedNetworkImage(
            imageUrl: widget.lowResUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            fadeInDuration: Duration.zero,
          ),
          // High-res image (loaded on top)
          AnimatedOpacity(
            opacity: _highResLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: CachedNetworkImage(
              imageUrl: widget.highResUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              fadeInDuration: Duration.zero,
              imageBuilder: (context, imageProvider) {
                if (!_highResLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _highResLoaded = true);
                    }
                  });
                }
                return Image(
                  image: imageProvider,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
