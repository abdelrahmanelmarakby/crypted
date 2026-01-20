import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/media_gallery/controllers/media_gallery_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Full-screen media viewer for photos and videos
class MediaViewerView extends StatefulWidget {
  const MediaViewerView({super.key});

  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  late PageController _pageController;
  late List<MessageModel> _items;
  late MediaType _type;
  late String? _roomName;
  late int _currentIndex;

  bool _showControls = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    _items = args['items'] as List<MessageModel>;
    _currentIndex = args['initialIndex'] as int? ?? 0;
    _type = args['type'] as MediaType? ?? MediaType.photos;
    _roomName = args['roomName'] as String?;

    _pageController = PageController(initialPage: _currentIndex);

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize video if needed
    if (_type == MediaType.videos && _items.isNotEmpty) {
      _initializeVideo(_currentIndex);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideo(int index) async {
    final item = _items[index];
    final videoUrl = item.videoUrl;

    if (videoUrl == null || videoUrl.isEmpty) return;

    _videoController?.dispose();
    _isVideoInitialized = false;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController?.play();
      });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_type == MediaType.videos) {
      _initializeVideo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main content
            if (_type == MediaType.photos || _type == MediaType.videos)
              _buildMediaGallery()
            else if (_type == MediaType.audio)
              _buildAudioViewer()
            else
              _buildGenericViewer(),

            // Top controls
            if (_showControls) _buildTopControls(),

            // Bottom controls
            if (_showControls) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGallery() {
    if (_type == MediaType.videos) {
      return _buildVideoPlayer();
    }

    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      pageController: _pageController,
      itemCount: _items.length,
      onPageChanged: _onPageChanged,
      builder: (context, index) {
        final item = _items[index];
        final imageUrl = item.photoUrl ?? item.videoUrl;

        return PhotoViewGalleryPageOptions(
          imageProvider: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes: PhotoViewHeroAttributes(tag: item.messageId ?? ''),
        );
      },
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event == null
              ? 0
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          color: ColorsManager.primary,
        ),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildVideoPlayer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        if (index != _currentIndex) {
          // Show thumbnail for non-current videos
          final item = _items[index];
          return Center(
            child: item.videoUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.videoUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 64,
                    ),
                  )
                : const Icon(Icons.videocam, color: Colors.white, size: 64),
          );
        }

        if (!_isVideoInitialized || _videoController == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                // Play/Pause overlay
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _videoController!.value.isPlaying ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioViewer() {
    final item = _items[_currentIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.audiotrack,
              size: 64,
              color: ColorsManager.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            item.fileName ?? 'Audio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.audioDuration ?? '0:00',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericViewer() {
    final item = _items[_currentIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            item.fileName ?? 'File',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_roomName != null)
                        Text(
                          _roomName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        '${_currentIndex + 1} of ${_items.length}',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareCurrentMedia,
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: _downloadCurrentMedia,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_type != MediaType.videos || _videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    return Column(
                      children: [
                        Slider(
                          value: value.position.inMilliseconds.toDouble(),
                          min: 0,
                          max: value.duration.inMilliseconds.toDouble(),
                          onChanged: (newValue) {
                            _videoController!.seekTo(
                              Duration(milliseconds: newValue.toInt()),
                            );
                          },
                          activeColor: ColorsManager.primary,
                          inactiveColor: Colors.grey,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _shareCurrentMedia() {
    final controller = Get.find<MediaGalleryController>();
    final item = _items[_currentIndex];
    controller.shareMedia(item, _type);
  }

  void _downloadCurrentMedia() {
    final controller = Get.find<MediaGalleryController>();
    final item = _items[_currentIndex];
    controller.downloadMedia(item);
  }
}
