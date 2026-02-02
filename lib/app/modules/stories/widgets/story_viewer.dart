import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/data_source/story_data_sources.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  static const Map<String, String> _reactionLabels = {
    '❤️': 'Love',
    '😂': 'Laugh',
    '😮': 'Wow',
    '😢': 'Sad',
    '👏': 'Clap',
    '🔥': 'Fire',
  };

  // FIX: Track video listener to prevent memory leak
  VoidCallback? _videoListener;

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

    // FIX: Remove video listener before disposing to prevent memory leak
    if (_videoListener != null && _videoController != null) {
      _videoController!.removeListener(_videoListener!);
      _videoListener = null;
    }
    _videoController?.dispose();

    super.dispose();
  }

  /// FIX: Preload next story media to eliminate loading delays
  void _preloadNextStory() {
    // Get the next story index
    final nextIndex = _currentStoryIndex + 1;

    // Check if there's a next story in the current user's stories
    if (nextIndex < _currentUserStories.length) {
      final nextStory = _currentUserStories[nextIndex];
      _preloadStoryMedia(nextStory);
    } else if (_currentUserIndex + 1 < _usersWithStories.length) {
      // Preload first story of next user
      final controller = Get.find<StoriesController>();
      final nextUser = _usersWithStories[_currentUserIndex + 1];
      final nextUserStories = controller.getStoriesForUser(nextUser.uid!);
      if (nextUserStories.isNotEmpty) {
        // Sort by creation time (oldest first)
        nextUserStories.sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));
        _preloadStoryMedia(nextUserStories.first);
      }
    }
  }

  /// Preload media for a specific story
  void _preloadStoryMedia(StoryModel story) {
    if (story.storyFileUrl == null || story.storyFileUrl!.isEmpty) return;

    switch (story.storyType) {
      case StoryType.image:
        // Preload image using CachedNetworkImageProvider
        if (mounted) {
          precacheImage(
            CachedNetworkImageProvider(story.storyFileUrl!),
            context,
          ).then((_) {
            print('✅ Preloaded image: ${story.storyFileUrl}');
          }).catchError((e) {
            print('⚠️ Failed to preload image: $e');
          });
        }
        break;
      case StoryType.video:
        // For videos, we don't preload the full video to save memory/bandwidth
        // The video will load when displayed
        print('📹 Next story is video - will load on display');
        break;
      case StoryType.event:
        // Preload event cover image if present
        if (story.storyFileUrl != null &&
            story.storyFileUrl!.isNotEmpty &&
            mounted) {
          precacheImage(
            CachedNetworkImageProvider(story.storyFileUrl!),
            context,
          ).catchError((_) {});
        }
        break;
      case StoryType.text:
      case null:
        // Text stories don't need preloading
        break;
    }
  }

  void _initializeStoryViewer() {
    final controller = Get.find<StoriesController>();
    final currentUser = UserService.currentUser.value;

    print('🔄 Initializing story viewer...');

    // Initialize unconditionally to prevent LateInitializationError in dispose()
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

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

    // FIX: Preload next story media while current one is playing
    _preloadNextStory();

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
      // FIX: Also pause video if playing
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
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
      // FIX: Also resume video if it was paused
      if (_videoController != null &&
          _videoController!.value.isInitialized &&
          !_videoController!.value.isPlaying) {
        _videoController!.play();
      }
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
      // FIX: Also pause video during long press
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
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
        // FIX: Resume video playback after long press
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            !_videoController!.value.isPlaying) {
          _videoController!.play();
        }
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
                  child: Semantics(
                    label: 'Close story viewer',
                    button: true,
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
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pause/Play button with long press support
                Positioned(
                  top: 50,
                  left: 20,
                  child: Semantics(
                    label: _isPaused ? 'Play story' : 'Pause story',
                    button: true,
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
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 30,
                          ),
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
                                  _showReactions
                                      ? 'Tap reaction to send'
                                      : 'Release to continue',
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

                // Link sticker (tappable — opens URL)
                _buildLinkSticker(currentStory),

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
      case StoryType.event:
        return _buildEventStory(story);
      default:
        return const Center(
          child: Text(
            'Unsupported story type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildEventStory(StoryModel story) {
    final hasImage =
        story.storyFileUrl != null && story.storyFileUrl!.isNotEmpty;
    final attendeeCount = story.attendeeCount;
    final currentUid = _currentUserId;
    final hasJoined = currentUid != null && story.hasJoined(currentUid);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background — cover image or gradient
        if (hasImage)
          CachedNetworkImage(
            imageUrl: story.storyFileUrl!,
            fit: BoxFit.cover,
            color: Colors.black.withAlpha(120),
            colorBlendMode: BlendMode.darken,
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460)
                ],
              ),
            ),
          ),
        // Event card content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category chip
                if (story.eventCategory != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      story.eventCategory!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Event title
                Text(
                  story.eventTitle ?? 'Event',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                if (story.eventDescription != null &&
                    story.eventDescription!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      story.eventDescription!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Date & venue info
                _buildEventInfoRow(
                  icon: Icons.calendar_today,
                  text: story.eventDate != null
                      ? _formatEventDate(story.eventDate!)
                      : 'Date TBD',
                ),
                if (story.eventVenue != null && story.eventVenue!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildEventInfoRow(
                      icon: Icons.location_on,
                      text: story.eventVenue!,
                    ),
                  ),
                const SizedBox(height: 8),
                _buildEventInfoRow(
                  icon: Icons.people,
                  text:
                      '$attendeeCount ${attendeeCount == 1 ? 'person' : 'people'} going'
                      '${story.eventMaxAttendees != null ? ' / ${story.eventMaxAttendees} max' : ''}',
                ),
                const SizedBox(height: 28),
                // Join / Leave button
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _toggleEventJoin(story, hasJoined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasJoined
                          ? Colors.white.withAlpha(40)
                          : const Color(0xFF31A354),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: hasJoined
                            ? const BorderSide(color: Colors.white30)
                            : BorderSide.none,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasJoined
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasJoined ? 'Joined' : 'Join Event',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final dayDiff = eventDay.difference(today).inDays;
    final day = '${date.day}/${date.month}/${date.year}';
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (dayDiff == 0) {
      return 'Today at $time';
    } else if (dayDiff == 1) {
      return 'Tomorrow at $time';
    }
    return '$day at $time';
  }

  String? get _currentUserId {
    return UserService.currentUser.value?.uid;
  }

  Future<void> _toggleEventJoin(StoryModel story, bool hasJoined) async {
    final uid = _currentUserId;
    if (uid == null || story.id == null) return;

    // Optimistically update the local story model
    final storyIndex = _currentUserStories.indexOf(story);
    if (storyIndex != -1) {
      final updatedAttendees = List<String>.from(story.attendeeIds ?? []);
      if (hasJoined) {
        updatedAttendees.remove(uid);
      } else {
        if (story.isEventFull) {
          Get.snackbar(
              'Event Full', 'This event has reached its maximum capacity');
          return;
        }
        updatedAttendees.add(uid);
      }
      setState(() {
        _currentUserStories[storyIndex] =
            story.copyWith(attendeeIds: updatedAttendees);
      });
    }

    // Persist to Firestore
    final dataSource = StoryDataSources();
    try {
      if (hasJoined) {
        await dataSource.leaveEvent(story.id!);
      } else {
        await dataSource.joinEvent(story.id!);
      }
    } catch (e) {
      // Revert on failure
      if (storyIndex != -1) {
        setState(() {
          _currentUserStories[storyIndex] = story;
        });
      }
      Get.snackbar('Error', 'Failed to update event. Please try again.');
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

    // FIX: Use CachedNetworkImage to benefit from preloading
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CachedNetworkImage(
        imageUrl: story.storyFileUrl!,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, downloadProgress) {
          return Center(
            child: CircularProgressIndicator(
              value: downloadProgress.progress,
              color: Colors.white,
            ),
          );
        },
        errorWidget: (context, url, error) {
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

    final videoPlayer = FutureBuilder(
      future: _initializeVideoPlayer(story.storyFileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_videoController != null &&
              _videoController!.value.isInitialized) {
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

    // If no text overlay metadata, return just the video
    final hasTextOverlay =
        story.storyText != null && story.storyText!.isNotEmpty;
    if (!hasTextOverlay) return videoPlayer;

    // Render text overlay on top of video (can't be composited without FFmpeg)
    final textColor =
        story.textColor != null ? _parseColor(story.textColor!) : Colors.white;
    final fontSize = story.fontSize ?? 20.0;

    // Determine vertical alignment from textPosition metadata
    final AlignmentGeometry textAlignment;
    switch (story.textPosition) {
      case 'top':
        textAlignment = const Alignment(0.0, -0.6);
        break;
      case 'bottom':
        textAlignment = const Alignment(0.0, 0.6);
        break;
      default:
        textAlignment = Alignment.center;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        videoPlayer,
        Align(
          alignment: textAlignment,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              story.storyText!,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      // FIX: Remove previous listener before disposing controller
      if (_videoListener != null && _videoController != null) {
        _videoController!.removeListener(_videoListener!);
        _videoListener = null;
      }

      // Dispose previous controller if exists
      await _videoController?.dispose();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      await _videoController!.play();

      // FIX: Create a tracked listener that can be removed later
      _videoListener = () {
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            _videoController!.value.position >=
                _videoController!.value.duration &&
            _videoController!.value.duration > Duration.zero) {
          _nextStory();
        }
      };
      _videoController!.addListener(_videoListener!);
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
              fontFamily: story.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    final currentUserId = UserService.currentUser.value?.uid;

    return Semantics(
      label: 'Story ${_currentStoryIndex + 1} of ${_currentUserStories.length}',
      child: Row(
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
      ),
    );
  }

  Widget _buildUserInfo(SocialMediaUser user, StoryModel story) {
    // Use the passed-in `user` (story owner), NOT controller.currentUser
    final storyOwner = user;

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
            backgroundImage:
                storyOwner.imageUrl != null && storyOwner.imageUrl!.isNotEmpty
                    ? NetworkImage(storyOwner.imageUrl!)
                    : const AssetImage('assets/images/Profile Image111.png')
                        as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storyOwner.fullName ?? 'Unknown',
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
                child: Semantics(
                  label: 'Previous story',
                  button: true,
                  onTap: _previousStory,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Middle area (pause/play)
              Expanded(
                flex: 1,
                child: Semantics(
                  label: _isPaused ? 'Play story' : 'Pause story',
                  button: true,
                  onTap: _togglePause,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Next story area (right side)
              Expanded(
                flex: 2,
                child: Semantics(
                  label: 'Next story',
                  button: true,
                  onTap: _nextStory,
                  child: Container(
                    color: Colors.transparent,
                  ),
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
      case StoryType.event:
        return Icons.event;
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

  // ═══════════════════════════════════════════════════════════
  // LINK STICKER — tappable URL overlay on story
  // ═══════════════════════════════════════════════════════════

  Widget _buildLinkSticker(StoryModel story) {
    if (story.linkUrl == null || story.linkUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayText = story.linkDisplayText?.isNotEmpty == true
        ? story.linkDisplayText!
        : _extractDomainFromUrl(story.linkUrl!);

    return Positioned(
      bottom: 80, // above the reply button
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _openLink(story.linkUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.link, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Iconsax.arrow_right_3,
                        color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _extractDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

      // Pause story while user views the link
      if (_progressController.isAnimating) {
        _progressController.stop();
        setState(() => _isPaused = true);
      }
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening link: $e');
      Get.snackbar('Error', 'Could not open link',
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
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
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2), width: 1),
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
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: Colors.white, width: 1.5),
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
            Semantics(
              label: 'Send reply',
              button: true,
              child: GestureDetector(
                onTap: _sendReply,
                child: Container(
                  width: 48,
                  height: 48,
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
        child: Semantics(
          label: 'Reply to story',
          button: true,
          child: GestureDetector(
            onTap: _toggleReplyField,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1),
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
                return Semantics(
                  label: 'React with ${_reactionLabels[emoji] ?? emoji}',
                  button: true,
                  selected: _selectedReaction == emoji,
                  child: GestureDetector(
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
