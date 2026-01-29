import 'dart:io';

import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_location_picker.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// Story preview/edit screen shown after capture or gallery pick.
///
/// Allows adding text overlay, location, and posting the story.
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

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final StoriesController _storiesController = Get.find<StoriesController>();

  // Text overlay state
  bool _showTextInput = false;
  final TextEditingController _textController = TextEditingController();
  String? _overlayText;
  Offset _textPosition = const Offset(0.5, 0.5); // Normalized (0-1)

  // Location state
  double? _latitude;
  double? _longitude;
  String? _placeName;

  // Upload state
  bool _isUploading = false;

  // Video preview
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.storyType == StoryType.text) {
      _overlayText = widget.storyText;
    }
    if (widget.storyType == StoryType.video && widget.mediaFile != null) {
      _videoController = VideoPlayerController.file(widget.mediaFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
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

  Future<void> _postStory() async {
    setState(() => _isUploading = true);

    try {
      await _storiesController.uploadStoryWithFile(
        file: widget.mediaFile,
        storyType: widget.storyType,
        overlayText: _overlayText,
        backgroundColor: widget.backgroundColor,
        latitude: _latitude,
        longitude: _longitude,
        placeName: _placeName,
      );

      if (mounted) {
        Get.back(); // Return to navbar
        Get.snackbar('Success', 'Story posted!',
            backgroundColor: ColorsManager.primary.withValues(alpha: 0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        Get.snackbar('Error', 'Failed to post story',
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white);
      }
    }
  }

  void _openLocationPicker() {
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

  void _toggleTextOverlay() {
    setState(() {
      _showTextInput = !_showTextInput;
      if (_showTextInput) {
        _textController.text = _overlayText ?? '';
      }
    });
  }

  void _confirmTextOverlay() {
    final text = _textController.text.trim();
    setState(() {
      _overlayText = text.isNotEmpty ? text : null;
      _showTextInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Preview content
            _buildPreviewContent(),

            // Text overlay (draggable)
            if (_overlayText != null && !_showTextInput)
              _buildDraggableTextOverlay(),

            // Top bar
            _buildTopBar(),

            // Bottom tools bar
            if (!_showTextInput) _buildBottomTools(),

            // Text input overlay
            if (_showTextInput) _buildTextInputOverlay(),

            // Upload progress
            if (_isUploading) _buildUploadOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Preview Content ─────────────────────────────────────────

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
    }
  }

  // ── Top Bar ─────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          // Post button
          GestureDetector(
            onTap: _isUploading ? null : _postStory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Post',
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Tools ────────────────────────────────────────────

  Widget _buildBottomTools() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location badge (if set)
          if (_placeName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
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
                    onTap: () => setState(() {
                      _latitude = null;
                      _longitude = null;
                      _placeName = null;
                    }),
                    child: const Icon(Icons.close, color: Colors.white70, size: 14),
                  ),
                ],
              ),
            ),

          // Tool buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToolButton(
                icon: Icons.location_on_outlined,
                label: 'Location',
                onTap: _openLocationPicker,
                isActive: _placeName != null,
              ),
              const SizedBox(width: 24),
              _buildToolButton(
                icon: Icons.text_fields_rounded,
                label: 'Text',
                onTap: _toggleTextOverlay,
                isActive: _overlayText != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorsManager.primary.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Draggable Text Overlay ──────────────────────────────────

  Widget _buildDraggableTextOverlay() {
    return Positioned(
      left: _textPosition.dx * MediaQuery.of(context).size.width - 100,
      top: _textPosition.dy * MediaQuery.of(context).size.height - 30,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _textPosition = Offset(
              (_textPosition.dx +
                      details.delta.dx / MediaQuery.of(context).size.width)
                  .clamp(0.1, 0.9),
              (_textPosition.dy +
                      details.delta.dy / MediaQuery.of(context).size.height)
                  .clamp(0.1, 0.9),
            );
          });
        },
        onTap: _toggleTextOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _overlayText!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Text Input Overlay ──────────────────────────────────────

  Widget _buildTextInputOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showTextInput = false),
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
            // Text input
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add text...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 24),
                      border: InputBorder.none,
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

  // ── Upload Overlay ──────────────────────────────────────────

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Posting story...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
