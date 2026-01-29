import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/views/story_preview_screen.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Full-screen camera story capture screen.
///
/// Uses the `camerawesome` package for reliable camera handling — avoids the
/// RangeError bug found in `camera_camera` with empty flash mode lists.
/// CamerAwesome manages its own native lifecycle, so no manual
/// `WidgetsBindingObserver` or `CameraController` boilerplate is needed.
class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  // Flash mode — kept in local state for icon display,
  // synced to camerawesome via state.sensorConfig.setFlashMode()
  FlashMode _flashMode = FlashMode.none;
  bool _isCapturing = false;

  // Text story mode
  bool _isTextMode = false;
  final TextEditingController _textController = TextEditingController();
  String _selectedBgColor = '#31A354';
  final List<String> _bgColors = [
    '#31A354',
    '#000000',
    '#1E88E5',
    '#E53935',
    '#FB8C00',
    '#8E24AA',
    '#00897B',
    '#F06292',
    '#5C6BC0',
    '#FFB300',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Flash helpers ───────────────────────────────────────────

  void _cycleFlash(CameraState state) {
    const modes = [FlashMode.none, FlashMode.auto, FlashMode.on, FlashMode.always];
    final idx = modes.indexOf(_flashMode);
    final next = modes[(idx + 1) % modes.length];
    state.sensorConfig.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.none:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.on:
        return Icons.flash_on;
      case FlashMode.always:
        return Icons.highlight;
    }
  }

  // ── Gallery pickers ─────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null && mounted) {
        Get.off(
          () => StoryPreviewScreen(
            mediaFile: File(pickedFile.path),
            storyType: StoryType.image,
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        Get.off(
          () => StoryPreviewScreen(
            mediaFile: File(pickedFile.path),
            storyType: StoryType.video,
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  // ── Text story ──────────────────────────────────────────────

  void _openTextStory() {
    setState(() => _isTextMode = true);
  }

  void _submitTextStory() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    Get.off(
      () => StoryPreviewScreen(
        storyType: StoryType.text,
        storyText: text,
        backgroundColor: _selectedBgColor,
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.black;
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _isTextMode ? _buildTextMode() : _buildCameraMode(),
    );
  }

  // ── Camera Mode ─────────────────────────────────────────────

  Widget _buildCameraMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photo(),
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          flashMode: _flashMode,
          aspectRatio: CameraAspectRatios.ratio_16_9,
        ),
        builder: (cameraState, preview) {
          return cameraState.when(
            onPreparingCamera: (state) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            onPhotoMode: (state) => _buildPhotoUI(state),
            onVideoMode: (state) => const SizedBox.shrink(),
            onVideoRecordingMode: (state) => const SizedBox.shrink(),
          );
        },
        onMediaCaptureEvent: (event) {
          switch ((event.status, event.isPicture, event.isVideo)) {
            case (MediaCaptureStatus.capturing, true, false):
              if (mounted) setState(() => _isCapturing = true);
            case (MediaCaptureStatus.success, true, false):
              event.captureRequest.when(
                single: (single) {
                  final xFile = single.file;
                  if (xFile != null && mounted) {
                    Get.off(
                      () => StoryPreviewScreen(
                        mediaFile: File(xFile.path),
                        storyType: StoryType.image,
                      ),
                    );
                  }
                },
                multiple: (_) {},
              );
            case (MediaCaptureStatus.failure, true, false):
              if (mounted) setState(() => _isCapturing = false);
            default:
              break;
          }
        },
      ),
    );
  }

  Widget _buildPhotoUI(PhotoCameraState state) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top bar — close, flash, flip
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: Icons.close,
                onTap: () => Get.back(),
              ),
              Row(
                children: [
                  _buildCircleButton(
                    icon: _flashIcon(),
                    onTap: () => _cycleFlash(state),
                  ),
                  const SizedBox(width: 12),
                  _buildCircleButton(
                    icon: Icons.flip_camera_ios,
                    onTap: () => state.switchCameraSensor(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom bar — gallery, shutter, text
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomAction(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                    onLongPress: _pickVideoFromGallery,
                  ),
                  // Shutter button
                  GestureDetector(
                    onTap: () => state.takePhoto(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  _buildBottomAction(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    onTap: _openTextStory,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
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

  // ── Text Story Mode ─────────────────────────────────────────

  Widget _buildTextMode() {
    final bgColor = _parseColor(_selectedBgColor);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => setState(() => _isTextMode = false),
                  ),
                  GestureDetector(
                    onTap: _submitTextStory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Next',
                        style: StylesManager.semiBold(
                          fontSize: FontSize.medium,
                          color: ColorsManager.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text input area — centered
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type your story...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),

            // Color picker bar
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _bgColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _bgColors[index];
                  final isSelected = color == _selectedBgColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBgColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
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
}
