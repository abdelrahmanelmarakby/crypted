import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/extensions/string.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRecording = false.obs;

  SocialMediaUser? sender;
  SocialMediaUser? receiver;
  String? blockingUserId;

  late final ChatDataSources chatDataSource;

  final RxInt yesVotes = 3.obs;
  final RxInt noVotes = 5.obs;
  final RxString selectedOption = ''.obs;

  static ChatController? currentlyPlayingController;

  double get totalVotes => (yesVotes.value + noVotes.value).toDouble();
  SocialMediaUser? get myUser => sender ?? UserService.currentUser.value;
  SocialMediaUser? get otherUser => receiver;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeFromArguments();
    _initializeChatDataSource();
    await _checkPermissions();
    _loadMessages();
  }

  Future<void> _initializeFromArguments() async {
    final arguments = Get.arguments;
    print("🔍 Chat arguments received: $arguments");

    // التحقق من استخدام مدير الجلسة
    final useSessionManager = arguments?['useSessionManager'] ?? false;

    if (useSessionManager && ChatSessionManager.instance.hasActiveSession) {
      // استخدام مدير الجلسة إذا كان متاحاً
      print("🎯 Using Chat Session Manager");
      sender = ChatSessionManager.instance.sender;
      receiver = ChatSessionManager.instance.receiver;
      blockingUserId = arguments?['blockingUserId'];

      ChatSessionManager.instance.printSessionInfo();
    } else {
      // الطريقة القديمة للتوافق مع الإصدارات السابقة
      print("🔄 Using legacy argument method");
      if (arguments != null) {
        sender = arguments['sender'];
        receiver = arguments['receiver'];
        blockingUserId = arguments['blockingUserId'];
      }

      // التأكد من أن sender دائماً هو المستخدم الحالي
      if (sender == null) {
        print("⚠️ Sender is null, using UserService.currentUser.value");
        sender = UserService.currentUser.value;
      }

      // إذا كان UserService.currentUser.value أيضاً null، محاولة جلبه
      if (sender == null && UserService.currentUser.value == null) {
        print("❌ Both sender and UserService.currentUser.value are null!");
        print("🔄 Trying to get current user...");
        await _tryToGetCurrentUser();
      }
    }

    print("👤 Sender set to: ${sender?.uid} - ${sender?.fullName}");
    print("👥 Receiver set to: ${receiver?.uid} - ${receiver?.fullName}");
    print("🚫 Blocked user ID: $blockingUserId");

    // التحقق من صحة البيانات النهائية وتصحيحها إذا لزم الأمر
    await _validateAndCorrectSenderReceiver();

    // التحقق من صحة البيانات النهائية
    if (sender?.uid == null) {
      print("❌ Final sender UID is null!");
    }
    if (receiver?.uid == null) {
      print("❌ Receiver UID is null!");
    }
  }

  Future<void> _tryToGetCurrentUser() async {
    try {
      // محاولة الحصول على userId من Firebase Auth أو Cache
      final currentUser = FirebaseAuth.instance.currentUser;
      final cachedUserId = CacheHelper.getUserId;
      final userId = currentUser?.uid ?? cachedUserId;

      if (userId != null) {
        print("🔄 Loading user profile for: $userId");
        final userProfile = await UserService().getProfile(userId);
        if (userProfile != null) {
          sender = userProfile;
          print("✅ Successfully loaded current user as sender");

          // إعادة تهيئة ChatDataSource مع البيانات الجديدة
          _initializeChatDataSource();
        } else {
          print("❌ Failed to load user profile for: $userId");
        }
      } else {
        print("❌ No user ID available from Firebase Auth or Cache");
      }
    } catch (e) {
      print("❌ Failed to get current user: $e");
    }
  }

  void _initializeChatDataSource() {
    print("🔧 Initializing ChatDataSource...");
    print("👤 My UID: ${sender?.uid}");
    print("👥 Other UID: ${receiver?.uid}");

    chatDataSource = ChatDataSources(
      chatServicesParameters: ChatServicesParameters(
        myId: sender?.uid
            ?.encryptTextToNumbers(), // الاحتفاظ بالتشفير للتوافق مع النظام الحالي
        hisId: receiver?.uid?.encryptTextToNumbers(),
        myUser: sender,
        hisUser: receiver,
      ),
    );

    print("✅ ChatDataSource initialized successfully");
  }

  /// التحقق من صحة المرسل والمستقبل وتصحيحهما إذا لزم الأمر
  Future<void> _validateAndCorrectSenderReceiver() async {
    final currentUserId = UserService.currentUser.value?.uid;
    print("🔍 Validating sender and receiver...");
    print("   Current user ID: $currentUserId");

    // التحقق من أن sender هو المستخدم الحالي
    if (sender?.uid != currentUserId) {
      print("⚠️ Sender is not current user, correcting...");

      // إذا كان receiver هو المستخدم الحالي، اقلبهما
      if (receiver?.uid == currentUserId) {
        // المرسل والمستقبل مقلوبين
        print("🔄 Swapping sender and receiver...");
        final temp = sender;
        sender = receiver;
        receiver = temp;
        print("✅ Sender and receiver swapped successfully");
      } else {
        // تعيين المستخدم الحالي كمرسل
        print("🔄 Setting current user as sender...");
        sender = UserService.currentUser.value;
        print("✅ Current user set as sender");
      }

      // إعادة تهيئة ChatDataSource مع البيانات المصححة
      _initializeChatDataSource();
    } else {
      print("✅ Sender is correctly set to current user");
    }

    // التحقق النهائي
    print("🎯 Final validation:");
    print("   Sender: ${sender?.uid} - ${sender?.fullName}");
    print("   Receiver: ${receiver?.uid} - ${receiver?.fullName}");
    print(
        "   Current User: $currentUserId - ${UserService.currentUser.value?.fullName}");
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    if (micStatus.isDenied) {
      await Permission.microphone.request();
    } else if (micStatus.isPermanentlyDenied) {
      _showToast('Microphone permission required for voice messages');
    }
    // طلب صلاحية الكاميرا أيضًا
    final camStatus = await Permission.camera.status;
    if (camStatus.isDenied) {
      await Permission.camera.request();
    } else if (camStatus.isPermanentlyDenied) {
      _showToast('Camera permission required for video calls');
    }
    // تأكد من تهيئة Zego إذا لم يكن مهيأ (احتياطي)
    if (sender?.uid != null && sender?.fullName != null) {
      await CallDataSources().onUserLogin(sender!.uid!, sender!.fullName!);
    }
  }

  void _loadMessages() {
    isLoading.value = false;
  }

  void onMessageTextChanged(String value) {
    messageController.value = messageController.value.copyWith(
      text: value,
      selection: TextSelection.fromPosition(
        TextPosition(offset: value.length),
      ),
    );
    update();
  }

  void onChangeRec(bool status) {
    isRecording.value = status;
    update();
  }

  void toggleRecording() {
    onChangeRec(!isRecording.value);
  }

  /// التحقق من حالة المستخدم وإعادة المحاولة إذا لزم الأمر
  Future<bool> ensureUserIsLoaded() async {
    print("🔍 Checking user status...");

    // التأكد من أن المرسل هو المستخدم الحالي دائماً
    if (sender?.uid != null &&
        sender?.uid == UserService.currentUser.value?.uid) {
      print("✅ Sender is correctly set to current user: ${sender?.fullName}");
      return true;
    }

    // إذا كان المرسل مختلف عن المستخدم الحالي، تصحيح ذلك
    if (UserService.currentUser.value?.uid != null) {
      print("🔄 Correcting sender to current user...");

      // إذا كان المرسل والمستقبل مقلوبين، تصحيح ذلك
      if (sender?.uid == UserService.currentUser.value?.uid) {
        // المرسل صحيح، لا حاجة للتغيير
        print("✅ Sender is already correct");
      } else if (receiver?.uid == UserService.currentUser.value?.uid) {
        // المرسل والمستقبل مقلوبين، تصحيح ذلك
        print("🔄 Swapping sender and receiver...");
        final temp = sender;
        sender = receiver;
        receiver = temp;
        print("✅ Sender and receiver swapped");
      } else {
        // تعيين المستخدم الحالي كمرسل
        sender = UserService.currentUser.value;
        print("✅ Set current user as sender: ${sender?.fullName}");
      }

      _initializeChatDataSource();
      return true;
    }

    print("🔄 Attempting to load current user...");
    await _tryToGetCurrentUser();

    if (sender?.uid != null) {
      print("✅ Successfully loaded sender: ${sender?.fullName}");
      return true;
    }

    print("❌ Failed to load user");
    return false;
  }

  /// طريقة مساعدة لإرسال رسالة مع التحقق من المستخدم
  Future<void> sendMessage(Message message) async {
    try {
      // التأكد من صحة المرسل والمستقبل قبل الإرسال
      await _validateAndCorrectSenderReceiver();

      // التأكد من تحميل المستخدم أولاً
      if (sender?.uid == null) {
        print("⚠️ Sender is null, trying to ensure user is loaded...");
        final userLoaded = await ensureUserIsLoaded();
        if (!userLoaded) {
          throw Exception('Cannot send message: User not loaded');
        }
      }

      // إضافة debugging لمعرفة البيانات
      print("📤 Sending message: ${message.toString()}");
      print("👤 Message senderId: ${message.senderId}");
      print(
          "👤 Current user: ${UserService.currentUser.value?.uid} - ${UserService.currentUser.value?.fullName}");
      print("👤 Controller sender: ${sender?.uid} - ${sender?.fullName}");
      print("👥 Controller receiver: ${receiver?.uid} - ${receiver?.fullName}");

      // التحقق من أن مرسل الرسالة هو المستخدم الحالي
      if (message.senderId != UserService.currentUser.value?.uid) {
        print("❌ ERROR: Message sender is not current user!");
        print("   Expected: ${UserService.currentUser.value?.uid}");
        print("   Actual: ${message.senderId}");
        throw Exception('Message sender is not current user');
      }

      // التحقق من البيانات المطلوبة
      if (sender?.uid == null || receiver?.uid == null) {
        if (sender?.uid == null) {
          throw Exception('Sender is null');
        }
        if (receiver?.uid == null) {
          throw Exception('Receiver is null');
        }
      }

      // استخدام postPrivateMessage بدلاً من _processMessageByType
      await chatDataSource.postPrivateMessage(privateMessage: message);

      _clearMessageInput();
      print("✅ Message sent successfully");
    } catch (e) {
      print("❌ Failed to send message: $e");
      _showErrorToast('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> sendCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final locationMessage = LocationMessage(
        id: '${position.latitude},${position.longitude}',
        roomId: receiver?.uid ?? '',
        senderId: sender?.uid ?? '',
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await chatDataSource.postMessageToChat(locationMessage);
    } catch (e) {
      _showErrorToast('Failed to send location');
    }
  }

  Future<void> makeAudioCall(CallModel call) async {
    _showLoading();
    try {
      final success = await CallDataSources().storeCall(call);
      if (success) {
        log('Audio call initiated');
      }
    } catch (_) {
    } finally {
      _hideLoading();
    }
  }

  Future<bool> makeVideoCall(CallModel call) async {
    _showLoading();
    try {
      final success = await CallDataSources().storeCall(call);
      if (success) {
        log('Video call initiated');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _hideLoading();
    }
  }

  void handleVote(String option) {
    if (selectedOption.value == option) return;

    if (selectedOption.value == 'Yes') yesVotes.value--;
    if (selectedOption.value == 'No') noVotes.value--;

    selectedOption.value = option;
    if (option == 'Yes') yesVotes.value++;
    if (option == 'No') noVotes.value++;
  }

  double getYesPercentage() =>
      totalVotes == 0 ? 0 : yesVotes.value / totalVotes;
  double getNoPercentage() => totalVotes == 0 ? 0 : noVotes.value / totalVotes;

  void addMessage(Message message) => messages.add(message);
  void removeMessage(int index) {
    if (index >= 0 && index < messages.length) {
      messages.removeAt(index);
    }
  }

  void clearMessages() => messages.clear();

  void _clearMessageInput() {
    messageController.clear();
    update();
  }

  void _showToast(String message) => BotToast.showText(text: message);

  void _showErrorToast(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showLoading() => BotToast.showLoading();
  void _hideLoading() => BotToast.closeAllLoading();

  /// طريقة اختبار لإرسال رسالة تجريبية
  Future<void> sendTestMessage() async {
    try {
      print("🧪 Sending test message...");

      final testMessage = TextMessage(
        id: '', // سيتم تعيينه من قبل Firestore
        roomId: receiver?.uid ?? '',
        senderId: sender?.uid ?? '',
        timestamp: DateTime.now(),
        text: 'Test message - ${DateTime.now().toIso8601String()}',
      );

      await sendMessage(testMessage);
    } catch (e) {
      print("❌ Test message failed: $e");
    }
  }

  /// إرسال رسالة نصية سريعة
  Future<void> sendQuickTextMessage(String text) async {
    if (text.trim().isEmpty) {
      print("⚠️ Empty text message, skipping");
      return;
    }

    // التأكد من صحة المرسل والمستقبل قبل الإرسال
    await _validateAndCorrectSenderReceiver();

    // التأكد من أن المرسل هو المستخدم الحالي
    final currentUserId = UserService.currentUser.value?.uid;
    if (currentUserId == null) {
      print("❌ Current user not available");
      return;
    }

    print("📝 Preparing to send text message: '$text'");
    print(
        "👤 Current user: $currentUserId - ${UserService.currentUser.value?.fullName}");
    print("👤 Sender: ${sender?.uid} - ${sender?.fullName}");
    print("👥 Receiver: ${receiver?.uid} - ${receiver?.fullName}");

    // استخدام المستخدم الحالي كمرسل دائماً
    final textMessage = TextMessage(
      id: '', // سيتم تعيينه من قبل Firestore
      roomId: receiver?.uid ?? '',
      senderId: currentUserId, // استخدام المستخدم الحالي دائماً
      timestamp: DateTime.now(),
      text: text.trim(),
    );

    print("📤 Sending message with senderId: ${textMessage.senderId}");
    await sendMessage(textMessage);
  }

  @override
  void onClose() {
    messageController.dispose();

    // إنهاء جلسة الشات عند إغلاق الشاشة
    if (ChatSessionManager.instance.hasActiveSession) {
      print("🔚 Chat screen closed, ending session");
      ChatSessionManager.instance.endChatSession();
    }

    super.onClose();
  }
}
