import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Wallpaper type enum
enum WallpaperType {
  none,
  color,
  gradient,
  preset,
  custom,
}

/// Wallpaper configuration model
class ChatWallpaper {
  final WallpaperType type;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final String? presetId;
  final String? customImagePath;

  const ChatWallpaper({
    this.type = WallpaperType.none,
    this.solidColor,
    this.gradientColors,
    this.presetId,
    this.customImagePath,
  });

  static const ChatWallpaper none = ChatWallpaper(type: WallpaperType.none);

  ChatWallpaper copyWith({
    WallpaperType? type,
    Color? solidColor,
    List<Color>? gradientColors,
    String? presetId,
    String? customImagePath,
  }) {
    return ChatWallpaper(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      presetId: presetId ?? this.presetId,
      customImagePath: customImagePath ?? this.customImagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'solidColor': solidColor?.value,
      'gradientColors': gradientColors?.map((c) => c.value).toList(),
      'presetId': presetId,
      'customImagePath': customImagePath,
    };
  }

  factory ChatWallpaper.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ChatWallpaper.none;
    return ChatWallpaper(
      type: WallpaperType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => WallpaperType.none,
      ),
      solidColor: map['solidColor'] != null ? Color(map['solidColor']) : null,
      gradientColors: map['gradientColors'] != null
          ? (map['gradientColors'] as List).map((c) => Color(c as int)).toList()
          : null,
      presetId: map['presetId'],
      customImagePath: map['customImagePath'],
    );
  }

  /// Build the wallpaper decoration
  BoxDecoration? toDecoration() {
    switch (type) {
      case WallpaperType.none:
        return null;
      case WallpaperType.color:
        return BoxDecoration(color: solidColor);
      case WallpaperType.gradient:
        if (gradientColors != null && gradientColors!.length >= 2) {
          return BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors!,
            ),
          );
        }
        return null;
      case WallpaperType.preset:
        // Presets would use asset images
        return null;
      case WallpaperType.custom:
        return null;
    }
  }

  /// Get image provider for preset/custom wallpapers
  ImageProvider? toImageProvider() {
    switch (type) {
      case WallpaperType.preset:
        if (presetId != null) {
          return AssetImage('assets/wallpapers/$presetId.jpg');
        }
        return null;
      case WallpaperType.custom:
        if (customImagePath != null) {
          return FileImage(File(customImagePath!));
        }
        return null;
      default:
        return null;
    }
  }
}

/// Preset wallpaper definitions
class PresetWallpaper {
  final String id;
  final String name;
  final List<Color> previewColors;
  final bool isGradient;

  const PresetWallpaper({
    required this.id,
    required this.name,
    required this.previewColors,
    this.isGradient = false,
  });

  static const List<PresetWallpaper> presets = [
    PresetWallpaper(
      id: 'ocean',
      name: 'Ocean',
      previewColors: [Color(0xFF1A237E), Color(0xFF0288D1)],
      isGradient: true,
    ),
    PresetWallpaper(
      id: 'sunset',
      name: 'Sunset',
      previewColors: [Color(0xFFFF6F00), Color(0xFFE91E63)],
      isGradient: true,
    ),
    PresetWallpaper(
      id: 'forest',
      name: 'Forest',
      previewColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
      isGradient: true,
    ),
    PresetWallpaper(
      id: 'lavender',
      name: 'Lavender',
      previewColors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
      isGradient: true,
    ),
    PresetWallpaper(
      id: 'midnight',
      name: 'Midnight',
      previewColors: [Color(0xFF0D47A1), Color(0xFF311B92)],
      isGradient: true,
    ),
    PresetWallpaper(
      id: 'coral',
      name: 'Coral',
      previewColors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
      isGradient: true,
    ),
  ];
}

/// Solid color options
class SolidColorOption {
  final String name;
  final Color color;

  const SolidColorOption(this.name, this.color);

  static const List<SolidColorOption> colors = [
    SolidColorOption('Default', Color(0xFFF5F5F5)),
    SolidColorOption('White', Colors.white),
    SolidColorOption('Light Blue', Color(0xFFE3F2FD)),
    SolidColorOption('Light Green', Color(0xFFE8F5E9)),
    SolidColorOption('Light Pink', Color(0xFFFCE4EC)),
    SolidColorOption('Light Yellow', Color(0xFFFFFDE7)),
    SolidColorOption('Light Purple', Color(0xFFF3E5F5)),
    SolidColorOption('Light Orange', Color(0xFFFFF3E0)),
    SolidColorOption('Dark', Color(0xFF121212)),
    SolidColorOption('Navy', Color(0xFF1A237E)),
    SolidColorOption('Forest', Color(0xFF1B5E20)),
    SolidColorOption('Burgundy', Color(0xFF880E4F)),
  ];
}

