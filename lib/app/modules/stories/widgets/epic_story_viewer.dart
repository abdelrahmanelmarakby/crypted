import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/story_cluster.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:video_player/video_player.dart';

/// Epic Story Viewer - Smoother than Snapchat! 🔥
class EpicStoryViewer extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final StoryCluster? cluster;

  const EpicStoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.cluster,
  });

  @override
  State<EpicStoryViewer> createState() => _EpicStoryViewerState();
}

class _EpicStoryViewerState extends State<EpicStoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _scaleController;

  int currentStoryIndex = 0;
  bool isPaused = false;
  VideoPlayerController? _videoController;
  Timer? _progressTimer;

  // Gesture tracking
  Offset? _longPressStart;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentStoryIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Enter animation
    _scaleController.forward();

    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startStory() async {
    final story = widget.stories[currentStoryIndex];

    // Reset progress
    _progressController.reset();

    // Handle video stories
    if (story.storyType == StoryType.video && story.storyFileUrl != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(story.storyFileUrl!);

      try {
        await _videoController!.initialize();
        await _videoController!.play();

        _progressController.duration = _videoController!.value.duration;
        _progressController.forward();

        _videoController!.addListener(() {
          if (_videoController!.value.position ==
              _videoController!.value.duration) {
            _nextStory();
          }
        });
      } catch (e) {
        print('Error loading video: $e');
        _nextStory();
      }
    } else {
      // Image or text story
      final duration = Duration(seconds: story.duration ?? 5);
      _progressController.duration = duration;
      _progressController.forward();

      _progressTimer = Timer(duration, () {
        if (!isPaused) _nextStory();
      });
    }

    setState(() {});
  }

  void _nextStory() {
    if (currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        currentStoryIndex++;
      });
      _pageController.animateToPage(
        currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      _exitViewer();
    }
  }

  void _previousStory() {
    if (currentStoryIndex > 0) {
      setState(() {
        currentStoryIndex--;
      });
      _pageController.animateToPage(
        currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _pauseStory() {
    setState(() {
      isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
    _progressTimer?.cancel();
  }

  void _resumeStory() {
    setState(() {
      isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();

    // Restart timer for remaining time
    if (_videoController == null) {
      final story = widget.stories[currentStoryIndex];
      final remainingDuration = Duration(
        milliseconds: ((1 - _progressController.value) *
                (story.duration ?? 5) *
                1000)
            .toInt(),
      );
      _progressTimer = Timer(remainingDuration, () {
        if (!isPaused) _nextStory();
      });
    }
  }

  void _exitViewer() async {
    await _scaleController.reverse();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: (details) {
            final width = Get.width;
            final tapX = details.globalPosition.dx;

            if (tapX < width / 3) {
              // Left tap - previous story
              _previousStory();
            } else if (tapX > width * 2 / 3) {
              // Right tap - next story
              _nextStory();
            }
          },
          onLongPressStart: (details) {
            _longPressStart = details.globalPosition;
            _isLongPressing = true;
            _pauseStory();
          },
          onLongPressEnd: (details) {
            _isLongPressing = false;
            _resumeStory();
          },
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 10) {
              // Swipe down to exit
              _exitViewer();
            }
          },
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(
                scale: Curves.easeOutCubic.transform(_scaleController.value),
                child: Opacity(
                  opacity: _scaleController.value,
                  child: child,
                ),
              );
            },
            child: Stack(
              children: [
                // Story Content
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.stories.length,
                  itemBuilder: (context, index) {
                    return _buildStoryContent(widget.stories[index]);
                  },
                ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
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
                  ),
                ),

                // Progress bars
                _buildProgressBars(),

                // Top info bar
                _buildTopBar(),

                // Location badge (if available)
                if (widget.stories[currentStoryIndex].hasLocation)
                  _buildLocationBadge(),

                // Long press hint
                if (_isLongPressing) _buildPauseIndicator(),

                // Tap zones indicator (show briefly on start)
                if (_shouldShowTapZones()) _buildTapZonesHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background based on story type
        if (story.storyType == StoryType.image && story.storyFileUrl != null)
          Image.network(
            story.storyFileUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              );
            },
          )
        else if (story.storyType == StoryType.video && _videoController != null)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else if (story.storyType == StoryType.text)
          Container(
            color: Color(
              int.parse(
                  story.backgroundColor?.replaceAll('#', '0xFF') ?? '0xFF000000'),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  story.storyText ?? '',
                  style: TextStyle(
                    color: Color(
                      int.parse(
                          story.textColor?.replaceAll('#', '0xFF') ?? '0xFFFFFFFF'),
                    ),
                    fontSize: story.fontSize ?? 32,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // Blur effect when paused
        if (isPaused)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBars() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(
            widget.stories.length,
            (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      double progress = 0.0;
                      if (index < currentStoryIndex) {
                        progress = 1.0;
                      } else if (index == currentStoryIndex) {
                        progress = _progressController.value;
                      }

                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final story = widget.stories[currentStoryIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: story.user?.imageUrl != null
                    ? Image.network(
                        story.user!.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: ColorsManager.primary,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story.user?.fullName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (story.remainingTime != null)
                    Text(
                      _formatTimeAgo(story.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: _exitViewer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    final story = widget.stories[currentStoryIndex];

    return Positioned(
      bottom: 100,
      left: 20,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: ColorsManager.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                story.locationString,
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
    );
  }

  Widget _buildPauseIndicator() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pause,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildTapZonesHint() {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTapZones() {
    // Show for first 2 seconds only
    return false; // Implement logic if needed
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
