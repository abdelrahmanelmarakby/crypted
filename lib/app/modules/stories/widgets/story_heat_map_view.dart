import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:crypted_app/app/data/data_source/nearby_data_source.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';
import 'package:crypted_app/app/modules/nearby/controllers/nearby_controller.dart';
import 'package:crypted_app/app/services/story_clustering_service.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/modules/stories/widgets/epic_story_viewer.dart';
import 'package:crypted_app/app/widgets/network_image.dart';

/// Snapchat-style Story Map — shows stories on a real Google Map
/// with user avatar markers and cluster indicators.
/// Falls back to a visual grid when no stories have location data.
class StoryHeatMapView extends StatefulWidget {
  final List<StoryModel> stories;
  final VoidCallback? onCreateStory;

  const StoryHeatMapView({
    super.key,
    required this.stories,
    this.onCreateStory,
  });

  @override
  State<StoryHeatMapView> createState() => _StoryHeatMapViewState();
}

class _StoryHeatMapViewState extends State<StoryHeatMapView> {
  GoogleMapController? _mapController;

  List<StoryCluster> clusters = [];
  Set<Marker> _markers = {};
  StoryCluster? selectedCluster;
  double _currentZoom = 12.0;

  // User's current location (fetched via Geolocator)
  LatLng? _userLocation;

  // Nearby People integration
  late NearbyController _nearbyController;
  NearbyUser? _selectedNearbyUser;

  // Default to a neutral position; will be adjusted when clusters load
  static const LatLng _defaultCenter = LatLng(24.7136, 46.6753); // Riyadh

  /// Stories that don't have location data — shown in the bottom card tray.
  List<StoryModel> get _storiesWithoutLocation =>
      widget.stories.where((s) => !s.hasLocation).toList();

