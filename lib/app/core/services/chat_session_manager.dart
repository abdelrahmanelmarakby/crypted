import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

/// مدير جلسة الشات لتحديد المرسل والمستقبل من البداية
class ChatSessionManager extends GetxController {
  static ChatSessionManager get instance => Get.find<ChatSessionManager>();

  // المتغيرات التفاعلية لتخزين المرسل والمستقبل
  final Rxn<SocialMediaUser> _sender = Rxn<SocialMediaUser>();
  final Rxn<SocialMediaUser> _receiver = Rxn<SocialMediaUser>();

  // Getters للوصول للبيانات
  SocialMediaUser? get sender => _sender.value;
  SocialMediaUser? get receiver => _receiver.value;

  // Streams للاستماع للتغييرات
  Stream<SocialMediaUser?> get senderStream => _sender.stream;
  Stream<SocialMediaUser?> get receiverStream => _receiver.stream;

  // متغير للتحقق من وجود جلسة شات نشطة
  final RxBool _hasActiveSession = false.obs;
  bool get hasActiveSession => _hasActiveSession.value;

  @override
  void onInit() {
    super.onInit();
    // التأكد من أن هذا المدير متاح في جميع أنحاء التطبيق
    ever(_sender, (user) => _updateSessionStatus());
    ever(_receiver, (user) => _updateSessionStatus());
  }

  /// تحديد المرسل والمستقبل لبدء جلسة شات جديدة
  void startChatSession({
    required SocialMediaUser sender,
    required SocialMediaUser receiver,
  }) {
    print("🚀 Starting chat session:");
    print("👤 Sender: ${sender.fullName} (${sender.uid})");
    print("👥 Receiver: ${receiver.fullName} (${receiver.uid})");

    // التحقق من أن المرسل والمستقبل مختلفين
    if (sender.uid == receiver.uid) {
      print("❌ ERROR: Sender and receiver cannot be the same user!");
      return;
    }

    // التأكد من أن المرسل هو المستخدم الحالي
    final currentUser = UserService.currentUser.value;
    if (currentUser != null && sender.uid != currentUser.uid) {
      print("⚠️ WARNING: Sender is not current user!");
      print("   Current user: ${currentUser.fullName} (${currentUser.uid})");
      print("   Provided sender: ${sender.fullName} (${sender.uid})");

      // تصحيح المرسل والمستقبل إذا كانا مقلوبين
      if (receiver.uid == currentUser.uid) {
        print("🔄 Correcting: swapping sender and receiver...");
        _sender.value = receiver;
        _receiver.value = sender;
      } else {
        print("🔄 Correcting: setting current user as sender...");
        _sender.value = currentUser;
        _receiver.value = receiver;
      }
    } else {
      _sender.value = sender;
      _receiver.value = receiver;
    }

    _hasActiveSession.value = true;

    print("✅ Chat session started successfully");
    print("🎯 Final session:");
    print("   Sender: ${_sender.value?.fullName} (${_sender.value?.uid})");
    print(
        "   Receiver: ${_receiver.value?.fullName} (${_receiver.value?.uid})");
  }

  /// إنهاء جلسة الشات الحالية
  void endChatSession() {
    print("🔚 Ending chat session");
    _sender.value = null;
    _receiver.value = null;
    _hasActiveSession.value = false;
    print("✅ Chat session ended");
  }

  /// التحقق من صحة جلسة الشات
  bool isSessionValid() {
    final isValid = _sender.value != null &&
        _receiver.value != null &&
        _sender.value!.uid != _receiver.value!.uid;

    if (!isValid) {
      print("⚠️ Invalid chat session:");
      print("   Sender: ${_sender.value?.uid}");
      print("   Receiver: ${_receiver.value?.uid}");
    }

    return isValid;
  }

  /// الحصول على بيانات الجلسة كـ Map
  Map<String, dynamic> getSessionData() {
    return {
      'sender': _sender.value,
      'receiver': _receiver.value,
      'hasActiveSession': _hasActiveSession.value,
    };
  }

  /// تحديث حالة الجلسة بناءً على وجود المرسل والمستقبل
  void _updateSessionStatus() {
    _hasActiveSession.value = _sender.value != null && _receiver.value != null;
  }

  /// التحقق من أن المستخدم هو المرسل
  bool isUserSender(String userId) {
    return _sender.value?.uid == userId;
  }

  /// التحقق من أن المستخدم هو المستقبل
  bool isUserReceiver(String userId) {
    return _receiver.value?.uid == userId;
  }

  /// الحصول على المستخدم الآخر (غير المستخدم الحالي)
  SocialMediaUser? getOtherUser(String currentUserId) {
    if (_sender.value?.uid == currentUserId) {
      return _receiver.value;
    } else if (_receiver.value?.uid == currentUserId) {
      return _sender.value;
    }
    return null;
  }

  /// طباعة معلومات الجلسة الحالية (للتطوير)
  void printSessionInfo() {
    print("📋 Current Chat Session Info:");
    print("   Sender: ${_sender.value?.fullName} (${_sender.value?.uid})");
    print(
        "   Receiver: ${_receiver.value?.fullName} (${_receiver.value?.uid})");
    print("   Has Active Session: $_hasActiveSession");
    print("   Session Valid: ${isSessionValid()}");
  }
}
