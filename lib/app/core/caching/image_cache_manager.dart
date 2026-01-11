// PERF-003 FIX: Image Cache Manager
// Manages memory cache for images in chat

import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Configuration for image cache
class ImageCacheConfig {
  /// Maximum number of images to cache
  final int maxImages;

  /// Maximum total size in bytes
  final int maxSizeBytes;

  /// Maximum individual image size
  final int maxImageSizeBytes;

  const ImageCacheConfig({
    this.maxImages = 100,
    this.maxSizeBytes = 100 * 1024 * 1024, // 100MB
    this.maxImageSizeBytes = 10 * 1024 * 1024, // 10MB per image
  });

  static const chat = ImageCacheConfig(
    maxImages: 50,
    maxSizeBytes: 50 * 1024 * 1024, // 50MB for chat
  );

  static const stories = ImageCacheConfig(
    maxImages: 30,
    maxSizeBytes: 30 * 1024 * 1024, // 30MB for stories
  );

  static const avatars = ImageCacheConfig(
    maxImages: 200,
    maxSizeBytes: 20 * 1024 * 1024, // 20MB for avatars
    maxImageSizeBytes: 1 * 1024 * 1024, // 1MB per avatar
  );
}

/// Cached image entry
class CachedImage {
  final String key;
  final Uint8List bytes;
  final DateTime cachedAt;
  final int accessCount;
  final String? roomId;

  CachedImage({
    required this.key,
    required this.bytes,
    this.roomId,
    int? accessCount,
  })  : cachedAt = DateTime.now(),
        accessCount = accessCount ?? 0;

  int get sizeBytes => bytes.length;

  CachedImage incrementAccess() {
    return CachedImage(
      key: key,
      bytes: bytes,
      roomId: roomId,
      accessCount: accessCount + 1,
    );
  }
}

