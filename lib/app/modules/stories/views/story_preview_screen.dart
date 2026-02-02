import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_location_picker.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:video_player/video_player.dart';

// ═════════════════════════════════════════════════════════════
// DATA MODELS for overlays
// ═════════════════════════════════════════════════════════════

class _TextOverlayData {
  String text;
  Offset position = const Offset(0.5, 0.4); // Normalized 0-1
  double scale = 1.0;
  double rotation = 0.0; // radians
  Color color;
  Color? backgroundColor;
  String fontFamily;
  TextAlign textAlign;

  _TextOverlayData({
    required this.text,
    this.color = Colors.white,
    this.backgroundColor,
    this.fontFamily = 'DM Sans',
    this.textAlign = TextAlign.center,
  });
}

class _LinkStickerData {
  String url;
  String displayText;
  Offset position = const Offset(0.5, 0.6);
  double scale = 1.0;

  _LinkStickerData({
    required this.url,
    required this.displayText,
  });
}

class _EmojiOverlayData {
  String emoji;
  Offset position;
  double scale = 1.0;
  double rotation = 0.0;

  _EmojiOverlayData({
    required this.emoji,
    this.position = const Offset(0.5, 0.5),
  });
}

class _DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

// ═════════════════════════════════════════════════════════════
// ACTIVE TOOL ENUM
// ═════════════════════════════════════════════════════════════

enum _ActiveTool { none, draw, text, link, emoji }

// ═════════════════════════════════════════════════════════════
// PREVIEW SCREEN
// ═════════════════════════════════════════════════════════════

/// Instagram-quality story preview/edit screen.
///
/// Features: Drawing tool, enhanced text (fonts, backgrounds, alignment),
/// link stickers, emoji overlays, vertical toolbar, animated upload
/// progress, and discard confirmation.
class StoryPreviewScreen extends StatefulWidget {
  final File? mediaFile;
  final StoryType storyType;
  final String? storyText;
  final String? backgroundColor;