/// Chat Wallpaper Picker
class ChatWallpaperPicker extends StatefulWidget {
  final String chatId;
  final String chatName;
  final ChatWallpaper currentWallpaper;
  final ValueChanged<ChatWallpaper>? onWallpaperChanged;

  const ChatWallpaperPicker({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.currentWallpaper,
    this.onWallpaperChanged,
  });

  /// Show the wallpaper picker
  static Future<ChatWallpaper?> show(
    BuildContext context, {
    required String chatId,
    required String chatName,
    required ChatWallpaper currentWallpaper,
  }) async {
    return await Navigator.of(context).push<ChatWallpaper>(
      MaterialPageRoute(
        builder: (context) => ChatWallpaperPicker(
          chatId: chatId,
          chatName: chatName,
          currentWallpaper: currentWallpaper,
        ),
      ),
    );
  }

  @override
  State<ChatWallpaperPicker> createState() => _ChatWallpaperPickerState();
}

class _ChatWallpaperPickerState extends State<ChatWallpaperPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatWallpaper _selectedWallpaper;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedWallpaper = widget.currentWallpaper;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Chat Wallpaper',
          style: StylesManager.semiBold(fontSize: FontSize.large),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveWallpaper,
            child: Text(
              'Save',
              style: StylesManager.semiBold(
                fontSize: FontSize.medium,
                color: ColorsManager.primary,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.primary,
          unselectedLabelColor: ColorsManager.grey,
          indicatorColor: ColorsManager.primary,
          tabs: const [
            Tab(text: 'Solid'),
            Tab(text: 'Gradient'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Preview
          _buildPreview(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSolidColorsTab(),
                _buildGradientsTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Wallpaper background
            Positioned.fill(
              child: _buildWallpaperPreview(),
            ),

            // Sample messages overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPreviewBubble('Hey! How are you?', false),
                    const SizedBox(height: 8),
                    _buildPreviewBubble('I\'m doing great, thanks!', true),
                    const SizedBox(height: 8),
                    _buildPreviewBubble('That\'s wonderful to hear 😊', false),
                  ],
                ),
              ),
            ),

            // Chat name overlay
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.chatName,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaperPreview() {
    switch (_selectedWallpaper.type) {
      case WallpaperType.none:
        return Container(color: Colors.grey.shade100);
      case WallpaperType.color:
        return Container(color: _selectedWallpaper.solidColor ?? Colors.grey.shade100);
      case WallpaperType.gradient:
        if (_selectedWallpaper.gradientColors != null &&
            _selectedWallpaper.gradientColors!.length >= 2) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _selectedWallpaper.gradientColors!,
              ),
            ),
          );
        }
        return Container(color: Colors.grey.shade100);
      case WallpaperType.preset:
        // For presets, use gradient preview
        final preset = PresetWallpaper.presets.firstWhere(
          (p) => p.id == _selectedWallpaper.presetId,
          orElse: () => PresetWallpaper.presets.first,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: preset.previewColors,
            ),
          ),
        );
      case WallpaperType.custom:
        if (_selectedWallpaper.customImagePath != null) {
          return Image.file(
            File(_selectedWallpaper.customImagePath!),
            fit: BoxFit.cover,
          );
        }
        return Container(color: Colors.grey.shade100);
    }
  }

  Widget _buildPreviewBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? ColorsManager.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSolidColorsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: SolidColorOption.colors.length + 1, // +1 for "None"
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildNoneOption();
        }
        final color = SolidColorOption.colors[index - 1];
        return _buildColorOption(color);
      },
    );
  }

  Widget _buildNoneOption() {
    final isSelected = _selectedWallpaper.type == WallpaperType.none;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedWallpaper = ChatWallpaper.none;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ColorsManager.primary, width: 3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.slash,
              color: ColorsManager.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'None',
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(SolidColorOption color) {
    final isSelected = _selectedWallpaper.type == WallpaperType.color &&
        _selectedWallpaper.solidColor == color.color;
    final isDark = color.color.computeLuminance() < 0.5;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedWallpaper = ChatWallpaper(
            type: WallpaperType.color,
            solidColor: color.color,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ColorsManager.primary, width: 3)
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: isDark ? Colors.white : ColorsManager.primary,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildGradientsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: PresetWallpaper.presets.length,
      itemBuilder: (context, index) {
        final preset = PresetWallpaper.presets[index];
        return _buildGradientOption(preset);
      },
    );
  }

  Widget _buildGradientOption(PresetWallpaper preset) {
    final isSelected = (_selectedWallpaper.type == WallpaperType.preset &&
            _selectedWallpaper.presetId == preset.id) ||
        (_selectedWallpaper.type == WallpaperType.gradient &&
            _selectedWallpaper.gradientColors != null &&
            _selectedWallpaper.gradientColors!.length >= 2 &&
            _selectedWallpaper.gradientColors![0] == preset.previewColors[0] &&
            _selectedWallpaper.gradientColors![1] == preset.previewColors[1]);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedWallpaper = ChatWallpaper(
            type: WallpaperType.gradient,
            gradientColors: preset.previewColors,
            presetId: preset.id,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: preset.previewColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Name label
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                preset.name,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Check mark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: ColorsManager.primary,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload from gallery
          _buildCustomOption(
            icon: Iconsax.gallery,
            title: 'Choose from Gallery',
            subtitle: 'Select a photo from your device',
            onTap: _pickImageFromGallery,
          ),
          const SizedBox(height: 12),

          // Take photo
          _buildCustomOption(
            icon: Iconsax.camera,
            title: 'Take a Photo',
            subtitle: 'Use your camera to capture a wallpaper',
            onTap: _takePhoto,
          ),
          const SizedBox(height: 24),

          // Current custom image preview
          if (_selectedWallpaper.type == WallpaperType.custom &&
              _selectedWallpaper.customImagePath != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Custom Wallpaper',
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(_selectedWallpaper.customImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedWallpaper = ChatWallpaper.none;
                    });
                  },
                  icon: const Icon(Iconsax.trash, size: 18),
                  label: const Text('Remove Custom Wallpaper'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),

          // Info card
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Custom wallpapers are stored locally on your device and won\'t sync across devices.',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ColorsManager.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: StylesManager.semiBold(fontSize: FontSize.medium),
                  ),
                  Text(
                    subtitle,
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ColorsManager.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedWallpaper = ChatWallpaper(
            type: WallpaperType.custom,
            customImagePath: image.path,
          );
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedWallpaper = ChatWallpaper(
            type: WallpaperType.custom,
            customImagePath: image.path,
          );
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _saveWallpaper() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_selectedWallpaper);
  }
}

