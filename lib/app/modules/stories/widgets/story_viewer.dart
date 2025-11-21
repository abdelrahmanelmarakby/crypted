import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isPaused = false;
  int _currentStoryIndex = 0;
  int _currentUserIndex = 0;
  List<StoryModel> _currentUserStories = [];
  List<SocialMediaUser> _usersWithStories = [];
  VideoPlayerController? _videoController;

  // متغيرات جديدة للتحكم في التنقل والضغط
  bool _isLongPressing = false;
  Timer? _longPressTimer;

  // متغيرات للتحكم في السحب
  double _verticalDragDistance = 0.0;
  double _horizontalDragDistance = 0.0;
  bool _isDragging = false;

  // متغيرات للتحكم في الردود والتفاعلات
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _showReplyField = false;

  // متغيرات للتفاعلات السريعة
  bool _showReactions = false;
  String? _selectedReaction;
  final List<String> _reactionEmojis = ['❤️', '😂', '😮', '😢', '👏', '🔥'];

  @override
  void initState() {
    super.initState();
    _initializeStoryViewer();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _longPressTimer?.cancel();
    _replyController.dispose();
    _replyFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeStoryViewer() {
    final controller = Get.find<StoriesController>();
    final currentUser = UserService.currentUser.value;

    print('🔄 Initializing story viewer...');

    // التحقق من نوع الفتح - هل هو للمستخدم الحالي أم لمستخدم آخر
    final isViewingCurrentUserStories =
        controller.isViewingCurrentUserStories.value;

    if (isViewingCurrentUserStories &&
        currentUser != null &&
        controller.userStories.isNotEmpty) {
      // فتح ستوريز المستخدم الحالي
      print('👤 Opening current user stories: ${currentUser.fullName}');
      _usersWithStories = [currentUser];
      _currentUserIndex = 0;
      // ترتيب الاستوريز تصاعدياً (الأقدم أولاً)
      _currentUserStories = List.from(controller.userStories)
        ..sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));
      _currentStoryIndex = 0;

      print('📱 Current user stories: ${_currentUserStories.length}');
      print('📱 Current story index: $_currentStoryIndex');

      // تهيئة AnimationController
      _progressController = AnimationController(
        duration: Duration(seconds: 5),
        vsync: this,
      );

      if (_currentUserStories.isNotEmpty) {
        print('✅ Starting story progress...');
        print('📱 Total stories: ${_currentUserStories.length}');
        print('📱 Current story index: $_currentStoryIndex');
        _startStoryProgress();
      } else {
        print('❌ No stories found for current user');
      }
    } else {
      // فتح ستوريز المستخدمين الآخرين
      _usersWithStories = controller.getUsersWithStories();
      print('👥 Other users with stories: ${_usersWithStories.length}');

      if (_usersWithStories.isNotEmpty) {
        _currentUserIndex = controller.currentUserIndex.value;
        final currentUser = _usersWithStories[_currentUserIndex];

        // ترتيب الاستوريز تصاعدياً (الأقدم أولاً)
        _currentUserStories =
            List.from(controller.getStoriesForUser(currentUser.uid!))
              ..sort((a, b) => (a.createdAt ?? DateTime.now())
                  .compareTo(b.createdAt ?? DateTime.now()));
        _currentStoryIndex = controller.currentStoryIndex.value;

        print('👤 Other user: ${currentUser.fullName}');
        print('📱 Other user stories: ${_currentUserStories.length}');
        print('📱 Current story index: $_currentStoryIndex');

        // تهيئة AnimationController
        _progressController = AnimationController(
          duration: Duration(seconds: 5),
          vsync: this,
        );

        if (_currentUserStories.isNotEmpty) {
          print('✅ Starting story progress...');
          _startStoryProgress();
        } else {
          print('❌ No stories found for current user');
        }
      } else {
        print('❌ No users with stories found');
      }
    }
  }

  void _startStoryProgress() {
    if (_currentStoryIndex >= _currentUserStories.length) return;

    final story = _currentUserStories[_currentStoryIndex];
    final duration = story.duration ?? 5;

    // إيقاف الـ AnimationController السابق إذا كان موجوداً
    if (_progressController.isAnimating) {
      _progressController.stop();
    }

    // إعادة تعيين الـ AnimationController بدلاً من إنشاء واحد جديد
    _progressController.duration = Duration(seconds: duration);
    _progressController.reset();

    // تحديث حالة المشاهدة
    final controller = Get.find<StoriesController>();
    if (story.id != null) {
      controller.markStoryAsViewed(story.id!);
    }

    // بدء التشغيل مع الاستماع للأحداث
    _progressController.forward().then((_) {
      print('✅ Story progress completed, moving to next story');
      // تأخير قصير للتأكد من اكتمال العملية
      Future.delayed(Duration(milliseconds: 100), () {
        _nextStory();
      });
    }).catchError((error) {
      print('❌ Error in story progress: $error');
      // في حالة حدوث خطأ، الانتقال للستوري التالي
      Future.delayed(Duration(milliseconds: 100), () {
        _nextStory();
      });
    });
  }

  void _nextStory() {
    print('➡️ Moving to next story');

    // إيقاف التشغيل الحالي
    if (_progressController.isAnimating) {
      _progressController.stop();
    }

    if (_currentStoryIndex < _currentUserStories.length - 1) {
      // الانتقال للستوري التالي لنفس المستخدم
      setState(() {
        _currentStoryIndex++;
      });

      final controller = Get.find<StoriesController>();
      controller.currentStoryIndex.value = _currentStoryIndex;

      print(
          '📱 Moving to story ${_currentStoryIndex + 1} of ${_currentUserStories.length}');
      _startStoryProgress();
    } else {
      // الانتقال للمستخدم التالي
      print('👤 Moving to next user');
      _nextUser();
    }
  }

  void _previousStory() {
    print('⬅️ Moving to previous story');

    // إيقاف التشغيل الحالي
    if (_progressController.isAnimating) {
      _progressController.stop();
    }

    if (_currentStoryIndex > 0) {
      // الانتقال للستوري السابق لنفس المستخدم
      setState(() {
        _currentStoryIndex--;
      });

      final controller = Get.find<StoriesController>();
      controller.currentStoryIndex.value = _currentStoryIndex;

      _startStoryProgress();
    } else {
      // الانتقال للمستخدم السابق
      _previousUser();
    }
  }

  void _nextUser() {
    // إذا كان المستخدم الحالي، لا يوجد مستخدمين آخرين
    if (Get.find<StoriesController>().isViewingCurrentUserStories.value) {
      _closeStoryViewer();
      return;
    }

    if (_currentUserIndex < _usersWithStories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });

      final controller = Get.find<StoriesController>();
      controller.currentUserIndex.value = _currentUserIndex;
      controller.currentStoryIndex.value = 0;

      final currentUser = _usersWithStories[_currentUserIndex];
      // ترتيب الاستوريز تصاعدياً (الأقدم أولاً)
      _currentUserStories =
          List.from(controller.getStoriesForUser(currentUser.uid!))
            ..sort((a, b) => (a.createdAt ?? DateTime.now())
                .compareTo(b.createdAt ?? DateTime.now()));

      if (_currentUserStories.isNotEmpty) {
        _startStoryProgress();
      }
    } else {
      _closeStoryViewer();
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
      });

      final controller = Get.find<StoriesController>();
      controller.currentUserIndex.value = _currentUserIndex;

      final currentUser = _usersWithStories[_currentUserIndex];
      // ترتيب الاستوريز تصاعدياً (الأقدم أولاً)
      _currentUserStories =
          List.from(controller.getStoriesForUser(currentUser.uid!))
            ..sort((a, b) => (a.createdAt ?? DateTime.now())
                .compareTo(b.createdAt ?? DateTime.now()));
      _currentStoryIndex = _currentUserStories.length - 1;
      controller.currentStoryIndex.value = _currentStoryIndex;

      if (_currentUserStories.isNotEmpty) {
        _startStoryProgress();
      }
    }
  }

  void _closeStoryViewer() {
    final controller = Get.find<StoriesController>();
    controller.closeStoryViewer();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _progressController.stop();
    } else {
      _progressController.forward().then((_) {
        // التأكد من أن الستوري اكتمل
        if (_progressController.value >= 1.0) {
          print('✅ Story completed after pause, moving to next');
          _nextStory();
        }
      }).catchError((error) {
        print('❌ Error resuming story after pause: $error');
      });
    }
  }

  // دالة جديدة للتعامل مع الضغط الطويل
  void _onLongPressStart() {
    if (!_isLongPressing) {
      setState(() {
        _isLongPressing = true;
        _showReactions = true; // إظهار التفاعلات
      });

      // إيقاف التشغيل عند الضغط الطويل
      if (_progressController.isAnimating) {
        _progressController.stop();
      }

      print('⏸️ Long press started - Story paused, reactions shown');
    }
  }

  // دالة جديدة للتعامل مع رفع الإصبع
  void _onLongPressEnd() {
    if (_isLongPressing) {
      setState(() {
        _isLongPressing = false;
        _showReactions = false; // إخفاء التفاعلات
      });

      // استئناف التشغيل عند رفع الإصبع
      if (!_isPaused && _progressController.value < 1.0) {
        _progressController.forward().then((_) {
          // التأكد من أن الستوري اكتمل
          if (_progressController.value >= 1.0) {
            print('✅ Story completed after long press, moving to next');
            _nextStory();
          }
        }).catchError((error) {
          print('❌ Error resuming story: $error');
        });
      }

      print('▶️ Long press ended - Story resumed, reactions hidden');
    }
  }

  // دالة جديدة للتعامل مع الضغط السريع
  void _onTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    // تحديد منطقة الضغط
    if (tapX < screenWidth * 0.4) {
      // الضغط على الجانب الأيسر - الانتقال للستوري السابق
      print('⬅️ Tap on left side - Previous story');
      _previousStory();
    } else if (tapX > screenWidth * 0.6) {
      // الضغط على الجانب الأيمن - الانتقال للستوري التالي
      print('➡️ Tap on right side - Next story');
      _nextStory();
    } else {
      // المنطقة الوسطى - إيقاف/تشغيل الاستوري
      print('⏸️ Tap on center - Toggle pause');
      _togglePause();
    }
  }

  // دوال للتعامل مع السحب العمودي والأفقي
  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _verticalDragDistance = 0;
    });
    // إيقاف التشغيل مؤقتاً أثناء السحب
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDragDistance += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // إذا سحب لأسفل أكثر من 150 بكسل، إغلاق المشاهد
    if (_verticalDragDistance > 150) {
      print('⬇️ Swipe down detected - Closing story viewer');
      _closeStoryViewer();
    } else {
      // العودة للموضع الأصلي واستكمال التشغيل
      setState(() {
        _verticalDragDistance = 0;
      });
      if (!_isPaused && _progressController.value < 1.0) {
        _progressController.forward().then((_) {
          if (_progressController.value >= 1.0) {
            _nextStory();
          }
        });
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _horizontalDragDistance = 0;
    });
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _horizontalDragDistance += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // السحب لليسار = المستخدم التالي
    if (_horizontalDragDistance < -100) {
      print('⬅️ Swipe left detected - Next user');
      _nextUser();
    }
    // السحب لليمين = المستخدم السابق
    else if (_horizontalDragDistance > 100) {
      print('➡️ Swipe right detected - Previous user');
      _previousUser();
    } else {
      // العودة للموضع الأصلي واستكمال التشغيل
      setState(() {
        _horizontalDragDistance = 0;
      });
      if (!_isPaused && _progressController.value < 1.0) {
        _progressController.forward().then((_) {
          if (_progressController.value >= 1.0) {
            _nextStory();
          }
        });
      }
    }
  }

  // دالة لإظهار حقل الرد
  void _toggleReplyField() {
    setState(() {
      _showReplyField = !_showReplyField;
    });
    if (_showReplyField) {
      _replyFocusNode.requestFocus();
      // إيقاف التشغيل عند فتح حقل الرد
      if (_progressController.isAnimating) {
        setState(() {
          _isPaused = true;
        });
        _progressController.stop();
      }
    } else {
      _replyFocusNode.unfocus();
      // استكمال التشغيل عند إغلاق حقل الرد
      if (_isPaused) {
        setState(() {
          _isPaused = false;
        });
        if (_progressController.value < 1.0) {
          _progressController.forward().then((_) {
            if (_progressController.value >= 1.0) {
              _nextStory();
            }
          });
        }
      }
    }
  }

  // دالة لإرسال الرد
  void _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    if (_currentStoryIndex >= _currentUserStories.length) return;
    final currentStory = _currentUserStories[_currentStoryIndex];

    if (currentStory.id == null || currentStory.uid == null) {
      Get.snackbar(
        'Error',
        'Cannot send reply to this story',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    print('💬 Sending reply: $replyText');

    final controller = Get.find<StoriesController>();
    final success = await controller.sendStoryReply(
      storyId: currentStory.id!,
      storyOwnerId: currentStory.uid!,
      replyText: replyText,
    );

    if (success) {
      Get.snackbar(
        'Reply Sent',
        'Your reply has been sent',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: ColorsManager.success,
        colorText: Colors.white,
      );
      _replyController.clear();
      _toggleReplyField();
    } else {
      Get.snackbar(
        'Error',
        'Failed to send reply. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  // دالة لإرسال التفاعل
  void _sendReaction(String emoji) async {
    setState(() {
      _selectedReaction = emoji;
      _showReactions = false;
      _isLongPressing = false;
    });

    if (_currentStoryIndex >= _currentUserStories.length) return;
    final currentStory = _currentUserStories[_currentStoryIndex];

    if (currentStory.id == null || currentStory.uid == null) {
      Get.snackbar(
        'Error',
        'Cannot send reaction to this story',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    print('❤️ Sending reaction: $emoji');

    final controller = Get.find<StoriesController>();
    final success = await controller.sendStoryReaction(
      storyId: currentStory.id!,
      storyOwnerId: currentStory.uid!,
      emoji: emoji,
    );

    // استئناف التشغيل بعد إرسال التفاعل
    if (!_isPaused && _progressController.value < 1.0) {
      _progressController.forward().then((_) {
        if (_progressController.value >= 1.0) {
          _nextStory();
        }
      });
    }

    // إظهار إشعار بسيط
    if (success) {
      Get.snackbar(
        'Reaction Sent',
        'You reacted with $emoji',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        backgroundColor: ColorsManager.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to send reaction',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoriesController>();

    return Obx(() {
      if (!controller.isViewingStory.value) {
        return const SizedBox.shrink();
      }

      // إعادة تهيئة الستوريز عند فتحها
      if (_currentUserStories.isEmpty) {
        print('🔄 Reinitializing story viewer...');
        _initializeStoryViewer();
        return const SizedBox.shrink();
      }

      if (_currentStoryIndex >= _currentUserStories.length) {
        print(
            '❌ Invalid story index: $_currentStoryIndex, total: ${_currentUserStories.length}');
        return const SizedBox.shrink();
      }

      final currentStory = _currentUserStories[_currentStoryIndex];
      final currentUser = _usersWithStories[_currentUserIndex];

      return GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(
              _horizontalDragDistance * 0.5,
              _verticalDragDistance * 0.5,
            )
            ..scale(1.0 - (_verticalDragDistance.abs() / 1000)),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Story content
                _buildStoryContent(currentStory),

            // Progress bars for all stories
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: _buildProgressBars(),
            ),

            // User info
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildUserInfo(currentUser, currentStory),
            ),

            // Close button with long press support
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: _closeStoryViewer,
                onLongPressStart: (_) => _onLongPressStart(),
                onLongPressEnd: (_) => _onLongPressEnd(),
                onLongPressCancel: () => _onLongPressEnd(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
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
                    color: Colors.black.withValues(alpha: 0.5),
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

            // Long press indicator with reactions
            if (_isLongPressing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reactions Bar
                      if (_showReactions) _buildReactionsBar(),

                      const SizedBox(height: 20),

                      // Pause Indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pause,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Story Paused',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _showReactions ? 'Tap reaction to send' : 'Release to continue',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Floating Reply Button
            _buildFloatingReplyButton(),

            // Navigation controls with new gesture handling
            _buildNavigationControls(),

            // Reply Input Field
            _buildReplyField(),
          ],
        ),
      ),
    ),
      );
    });
  }

  Widget _buildStoryContent(StoryModel story) {
    switch (story.storyType) {
      case StoryType.image:
        return _buildImageStory(story);
      case StoryType.video:
        return _buildVideoStory(story);
      case StoryType.text:
        return _buildTextStory(story);
      default:
        return const Center(
          child: Text(
            'Unsupported story type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildImageStory(StoryModel story) {
    if (story.storyFileUrl == null || story.storyFileUrl!.isEmpty) {
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
        story.storyFileUrl!,
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

  Widget _buildVideoStory(StoryModel story) {
    if (story.storyFileUrl == null || story.storyFileUrl!.isEmpty) {
      return const Center(
        child: Text(
          'No video available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return FutureBuilder(
      future: _initializeVideoPlayer(story.storyFileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_videoController != null && _videoController!.value.isInitialized) {
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            );
          } else {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Error loading video',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        } else {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      // Dispose previous controller if exists
      await _videoController?.dispose();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      await _videoController!.play();

      // Listen for video completion
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _nextStory();
        }
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  Widget _buildTextStory(StoryModel story) {
    if (story.storyText == null || story.storyText!.isEmpty) {
      return const Center(
        child: Text(
          'No text available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Color backgroundColor = Colors.black;
    Color textColor = Colors.white;
    double fontSize = story.fontSize ?? 24.0;

    if (story.backgroundColor != null) {
      backgroundColor = _parseColor(story.backgroundColor!);
    }
    if (story.textColor != null) {
      textColor = _parseColor(story.textColor!);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            story.storyText!,
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

  Widget _buildProgressBars() {
    final currentUserId = UserService.currentUser.value?.uid;

    return Row(
      children: List.generate(_currentUserStories.length, (index) {
        final isCurrentStory = index == _currentStoryIndex;
        final story = _currentUserStories[index];
        final isViewed = story.isViewedBy(currentUserId ?? '');

        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(
                right: index < _currentUserStories.length - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isViewed
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: isCurrentStory
                ? AnimatedBuilder(
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
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildUserInfo(SocialMediaUser user, StoryModel story) {
    final controller = Get.find<StoriesController>();
    final currentUser = controller.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
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
                  '${_currentStoryIndex + 1} of ${_currentUserStories.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                // مؤشر الستوريز المشاهدة
                if (_currentUserStories.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentUserStories.where((s) => s.isViewedBy(UserService.currentUser.value?.uid ?? '')).length} viewed',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Story type icon
          Icon(
            _getStoryTypeIcon(story.storyType),
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: _onTap,
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        onLongPressCancel: () => _onLongPressEnd(),
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              // Previous story area (left side)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // Middle area (no action)
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // Next story area (right side)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
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

  // بناء حقل الرد مع الأنيميشن
  Widget _buildReplyField() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      bottom: _showReplyField ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                focusNode: _replyFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Reply to story...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendReply,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorsManager.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر الرد العائم
  Widget _buildFloatingReplyButton() {
    if (_showReplyField) return const SizedBox.shrink();

    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _toggleReplyField,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.reply,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Reply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء شريط التفاعلات السريعة
  Widget _buildReactionsBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _reactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () => _sendReaction(emoji),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedReaction == emoji
                          ? ColorsManager.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
