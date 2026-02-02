import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

/// Data source for the Nearby People feature.
///
/// Manages user location sharing and querying nearby discoverable users.
/// Uses Firestore `user_locations` collection with lat/lng range queries.
class NearbyDataSource {
  final CollectionReference<Map<String, dynamic>> _locationsCollection =
      FirebaseFirestore.instance.collection(FirebaseCollections.userLocations);

  final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseFirestore.instance.collection(FirebaseCollections.users);

  /// Update current user's location for discoverability.
  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
    String? placeName,
    String? city,
    String? country,
    required bool isDiscoverable,
  }) async {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return;

    final currentUser = UserService.currentUser.value;
    final data = {
      'uid': uid,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'city': city,
      'country': country,
      'isDiscoverable': isDiscoverable,
      'lastUpdated': FieldValue.serverTimestamp(),
      'fullName': currentUser?.fullName,
      'imageUrl': currentUser?.imageUrl,
      'bio': currentUser?.bio,
    };

    await _locationsCollection.doc(uid).set(data, SetOptions(merge: true));
    log('[NearbyDataSource] Location updated for $uid: ($latitude, $longitude)');
  }

  /// Toggle discoverability on/off.
  Future<void> setDiscoverable(bool isDiscoverable) async {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return;

    await _locationsCollection.doc(uid).set(
      {
        'isDiscoverable': isDiscoverable,
        'lastUpdated': FieldValue.serverTimestamp()
      },
      SetOptions(merge: true),
    );
  }

  /// Remove user's location from the map entirely.
  Future<void> removeMyLocation() async {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return;
    await _locationsCollection.doc(uid).delete();
  }

  /// Query nearby users within a lat/lng bounding box.
  ///
  /// Uses a simple bounding box approach:
  /// - 1 degree latitude ~= 111km
  /// - 1 degree longitude ~= 111km * cos(latitude)
  ///
  /// [radiusKm] — search radius in kilometers.
  Future<List<NearbyUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    final myUid = UserService.currentUser.value?.uid;

    // Calculate bounding box
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * _cos(latitude * 3.14159 / 180));

    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;
    final minLng = longitude - lngDelta;
    final maxLng = longitude + lngDelta;

    try {
      // Firestore only supports one inequality filter per query, so we filter
      // latitude server-side and longitude client-side.
      final snapshot = await _locationsCollection
          .where('isDiscoverable', isEqualTo: true)
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .orderBy('latitude')
          .limit(100) // Cap results
          .get();

      final results = <NearbyUser>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = data['uid'] as String?;
        if (uid == null || uid == myUid) continue; // Skip self

        final lng = (data['longitude'] as num?)?.toDouble();
        if (lng == null || lng < minLng || lng > maxLng)
          continue; // Client-side lng filter

        final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final distance = _haversineDistance(latitude, longitude, lat, lng);

        if (distance <= radiusKm) {
          results.add(NearbyUser(
            uid: uid,
            fullName: data['fullName'] as String?,
            imageUrl: data['imageUrl'] as String?,
            bio: data['bio'] as String?,
            latitude: lat,
            longitude: lng,
            placeName: data['placeName'] as String?,
            city: data['city'] as String?,
            country: data['country'] as String?,
            distanceKm: distance,
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
          ));
        }
      }

      // Sort by distance
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return results;
    } catch (e) {
      log('[NearbyDataSource] Error querying nearby users: $e');
      return [];
    }
  }

  /// Stream nearby events (event stories) within a radius.
  Stream<List<Map<String, dynamic>>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) {
    final latDelta = radiusKm / 111.0;
    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;

    return FirebaseFirestore.instance
        .collection(FirebaseCollections.stories)
        .where('storyType', isEqualTo: 'event')
        .where('latitude', isGreaterThanOrEqualTo: minLat)
        .where('latitude', isLessThanOrEqualTo: maxLat)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('latitude')
        .orderBy('expiresAt')
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Haversine distance in km
  double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  // Math helpers using dart:math would be better, but matching existing codebase pattern
  static double _toRadians(double d) => d * 3.141592653589793 / 180;
  static double _sin(double x) {
    // Taylor series approximation — accurate enough for distances
    x = x % (2 * 3.141592653589793);
    if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    if (x < -3.141592653589793) x += 2 * 3.141592653589793;
    double result = x;
    double term = x;
    for (int i = 1; i <= 7; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(x + 3.141592653589793 / 2);
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 15; i++) {
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

  static double _atan(double x) {
    // Padé approximation for atan
    if (x.abs() > 1) {
      final sign = x > 0 ? 1.0 : -1.0;
      return sign * 3.141592653589793 / 2 - _atan(1 / x);
    }
    return x -
        (x * x * x) / 3 +
        (x * x * x * x * x) / 5 -
        (x * x * x * x * x * x * x) / 7;
  }
}

/// Model for a nearby discoverable user.
class NearbyUser {
  final String uid;
  final String? fullName;
  final String? imageUrl;
  final String? bio;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? city;
  final String? country;
  final double distanceKm;
  final DateTime? lastUpdated;

  const NearbyUser({
    required this.uid,
    this.fullName,
    this.imageUrl,
    this.bio,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.city,
    this.country,
    required this.distanceKm,
    this.lastUpdated,
  });

  /// Formatted distance string.
  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    }
    return '${distanceKm.toStringAsFixed(1)}km away';
  }

  /// Formatted location string.
  String get locationText {
    if (placeName != null && placeName!.isNotEmpty) return placeName!;
    if (city != null && city!.isNotEmpty) {
      if (country != null && country!.isNotEmpty) return '$city, $country';
      return city!;
    }
    return 'Nearby';
  }
}
