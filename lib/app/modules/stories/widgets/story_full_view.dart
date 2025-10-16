import 'dart:io';
import 'dart:async';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class StoryFullView extends StatefulWidget {
  final StoryModel story;
  final int userIndex;
  final int storyIndex;

  const StoryFullView({
    super.key,
    required this.story,
    required this.userIndex,
    required this.storyIndex,
  });

  @override
  State<StoryFullView> createState() => _StoryFullViewState();
}

class _StoryFullViewState extends State<StoryFullView>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _initializeStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeStory() {
    final duration = widget.story.duration ?? 5;
    _progressController = AnimationController(
      duration: Duration(seconds: duration),
      vsync: this,
    );

    // تحديث حالة المشاهدة
    final controller = Get.find<StoriesController>();
    if (widget.story.id != null) {
      controller.markStoryAsViewed(widget.story.id!);
    }

    if (widget.story.storyType == StoryType.video &&
        widget.story.storyFileUrl != null) {
      _initializeVideo(widget.story.storyFileUrl!);
    } else {
      _startProgress();
    }
  }

  void _initializeVideo(String videoUrl) async {
    try {
      print('🎥 Initializing video: $videoUrl');
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController!.play();
      _videoController!.addListener(_onVideoProgress);
    } catch (e) {
      print('❌ Error initializing video: $e');
      _startProgress();
    }
  }

  void _onVideoProgress() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final progress = _videoController!.value.position.inMilliseconds /
          _videoController!.value.duration.inMilliseconds;
      _progressController.value = progress;

      if (progress >= 1.0) {
        _nextStory();
      }
    }
  }

  void _startProgress() {
    print('⏱️ Starting story progress');
    _progressController.forward().then((_) {
      _nextStory();
    });
  }

  void _nextStory() {
    print('➡️ Moving to next story');
    final controller = Get.find<StoriesController>();

    // إذا كان المستخدم الحالي
    if (controller.isViewingCurrentUserStories.value) {
      if (controller.currentStoryIndex.value <
          controller.userStories.length - 1) {
        controller.currentStoryIndex.value++;
      } else {
        Navigator.pop(context);
      }
    } else {
      controller.nextStory();
    }
    Navigator.pop(context);
  }

  void _previousStory() {
    print('⬅️ Moving to previous story');
    final controller = Get.find<StoriesController>();

    // إذا كان المستخدم الحالي
    if (controller.isViewingCurrentUserStories.value) {
      if (controller.currentStoryIndex.value > 0) {
        controller.currentStoryIndex.value--;
      } else {
        Navigator.pop(context);
      }
    } else {
      controller.previousStory();
    }
    Navigator.pop(context);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _progressController.stop();
      _videoController?.pause();
    } else {
      _progressController.forward();
      _videoController?.play();
    }
  }

  // دالة للتعامل مع الضغط الطويل
  void _onLongPressStart() {
    if (!_isLongPressing) {
      setState(() {
        _isLongPressing = true;
      });

      // إيقاف التشغيل عند الضغط الطويل
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      _videoController?.pause();

      print('⏸️ Long press started - Story paused');
    }
  }

  // دالة للتعامل مع رفع الإصبع
  void _onLongPressEnd() {
    if (_isLongPressing) {
      setState(() {
        _isLongPressing = false;
      });

      // استئناف التشغيل عند رفع الإصبع
      if (!_isPaused && _progressController.value < 1.0) {
        _progressController.forward();
      }
      if (!_isPaused) {
        _videoController?.play();
      }

      print('▶️ Long press ended - Story resumed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story content
          _buildStoryContent(),

          // Progress bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildProgressBar(),
          ),

          // User info
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: _buildUserInfo(),
          ),

          // Controls
          _buildControls(),

          // Close button with long press support
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              onLongPressStart: (_) => _onLongPressStart(),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onLongPressCancel: () => _onLongPressEnd(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Pause/Play button with long press support
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: _togglePause,
              onLongPressStart: (_) => _onLongPressStart(),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onLongPressCancel: () => _onLongPressEnd(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Story type indicator
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStoryTypeText(widget.story.storyType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Long press indicator
          if (_isLongPressing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Story Paused',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Release to continue',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
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

  Widget _buildStoryContent() {
    switch (widget.story.storyType) {
      case StoryType.image:
        return _buildImageStory();
      case StoryType.video:
        return _buildVideoStory();
      case StoryType.text:
        return _buildTextStory();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageStory() {
    if (widget.story.storyFileUrl == null) {
      return const Center(
        child: Text(
          'No image available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        widget.story.storyFileUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoStory() {
    if (widget.story.storyFileUrl == null || !_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildTextStory() {
    if (widget.story.storyText == null) {
      return const Center(
        child: Text(
          'No text available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Color backgroundColor = Colors.black;
    Color textColor = Colors.white;
    double fontSize = widget.story.fontSize ?? 24.0;

    if (widget.story.backgroundColor != null) {
      backgroundColor = _parseColor(widget.story.backgroundColor!);
    }
    if (widget.story.textColor != null) {
      textColor = _parseColor(widget.story.textColor!);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            widget.story.storyText!,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      print('Error parsing color: $e');
    }
    return Colors.white;
  }

  Widget _buildProgressBar() {
    final currentUserId = UserService.currentUser.value?.uid;
    final isViewed = widget.story.isViewedBy(currentUserId ?? '');

    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: isViewed
            ? Colors.white.withOpacity(0.6)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressController.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo() {
    final controller = Get.find<StoriesController>();
    final currentUser = controller.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: currentUser?.imageUrl != null &&
                    currentUser!.imageUrl!.isNotEmpty
                ? NetworkImage(currentUser.imageUrl!)
                : const AssetImage('assets/images/Profile Image111.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.fullName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTimeAgo(widget.story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                // مؤشر حالة المشاهدة
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      widget.story.isViewedBy(
                              UserService.currentUser.value?.uid ?? '')
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: widget.story.isViewedBy(
                              UserService.currentUser.value?.uid ?? '')
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.5),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.story.isViewedBy(
                              UserService.currentUser.value?.uid ?? '')
                          ? 'Viewed'
                          : 'Not viewed',
                      style: TextStyle(
                        color: widget.story.isViewedBy(
                                UserService.currentUser.value?.uid ?? '')
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Story type icon
          Icon(
            _getStoryTypeIcon(widget.story.storyType),
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  IconData _getStoryTypeIcon(StoryType? storyType) {
    switch (storyType) {
      case StoryType.image:
        return Icons.image;
      case StoryType.video:
        return Icons.video_library;
      case StoryType.text:
        return Icons.text_fields;
      default:
        return Icons.article;
    }
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // منطقة للانتقال للقصة السابقة
            Expanded(
              child: GestureDetector(
                onTap: _previousStory,
                onLongPressStart: (_) => _onLongPressStart(),
                onLongPressEnd: (_) => _onLongPressEnd(),
                onLongPressCancel: () => _onLongPressEnd(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // منطقة للانتقال للقصة التالية
            Expanded(
              child: GestureDetector(
                onTap: _nextStory,
                onLongPressStart: (_) => _onLongPressStart(),
                onLongPressEnd: (_) => _onLongPressEnd(),
                onLongPressCancel: () => _onLongPressEnd(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getStoryTypeText(StoryType? storyType) {
    switch (storyType) {
      case StoryType.image:
        return 'صورة';
      case StoryType.video:
        return 'فيديو';
      case StoryType.text:
        return 'نص';
      default:
        return 'قصة';
    }
  }
}
