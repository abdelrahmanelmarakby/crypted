import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';

/// Service for clustering stories by location
/// Uses DBSCAN-like algorithm for grouping nearby stories
class StoryClusteringService {
  // Maximum distance (in km) for stories to be in the same cluster
  static const double defaultClusterRadius = 1.0; // 1 km

  // Minimum stories required to form a cluster
  static const int minClusterSize = 1;

  /// Cluster stories by location
  /// Returns list of clusters containing grouped stories
  static List<StoryCluster> clusterStories(
    List<StoryModel> stories, {
    double clusterRadiusKm = defaultClusterRadius,
  }) {
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

  /// Calculate distance between two coordinates
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) =>
      degree * 3.141592653589793 / 180;
  static double _sin(double x) =>
      x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  static double _atan(double x) =>
      x - (x * x * x) / 3 + (x * x * x * x * x) / 5;

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