  const StoryPreviewScreen({
    super.key,
    this.mediaFile,
    required this.storyType,
    this.storyText,
    this.backgroundColor,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen>
    with TickerProviderStateMixin {
  final StoriesController _storiesController = Get.find<StoriesController>();

  // ── Compositing key ─────────────────────────────────────
  final GlobalKey _compositeKey = GlobalKey();

  // ── Active tool ───────────────────────────────────────────
  _ActiveTool _activeTool = _ActiveTool.none;

  // ── Text overlays ─────────────────────────────────────────
  final List<_TextOverlayData> _textOverlays = [];
  int? _editingTextIndex; // index being edited (null = adding new)
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;
  // Text style options
  String _selectedFontFamily = 'DM Sans';
  Color _selectedTextColor = Colors.white;
  Color? _selectedTextBg;
  TextAlign _selectedTextAlign = TextAlign.center;
  static const List<String> _fontFamilies = [
    'DM Sans',
    'IBM Plex Sans Arabic',
  ];

  // ── Link stickers ─────────────────────────────────────────
  final List<_LinkStickerData> _linkStickers = [];
  final TextEditingController _linkUrlController = TextEditingController();
  final TextEditingController _linkDisplayController = TextEditingController();

  // ── Emoji overlays ────────────────────────────────────────
  final List<_EmojiOverlayData> _emojiOverlays = [];
  static const List<String> _popularEmojis = [
    '😀',
    '😂',
    '🥰',
    '😎',
    '🤩',
    '😍',
    '🥳',
    '🤔',
    '😱',
    '🔥',
    '❤️',
    '💯',
    '✨',
    '🎉',
    '👏',
    '🙌',
    '💪',
    '🎶',
    '🌟',
    '⭐',
    '🌈',
    '🦋',
    '🌸',
    '🍕',
    '☕',
    '🎮',
    '📸',
    '🏆',
    '💎',
    '🚀',
    '👋',
    '✌️',
    '🤙',
    '👀',
    '💀',
    '🫠',
    '🥺',
    '😈',
    '🤡',
    '💅',
  ];

  // ── Drawing ───────────────────────────────────────────────
  final List<_DrawingPath> _drawingPaths = [];
  List<Offset> _currentDrawingPoints = [];
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 4.0;
  static const List<double> _strokeWidths = [2.0, 4.0, 8.0];

  // ── Color palette (shared) ────────────────────────────────
  static final List<Color> _colorPalette = [
    Colors.white,
    Colors.black,
    const Color(0xFF31A354), // Primary green
    const Color(0xFF1E88E5), // Blue
    const Color(0xFFE53935), // Red
    const Color(0xFFFB8C00), // Orange
    const Color(0xFF8E24AA), // Purple
    const Color(0xFFF06292), // Pink
    const Color(0xFFFFB300), // Amber
    const Color(0xFF00897B), // Teal
  ];

  // ── Location state (required for Snap Map) ────────────────
  double? _latitude;
  double? _longitude;
  String? _placeName;
  bool _isLocationLoading = true;

  // ── Upload state ──────────────────────────────────────────
  bool _isUploading = false;

  // ── Video preview ─────────────────────────────────────────
  VideoPlayerController? _videoController;

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _toolbarAnimController;
  late final AnimationController _uploadProgressController;

  @override
  void initState() {
    super.initState();

    _toolbarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _toolbarAnimController.forward();

    _uploadProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.storyType == StoryType.video && widget.mediaFile != null) {
      _videoController = VideoPlayerController.file(widget.mediaFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }

    // Auto-fetch location — required for Snap Map publishing
    _autoFetchLocation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkUrlController.dispose();
    _linkDisplayController.dispose();
    _videoController?.dispose();
    _toolbarAnimController.dispose();
    _uploadProgressController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.black;
  }

  // ═══════════════════════════════════════════════════════════
  // COMPOSITING — Bake overlays into final image
  // ═══════════════════════════════════════════════════════════

  bool get _hasOverlays =>
      _drawingPaths.isNotEmpty ||
      _textOverlays.isNotEmpty ||
      _linkStickers.isNotEmpty ||
      _emojiOverlays.isNotEmpty;

  /// Captures the RepaintBoundary as a PNG file.
  ///
  /// This flattens all visual overlays (drawings, text, emoji, link stickers)
  /// into a single composite image that can be uploaded to Firebase.
  Future<File?> _compositeToImage() async {
    try {
      final boundary = _compositeKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/story_composite_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      debugPrint('Error compositing story: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  /// Auto-fetch device location on preview open.
  /// Location is required for publishing stories to the Snap Map.
  Future<void> _autoFetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLocationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLocationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _placeName = 'Current Location';
          _isLocationLoading = false;
        });

        // Save to recent locations for quick re-use
        StoryLocationPicker.saveRecentLocation(
          position.latitude,
          position.longitude,
          'Current Location',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLocationLoading = false);
      debugPrint('Error auto-fetching location: $e');
    }
  }

  Future<void> _postStory() async {
    HapticFeedback.lightImpact();

    // Location is required for story publishing
    if (_latitude == null || _longitude == null) {
      Get.snackbar(
        'Location Required',
        'Please add a location to publish your story',
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      _openLocationPicker();
      return;
    }

    // ── Composite overlays into image (before showing upload UI) ──
    // For image/text stories with overlays, flatten everything into one image.
    // For video stories, overlays can't be baked in without FFmpeg, so we
    // save metadata (text, link) and the raw video file.
    File? uploadFile = widget.mediaFile;
    StoryType uploadType = widget.storyType;

    if (_hasOverlays && widget.storyType != StoryType.video) {
      final compositeFile = await _compositeToImage();
      if (compositeFile != null) {
        uploadFile = compositeFile;
        // Text stories with overlays become image stories
        uploadType = StoryType.image;
      }
    }

    setState(() => _isUploading = true);
    _uploadProgressController.forward(from: 0.0);

    try {
      // Collect first text overlay as the primary overlay text
      final primaryText =
          _textOverlays.isNotEmpty ? _textOverlays.first.text : null;
      final primaryLink =
          _linkStickers.isNotEmpty ? _linkStickers.first.url : null;
      final primaryLinkDisplay =
          _linkStickers.isNotEmpty ? _linkStickers.first.displayText : null;

      await _storiesController.uploadStoryWithFile(
        file: uploadFile,
        storyType: uploadType,
        overlayText: primaryText ?? widget.storyText,
        backgroundColor: widget.backgroundColor,
        latitude: _latitude,
        longitude: _longitude,
        placeName: _placeName,
        linkUrl: primaryLink,
        linkDisplayText: primaryLinkDisplay,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        Get.back();
        Get.snackbar('Success', 'Story posted!',
            backgroundColor: ColorsManager.primary.withValues(alpha: 0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _uploadProgressController.stop();
        Get.snackbar('Error', 'Failed to post story',
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white);
      }
    }
  }

  void _showDiscardDialog() {
    HapticFeedback.lightImpact();
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Discard story?',
      desc: 'Your changes will be lost.',
      btnCancelText: 'Keep Editing',
      btnOkText: 'Discard',
      btnCancelColor: ColorsManager.primary,
      btnOkColor: Colors.red,
      btnCancelOnPress: () {},
      btnOkOnPress: () => Get.back(),
    ).show();
  }

  void _openLocationPicker() {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      StoryLocationPicker(
        onLocationSelected: (lat, lon, placeName) {
          setState(() {
            _latitude = lat;
            _longitude = lon;
            _placeName = placeName;
          });
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _setActiveTool(_ActiveTool tool) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeTool = _activeTool == tool ? _ActiveTool.none : tool;
      if (tool == _ActiveTool.text) {
        _showTextInput = _activeTool == _ActiveTool.text;
        if (_showTextInput) {
          _editingTextIndex = null;
          _textController.clear();
          _selectedTextColor = Colors.white;
          _selectedTextBg = null;
          _selectedTextAlign = TextAlign.center;
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDiscardDialog();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Compositable layer ──────────────────────────
              // Everything inside this RepaintBoundary gets flattened
              // into a single image when the user posts (for image/text stories).
              RepaintBoundary(
                key: _compositeKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Preview content (image / video / text bg)
                    _buildPreviewContent(),

                    // 2. Drawing paths rendered (always visible)
                    if (_drawingPaths.isNotEmpty) _buildDrawingOverlay(),

                    // 3. Text overlays (draggable)
                    ..._textOverlays
                        .asMap()
                        .entries
                        .map((e) => _buildDraggableText(e.key, e.value)),

                    // 4. Link sticker overlays
                    ..._linkStickers
                        .asMap()
                        .entries
                        .map((e) => _buildDraggableLinkSticker(e.key, e.value)),

                    // 5. Emoji overlays
                    ..._emojiOverlays
                        .asMap()
                        .entries
                        .map((e) => _buildDraggableEmoji(e.key, e.value)),

                    // 6. Location badge (always show — location is required)
                    _placeName != null
                        ? _buildLocationBadge()
                        : _buildLocationRequiredBadge(),
                  ],
                ),
              ),

              // ── UI controls (NOT composited into final image) ──

              // 7. Drawing canvas overlay (active tool — captures gestures)
              if (_activeTool == _ActiveTool.draw) _buildDrawingCanvas(),

              // 8. Top bar (back + post)
              if (!_showTextInput) _buildTopBar(),

              // 9. Vertical toolbar (right side)
              if (!_showTextInput && _activeTool != _ActiveTool.draw)
                _buildVerticalToolbar(),

              // 10. Drawing toolbar (bottom, when drawing active)
              if (_activeTool == _ActiveTool.draw) _buildDrawingToolbar(),

              // 11. Text input overlay
              if (_showTextInput) _buildTextInputOverlay(),

              // 12. Emoji picker
              if (_activeTool == _ActiveTool.emoji) _buildEmojiPicker(),

              // 13. Upload overlay
              if (_isUploading) _buildUploadOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PREVIEW CONTENT
  // ═══════════════════════════════════════════════════════════

  Widget _buildPreviewContent() {
    switch (widget.storyType) {
      case StoryType.image:
        return widget.mediaFile != null
            ? Image.file(
                widget.mediaFile!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : const SizedBox.expand();

      case StoryType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );

      case StoryType.text:
        final bgColor = _parseColor(widget.backgroundColor ?? '#000000');
        return Container(
          color: bgColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.storyText ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

      case StoryType.event:
        // Events are created via EventCreationSheet, not via StoryPreviewScreen
        return Container(
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: Icon(Icons.event, size: 64, color: Colors.white54),
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (discard)
          _buildFrostedCircle(
            icon: Iconsax.arrow_left,
            onTap: _showDiscardDialog,
          ),
          // Post button
          GestureDetector(
            onTap: _isUploading ? null : _postStory,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.send_1, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Post',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: Colors.white,
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

  Widget _buildFrostedCircle({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorsManager.primary.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? ColorsManager.primary
                    : Colors.white.withValues(alpha: 0.15),
                width: isActive ? 2 : 0.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VERTICAL TOOLBAR (Right Side — Iconsax)
  // ═══════════════════════════════════════════════════════════

  Widget _buildVerticalToolbar() {
    final tools = <(IconData, String, _ActiveTool)>[
      (Iconsax.brush_1, 'Draw', _ActiveTool.draw),
      (Iconsax.text, 'Text', _ActiveTool.text),
      (Iconsax.link, 'Link', _ActiveTool.link),
      (Iconsax.emoji_happy, 'Emoji', _ActiveTool.emoji),
      (Iconsax.location, 'Place', _ActiveTool.none),
    ];

    return Positioned(
      right: 12,
      top: MediaQuery.of(context).padding.top + 70,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _toolbarAnimController,
          curve: Curves.easeOutBack,
        )),
        child: Column(
          children: tools.asMap().entries.map((entry) {
            final (icon, label, tool) = entry.value;
            final delay = entry.key * 0.1;
            final isActive = _activeTool == tool && tool != _ActiveTool.none;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(2.0, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _toolbarAnimController,
                  curve:
                      Interval(delay, delay + 0.4, curve: Curves.easeOutBack),
                )),
                child: Column(
                  children: [
                    _buildFrostedCircle(
                      icon: icon,
                      isActive: isActive,
                      onTap: () {
                        if (label == 'Place') {
                          _openLocationPicker();
                        } else if (label == 'Link') {
                          _showLinkBottomSheet();
                        } else {
                          _setActiveTool(tool);
                        }
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DRAWING TOOL
  // ═══════════════════════════════════════════════════════════

  Widget _buildDrawingCanvas() {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentDrawingPoints = [details.localPosition];
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentDrawingPoints = [
            ..._currentDrawingPoints,
            details.localPosition
          ];
        });
      },
      onPanEnd: (details) {
        if (_currentDrawingPoints.isNotEmpty) {
          setState(() {
            _drawingPaths.add(_DrawingPath(
              points: List.from(_currentDrawingPoints),
              color: _drawingColor,
              strokeWidth: _drawingStrokeWidth,
            ));
            _currentDrawingPoints = [];
          });
        }
      },
      child: CustomPaint(
        painter: _DrawingPainter(
          paths: _drawingPaths,
          currentPoints: _currentDrawingPoints,
          currentColor: _drawingColor,
          currentStrokeWidth: _drawingStrokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildDrawingOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DrawingPainter(
          paths: _drawingPaths,
          currentPoints: const [],
          currentColor: _drawingColor,
          currentStrokeWidth: _drawingStrokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color palette
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _colorPalette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = _colorPalette[index];
                final isSelected = color == _drawingColor;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _drawingColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isSelected ? 36 : 30,
                    height: isSelected ? 36 : 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white30,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Stroke width + undo + done
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stroke width selector
                Row(
                  children: _strokeWidths.map((width) {
                    final isSelected = width == _drawingStrokeWidth;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _drawingStrokeWidth = width);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: width * 4 + 12,
                          height: width * 4 + 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Container(
                              width: width * 2,
                              height: width * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected ? _drawingColor : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Row(
                  children: [
                    // Undo
                    _buildFrostedCircle(
                      icon: Iconsax.undo,
                      onTap: () {
                        if (_drawingPaths.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          setState(() => _drawingPaths.removeLast());
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    // Done
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _activeTool = _ActiveTool.none);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: ColorsManager.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Done',
                              style: StylesManager.semiBold(
                                fontSize: FontSize.small,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ENHANCED TEXT TOOL
  // ═══════════════════════════════════════════════════════════

  Widget _buildTextInputOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar: Cancel / Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showTextInput = false;
                        _activeTool = _ActiveTool.none;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: _confirmTextOverlay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Font family selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _fontFamilies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final font = _fontFamilies[index];
                  final isSelected = font == _selectedFontFamily;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFontFamily = font);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.white54 : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        font,
                        style: TextStyle(
                          fontFamily: font,
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Alignment + background toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Alignment buttons
                  ...[TextAlign.left, TextAlign.center, TextAlign.right]
                      .map((align) {
                    final isSelected = _selectedTextAlign == align;
                    final icon = align == TextAlign.left
                        ? Iconsax.textalign_left
                        : align == TextAlign.center
                            ? Iconsax.textalign_center
                            : Iconsax.textalign_right;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTextAlign = align);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            color: isSelected ? Colors.white : Colors.white54,
                            size: 20),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Text background toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_selectedTextBg == null) {
                          _selectedTextBg = Colors.black.withValues(alpha: 0.5);
                        } else if (_selectedTextBg!.a < 0.8) {
                          _selectedTextBg = Colors.black;
                        } else {
                          _selectedTextBg = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTextBg != null
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.text_block,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _selectedTextBg == null
                                ? 'No BG'
                                : _selectedTextBg!.a < 0.8
                                    ? 'Semi'
                                    : 'Solid',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Text input
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: _selectedTextBg != null
                        ? const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8)
                        : null,
                    decoration: _selectedTextBg != null
                        ? BoxDecoration(
                            color: _selectedTextBg,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      textAlign: _selectedTextAlign,
                      maxLines: null,
                      style: TextStyle(
                        fontFamily: _selectedFontFamily,
                        color: _selectedTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add text...',
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Color picker
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _colorPalette.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _colorPalette[index];
                  final isSelected = color == _selectedTextColor;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTextColor = color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 36 : 28,
                      height: isSelected ? 36 : 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white30,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmTextOverlay() {
    final text = _textController.text.trim();
    HapticFeedback.lightImpact();
    setState(() {
      if (text.isNotEmpty) {
        if (_editingTextIndex != null) {
          // Update existing
          _textOverlays[_editingTextIndex!]
            ..text = text
            ..color = _selectedTextColor
            ..backgroundColor = _selectedTextBg
            ..fontFamily = _selectedFontFamily
            ..textAlign = _selectedTextAlign;
        } else {
          // Add new
          _textOverlays.add(_TextOverlayData(
            text: text,
            color: _selectedTextColor,
            backgroundColor: _selectedTextBg,
            fontFamily: _selectedFontFamily,
            textAlign: _selectedTextAlign,
          ));
        }
      }
      _showTextInput = false;
      _activeTool = _ActiveTool.none;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // DRAGGABLE TEXT OVERLAY
  // ═══════════════════════════════════════════════════════════

  Widget _buildDraggableText(int index, _TextOverlayData data) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: data.position.dx * screenSize.width - 80,
      top: data.position.dy * screenSize.height - 20,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            data.position = Offset(
              (data.position.dx + details.delta.dx / screenSize.width)
                  .clamp(0.05, 0.95),
              (data.position.dy + details.delta.dy / screenSize.height)
                  .clamp(0.05, 0.95),
            );
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            data.scale = (data.scale * details.scale).clamp(0.5, 3.0);
            data.rotation += details.rotation;
          });
        },
        onTap: () {
          // Edit text on tap
          HapticFeedback.lightImpact();
          setState(() {
            _editingTextIndex = index;
            _textController.text = data.text;
            _selectedTextColor = data.color;
            _selectedTextBg = data.backgroundColor;
            _selectedFontFamily = data.fontFamily;
            _selectedTextAlign = data.textAlign;
            _showTextInput = true;
            _activeTool = _ActiveTool.text;
          });
        },
        child: Transform.rotate(
          angle: data.rotation,
          child: Transform.scale(
            scale: data.scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: data.backgroundColor != null
                  ? BoxDecoration(
                      color: data.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Text(
                data.text,
                textAlign: data.textAlign,
                style: TextStyle(
                  fontFamily: data.fontFamily,
                  color: data.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LINK STICKER
  // ═══════════════════════════════════════════════════════════

  void _showLinkBottomSheet() {
    HapticFeedback.lightImpact();
    _linkUrlController.clear();
    _linkDisplayController.clear();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Link',
              style: StylesManager.semiBold(
                fontSize: FontSize.large,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // URL field
            TextField(
              controller: _linkUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Iconsax.link, color: Colors.white54, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // Display text field
            TextField(
              controller: _linkDisplayController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Display text (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Iconsax.text, color: Colors.white54, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final url = _linkUrlController.text.trim();
                  if (url.isEmpty) return;
                  HapticFeedback.mediumImpact();
                  final display = _linkDisplayController.text.trim().isNotEmpty
                      ? _linkDisplayController.text.trim()
                      : _extractDomain(url);
                  setState(() {
                    _linkStickers.add(_LinkStickerData(
                      url: url,
                      displayText: display,
                    ));
                  });
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Add Link',
                  style: StylesManager.semiBold(fontSize: FontSize.medium),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Widget _buildDraggableLinkSticker(int index, _LinkStickerData data) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: data.position.dx * screenSize.width - 70,
      top: data.position.dy * screenSize.height - 20,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            data.position = Offset(
              (data.position.dx + details.delta.dx / screenSize.width)
                  .clamp(0.05, 0.95),
              (data.position.dy + details.delta.dy / screenSize.height)
                  .clamp(0.05, 0.95),
            );
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            data.scale = (data.scale * details.scale).clamp(0.5, 2.0);
          });
        },
        onLongPress: () {
          // Remove on long press
          HapticFeedback.mediumImpact();
          setState(() => _linkStickers.removeAt(index));
        },
        child: Transform.scale(
          scale: data.scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.link, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      data.displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMOJI PICKER & OVERLAY
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmojiPicker() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Emoji grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _popularEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _emojiOverlays.add(_EmojiOverlayData(
                          emoji: _popularEmojis[index],
                          position: Offset(
                            0.3 + Random().nextDouble() * 0.4,
                            0.3 + Random().nextDouble() * 0.3,
                          ),
                        ));
                        _activeTool = _ActiveTool.none;
                      });
                    },
                    child: Center(
                      child: Text(
                        _popularEmojis[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableEmoji(int index, _EmojiOverlayData data) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: data.position.dx * screenSize.width - 24,
      top: data.position.dy * screenSize.height - 24,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            data.position = Offset(
              (data.position.dx + details.delta.dx / screenSize.width)
                  .clamp(0.05, 0.95),
              (data.position.dy + details.delta.dy / screenSize.height)
                  .clamp(0.05, 0.95),
            );
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            data.scale = (data.scale * details.scale).clamp(0.5, 4.0);
            data.rotation += details.rotation;
          });
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _emojiOverlays.removeAt(index));
        },
        child: Transform.rotate(
          angle: data.rotation,
          child: Transform.scale(
            scale: data.scale,
            child: Text(
              data.emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOCATION BADGE
  // ═══════════════════════════════════════════════════════════

  Widget _buildLocationBadge() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.location, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _placeName!,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openLocationPicker();
                    },
                    child: Icon(Iconsax.edit_2,
                        color: Colors.white.withValues(alpha: 0.7), size: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRequiredBadge() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isLocationLoading ? null : _openLocationPicker,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLocationLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Iconsax.location,
                          color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isLocationLoading
                          ? 'Getting location...'
                          : 'Tap to add location',
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPLOAD OVERLAY — Animated Progress
  // ═══════════════════════════════════════════════════════════

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _uploadProgressController,
              builder: (context, child) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: _UploadRingPainter(
                      progress: _uploadProgressController.value,
                    ),
                    child: Center(
                      child: _uploadProgressController.value >= 1.0
                          ? const Icon(Iconsax.tick_circle,
                              color: Colors.white, size: 36)
                          : Text(
                              '${(_uploadProgressController.value * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Posting story...',
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═════════════════════════════════════════════════════════════

class _DrawingPainter extends CustomPainter {
  final List<_DrawingPath> paths;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;

  _DrawingPainter({
    required this.paths,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed paths
    for (final path in paths) {
      _drawPath(canvas, path.points, path.color, path.strokeWidth);
    }
    // Draw current (in-progress) path
    if (currentPoints.isNotEmpty) {
      _drawPath(canvas, currentPoints, currentColor, currentStrokeWidth);
    }
  }

  void _drawPath(
      Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      // Smooth curves using quadratic bezier
      final p0 = points[i - 1];
      final p1 = points[i];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}

class _UploadRingPainter extends CustomPainter {
  final double progress;

  _UploadRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF31A354) // Primary green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_UploadRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
