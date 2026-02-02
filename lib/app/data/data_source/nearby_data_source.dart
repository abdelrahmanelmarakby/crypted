import 'dart:developer';
import 'dart:math' as math;

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
    final lngDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180));

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
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
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
