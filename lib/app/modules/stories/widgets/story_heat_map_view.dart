import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';
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

  /// Build Google Maps markers from clusters — each marker is a user avatar circle.
  Future<void> _buildMarkers() async {
    final newMarkers = <Marker>{};

    for (final cluster in clusters) {
      final markerId = MarkerId(cluster.id);
      final position = LatLng(cluster.centerLatitude, cluster.centerLongitude);

      // Generate a custom avatar marker bitmap
      final icon = await _createAvatarMarker(cluster);

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _onClusterTap(cluster),
          zIndexInt: cluster.size, // Larger clusters on top
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  /// Creates a circular avatar marker bitmap for a story cluster.
  /// Single stories show the user's initial; clusters show the count.
  Future<BitmapDescriptor> _createAvatarMarker(StoryCluster cluster) async {
    final size = cluster.size > 1 ? 80.0 : 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Outer glow ring (Snapchat-style colored ring)
    final ringColor = _getClusterColor(cluster);
    paint
      ..color = ringColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Main circle background
    paint
      ..color = ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, paint);

    // Inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, paint);

    // Center content: cluster count or user initial
    paint.color = ringColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Draw text (count or initial)
    final text = cluster.size > 1
        ? '${cluster.size}'
        : (cluster.previewStories.isNotEmpty
            ? (cluster.previewStories.first.user?.fullName ?? '?')[0]
                .toUpperCase()
            : '?');

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: cluster.size > 1 ? 20 : 22,
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

        // Empty state overlay when no stories at all
        if (widget.stories.isEmpty) _buildEmptyState(),

        // Non-geolocated stories → bottom horizontal card tray
        if (_storiesWithoutLocation.isNotEmpty && selectedCluster == null)
          _buildBottomStoryTray(),

        // Selected cluster preview sheet (Snapchat-style bottom card)
        if (selectedCluster != null) _buildClusterPreview(),

        // Create Story FAB
        _buildCreateStoryButton(),
      ],
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
                          backgroundImage:
                              NetworkImage(story.user!.imageUrl!),
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
    final showTray = _storiesWithoutLocation.isNotEmpty && selectedCluster == null;
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
    if (cluster.size >= 10) return Colors.red;
    if (cluster.size >= 5) return Colors.orange;
    if (cluster.size >= 3) return Colors.amber;
    return ColorsManager.primary;
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
