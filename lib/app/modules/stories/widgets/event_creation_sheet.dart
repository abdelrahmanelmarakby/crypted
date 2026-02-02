import 'dart:io';

import 'package:crypted_app/app/data/data_source/story_data_sources.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for creating a public event story.
/// Anyone on the app can see it and join — even strangers.
class EventCreationSheet extends StatefulWidget {
  const EventCreationSheet({super.key});

  @override
  State<EventCreationSheet> createState() => _EventCreationSheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EventCreationSheet(),
    );
  }
}

class _EventCreationSheetState extends State<EventCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _eventEndDate;
  TimeOfDay? _eventEndTime;
  String _selectedCategory = 'social';
  File? _coverImage;
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  double? _latitude;
  double? _longitude;
  String? _placeName;
  String? _city;
  String? _country;

  static const List<Map<String, dynamic>> _categories = [
    {'id': 'social', 'label': 'Social', 'icon': Icons.people_outline},
    {'id': 'sports', 'label': 'Sports', 'icon': Icons.sports_basketball},
    {'id': 'music', 'label': 'Music', 'icon': Icons.music_note},
    {'id': 'food', 'label': 'Food', 'icon': Icons.restaurant},
    {'id': 'tech', 'label': 'Tech', 'icon': Icons.computer},
    {'id': 'art', 'label': 'Art', 'icon': Icons.palette},
    {'id': 'education', 'label': 'Education', 'icon': Icons.school},
    {'id': 'other', 'label': 'Other', 'icon': Icons.category},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  Future<void> _pickDate(bool isEndDate) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_eventDate ?? now) : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: ColorsManager.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: ColorsManager.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      if (isEndDate) {
        _eventEndDate = date;
        _eventEndTime = time;
      } else {
        _eventDate = date;
        _eventTime = time;
      }
    });
  }

  DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    final t = time ?? const TimeOfDay(hour: 12, minute: 0);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _placeName = place.name ?? place.street;
          _city = place.locality;
          _country = place.country;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      Get.snackbar('Missing Date', 'Please select an event date');
      return;
    }

    // Validate end date is after start date
    final eventDateTime = _combineDateAndTime(_eventDate, _eventTime);
    final eventEndDateTime = _combineDateAndTime(_eventEndDate, _eventEndTime);
    if (eventDateTime != null &&
        eventEndDateTime != null &&
        eventEndDateTime.isBefore(eventDateTime)) {
      Get.snackbar('Invalid Date', 'End date must be after start date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch location if enabled
      if (_useCurrentLocation) {
        await _fetchLocation();
      }

      final maxAttendees = _maxAttendeesController.text.isNotEmpty
          ? int.tryParse(_maxAttendeesController.text)
          : null;

      final story = StoryModel(
        eventTitle: _titleController.text.trim(),
        eventDescription: _descriptionController.text.trim(),
        eventDate: eventDateTime,
        eventEndDate: eventEndDateTime,
        eventVenue: _venueController.text.trim(),
        eventCategory: _selectedCategory,
        eventMaxAttendees: maxAttendees,
        storyType: StoryType.event,
        latitude: _latitude,
        longitude: _longitude,
        placeName: _placeName,
        city: _city,
        country: _country,
        isLocationPublic: true,
        // Use event title as story text for display in story viewer
        storyText: _titleController.text.trim(),
        backgroundColor: '#1A1A2E',
        textColor: '#FFFFFF',
      );

      final dataSource = StoryDataSources();
      bool success;

      if (_coverImage != null) {
        // Upload cover image to Storage first, then create event story
        success =
            await dataSource.uploadEventStoryWithCover(story, _coverImage!);
      } else {
        // Upload as event story (no cover image)
        success = await dataSource.uploadEventStory(story);
      }

      if (success) {
        HapticFeedback.mediumImpact();
        // Refresh stories controller if available
        try {
          final storiesController = Get.find<StoriesController>();
          storiesController.fetchAllStories();
        } catch (_) {}
        Get.back();
        Get.snackbar(
          'Event Created',
          'Your event is now visible to everyone!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorsManager.primary.withAlpha(230),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', 'Failed to create event. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: ColorsManager.scaffoldBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Paddings.large,
              vertical: Paddings.normal,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event,
                    color: ColorsManager.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: FontSize.xLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                      Text(
                        'Anyone nearby can discover and join',
                        style: TextStyle(
                          fontSize: FontSize.small,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: Paddings.large,
                right: Paddings.large,
                bottom: bottomInset + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Cover image
                    _buildCoverImagePicker(),
                    const SizedBox(height: 20),
                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Event Title',
                      hint: 'What\'s happening?',
                      icon: Iconsax.text,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Tell people what this event is about...',
                      icon: Iconsax.document_text,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Category
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    // Date & Time
                    _buildDateTimePicker(
                      label: 'Starts',
                      date: _eventDate,
                      time: _eventTime,
                      onTap: () => _pickDate(false),
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDateTimePicker(
                      label: 'Ends (optional)',
                      date: _eventEndDate,
                      time: _eventEndTime,
                      onTap: () => _pickDate(true),
                    ),
                    const SizedBox(height: 16),
                    // Venue
                    _buildTextField(
                      controller: _venueController,
                      label: 'Venue',
                      hint: 'Where is this happening?',
                      icon: Iconsax.location,
                    ),
                    const SizedBox(height: 12),
                    // Use location toggle
                    SwitchListTile.adaptive(
                      title: Text(
                        'Share my location',
                        style: TextStyle(
                          fontSize: FontSize.medium,
                          color: ColorsManager.textPrimaryAdaptive(context),
                        ),
                      ),
                      subtitle: Text(
                        'Show event on the map for nearby people',
                        style: TextStyle(
                          fontSize: FontSize.small,
                          color: Colors.grey,
                        ),
                      ),
                      value: _useCurrentLocation,
                      activeColor: ColorsManager.primary,
                      onChanged: (v) => setState(() => _useCurrentLocation = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    // Max attendees
                    _buildTextField(
                      controller: _maxAttendeesController,
                      label: 'Max Attendees (optional)',
                      hint: 'Leave empty for unlimited',
                      icon: Iconsax.profile_2user,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.celebration, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Publish Event',
                                    style: TextStyle(
                                      fontSize: FontSize.large,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImagePicker() {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: ColorsManager.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ColorsManager.primary.withAlpha(60),
            width: 1.5,
          ),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.gallery_add,
                    size: 36,
                    color: ColorsManager.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Cover Photo (optional)',
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _coverImage = null),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: FontSize.medium,
            fontWeight: FontWeight.w600,
            color: ColorsManager.textPrimaryAdaptive(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = cat['id'] == _selectedCategory;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : ColorsManager.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(cat['label'] as String),
                ],
              ),
              selected: isSelected,
              selectedColor: ColorsManager.primary,
              backgroundColor: ColorsManager.primary.withAlpha(15),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : ColorsManager.textPrimaryAdaptive(context),
                fontSize: FontSize.small,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) =>
                  setState(() => _selectedCategory = cat['id'] as String),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    final dateText = date != null
        ? '${DateFormat('EEE, MMM d').format(date)} at ${time?.format(context) ?? '12:00 PM'}'
        : 'Tap to select';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: (isRequired && date == null)
                ? Colors.red.withAlpha(120)
                : Colors.grey.withAlpha(60),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar_1, size: 20, color: ColorsManager.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: FontSize.xSmall,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: FontSize.medium,
                      color: date != null
                          ? ColorsManager.textPrimaryAdaptive(context)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        color: ColorsManager.textPrimaryAdaptive(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: ColorsManager.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorsManager.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
