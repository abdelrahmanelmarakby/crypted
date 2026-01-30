import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/views/story_preview_screen.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

/// Instagram-quality camera story screen.
///
/// Features: Photo + Video capture, mode pills, animated shutter,
/// frosted glass UI, camera filters, gallery thumbnail, pinch-to-zoom,
/// recording timer, and haptic feedback throughout.
class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

enum _CaptureMode { photo, video, text }

class _StoryCameraScreenState extends State<StoryCameraScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // ── Camera state ──────────────────────────────────────────
  FlashMode _flashMode = FlashMode.none;
  bool _isCapturing = false;
  _CaptureMode _captureMode = _CaptureMode.photo;

  // ── Recording timer ───────────────────────────────────────
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  static const int _maxRecordingSeconds = 60;

  // ── Filters ───────────────────────────────────────────────
  bool _showFilters = false;
  int _selectedFilterIndex = 0;
  static final List<AwesomeFilter> _filters = [
    AwesomeFilter.None,
    AwesomeFilter.Aden,
    AwesomeFilter.Amaro,
    AwesomeFilter.Clarendon,
    AwesomeFilter.Gingham,
    AwesomeFilter.Hudson,
    AwesomeFilter.Juno,
    AwesomeFilter.Lark,
    AwesomeFilter.LoFi,
    AwesomeFilter.Moon,
    AwesomeFilter.Perpetua,
    AwesomeFilter.Reyes,
    AwesomeFilter.Sierra,
    AwesomeFilter.Slumber,
    AwesomeFilter.Walden,
    AwesomeFilter.XProII,
  ];
  static final List<String> _filterNames = [
    'Original',
    'Aden',
    'Amaro',
    'Clarendon',
    'Gingham',
    'Hudson',
    'Juno',
    'Lark',
    'Lo-Fi',
    'Moon',
    'Perpetua',
    'Reyes',
    'Sierra',
    'Slumber',
    'Walden',
    'X-Pro II',
  ];

  // ── Gallery thumbnail ─────────────────────────────────────
  Uint8List? _galleryThumbnail;

  // ── Zoom ──────────────────────────────────────────────────
  double _currentZoom = 0.0;
  double _baseZoom = 0.0;

  // ── Text story mode ───────────────────────────────────────
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

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _shutterScaleController;
  late final AnimationController _recordRingController;

  @override
  void initState() {
    super.initState();
    _loadGalleryThumbnail();

    _shutterScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );

    _recordRingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxRecordingSeconds),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _recordingTimer?.cancel();
    _shutterScaleController.dispose();
    _recordRingController.dispose();
    super.dispose();
  }

  // ── Gallery thumbnail ─────────────────────────────────────

  Future<void> _loadGalleryThumbnail() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return;

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );
      if (albums.isEmpty) return;

      final recentAlbum = albums.first;
      final assets = await recentAlbum.getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) return;

      final thumb = await assets.first.thumbnailDataWithSize(
        const ThumbnailSize(80, 80),
        quality: 80,
      );
      if (thumb != null && mounted) {
        setState(() => _galleryThumbnail = thumb);
      }
    } catch (_) {
      // Gallery thumbnail is non-critical — ignore errors
    }
  }

  // ── Flash helpers ─────────────────────────────────────────

  void _cycleFlash(CameraState state) {
    HapticFeedback.selectionClick();
    const modes = [FlashMode.none, FlashMode.auto, FlashMode.on, FlashMode.always];
    final idx = modes.indexOf(_flashMode);
    final next = modes[(idx + 1) % modes.length];
    state.sensorConfig.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.none:
        return Iconsax.flash_slash;
      case FlashMode.auto:
        return Iconsax.flash_1;
      case FlashMode.on:
        return Iconsax.flash_1;
      case FlashMode.always:
        return Iconsax.flash_1;
    }
  }

  String _flashLabel() {
    switch (_flashMode) {
      case FlashMode.none:
        return 'Off';
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.on:
        return 'On';
      case FlashMode.always:
        return 'Always';
    }
  }

  // ── Gallery pickers ───────────────────────────────────────

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
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
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        Get.off(
          () => StoryPreviewScreen(
            mediaFile: File(pickedFile.path),
            storyType: StoryType.video,
          ),
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  // ── Recording timer ───────────────────────────────────────

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingSeconds++;
        if (_recordingSeconds >= _maxRecordingSeconds) {
          // Auto-stop handled by the caller checking this
          timer.cancel();
        }
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Text story ────────────────────────────────────────────

  void _submitTextStory() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();

    Get.off(
      () => StoryPreviewScreen(
        storyType: StoryType.text,
        storyText: text,
        backgroundColor: _selectedBgColor,
      ),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
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

  // ── Mode switching ────────────────────────────────────────

  void _switchMode(_CaptureMode mode, CameraState? cameraState) {
    if (mode == _captureMode) return;
    HapticFeedback.selectionClick();

    setState(() => _captureMode = mode);

    // Switch CamerAwesome capture mode for photo/video
    if (mode == _CaptureMode.photo && cameraState != null) {
      cameraState.setState(CaptureMode.photo);
    } else if (mode == _CaptureMode.video && cameraState != null) {
      cameraState.setState(CaptureMode.video);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _captureMode == _CaptureMode.text
          ? _buildTextMode()
          : _buildCameraMode(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CAMERA MODE
  // ═══════════════════════════════════════════════════════════

  Widget _buildCameraMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photoAndVideo(
          initialCaptureMode: _captureMode == _CaptureMode.video
              ? CaptureMode.video
              : CaptureMode.photo,
        ),
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          flashMode: _flashMode,
          aspectRatio: CameraAspectRatios.ratio_16_9,
        ),
        builder: (cameraState, preview) {
          return GestureDetector(
            // Pinch-to-zoom
            onScaleStart: (_) => _baseZoom = _currentZoom,
            onScaleUpdate: (details) {
              final newZoom = (_baseZoom + (details.scale - 1) * 0.5).clamp(0.0, 1.0);
              cameraState.sensorConfig.setZoom(newZoom);
              setState(() => _currentZoom = newZoom);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview is rendered by CamerAwesome behind this stack

                // Dispatch UI based on camera state
                cameraState.when(
                  onPreparingCamera: (state) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  onPhotoMode: (state) =>
                      _buildCameraUI(cameraState: state, isVideoMode: false),
                  onVideoMode: (state) =>
                      _buildCameraUI(cameraState: state, isVideoMode: true),
                  onVideoRecordingMode: (state) =>
                      _buildRecordingUI(state: state),
                ),
              ],
            ),
          );
        },
        onMediaCaptureEvent: (event) {
          switch ((event.status, event.isPicture, event.isVideo)) {
            // ── Photo events ──
            case (MediaCaptureStatus.capturing, true, false):
              if (mounted) setState(() => _isCapturing = true);
            case (MediaCaptureStatus.success, true, false):
              event.captureRequest.when(
                single: (single) {
                  final xFile = single.file;
                  if (xFile != null && mounted) {
                    HapticFeedback.mediumImpact();
                    Get.off(
                      () => StoryPreviewScreen(
                        mediaFile: File(xFile.path),
                        storyType: StoryType.image,
                      ),
                      transition: Transition.downToUp,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
                multiple: (_) {},
              );
            case (MediaCaptureStatus.failure, true, false):
              if (mounted) setState(() => _isCapturing = false);

            // ── Video events ──
            case (MediaCaptureStatus.capturing, false, true):
              if (mounted) {
                _startRecordingTimer();
                _recordRingController.forward(from: 0.0);
                HapticFeedback.heavyImpact();
              }
            case (MediaCaptureStatus.success, false, true):
              _stopRecordingTimer();
              _recordRingController.stop();
              event.captureRequest.when(
                single: (single) {
                  final xFile = single.file;
                  if (xFile != null && mounted) {
                    HapticFeedback.mediumImpact();
                    Get.off(
                      () => StoryPreviewScreen(
                        mediaFile: File(xFile.path),
                        storyType: StoryType.video,
                      ),
                      transition: Transition.downToUp,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
                multiple: (_) {},
              );
            case (MediaCaptureStatus.failure, false, true):
              if (mounted) {
                _stopRecordingTimer();
                _recordRingController.stop();
              }

            default:
              break;
          }
        },
      ),
    );
  }

  // ── Main Camera UI (Photo & Video idle) ───────────────────

  Widget _buildCameraUI({
    required CameraState cameraState,
    required bool isVideoMode,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Top bar (frosted glass) ──
        _buildFrostedTopBar(cameraState),

        // ── Recording timer badge (hidden when not recording) ──
        // Only relevant during recording — not shown in idle state

        // ── Filter strip (shown/hidden) ──
        if (_showFilters) _buildFilterStrip(cameraState),

        // ── Bottom area: gallery, shutter, mode pills ──
        _buildBottomArea(cameraState, isVideoMode),

        // ── Zoom indicator ──
        if (_currentZoom > 0.01) _buildZoomIndicator(),
      ],
    );
  }

  // ── Recording UI ──────────────────────────────────────────

  Widget _buildRecordingUI({required VideoRecordingCameraState state}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top bar with recording timer
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: Center(
            child: _buildRecordingBadge(),
          ),
        ),

        // Stop button (centered at bottom)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 40,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stop/shutter button with progress ring
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  state.stopRecording();
                },
                child: _buildRecordingShutter(),
              ),
              const SizedBox(height: 20),
              // Mode label
              Text(
                'RECORDING',
                style: StylesManager.semiBold(
                  fontSize: FontSize.xSmall,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FROSTED GLASS TOP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildFrostedTopBar(CameraState cameraState) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close
          _buildFrostedButton(
            icon: Iconsax.close_circle,
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
          ),
          Row(
            children: [
              // Flash with label
              _buildFrostedButton(
                icon: _flashIcon(),
                label: _flashLabel(),
                onTap: () => _cycleFlash(cameraState),
              ),
              const SizedBox(width: 10),
              // Flip camera
              _buildFrostedButton(
                icon: Iconsax.refresh,
                onTap: () {
                  HapticFeedback.selectionClick();
                  cameraState.switchCameraSensor();
                },
              ),
              const SizedBox(width: 10),
              // Filters toggle
              _buildFrostedButton(
                icon: Iconsax.magic_star,
                isActive: _showFilters,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showFilters = !_showFilters);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    String? label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(label != null ? 20 : 22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: label != null ? 14 : 0),
            constraints: BoxConstraints(minWidth: label != null ? 0 : 40),
            decoration: BoxDecoration(
              color: isActive
                  ? ColorsManager.primary.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(label != null ? 20 : 22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FILTER STRIP
  // ═══════════════════════════════════════════════════════════

  Widget _buildFilterStrip(CameraState cameraState) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 170,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final isSelected = index == _selectedFilterIndex;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilterIndex = index);
                cameraState.setFilter(_filters[index]);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? ColorsManager.primary : Colors.white30,
                        width: isSelected ? 2.5 : 1,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: isSelected ? 0.3 : 0.1),
                          Colors.white.withValues(alpha: isSelected ? 0.15 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _filterNames[index].substring(0, _filterNames[index].length > 2 ? 2 : _filterNames[index].length),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _filterNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM AREA: Gallery, Shutter, Mode Pills
  // ═══════════════════════════════════════════════════════════

  Widget _buildBottomArea(CameraState cameraState, bool isVideoMode) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main row: gallery, shutter, text-story shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery thumbnail
              _buildGalleryButton(),

              // Shutter button
              _buildShutterButton(cameraState, isVideoMode),

              // Text story shortcut (visible only in photo mode)
              _captureMode == _CaptureMode.photo
                  ? _buildBottomAction(
                      icon: Iconsax.text,
                      label: 'Text',
                      onTap: () => _switchMode(_CaptureMode.text, cameraState),
                    )
                  : const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 16),
          // Mode pills
          _buildModePills(cameraState),
        ],
      ),
    );
  }

  // ── Gallery button ────────────────────────────────────────

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _pickFromGallery,
      onLongPress: _pickVideoFromGallery,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white38, width: 1.5),
              image: _galleryThumbnail != null
                  ? DecorationImage(
                      image: MemoryImage(_galleryThumbnail!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: _galleryThumbnail == null
                  ? Colors.black.withValues(alpha: 0.4)
                  : null,
            ),
            child: _galleryThumbnail == null
                ? const Icon(Iconsax.gallery, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Gallery',
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shutter button ────────────────────────────────────────

  Widget _buildShutterButton(CameraState cameraState, bool isVideoMode) {
    return GestureDetector(
      onTapDown: (_) => _shutterScaleController.reverse(),
      onTapUp: (_) {
        _shutterScaleController.forward();
        if (isVideoMode) {
          // In video mode: tap to start recording
          if (cameraState is VideoCameraState) {
            cameraState.startRecording();
          }
        } else {
          // In photo mode: tap to take photo
          HapticFeedback.mediumImpact();
          if (cameraState is PhotoCameraState) {
            cameraState.takePhoto();
          }
        }
      },
      onTapCancel: () => _shutterScaleController.forward(),
      child: ScaleTransition(
        scale: _shutterScaleController,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isVideoMode ? Colors.red : Colors.white,
              width: 4,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVideoMode
                  ? Colors.red
                  : (_isCapturing ? Colors.white54 : Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ── Recording shutter (with progress ring) ────────────────

  Widget _buildRecordingShutter() {
    return AnimatedBuilder(
      animation: _recordRingController,
      builder: (context, child) {
        return CustomPaint(
          painter: _RecordingRingPainter(
            progress: _recordRingController.value,
          ),
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Recording badge ───────────────────────────────────────

  Widget _buildRecordingBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing red dot
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: value),
                    ),
                  );
                },
                onEnd: () {
                  // This triggers a continuous pulse by rebuilding
                },
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mode pills ────────────────────────────────────────────

  Widget _buildModePills(CameraState cameraState) {
    final modes = [
      ('PHOTO', _CaptureMode.photo),
      ('VIDEO', _CaptureMode.video),
      ('TEXT', _CaptureMode.text),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: modes.map((entry) {
        final (label, mode) = entry;
        final isActive = _captureMode == mode;
        return GestureDetector(
          onTap: () => _switchMode(mode, cameraState),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 20 : 0,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Bottom action helper ──────────────────────────────────

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
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

  // ── Zoom indicator ────────────────────────────────────────

  Widget _buildZoomIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(_currentZoom * 10 + 1).toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
  // TEXT STORY MODE
  // ═══════════════════════════════════════════════════════════

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
                  _buildFrostedButton(
                    icon: Iconsax.arrow_left,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _captureMode = _CaptureMode.photo);
                    },
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBgColor = color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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

// ═════════════════════════════════════════════════════════════
// RECORDING PROGRESS RING PAINTER
// ═════════════════════════════════════════════════════════════

class _RecordingRingPainter extends CustomPainter {
  final double progress;

  _RecordingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      2 * 3.14159 * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RecordingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
