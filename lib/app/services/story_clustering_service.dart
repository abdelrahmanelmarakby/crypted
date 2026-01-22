import 'dart:math' as math;

import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';

/// Service for clustering stories by location
/// Uses DBSCAN-like algorithm for grouping nearby stories
class StoryClusteringService {
  // Maximum distance (in km) for stories to be in the same cluster
  static const double defaultClusterRadius = 1.0; // 1 km

  // Minimum stories required to form a cluster
  static const int minClusterSize = 1;

  // FIX: Cache cluster results to avoid recalculating on every rebuild
  static List<StoryCluster>? _cachedClusters;
  static String? _cachedStoriesHash;
  static double? _cachedRadius;

  /// Clear the cache (call when stories update)
  static void clearCache() {
    _cachedClusters = null;
    _cachedStoriesHash = null;
    _cachedRadius = null;
  }

  /// Generate a hash for the stories list to detect changes
  static String _generateStoriesHash(List<StoryModel> stories) {
    final ids = stories
        .where((s) => s.hasLocation && (s.isLocationPublic ?? true))
        .map((s) => s.id ?? '')
        .toList()
      ..sort();
    return ids.join(',');
  }

  /// Cluster stories by location
  /// Returns list of clusters containing grouped stories
  /// FIX: Now uses caching to avoid O(n²) on every call
  static List<StoryCluster> clusterStories(
    List<StoryModel> stories, {
    double clusterRadiusKm = defaultClusterRadius,
  }) {
    // Check cache validity
    final currentHash = _generateStoriesHash(stories);
    if (_cachedClusters != null &&
        _cachedStoriesHash == currentHash &&
        _cachedRadius == clusterRadiusKm) {
      print('📦 Using cached clusters (${_cachedClusters!.length} clusters)');
      return _cachedClusters!;
    }

    print('🗺️ Clustering ${stories.length} stories with radius ${clusterRadiusKm}km');

    // Filter stories with valid location data
    final storiesWithLocation = stories
        .where((story) => story.hasLocation && (story.isLocationPublic ?? true))
        .toList();

    if (storiesWithLocation.isEmpty) {
      print('⚠️ No stories with location data');
      return [];
    }

    print('📍 ${storiesWithLocation.length} stories have location data');

    // Create clusters using DBSCAN-like algorithm
    final List<List<StoryModel>> clusters = [];
    final Set<String> visited = {};
    final Set<String> clustered = {};

    for (final story in storiesWithLocation) {
      if (visited.contains(story.id)) continue;
      visited.add(story.id!);

      // Find all neighbors within cluster radius
      final neighbors = _findNeighbors(
        story,
        storiesWithLocation,
        clusterRadiusKm,
      );

      if (neighbors.length >= minClusterSize) {
        // Create a new cluster
        final cluster = <StoryModel>[story];
        clustered.add(story.id!);

        // Expand cluster
        final queue = List<StoryModel>.from(neighbors);
        while (queue.isNotEmpty) {
          final neighbor = queue.removeAt(0);

          if (!visited.contains(neighbor.id)) {
            visited.add(neighbor.id!);

            final neighborNeighbors = _findNeighbors(
              neighbor,
              storiesWithLocation,
              clusterRadiusKm,
            );

            if (neighborNeighbors.length >= minClusterSize) {
              queue.addAll(neighborNeighbors);
            }
          }

          if (!clustered.contains(neighbor.id)) {
            cluster.add(neighbor);
            clustered.add(neighbor.id!);
          }
        }

        clusters.add(cluster);
      }
    }

    // Create StoryCluster objects
    final result = clusters.map((stories) {
      try {
        return StoryCluster.fromStories(stories);
      } catch (e) {
        print('❌ Error creating cluster: $e');
        return null;
      }
    }).whereType<StoryCluster>().toList();

    // Sort by cluster size (largest first)
    result.sort((a, b) => b.size.compareTo(a.size));

    print('✅ Created ${result.length} clusters');
    for (final cluster in result) {
      print('   Cluster: ${cluster.size} stories at ${cluster.locationString}');
    }

    // FIX: Cache the results
    _cachedClusters = result;
    _cachedStoriesHash = currentHash;
    _cachedRadius = clusterRadiusKm;

    return result;
  }

  /// Find all neighbors within radius
  static List<StoryModel> _findNeighbors(
    StoryModel story,
    List<StoryModel> allStories,
    double radiusKm,
  ) {
    final neighbors = <StoryModel>[];

    for (final other in allStories) {
      if (story.id == other.id) continue;
      if (!other.hasLocation) continue;

      final distance = StoryModel.calculateDistance(story, other);
      if (distance <= radiusKm) {
        neighbors.add(other);
      }
    }

    return neighbors;
  }

  /// Get heat map intensity for a location
  /// Returns value between 0 (no stories) and 1 (max stories)
  static double getHeatIntensity(
    double latitude,
    double longitude,
    List<StoryModel> stories,
    double radiusKm,
  ) {
    int nearbyCount = 0;
    const maxCount = 20; // Max stories for full intensity

    for (final story in stories) {
      if (!story.hasLocation) continue;

      final distance = _calculateDistance(
        latitude,
        longitude,
        story.latitude!,
        story.longitude!,
      );

      if (distance <= radiusKm) {
        nearbyCount++;
      }
    }

    return (nearbyCount / maxCount).clamp(0.0, 1.0);
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// FIX: Replaced custom Taylor series approximations with accurate dart:math functions
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degree) => degree * math.pi / 180;

  /// Adaptive clustering - adjust radius based on zoom level
  static double getAdaptiveRadius(double zoomLevel) {
    // Zoom level 0-2: Very zoomed out (100km radius)
    // Zoom level 3-5: City level (10km radius)
    // Zoom level 6-10: Neighborhood (1km radius)
    // Zoom level 11+: Street level (0.1km radius)

    if (zoomLevel <= 2) return 100.0;
    if (zoomLevel <= 5) return 10.0;
    if (zoomLevel <= 10) return 1.0;
    return 0.1;
  }
}
