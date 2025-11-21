import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/app/modules/stories/widgets/google_places_location_picker.dart';

/// Beautiful Location Picker for Stories
class StoryLocationPicker extends StatefulWidget {
  final Function(double lat, double lon, String? placeName) onLocationSelected;

  const StoryLocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<StoryLocationPicker> createState() => _StoryLocationPickerState();
}

class _StoryLocationPickerState extends State<StoryLocationPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationEnabled = true;

  final List<Map<String, dynamic>> _recentLocations = [
    {'name': 'Current Location', 'icon': Icons.my_location},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Work', 'icon': Icons.work},
    {'name': 'Custom Location', 'icon': Icons.edit_location},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationEnabled = false;
          _isLoading = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationEnabled = false;
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationEnabled = false;
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _controller.value) * 300),
          child: child,
        );
      },
      child: Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: ColorsManager.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Let friends know where you are',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorsManager.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Getting your location...',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : !_locationEnabled
                      ? _buildLocationDisabled()
                      : _buildLocationOptions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisabled() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Location Services Disabled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enable location services to share your location with stories',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                _getCurrentLocation();
              },
              icon: Icon(Icons.settings),
              label: Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOptions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Current location (if available)
        if (_currentPosition != null)
          _buildLocationTile(
            icon: Icons.my_location,
            title: 'Current Location',
            subtitle:
                '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
            onTap: () {
              widget.onLocationSelected(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                'Current Location',
              );
              Get.back();
            },
            isPrimary: true,
          ),

        const SizedBox(height: 24),

        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Recent Locations',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),

        // Recent locations
        ...List.generate(
          3,
          (index) => _buildLocationTile(
            icon: Icons.location_on,
            title: 'Recent Location ${index + 1}',
            subtitle: 'Tap to select',
            onTap: () {
              // Implement recent location logic
              Get.snackbar(
                'Coming Soon',
                'Recent locations feature will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Search location with Google Places
        _buildLocationTile(
          icon: Icons.search,
          title: 'Search Location',
          subtitle: 'Find a specific place with Google Maps',
          onTap: () {
            // Close current picker and open Google Places picker
            Get.back();
            Get.bottomSheet(
              GooglePlacesLocationPicker(
                onLocationSelected: widget.onLocationSelected,
              ),
              isScrollControlled: true,
              enableDrag: true,
            );
          },
        ),

        const SizedBox(height: 16),

        // No location option
        _buildLocationTile(
          icon: Icons.location_off,
          title: 'Don\'t Share Location',
          subtitle: 'Story won\'t appear on map',
          onTap: () {
            Get.back();
          },
          isDanger: true,
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? Border.all(
                  color: ColorsManager.primary.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDanger
                        ? Colors.red.withValues(alpha: 0.1)
                        : isPrimary
                            ? ColorsManager.primary.withValues(alpha: 0.2)
                            : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDanger
                        ? Colors.red
                        : isPrimary
                            ? ColorsManager.primary
                            : Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDanger ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