  // Snapchat-style dark map theme
  static const String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1d2b"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8e8e9e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d1d2b"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#3a3a4e"},{"visibility":"on"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1d1d2b"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2a2a3d"}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#333347"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#141423"}]},
  {"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]}
]
''';

  @override
  void initState() {
    super.initState();

    // Initialize or find NearbyController
    if (!Get.isRegistered<NearbyController>()) {
      Get.put(NearbyController());
    }
    _nearbyController = Get.find<NearbyController>();

    // Listen to nearby users changes
    ever(_nearbyController.nearbyUsers, (_) {
      _buildMarkers();
    });

    _initializeClusters();
    _fetchUserLocation();
  }

  /// Fetch the user's current GPS position so we can center the map on them.
  Future<void> _fetchUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          log('⚠️ Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        log('⚠️ Location permission permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        // If no clusters, center map on user
        if (clusters.isEmpty) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
          );
        }
      }
    } catch (e) {
      log('⚠️ Failed to get user location: $e');
    }
  }

  @override
  void didUpdateWidget(StoryHeatMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stories.length != widget.stories.length ||
        !identical(oldWidget.stories, widget.stories)) {
      _initializeClusters();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeClusters() {
    final radius = StoryClusteringService.getAdaptiveRadius(_currentZoom);
    clusters = StoryClusteringService.clusterStories(
      widget.stories,
      clusterRadiusKm: radius,
    );
    _buildMarkers();
    _fitMapToMarkers();
    setState(() {});
  }

  /// Build Google Maps markers from clusters, events, and nearby people.
  ///
  /// Color coding:
  /// - Green ring = Regular stories (image/video/text)
  /// - Orange ring = Event stories
  /// - Blue ring = Nearby discoverable people
  Future<void> _buildMarkers() async {
    final newMarkers = <Marker>{};

    // 1) Story cluster markers (Green)
    for (final cluster in clusters) {
      // Separate events from regular stories within the cluster
      final hasEvents =
          cluster.stories.any((s) => s.storyType == StoryType.event);
      final hasRegular =
          cluster.stories.any((s) => s.storyType != StoryType.event);

      if (hasRegular) {
        final regularStories = cluster.stories
            .where((s) => s.storyType != StoryType.event)
            .toList();
        final markerId = MarkerId('story_${cluster.id}');
        final position =
            LatLng(cluster.centerLatitude, cluster.centerLongitude);
        final text = regularStories.length > 1
            ? '${regularStories.length}'
            : (regularStories.first.user?.fullName ?? '?')[0].toUpperCase();
        final icon = await _createColoredMarker(
          text: text,
          ringColor: const Color(0xFF31A354), // Green for stories
          size: regularStories.length > 1 ? 80.0 : 64.0,
        );
        newMarkers.add(Marker(
          markerId: markerId,
          position: position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _onClusterTap(cluster),
          zIndexInt: cluster.size,
        ));
      }

      // Event markers within this cluster (Orange) — show individually
      if (hasEvents) {
        for (final event
            in cluster.stories.where((s) => s.storyType == StoryType.event)) {
          if (!event.hasLocation) continue;
          final markerId = MarkerId('event_${event.id}');
          final icon = await _createColoredMarker(
            text: (event.eventTitle ?? 'E')[0].toUpperCase(),
            ringColor: const Color(0xFFFF6B35), // Orange for events
            size: 72.0,
            isEvent: true,
          );
          newMarkers.add(Marker(
            markerId: markerId,
            position: LatLng(event.latitude!, event.longitude!),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => _openStoryViewer(event),
            zIndexInt: 100, // Events on top
          ));
        }
      }
    }

    // 2) Nearby people markers (Blue)
    for (final user in _nearbyController.nearbyUsers) {
      final markerId = MarkerId('person_${user.uid}');
      final icon = await _createColoredMarker(
        text: (user.fullName ?? '?')[0].toUpperCase(),
        ringColor: const Color(0xFF4A90D9), // Blue for people
        size: 60.0,
      );
      newMarkers.add(Marker(
        markerId: markerId,
        position: LatLng(user.latitude, user.longitude),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        onTap: () => _onNearbyUserTap(user),
        zIndexInt: 50,
      ));
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  /// Creates a circular marker bitmap with a colored ring.
  ///
  /// [text] — the character or number to display in the center.
  /// [ringColor] — Green (stories), Orange (events), Blue (people).
  /// [size] — marker diameter in pixels.
  /// [isEvent] — if true, adds a small calendar icon indicator.
  Future<BitmapDescriptor> _createColoredMarker({
    required String text,
    required Color ringColor,
    double size = 64.0,
    bool isEvent = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Outer glow ring
    paint
      ..color = ringColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Solid ring
    paint.color = ringColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, paint);

    // Inner white ring
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6, paint);

    // Center circle (same as ring color, slightly darker)
    paint.color = ringColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 9, paint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size > 70 ? 20 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  /// Fits the map camera to show all markers with padding.
  void _fitMapToMarkers() {
    if (_mapController == null || clusters.isEmpty) return;

    if (clusters.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(clusters.first.centerLatitude, clusters.first.centerLongitude),
          14.0,
        ),
      );
      return;
    }

    // Build bounds from all cluster centers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final cluster in clusters) {
      if (cluster.centerLatitude < minLat) minLat = cluster.centerLatitude;
      if (cluster.centerLatitude > maxLat) maxLat = cluster.centerLatitude;
      if (cluster.centerLongitude < minLng) minLng = cluster.centerLongitude;
      if (cluster.centerLongitude > maxLng) maxLng = cluster.centerLongitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0, // padding
      ),
    );
  }

  LatLng _computeInitialCenter() {
    if (clusters.isEmpty) return _userLocation ?? _defaultCenter;

    if (clusters.length == 1) {
      return LatLng(
        clusters.first.centerLatitude,
        clusters.first.centerLongitude,
      );
    }

    double sumLat = 0, sumLng = 0;
    for (final c in clusters) {
      sumLat += c.centerLatitude;
      sumLng += c.centerLongitude;
    }
    return LatLng(sumLat / clusters.length, sumLng / clusters.length);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Always show the Google Map — even when no stories have location
        _buildSnapMap(),

        // Legend bar (top)
        _buildLegendBar(),

        // Discoverability toggle (below legend)
        _buildDiscoverabilityToggle(),

        // Empty state overlay when no stories at all
        if (widget.stories.isEmpty && _nearbyController.nearbyUsers.isEmpty)
          _buildEmptyState(),

        // Non-geolocated stories → bottom horizontal card tray
        if (_storiesWithoutLocation.isNotEmpty &&
            selectedCluster == null &&
            _selectedNearbyUser == null)
          _buildBottomStoryTray(),

        // Selected cluster preview sheet (Snapchat-style bottom card)
        if (selectedCluster != null) _buildClusterPreview(),

        // Selected nearby user profile sheet
        if (_selectedNearbyUser != null) _buildNearbyUserSheet(),

        // Create Story FAB
        _buildCreateStoryButton(),
      ],
    );
  }

  // ── Legend Bar ────────────────────────────────────────────────

  Widget _buildLegendBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1d1d2b).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              color: const Color(0xFF31A354),
              label: 'Stories',
              count: widget.stories
                  .where((s) => s.storyType != StoryType.event)
                  .length,
            ),
            _buildLegendDivider(),
            _buildLegendItem(
              color: const Color(0xFFFF6B35),
              label: 'Events',
              count: widget.stories
                  .where((s) => s.storyType == StoryType.event)
                  .length,
            ),
            _buildLegendDivider(),
            Obx(() => _buildLegendItem(
                  color: const Color(0xFF4A90D9),
                  label: 'People',
                  count: _nearbyController.nearbyUsers.length,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDivider() {
    return Container(
      width: 1,
      height: 16,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ── Discoverability Toggle ───────────────────────────────────

  Widget _buildDiscoverabilityToggle() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 54,
      right: 16,
      child: Obx(() {
        final isOn = _nearbyController.isDiscoverable.value;
        return GestureDetector(
          onTap: () => _nearbyController.toggleDiscoverability(!isOn),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOn
                  ? const Color(0xFF4A90D9).withValues(alpha: 0.9)
                  : const Color(0xFF1d1d2b).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn
                    ? const Color(0xFF4A90D9)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOn ? Icons.visibility : Icons.visibility_off,
                  size: 15,
                  color: isOn ? Colors.white : Colors.white54,
                ),
                const SizedBox(width: 6),
                Text(
                  isOn ? 'Visible' : 'Hidden',
                  style: TextStyle(
                    color: isOn ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Nearby User Profile Sheet ────────────────────────────────

  Widget _buildNearbyUserSheet() {
    final user = _selectedNearbyUser!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 300, end: 0),
        builder: (context, double offset, child) {
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1d1d2b),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar with blue ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4A90D9),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        const Color(0xFF4A90D9).withValues(alpha: 0.2),
                    backgroundImage: user.imageUrl != null
                        ? NetworkImage(user.imageUrl!)
                        : null,
                    child: user.imageUrl == null
                        ? Text(
                            (user.fullName ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  user.fullName ?? 'Someone nearby',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Distance + location
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.near_me,
                        size: 14, color: Color(0xFF4A90D9)),
                    const SizedBox(width: 4),
                    Text(
                      user.distanceText,
                      style: const TextStyle(
                        color: Color(0xFF4A90D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.city != null) ...[
                      Text(
                        '  \u2022  ${user.locationText}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    // Say Hi button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _selectedNearbyUser = null);
                            Get.toNamed('/chat', arguments: {
                              'userId': user.uid,
                              'userName': user.fullName,
                              'userImage': user.imageUrl,
                            });
                          },
                          icon: const Icon(Icons.waving_hand, size: 18),
                          label: const Text('Say Hi',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dismiss
                    SizedBox(
                      height: 46,
                      width: 46,
                      child: IconButton(
                        onPressed: () =>
                            setState(() => _selectedNearbyUser = null),
                        icon: const Icon(Icons.close,
                            color: Colors.white54, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Snap Map (Google Maps with avatar markers) ──────────────

  Widget _buildSnapMap() {
    final initialCenter = _computeInitialCenter();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialCenter,
        zoom: _currentZoom,
      ),
      style: _mapStyle,
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        // Fit to markers after map is ready
        Future.delayed(const Duration(milliseconds: 500), _fitMapToMarkers);
      },
      onCameraMove: (position) {
        _currentZoom = position.zoom;
      },
      onCameraIdle: () {
        // Re-cluster at new zoom level for adaptive grouping
        final radius = StoryClusteringService.getAdaptiveRadius(_currentZoom);
        final newClusters = StoryClusteringService.clusterStories(
          widget.stories,
          clusterRadiusKm: radius,
        );
        if (newClusters.length != clusters.length) {
          clusters = newClusters;
          _buildMarkers();
        }
      },
      onTap: (_) {
        // Dismiss cluster preview when tapping empty map area
        if (selectedCluster != null) {
          setState(() => selectedCluster = null);
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: false,
      indoorViewEnabled: false,
      trafficEnabled: false,
      liteModeEnabled: false,
    );
  }

  // ── Empty State ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_rounded,
            size: 80,
            color: ColorsManager.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No stories yet',
            style: StylesManager.semiBold(
              fontSize: FontSize.large,
              color: ColorsManager.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to share your first story',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCardBackground(StoryModel story) {
    if (story.storyType == StoryType.image && story.storyFileUrl != null) {
      return AppCachedNetworkImage(
        imageUrl: story.storyFileUrl!,
        fit: BoxFit.cover,
      );
    }

    if (story.storyType == StoryType.video && story.storyFileUrl != null) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 48,
          ),
        ),
      );
    }

    // Event story
    if (story.storyType == StoryType.event) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, color: Colors.white70, size: 28),
              const SizedBox(height: 6),
              Text(
                story.eventTitle ?? 'Event',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${story.attendeeCount} going',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    // Text story
    final bgHex = story.backgroundColor ?? '#000000';
    Color bgColor;
    try {
      bgColor = Color(
        int.parse(bgHex.replaceAll('#', ''), radix: 16) + 0xFF000000,
      );
    } catch (_) {
      bgColor = Colors.black;
    }

    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            story.storyText ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ── Bottom Story Card Tray (non-geolocated stories) ────────

  Widget _buildBottomStoryTray() {
    final stories = _storiesWithoutLocation;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 300, end: 0),
        builder: (context, double offset, child) {
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF1d1d2b).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 12),

              // Header: "Stories" + count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: ColorsManager.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Stories',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stories.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorsManager.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal scrollable story cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    return _buildStoryPreviewCard(stories[index], index);
                  },
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cluster Preview Sheet (Snapchat-style bottom card) ──────

  Widget _buildClusterPreview() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 300, end: 0),
        builder: (context, double offset, child) {
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF1d1d2b), // Match dark map theme
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // Location info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.place,
                        color: ColorsManager.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCluster!.locationString,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedCluster!.size} ${selectedCluster!.size == 1 ? 'Story' : 'Stories'} • ${selectedCluster!.uniqueUserCount} ${selectedCluster!.uniqueUserCount == 1 ? 'Person' : 'People'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        setState(() => selectedCluster = null);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Story previews — horizontal scroll
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedCluster!.stories.length,
                  itemBuilder: (context, index) {
                    final story = selectedCluster!.stories[index];
                    return _buildStoryPreviewCard(story, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPreviewCard(StoryModel story, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _openStoryViewer(story),
        child: Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildStoryCardBackground(story),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // User info
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (story.user?.imageUrl != null)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(story.user!.imageUrl!),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        story.user?.fullName ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Create Story FAB ────────────────────────────────────────

  Widget _buildCreateStoryButton() {
    // Push FAB above the bottom tray when it's visible
    final showTray =
        _storiesWithoutLocation.isNotEmpty && selectedCluster == null;
    return Positioned(
      right: 20,
      bottom: showTray ? 236 : 100,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: FloatingActionButton.extended(
          onPressed: widget.onCreateStory,
          backgroundColor: ColorsManager.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Story',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Color _getClusterColor(StoryCluster cluster) {
    // Check if cluster contains events
    final hasEvents =
        cluster.stories.any((s) => s.storyType == StoryType.event);
    if (hasEvents) return const Color(0xFFFF6B35); // Orange
    return const Color(0xFF31A354); // Green for regular stories
  }

  void _onNearbyUserTap(NearbyUser user) {
    setState(() {
      selectedCluster = null;
      _selectedNearbyUser = user;
    });
  }

  void _onClusterTap(StoryCluster cluster) {
    setState(() {
      selectedCluster = cluster;
    });

    // Smoothly pan camera to the tapped cluster
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(cluster.centerLatitude, cluster.centerLongitude),
      ),
    );
  }

  void _openStoryViewer(StoryModel story) {
    // Use the cluster stories if a cluster is selected, otherwise use all
    // non-geolocated stories (for the bottom tray), or just the single story.
    final List<StoryModel> stories;
    if (selectedCluster != null) {
      stories = selectedCluster!.stories;
    } else if (_storiesWithoutLocation.contains(story)) {
      stories = _storiesWithoutLocation;
    } else {
      stories = [story];
    }
    final initialIndex = stories.indexOf(story).clamp(0, stories.length - 1);

    Get.to(
      () => EpicStoryViewer(
        stories: stories,
        initialIndex: initialIndex,
        cluster: selectedCluster,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
}
