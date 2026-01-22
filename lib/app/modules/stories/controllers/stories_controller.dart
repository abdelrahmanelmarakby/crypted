import 'dart:async';
import 'dart:io';

import 'package:crypted_app/app/data/data_source/story_data_sources.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/services/story_clustering_service.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class StoriesController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final StoryDataSources _storyDataSources = StoryDataSources();
  final UserService _userService = UserService();

  // متغيرات للـ UI
  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<File?> selectedVideo = Rx<File?>(null);
  RxString storyText = ''.obs;
  RxString backgroundColor = '#000000'.obs;
  RxString textColor = '#FFFFFF'.obs;
  RxDouble fontSize = 24.0.obs;
  RxString textPosition = 'center'.obs;
  RxBool isUploading = false.obs;

  // Location variables
  Rx<double?> selectedLatitude = Rx<double?>(null);
  Rx<double?> selectedLongitude = Rx<double?>(null);
  Rx<String?> selectedPlaceName = Rx<String?>(null);

  // متغيرات للـ stories
  RxList<StoryModel> allStories = <StoryModel>[].obs;
  RxList<StoryModel> userStories = <StoryModel>[].obs;
  RxMap<String, List<StoryModel>> storiesByUser =
      <String, List<StoryModel>>{}.obs;
  RxList<SocialMediaUser> allUsers = <SocialMediaUser>[].obs;
  RxMap<String, SocialMediaUser> usersMap = <String, SocialMediaUser>{}.obs;

  // FIX: Stream subscriptions for proper cleanup and error recovery
  StreamSubscription? _allStoriesSubscription;
  StreamSubscription? _userStoriesSubscription;
  int _allStoriesRetryCount = 0;
  int _userStoriesRetryCount = 0;
  static const int _maxRetries = 5;

  // متغيرات للـ story viewer
  RxInt currentStoryIndex = 0.obs;
  RxInt currentUserIndex = 0.obs;
  RxBool isViewingStory = false.obs;
  RxBool isViewingCurrentUserStories = false.obs;
  VideoPlayerController? videoController;

  @override
  void onInit() {
    super.onInit();
    print('🚀 StoriesController initialized');
    _initializeStories();
  }

  @override
  void onClose() {
    // FIX: Cancel stream subscriptions to prevent memory leaks
    _allStoriesSubscription?.cancel();
    _userStoriesSubscription?.cancel();
    videoController?.dispose();
    super.onClose();
  }

  // تهيئة الستوريز
  void _initializeStories() {
    print('📱 Initializing stories...');

    // FIX: Clean up expired stories on initialization
    // This prevents Firestore from growing indefinitely with expired stories
    _cleanupExpiredStories();

    fetchAllStories();
    fetchUserStories();
    fetchAllUsers();
  }

  /// FIX: Cleanup expired stories from Firestore
  /// Called on initialization to prevent database bloat
  Future<void> _cleanupExpiredStories() async {
    try {
      print('🧹 Cleaning up expired stories...');
      await _storyDataSources.deleteExpiredStories();
    } catch (e) {
      print('⚠️ Error cleaning up expired stories: $e');
      // Don't block initialization if cleanup fails
    }
  }

  // جلب جميع المستخدمين
  void fetchAllUsers() async {
    try {
      print('👥 Fetching all users...');
      final users = await _userService.getAllUsers();
      allUsers.value = users;

      // إنشاء map للوصول السريع للمستخدمين
      for (var user in users) {
        if (user.uid != null) {
          usersMap[user.uid!] = user;
        }
      }

      print('👥 Fetched ${users.length} users');
      update();
    } catch (e) {
      print('❌ Error fetching users: $e');
    }
  }

  // جلب جميع الـ stories
  // FIX: Added retry logic with exponential backoff for stream errors
  void fetchAllStories() {
    print('📱 Setting up stories stream...');

    // Cancel existing subscription if any
    _allStoriesSubscription?.cancel();

    _allStoriesSubscription = _storyDataSources.getAllStories().listen(
      (stories) {
        print('📱 Fetched ${stories.length} stories');
        _allStoriesRetryCount = 0; // Reset retry count on success
        allStories.value = stories;
        _groupStoriesByUser(stories);
        // FIX: Clear clustering cache when stories update so map view gets fresh clusters
        StoryClusteringService.clearCache();
        update();
      },
      onError: (error) {
        print('❌ Error in stories stream: $error');
        _handleAllStoriesError(error);
      },
      cancelOnError: false, // Don't cancel on error, we'll handle retry
    );
  }

  /// FIX: Error recovery with exponential backoff for all stories stream
  void _handleAllStoriesError(dynamic error) {
    if (_allStoriesRetryCount >= _maxRetries) {
      print('❌ Max retries reached for stories stream. Giving up.');
      return;
    }

    _allStoriesRetryCount++;
    final backoffMs = 1000 * (1 << (_allStoriesRetryCount - 1)); // Exponential: 1s, 2s, 4s, 8s, 16s
    print('🔄 Retrying stories stream in ${backoffMs}ms (attempt $_allStoriesRetryCount/$_maxRetries)');

    Future.delayed(Duration(milliseconds: backoffMs), () {
      if (!isClosed) {
        fetchAllStories();
      }
    });
  }

  // جلب stories المستخدم الحالي
  // FIX: Added retry logic with exponential backoff for stream errors
  void fetchUserStories() {
    final userId = UserService.currentUser.value?.uid;
    if (userId != null) {
      print('👤 Fetching stories for current user: $userId');

      // Cancel existing subscription if any
      _userStoriesSubscription?.cancel();

      _userStoriesSubscription = _storyDataSources.getUserStories(userId).listen(
        (stories) {
          print('👤 Fetched ${stories.length} user stories for $userId');
          _userStoriesRetryCount = 0; // Reset retry count on success
          userStories.value = stories;
          update();
        },
        onError: (error) {
          print('❌ Error in user stories stream: $error');
          _handleUserStoriesError(error);
        },
        cancelOnError: false, // Don't cancel on error, we'll handle retry
      );
    } else {
      print('❌ Current user ID is null');
    }
  }

  /// FIX: Error recovery with exponential backoff for user stories stream
  void _handleUserStoriesError(dynamic error) {
    if (_userStoriesRetryCount >= _maxRetries) {
      print('❌ Max retries reached for user stories stream. Giving up.');
      return;
    }

    _userStoriesRetryCount++;
    final backoffMs = 1000 * (1 << (_userStoriesRetryCount - 1)); // Exponential: 1s, 2s, 4s, 8s, 16s
    print('🔄 Retrying user stories stream in ${backoffMs}ms (attempt $_userStoriesRetryCount/$_maxRetries)');

    Future.delayed(Duration(milliseconds: backoffMs), () {
      if (!isClosed) {
        fetchUserStories();
      }
    });
  }

  // تجميع الـ stories حسب المستخدم مع معلومات المستخدم
  void _groupStoriesByUser(List<StoryModel> stories) {
    print('📊 Grouping stories by user...');
    final grouped = <String, List<StoryModel>>{};

    for (var story in stories) {
      if (story.uid != null) {
        grouped.putIfAbsent(story.uid!, () => []).add(story);
        print(
            '📊 Added story ${story.id} for user ${story.user?.fullName} (${story.uid})');
      }
    }
    storiesByUser.value = grouped;
    print('📊 Grouped stories for ${grouped.length} users');
  }

  // الحصول على معلومات المستخدم من الـ story
  SocialMediaUser? getUserFromStory(StoryModel story) {
    if (story.uid == null) return null;

    // أولاً، تحقق من story.user
    if (story.user != null) {
      return story.user;
    }

    // ثانياً، تحقق من usersMap
    return usersMap[story.uid];
  }

  // الحصول على قائمة المستخدمين الذين لديهم stories
  List<SocialMediaUser> getUsersWithStories() {
    final usersWithStories = <SocialMediaUser>[];
    final currentUser = UserService.currentUser.value;

    for (var entry in storiesByUser.entries) {
      final userId = entry.key;
      final user = usersMap[userId];
      // تأكد من أن المستخدم لديه ستوريز
      if (user != null && entry.value.isNotEmpty) {
        usersWithStories.add(user);
        print(
            '👥 Added user ${user.fullName} with ${entry.value.length} stories');
      }
    }

    print('👥 Found ${usersWithStories.length} users with stories');
    return usersWithStories;
  }

  // الحصول على المستخدم الحالي إذا كان لديه ستوريز
  SocialMediaUser? getCurrentUserWithStories() {
    final currentUser = UserService.currentUser.value;
    if (currentUser != null && userStories.isNotEmpty) {
      print('👤 Current user has ${userStories.length} stories');
      return currentUser;
    }
    return null;
  }

  // الحصول على stories لمستخدم محدد
  List<StoryModel> getStoriesForUser(String userId) {
    final currentUser = UserService.currentUser.value;

    // إذا كان المستخدم الحالي، استخدم userStories
    if (currentUser?.uid == userId) {
      return userStories;
    }

    // إذا كان مستخدم آخر، استخدم storiesByUser
    return storiesByUser[userId] ?? [];
  }

  // اختيار صورة
  Future<void> pickImage() async {
    try {
      print('📸 Picking image...');
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        selectedVideo.value = null; // إلغاء الفيديو المحدد
        print('📸 Image selected: ${pickedFile.path}');
        update();
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(Constants.kError.tr, Constants.kFailedToPickImage.tr);
    }
  }

  // اختيار فيديو
  Future<void> pickVideo() async {
    try {
      print('🎥 Picking video...');
      final pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        selectedVideo.value = File(pickedFile.path);
        selectedImage.value = null; // إلغاء الصورة المحددة
        print('🎥 Video selected: ${pickedFile.path}');
        update();
      }
    } catch (e) {
      print('❌ Error picking video: $e');
      Get.snackbar(Constants.kError.tr, Constants.kFailedToPickImage.tr);
    }
  }

  // التقاط صورة من الكاميرا
  Future<void> takePhoto() async {
    try {
      print('📷 Taking photo...');
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        selectedVideo.value = null;
        print('📷 Photo taken: ${pickedFile.path}');
        update();
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      Get.snackbar(Constants.kError.tr, Constants.kFailedToPickImage.tr);
    }
  }

  // رفع story
  Future<void> uploadStory() async {
    print('🚀 Starting story upload...');

    if (selectedImage.value == null &&
        selectedVideo.value == null &&
        storyText.value.isEmpty) {
      print('❌ No content selected for story');
      // Get.snackbar(Constants.kError.tr, Constants.k.tr);
      return;
    }

    isUploading.value = true;
    update();

    try {
      bool success = false;

      if (selectedImage.value != null) {
        print('📸 Uploading image story...');
        // رفع صورة
        final story = StoryModel(
          storyType: StoryType.image,
          duration: 5, // 5 ثواني للصور
          latitude: selectedLatitude.value,
          longitude: selectedLongitude.value,
          placeName: selectedPlaceName.value,
          isLocationPublic: selectedLatitude.value != null,
        );
        success =
            await _storyDataSources.uploadStory(story, selectedImage.value!);
      } else if (selectedVideo.value != null) {
        print('🎥 Uploading video story...');
        // رفع فيديو
        final story = StoryModel(
          storyType: StoryType.video,
          duration: 15, // 15 ثانية للفيديو
          latitude: selectedLatitude.value,
          longitude: selectedLongitude.value,
          placeName: selectedPlaceName.value,
          isLocationPublic: selectedLatitude.value != null,
        );
        success =
            await _storyDataSources.uploadStory(story, selectedVideo.value!);
      } else if (storyText.value.isNotEmpty) {
        print('📝 Uploading text story...');
        // رفع نص
        final story = StoryModel(
          storyText: storyText.value,
          storyType: StoryType.text,
          backgroundColor: backgroundColor.value,
          textColor: textColor.value,
          fontSize: fontSize.value,
          textPosition: textPosition.value,
          duration: 5,
          latitude: selectedLatitude.value,
          longitude: selectedLongitude.value,
          placeName: selectedPlaceName.value,
          isLocationPublic: selectedLatitude.value != null,
        );
        success = await _storyDataSources.uploadTextStory(story);
      }

      if (success) {
        print('✅ Story uploaded successfully');
        Get.snackbar(Constants.kSuccess.tr,"Story uploaded successfully");
        clearStoryData();
        // تحديث البيانات بعد الرفع
        fetchAllStories();
        fetchUserStories();
      } else {
        print('❌ Story upload failed');
        Get.snackbar(Constants.kError.tr,"Story upload failed");
      }
    } catch (e) {
      print('❌ Error uploading story: $e');
      Get.snackbar(Constants.kError.tr,"Story upload failed");
    } finally {
      isUploading.value = false;
      update();
    }
  }

  // مسح بيانات الـ story
  void clearStoryData() {
    selectedImage.value = null;
    selectedVideo.value = null;
    storyText.value = '';
    backgroundColor.value = '#000000';
    textColor.value = '#FFFFFF';
    fontSize.value = 24.0;
    textPosition.value = 'center';
    clearLocation();
    update();
  }

  // Set location for story
  void setLocation(double lat, double lon, String? placeName) {
    selectedLatitude.value = lat;
    selectedLongitude.value = lon;
    selectedPlaceName.value = placeName;
    print('📍 Location set: $lat, $lon - $placeName');
    update();
  }

  // Clear location
  void clearLocation() {
    selectedLatitude.value = null;
    selectedLongitude.value = null;
    selectedPlaceName.value = null;
    update();
  }

  // فتح story viewer
  void openStoryViewer(int userIndex, int storyIndex) {
    currentUserIndex.value = userIndex;
    currentStoryIndex.value = storyIndex;
    isViewingStory.value = true;
    update();
  }

  // إغلاق story viewer
  void closeStoryViewer() {
    isViewingStory.value = false;
    isViewingCurrentUserStories.value = false;
    videoController?.dispose();
    videoController = null;
    update();
  }

  // التالي في الـ story
  void nextStory() {
    // إذا كان المستخدم الحالي
    if (isViewingCurrentUserStories.value) {
      if (currentStoryIndex.value < userStories.length - 1) {
        currentStoryIndex.value++;
      } else {
        closeStoryViewer();
      }
      update();
      return;
    }

    // إذا كان مستخدم آخر
    final usersWithStories = getUsersWithStories();
    if (usersWithStories.isEmpty) {
      closeStoryViewer();
      return;
    }

    final currentUser = usersWithStories[currentUserIndex.value];
    final currentUserStories = getStoriesForUser(currentUser.uid!);

    if (currentStoryIndex.value < currentUserStories.length - 1) {
      currentStoryIndex.value++;
    } else {
      // التالي إلى المستخدم التالي
      if (currentUserIndex.value < usersWithStories.length - 1) {
        currentUserIndex.value++;
        currentStoryIndex.value = 0;
      } else {
        closeStoryViewer();
      }
    }
    update();
  }

  // السابق في الـ story
  void previousStory() {
    // إذا كان المستخدم الحالي
    if (isViewingCurrentUserStories.value) {
      if (currentStoryIndex.value > 0) {
        currentStoryIndex.value--;
      } else {
        closeStoryViewer();
      }
      update();
      return;
    }

    // إذا كان مستخدم آخر
    final usersWithStories = getUsersWithStories();
    if (usersWithStories.isEmpty) {
      closeStoryViewer();
      return;
    }

    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
    } else {
      // السابق إلى المستخدم السابق
      if (currentUserIndex.value > 0) {
        currentUserIndex.value--;
        final previousUser = usersWithStories[currentUserIndex.value];
        final previousUserStories = getStoriesForUser(previousUser.uid!);
        currentStoryIndex.value = previousUserStories.length - 1;
      }
    }
    update();
  }

  // تحديث حالة مشاهدة story
  Future<void> markStoryAsViewed(String storyId) async {
    final userId = UserService.currentUser.value?.uid;
    if (userId != null) {
      await _storyDataSources.markStoryAsViewed(storyId, userId);
    }
  }

  // حذف story
  Future<void> deleteStory(String storyId) async {
    final success = await _storyDataSources.deleteStory(storyId);
    if (success) {
      Get.snackbar(Constants.kSuccess.tr,"Story deleted successfully");
    } else {
      Get.snackbar(Constants.kError.tr,"Story deleted failed");
    }
  }

  // الحصول على الـ story الحالية
  StoryModel? get currentStory {
    // إذا كان المستخدم الحالي
    if (isViewingCurrentUserStories.value) {
      if (userStories.isEmpty ||
          currentStoryIndex.value >= userStories.length) {
        return null;
      }
      return userStories[currentStoryIndex.value];
    }

    // إذا كان مستخدم آخر
    final usersWithStories = getUsersWithStories();
    if (usersWithStories.isEmpty) return null;

    final currentUser = usersWithStories[currentUserIndex.value];
    final otherUserStories = getStoriesForUser(currentUser.uid!);

    if (otherUserStories.isEmpty ||
        currentStoryIndex.value >= otherUserStories.length) {
      return null;
    }
    return otherUserStories[currentStoryIndex.value];
  }

  // الحصول على المستخدم الحالي
  SocialMediaUser? get currentUser {
    // إذا كان المستخدم الحالي
    if (isViewingCurrentUserStories.value) {
      return UserService.currentUser.value;
    }

    // إذا كان مستخدم آخر
    final usersWithStories = getUsersWithStories();
    if (usersWithStories.isEmpty) return null;

    final currentUser = usersWithStories[currentUserIndex.value];
    return currentUser;
  }

  // فتح story viewer لمستخدم محدد
  void openUserStories(String userId) {
    print('👤 Opening stories for user: $userId');
    final currentUser = UserService.currentUser.value;

    // إذا كان المستخدم الحالي
    if (currentUser?.uid == userId) {
      print('👤 Opening current user stories');
      isViewingCurrentUserStories.value = true;
      currentUserIndex.value = 0;
      currentStoryIndex.value = 0;
      isViewingStory.value = true;
      update();
      return;
    }

    // إذا كان مستخدم آخر
    isViewingCurrentUserStories.value = false;
    final usersWithStories = getUsersWithStories();
    final userIndex = usersWithStories.indexWhere((user) => user.uid == userId);

    if (userIndex != -1) {
      currentUserIndex.value = userIndex;
      currentStoryIndex.value = 0;
      isViewingStory.value = true;
      update();
    } else {
      print('❌ User not found in users with stories');
    }
  }

  // فتح story viewer للـ story المحددة
  void openStoryAtIndex(int userIndex, int storyIndex) {
    final usersWithStories = getUsersWithStories();
    if (userIndex < usersWithStories.length) {
      isViewingCurrentUserStories.value = false;
      currentUserIndex.value = userIndex;
      currentStoryIndex.value = storyIndex;
      isViewingStory.value = true;
      update();
    }
  }

  // إرسال رد على story
  Future<bool> sendStoryReply({
    required String storyId,
    required String storyOwnerId,
    required String replyText,
  }) async {
    try {
      final success = await _storyDataSources.sendStoryReply(
        storyId: storyId,
        storyOwnerId: storyOwnerId,
        replyText: replyText,
      );
      if (success) {
        print('✅ Reply sent successfully via controller');
      }
      return success;
    } catch (e) {
      print('❌ Error sending reply via controller: $e');
      return false;
    }
  }

  // إرسال تفاعل على story
  Future<bool> sendStoryReaction({
    required String storyId,
    required String storyOwnerId,
    required String emoji,
  }) async {
    try {
      final success = await _storyDataSources.sendStoryReaction(
        storyId: storyId,
        storyOwnerId: storyOwnerId,
        emoji: emoji,
      );
      if (success) {
        print('✅ Reaction sent successfully via controller');
      }
      return success;
    } catch (e) {
      print('❌ Error sending reaction via controller: $e');
      return false;
    }
  }

  // جلب ردود story
  Stream<List<Map<String, dynamic>>> getStoryReplies(String storyId) {
    return _storyDataSources.getStoryReplies(storyId);
  }

  // جلب تفاعلات story
  Stream<List<Map<String, dynamic>>> getStoryReactions(String storyId) {
    return _storyDataSources.getStoryReactions(storyId);
  }
}
