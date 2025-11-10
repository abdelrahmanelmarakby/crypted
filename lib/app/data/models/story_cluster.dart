import 'package:crypted_app/app/data/models/story_model.dart';

/// Story Cluster Model for grouping nearby stories on the heat map
class StoryCluster {
  final String id;
  final double centerLatitude;
  final double centerLongitude;
  final List<StoryModel> stories;
  final String? placeName;
  final String? city;

  StoryCluster({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.stories,
    this.placeName,
    this.city,
  });

  // Get cluster size (number of stories)
  int get size => stories.length;

  // Check if cluster has multiple stories
  bool get hasMultipleStories => stories.length > 1;

  // Get formatted location
  String get locationString {
    if (placeName != null && placeName!.isNotEmpty) {
      return placeName!;
    }
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    return '${stories.length} ${stories.length == 1 ? 'Story' : 'Stories'}';
  }

  // Get unique user count in cluster
  int get uniqueUserCount {
    final uniqueUserIds = stories
        .where((story) => story.uid != null)
        .map((story) => story.uid!)
        .toSet();
    return uniqueUserIds.length;
  }

  // Get preview stories (first 3)
  List<StoryModel> get previewStories => stories.take(3).toList();

  // Calculate cluster radius (max distance from center)
  double get radius {
    double maxDistance = 0;
    for (final story in stories) {
      if (!story.hasLocation) continue;

      final distance = _calculateDistance(
        centerLatitude,
        centerLongitude,
        story.latitude!,
        story.longitude!,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
    return maxDistance;
  }

  // Helper method to calculate distance
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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

  // Create cluster from list of stories
  factory StoryCluster.fromStories(List<StoryModel> stories) {
    if (stories.isEmpty) {
      throw ArgumentError('Cannot create cluster from empty story list');
    }

    // Calculate center point (average of all locations)
    double sumLat = 0;
    double sumLon = 0;
    int validLocations = 0;

    for (final story in stories) {
      if (story.hasLocation) {
        sumLat += story.latitude!;
        sumLon += story.longitude!;
        validLocations++;
      }
    }

    if (validLocations == 0) {
      throw ArgumentError('No stories with valid location data');
    }

    final centerLat = sumLat / validLocations;
    final centerLon = sumLon / validLocations;

    // Try to get place name from first story with place data
    String? placeName;
    String? city;

    for (final story in stories) {
      if (placeName == null && story.placeName != null) {
        placeName = story.placeName;
      }
      if (city == null && story.city != null) {
        city = story.city;
      }
      if (placeName != null && city != null) break;
    }

    return StoryCluster(
      id: 'cluster_${DateTime.now().millisecondsSinceEpoch}',
      centerLatitude: centerLat,
      centerLongitude: centerLon,
      stories: stories,
      placeName: placeName,
      city: city,
    );
  }

  // Merge another cluster into this one
  StoryCluster merge(StoryCluster other) {
    final allStories = [...stories, ...other.stories];
    return StoryCluster.fromStories(allStories);
  }

  // Check if a story is close enough to be part of this cluster
  bool isNearby(StoryModel story, double maxDistanceKm) {
    if (!story.hasLocation) return false;

    final distance = _calculateDistance(
      centerLatitude,
      centerLongitude,
      story.latitude!,
      story.longitude!,
    );

    return distance <= maxDistanceKm;
  }

  @override
  String toString() {
    return 'StoryCluster(id: $id, size: $size, location: $locationString)';
  }
}