/// LRU Image Cache Manager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final ImageCacheConfig _config;
  final LinkedHashMap<String, CachedImage> _cache = LinkedHashMap();
  int _currentSizeBytes = 0;

  ImageCacheManager._({ImageCacheConfig? config})
      : _config = config ?? const ImageCacheConfig();

  /// Create a new instance with specific config
  static ImageCacheManager withConfig(ImageCacheConfig config) {
    return ImageCacheManager._(config: config);
  }

  /// Get image from cache
  Uint8List? get(String key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    // Move to end (most recently used)
    final updated = entry.incrementAccess();
    _cache[key] = updated;

    if (kDebugMode) {
      print('[ImageCache] Hit: $key (${_formatBytes(entry.sizeBytes)})');
    }

    return entry.bytes;
  }

  /// Put image in cache
  void put(String key, Uint8List bytes, {String? roomId}) {
    // Check if image is too large
    if (bytes.length > _config.maxImageSizeBytes) {
      if (kDebugMode) {
        print('[ImageCache] Image too large to cache: $key (${_formatBytes(bytes.length)})');
      }
      return;
    }

    // Remove existing entry if present
    final existing = _cache.remove(key);
    if (existing != null) {
      _currentSizeBytes -= existing.sizeBytes;
    }

    // Evict if necessary
    _evictIfNeeded(bytes.length);

    // Add new entry
    _cache[key] = CachedImage(
      key: key,
      bytes: bytes,
      roomId: roomId,
    );
    _currentSizeBytes += bytes.length;

    if (kDebugMode) {
      print('[ImageCache] Cached: $key (${_formatBytes(bytes.length)}) - '
          'Total: ${_cache.length} images, ${_formatBytes(_currentSizeBytes)}');
    }
  }

  /// Check if image is cached
  bool contains(String key) {
    return _cache.containsKey(key);
  }

  /// Remove specific image
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
    }
  }

  /// Remove all images for a specific room
  void removeForRoom(String roomId) {
    final keysToRemove = _cache.entries
        .where((e) => e.value.roomId == roomId)
        .map((e) => e.key)
        .toList();

    for (final key in keysToRemove) {
      final entry = _cache.remove(key);
      if (entry != null) {
        _currentSizeBytes -= entry.sizeBytes;
      }
    }

    if (kDebugMode) {
      print('[ImageCache] Removed ${keysToRemove.length} images for room: $roomId');
    }
  }

  /// Clear all cached images
  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
    if (kDebugMode) {
      print('[ImageCache] Cache cleared');
    }
  }

  /// Evict least recently used entries until we have space
  void _evictIfNeeded(int neededBytes) {
    // Evict by count
    while (_cache.length >= _config.maxImages) {
      _evictLru();
    }

    // Evict by size
    while (_currentSizeBytes + neededBytes > _config.maxSizeBytes && _cache.isNotEmpty) {
      _evictLru();
    }
  }

  /// Evict least recently used entry
  void _evictLru() {
    if (_cache.isEmpty) return;

    final key = _cache.keys.first;
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      if (kDebugMode) {
        print('[ImageCache] Evicted LRU: $key (${_formatBytes(entry.sizeBytes)})');
      }
    }
  }

  /// Get cache statistics
  ImageCacheStats get stats => ImageCacheStats(
        imageCount: _cache.length,
        totalSizeBytes: _currentSizeBytes,
        maxImages: _config.maxImages,
        maxSizeBytes: _config.maxSizeBytes,
        hitRate: _calculateHitRate(),
      );

  double _calculateHitRate() {
    if (_cache.isEmpty) return 0.0;
    final totalAccesses = _cache.values.fold<int>(0, (sum, e) => sum + e.accessCount);
    if (totalAccesses == 0) return 0.0;
    return totalAccesses / _cache.length;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Image cache statistics
class ImageCacheStats {
  final int imageCount;
  final int totalSizeBytes;
  final int maxImages;
  final int maxSizeBytes;
  final double hitRate;

  ImageCacheStats({
    required this.imageCount,
    required this.totalSizeBytes,
    required this.maxImages,
    required this.maxSizeBytes,
    required this.hitRate,
  });

  double get usagePercent => maxSizeBytes > 0 ? totalSizeBytes / maxSizeBytes : 0.0;

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'ImageCacheStats('
        'images: $imageCount/$maxImages, '
        'size: $formattedSize, '
        'usage: ${(usagePercent * 100).toStringAsFixed(1)}%, '
        'hitRate: ${hitRate.toStringAsFixed(2)})';
  }
}

/// Widget for cached network images with memory management
class ManagedCachedImage extends StatefulWidget {
  final String imageUrl;
  final String? cacheKey;
  final String? roomId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ManagedCachedImage({
    super.key,
    required this.imageUrl,
    this.cacheKey,
    this.roomId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<ManagedCachedImage> createState() => _ManagedCachedImageState();
}

class _ManagedCachedImageState extends State<ManagedCachedImage> {
  final _cacheManager = ImageCacheManager();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  String get _cacheKey => widget.cacheKey ?? widget.imageUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ManagedCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Try cache first
    final cached = _cacheManager.get(_cacheKey);
    if (cached != null) {
      setState(() {
        _imageBytes = cached;
        _isLoading = false;
      });
      return;
    }

    // Fetch from network
    // Note: In production, use http package or cached_network_image
    // This is a simplified placeholder
    setState(() {
      _isLoading = false;
      // Would load from network here
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: Icon(Icons.error)),
          );
    }

    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

/// Extension to clear image cache when leaving chat
extension ImageCacheCleanup on ImageCacheManager {
  /// Clear cache for a specific chat when leaving
  void onChatClosed(String roomId) {
    removeForRoom(roomId);
  }

  /// Trim cache to specified percentage of max size
  void trim({double targetPercent = 0.5}) {
    final targetSize = (_config.maxSizeBytes * targetPercent).toInt();

    while (_currentSizeBytes > targetSize && _cache.isNotEmpty) {
      _evictLru();
    }

    if (kDebugMode) {
      print('[ImageCache] Trimmed to ${_formatBytes(_currentSizeBytes)}');
    }
  }
}