/// Chat Wallpaper Tile for Settings Lists
class ChatWallpaperTile extends StatelessWidget {
  final String chatId;
  final String chatName;
  final ChatWallpaper currentWallpaper;
  final ValueChanged<ChatWallpaper>? onWallpaperChanged;

  const ChatWallpaperTile({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.currentWallpaper,
    this.onWallpaperChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        final result = await ChatWallpaperPicker.show(
          context,
          chatId: chatId,
          chatName: chatName,
          currentWallpaper: currentWallpaper,
        );
        if (result != null && onWallpaperChanged != null) {
          onWallpaperChanged!(result);
        }
      },
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: _buildThumbnail(),
        ),
      ),
      title: Text(
        'Wallpaper',
        style: StylesManager.medium(fontSize: FontSize.medium),
      ),
      subtitle: Text(
        _getWallpaperDescription(),
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: ColorsManager.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ColorsManager.grey,
      ),
    );
  }

  Widget _buildThumbnail() {
    switch (currentWallpaper.type) {
      case WallpaperType.none:
        return Container(
          color: Colors.grey.shade100,
          child: Icon(Iconsax.image, color: ColorsManager.grey, size: 20),
        );
      case WallpaperType.color:
        return Container(color: currentWallpaper.solidColor);
      case WallpaperType.gradient:
        if (currentWallpaper.gradientColors != null &&
            currentWallpaper.gradientColors!.length >= 2) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentWallpaper.gradientColors!,
              ),
            ),
          );
        }
        return Container(color: Colors.grey.shade100);
      case WallpaperType.preset:
        final preset = PresetWallpaper.presets.firstWhere(
          (p) => p.id == currentWallpaper.presetId,
          orElse: () => PresetWallpaper.presets.first,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: preset.previewColors,
            ),
          ),
        );
      case WallpaperType.custom:
        if (currentWallpaper.customImagePath != null) {
          return Image.file(
            File(currentWallpaper.customImagePath!),
            fit: BoxFit.cover,
          );
        }
        return Container(color: Colors.grey.shade100);
    }
  }

  String _getWallpaperDescription() {
    switch (currentWallpaper.type) {
      case WallpaperType.none:
        return 'Default';
      case WallpaperType.color:
        return 'Solid color';
      case WallpaperType.gradient:
        return 'Gradient';
      case WallpaperType.preset:
        final preset = PresetWallpaper.presets.firstWhere(
          (p) => p.id == currentWallpaper.presetId,
          orElse: () => PresetWallpaper.presets.first,
        );
        return preset.name;
      case WallpaperType.custom:
        return 'Custom image';
    }
  }
}
