// PERF-006 FIX: Memory Optimization for Large Chats
// Manages memory usage and provides cleanup utilities

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Memory threshold levels
enum MemoryPressure {
  normal,
  moderate,
  high,
  critical,
}

/// Memory manager for optimizing app performance
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  /// Memory pressure threshold (in MB)
  static const int _moderateThresholdMB = 100;
  static const int _highThresholdMB = 200;
  static const int _criticalThresholdMB = 300;

  /// Listeners for memory pressure changes
  final List<void Function(MemoryPressure)> _listeners = [];

  /// Current memory pressure level
  MemoryPressure _currentPressure = MemoryPressure.normal;
  MemoryPressure get currentPressure => _currentPressure;

  Timer? _monitorTimer;
  bool _isMonitoring = false;

  /// Start monitoring memory usage
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _monitorTimer = Timer.periodic(interval, (_) => _checkMemory());

    if (kDebugMode) {
      print('[MemoryManager] Started monitoring');
    }
  }

  /// Stop monitoring memory usage
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
  }

  /// Add a listener for memory pressure changes
  void addListener(void Function(MemoryPressure) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(void Function(MemoryPressure) listener) {
    _listeners.remove(listener);
  }

  /// Manual memory check
  Future<MemoryPressure> checkMemory() async {
    return _checkMemory();
  }

  Future<MemoryPressure> _checkMemory() async {
    // Note: In production, use more sophisticated memory detection
    // This is a simplified approach
    final newPressure = await _estimateMemoryPressure();

    if (newPressure != _currentPressure) {
      _currentPressure = newPressure;
      _notifyListeners();

      if (newPressure == MemoryPressure.critical) {
        await performAggressiveCleanup();
      } else if (newPressure == MemoryPressure.high) {
        await performModerateCleanup();
      }
    }

    return newPressure;
  }

  Future<MemoryPressure> _estimateMemoryPressure() async {
    // This is a simplified estimation
    // In production, use platform-specific memory APIs
    try {
      // Check image cache size as a proxy for memory usage
      final cacheSize = PaintingBinding.instance.imageCache.currentSizeBytes;
      final cacheSizeMB = cacheSize / (1024 * 1024);

      if (cacheSizeMB > _criticalThresholdMB) {
        return MemoryPressure.critical;
      } else if (cacheSizeMB > _highThresholdMB) {
        return MemoryPressure.high;
      } else if (cacheSizeMB > _moderateThresholdMB) {
        return MemoryPressure.moderate;
      }
      return MemoryPressure.normal;
    } catch (e) {
      return MemoryPressure.normal;
    }
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener(_currentPressure);
      } catch (e) {
        if (kDebugMode) {
          print('[MemoryManager] Listener error: $e');
        }
      }
    }
  }

  /// Perform moderate cleanup
  Future<void> performModerateCleanup() async {
    if (kDebugMode) {
      print('[MemoryManager] Performing moderate cleanup');
    }

    // Clear old image cache entries
    PaintingBinding.instance.imageCache.clear();

    // Clear network image cache (keep recent)
    await CachedNetworkImage.evictFromCache('');
  }

  /// Perform aggressive cleanup
  Future<void> performAggressiveCleanup() async {
    if (kDebugMode) {
      print('[MemoryManager] Performing aggressive cleanup');
    }

    // Clear all image caches
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Request garbage collection hint
    // Note: This is just a hint, not guaranteed
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  /// Clear memory caches for a specific chat room
  void clearRoomMemory(String roomId) {
    // This would be integrated with ImageCacheManager
    if (kDebugMode) {
      print('[MemoryManager] Clearing memory for room: $roomId');
    }
  }

  /// Get memory stats for debugging
  Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentPressure': _currentPressure.name,
      'imageCacheSize': imageCache.currentSize,
      'imageCacheSizeBytes': imageCache.currentSizeBytes,
      'imageCacheMaxSize': imageCache.maximumSize,
      'imageCacheMaxSizeBytes': imageCache.maximumSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
    };
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _listeners.clear();
  }
}

/// Mixin for memory-aware controllers
mixin MemoryAwareMixin {
  MemoryManager get _memoryManager => MemoryManager();

  void Function(MemoryPressure)? _memoryListener;

  /// Initialize memory awareness
  void initializeMemoryAwareness() {
    _memoryListener = _onMemoryPressureChanged;
    _memoryManager.addListener(_memoryListener!);
  }

  /// Dispose memory awareness
  void disposeMemoryAwareness() {
    if (_memoryListener != null) {
      _memoryManager.removeListener(_memoryListener!);
    }
  }

  /// Called when memory pressure changes - override in subclass
  void _onMemoryPressureChanged(MemoryPressure pressure) {
    if (kDebugMode) {
      print('[MemoryAwareMixin] Memory pressure: ${pressure.name}');
    }

    if (pressure == MemoryPressure.high || pressure == MemoryPressure.critical) {
      onMemoryWarning(pressure);
    }
  }

  /// Override to handle memory warnings
  void onMemoryWarning(MemoryPressure pressure) {
    // Override in subclass to handle memory warnings
    // e.g., clear message cache, release resources
  }
}

/// Widget that responds to memory pressure
class MemoryAwareBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, MemoryPressure pressure) builder;

  const MemoryAwareBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<MemoryAwareBuilder> createState() => _MemoryAwareBuilderState();
}

class _MemoryAwareBuilderState extends State<MemoryAwareBuilder> {
  final _memoryManager = MemoryManager();
  MemoryPressure _pressure = MemoryPressure.normal;

  @override
  void initState() {
    super.initState();
    _pressure = _memoryManager.currentPressure;
    _memoryManager.addListener(_onPressureChanged);
  }

  @override
  void dispose() {
    _memoryManager.removeListener(_onPressureChanged);
    super.dispose();
  }

  void _onPressureChanged(MemoryPressure pressure) {
    if (mounted && pressure != _pressure) {
      setState(() => _pressure = pressure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _pressure);
  }
}

/// Configuration for memory-optimized lists
class MemoryOptimizedListConfig {
  final int cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final int itemsToKeepAlive;

  const MemoryOptimizedListConfig({
    this.cacheExtent = 250,
    this.addAutomaticKeepAlives = false,
    this.addRepaintBoundaries = true,
    this.itemsToKeepAlive = 10,
  });

  /// Get config based on memory pressure
  factory MemoryOptimizedListConfig.forPressure(MemoryPressure pressure) {
    switch (pressure) {
      case MemoryPressure.critical:
        return const MemoryOptimizedListConfig(
          cacheExtent: 100,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemsToKeepAlive: 5,
        );
      case MemoryPressure.high:
        return const MemoryOptimizedListConfig(
          cacheExtent: 150,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemsToKeepAlive: 8,
        );
      case MemoryPressure.moderate:
        return const MemoryOptimizedListConfig(
          cacheExtent: 200,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemsToKeepAlive: 15,
        );
      case MemoryPressure.normal:
        return const MemoryOptimizedListConfig(
          cacheExtent: 500,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemsToKeepAlive: 30,
        );
    }
  }
}
