import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🗺️ Interactive Map Viewer
/// Full-screen interactive map with Google Maps
/// Shows a location with marker and allows zoom/pan
class InteractiveMapViewer extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? address;

  const InteractiveMapViewer({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.address,
  }) : super(key: key);

  @override
  State<InteractiveMapViewer> createState() => _InteractiveMapViewerState();
}

class _InteractiveMapViewerState extends State<InteractiveMapViewer> {
  GoogleMapController? _mapController;
  late CameraPosition _initialPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 15.0,
    );

    // Create marker
    _markers.add(
      Marker(
        markerId: const MarkerId('location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: widget.locationName ?? 'Location',
          snippet: widget.address,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw 'Launch failed';
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to open Google Maps',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _zoomIn() async {
    final currentZoom = await _mapController?.getZoomLevel() ?? 15.0;
    _mapController?.animateCamera(
      CameraUpdate.zoomTo(currentZoom + 1),
    );
  }

  Future<void> _zoomOut() async {
    final currentZoom = await _mapController?.getZoomLevel() ?? 15.0;
    _mapController?.animateCamera(
      CameraUpdate.zoomTo(currentZoom - 1),
    );
  }

  void _resetCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
          ),

          // Top bar with gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Get.back(),
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Location info
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: ColorsManager.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.locationName ?? 'Location',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.address != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.address!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Zoom controls (right side)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _buildControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: Icons.my_location,
                  onPressed: _resetCamera,
                ),
              ],
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Coordinates
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Open in Google Maps button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.map, size: 22),
                          label: const Text(
                            'Open in Google Maps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.black87,
        iconSize: 24,
      ),
    );
  }
}
