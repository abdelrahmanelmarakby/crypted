import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:crypted_app/app/data/data_source/nearby_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Controller for the Nearby People feature.
///
/// Manages:
/// - Current user's location sharing (opt-in)
/// - Querying nearby discoverable users
/// - Discoverability toggle
class NearbyController extends GetxController {
  final NearbyDataSource dataSource = NearbyDataSource();

  // ── State ────────────────────────────────────────────────
  final RxList<NearbyUser> nearbyUsers = <NearbyUser>[].obs;
  final Rx<LatLng?> myLocation = Rx<LatLng?>(null);
  final RxBool isDiscoverable = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLocationPermission = false.obs;
  final RxDouble searchRadiusKm = 50.0.obs;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _checkPermissions();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // ── Permissions ──────────────────────────────────────────

  Future<void> checkAndFetchLocation() async {
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      hasLocationPermission.value = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (hasLocationPermission.value) {
        await fetchCurrentLocation();
      }
    } catch (e) {
      log('[NearbyController] Error checking location permissions: $e');
    }
  }

  // ── Location ─────────────────────────────────────────────

  Future<void> fetchCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      myLocation.value = LatLng(position.latitude, position.longitude);
      await refreshNearbyUsers();

      // Periodic refresh every 2 minutes
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        refreshNearbyUsers();
      });
    } catch (e) {
      log('[NearbyController] Error fetching location: $e');
    }
  }

  // ── Discoverability ──────────────────────────────────────

  Future<void> toggleDiscoverability(bool value) async {
    isDiscoverable.value = value;

    if (value) {
      if (!hasLocationPermission.value) {
        await _checkPermissions();
        if (!hasLocationPermission.value) {
          isDiscoverable.value = false;
          return;
        }
      }

      final loc = myLocation.value;
      if (loc == null) await fetchCurrentLocation();

      final currentLoc = myLocation.value;
      if (currentLoc != null) {
        String? placeName, city, country;
        try {
          final placemarks = await placemarkFromCoordinates(
              currentLoc.latitude, currentLoc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            placeName = p.name ?? p.street;
            city = p.locality;
            country = p.country;
          }
        } catch (_) {}

        await dataSource.updateMyLocation(
          latitude: currentLoc.latitude,
          longitude: currentLoc.longitude,
          placeName: placeName,
          city: city,
          country: country,
          isDiscoverable: true,
        );
      }
    } else {
      await dataSource.setDiscoverable(false);
    }
  }

  // ── Refresh ──────────────────────────────────────────────

  Future<void> refreshNearbyUsers() async {
    final loc = myLocation.value;
    if (loc == null) return;

    isLoading.value = true;
    try {
      final users = await dataSource.getNearbyUsers(
        latitude: loc.latitude,
        longitude: loc.longitude,
        radiusKm: searchRadiusKm.value,
      );
      nearbyUsers.value = users;
    } catch (e) {
      log('[NearbyController] Error refreshing nearby users: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
