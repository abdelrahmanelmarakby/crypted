import 'dart:io';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
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

    _startProgress();
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
    controller.nextStory();
    Navigator.pop(context);
  }

  void _previousStory() {
    print('⬅️ Moving to previous story');
    final controller = Get.find<StoriesController>();
    controller.previousStory();
    Navigator.pop(context);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _progressController.stop();
    } else {
      _progressController.forward();
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

          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),

          // Pause/Play button
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _togglePause,
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          // Navigation controls
          _buildNavigationControls(),
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
        return const Center(
          child: Text(
            'Unsupported story type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildImageStory() {
    if (widget.story.storyFileUrl == null ||
        widget.story.storyFileUrl!.isEmpty) {
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
    if (widget.story.storyFileUrl == null ||
        widget.story.storyFileUrl!.isEmpty) {
      return const Center(
        child: Text(
          'No video available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Video Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Video playback not implemented yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStory() {
    if (widget.story.storyText == null || widget.story.storyText!.isEmpty) {
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

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
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
            backgroundImage: widget.story.user?.imageUrl != null &&
                    widget.story.user!.imageUrl!.isNotEmpty
                ? NetworkImage(widget.story.user!.imageUrl!)
                : const AssetImage('assets/images/Profile Image111.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.user?.fullName ?? 'Unknown',
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

  Widget _buildNavigationControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // Previous story area
            Expanded(
              child: GestureDetector(
                onTap: _previousStory,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Next story area
            Expanded(
              child: GestureDetector(
                onTap: _nextStory,
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
}
