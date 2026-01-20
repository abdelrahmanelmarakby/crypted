import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/app/modules/stories/widgets/google_places_location_picker.dart';

/// Model for stored location
class StoredLocation {
  final double latitude;
  final double longitude;
  final String name;
  final DateTime usedAt;

  StoredLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.usedAt,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'usedAt': usedAt.toIso8601String(),
      };

  factory StoredLocation.fromJson(Map<String, dynamic> json) => StoredLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String,
        usedAt: DateTime.parse(json['usedAt'] as String),
      );
}

/// Beautiful Location Picker for Stories
class StoryLocationPicker extends StatefulWidget {
  final Function(double lat, double lon, String? placeName) onLocationSelected;

  const StoryLocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  /// Save a location to recent locations
  static Future<void> saveRecentLocation(double lat, double lon, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('recent_story_locations') ?? [];

      // Create new location
      final newLocation = StoredLocation(
        latitude: lat,
        longitude: lon,
        name: name,
        usedAt: DateTime.now(),
      );

      // Remove if same location exists (by name or coordinates)
      stored.removeWhere((jsonStr) {
        try {
          final loc = StoredLocation.fromJson(jsonDecode(jsonStr));
          return loc.name == name ||
              (loc.latitude == lat && loc.longitude == lon);
        } catch (_) {
          return false;
        }
      });

      // Add to beginning
      stored.insert(0, jsonEncode(newLocation.toJson()));

      // Keep only last 10 locations
      if (stored.length > 10) {
        stored.removeRange(10, stored.length);
      }

      await prefs.setStringList('recent_story_locations', stored);
    } catch (e) {
      debugPrint('Error saving recent location: $e');
    }
  }

  @override
  State<StoryLocationPicker> createState() => _StoryLocationPickerState();
}

class _StoryLocationPickerState extends State<StoryLocationPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationEnabled = true;
  List<StoredLocation> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _getCurrentLocation();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('recent_story_locations') ?? [];

      final locations = stored.map((jsonStr) {
        try {
          return StoredLocation.fromJson(jsonDecode(jsonStr));
        } catch (_) {
          return null;
        }
      }).whereType<StoredLocation>().toList();

      // Sort by most recently used
      locations.sort((a, b) => b.usedAt.compareTo(a.usedAt));

      setState(() {
        _recentLocations = locations;
      });
    } catch (e) {
      debugPrint('Error loading recent locations: $e');
    }
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
              // Save to recent locations
              StoryLocationPicker.saveRecentLocation(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                'Current Location',
              );

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

        // Recent locations section (only show if we have any)
        if (_recentLocations.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Locations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (_recentLocations.length > 3)
                  TextButton(
                    onPressed: () => _showAllRecentLocations(),
                    child: Text(
                      'See All (${_recentLocations.length})',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Show up to 3 recent locations
          ...(_recentLocations.take(3).map(
                (location) => _buildLocationTile(
                  icon: Icons.history_rounded,
                  title: location.name,
                  subtitle: '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  onTap: () => _selectRecentLocation(location),
                ),
              )),
        ] else ...[
          // No recent locations message
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Text(
              'No recent locations yet. Your selected locations will appear here.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

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

  void _selectRecentLocation(StoredLocation location) {
    // Update usage time by saving again
    StoryLocationPicker.saveRecentLocation(
      location.latitude,
      location.longitude,
      location.name,
    );

    widget.onLocationSelected(
      location.latitude,
      location.longitude,
      location.name,
    );
    Get.back();
  }

  void _showAllRecentLocations() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: ColorsManager.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'All Recent Locations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _recentLocations.length,
                itemBuilder: (context, index) {
                  final location = _recentLocations[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: ColorsManager.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      location.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Get.back(); // Close "all locations" sheet
                      _selectRecentLocation(location);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
