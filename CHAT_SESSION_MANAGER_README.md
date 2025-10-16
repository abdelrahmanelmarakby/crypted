# نظام إدارة جلسة الشات - Chat Session Manager

## نظرة عامة

تم تطوير نظام إدارة جلسة الشات لحل مشكلة تحديد المرسل والمستقبل في تطبيق الشات. هذا النظام يضمن تحديد المرسل والمستقبل من البداية في صفحة home قبل الانتقال إلى صفحة الشات.

## المميزات الرئيسية

### 1. تحديد المرسل والمستقبل من البداية
- يتم تحديد المرسل (المستخدم الحالي) والمستقبل (المستخدم المختار) في صفحة home
- لا يتم الانتقال إلى صفحة الشات إلا بعد التأكد من صحة البيانات

### 2. مدير جلسة الشات (ChatSessionManager)
- إدارة مركزية لحالة الشات
- تخزين المرسل والمستقبل بشكل آمن
- التحقق من صحة الجلسة
- إنهاء الجلسة تلقائياً عند إغلاق الشات

### 3. واجهة مستخدم محسنة
- تصميم جديد لاختيار المستخدمين
- مؤشرات بصرية للاختيار
- رسائل خطأ واضحة
- تجربة مستخدم سلسة

## كيفية الاستخدام

### 1. بدء جلسة شات جديدة

```dart
// في HomeController
void creatNewChatRoom(SocialMediaUser user) async {
  // التأكد من وجود المستخدم الحالي
  if (UserService.myUser == null) {
    BotToast.showText(text: 'User not loaded. Please try again.');
    return;
  }

  // تحديد المرسل والمستقبل
  final currentUser = UserService.myUser!;
  final otherUser = user;

  // بدء جلسة الشات
  ChatSessionManager.instance.startChatSession(
    sender: currentUser,
    receiver: otherUser,
  );

  // إنشاء غرفة الشات والانتقال إليها
  // ...
}
```

### 2. استخدام بيانات الجلسة في ChatController

```dart
// في ChatController
Future<void> _initializeFromArguments() async {
  final arguments = Get.arguments;
  final useSessionManager = arguments?['useSessionManager'] ?? false;
  
  if (useSessionManager && ChatSessionManager.instance.hasActiveSession) {
    // استخدام مدير الجلسة
    sender = ChatSessionManager.instance.sender;
    receiver = ChatSessionManager.instance.receiver;
  } else {
    // الطريقة القديمة للتوافق
    // ...
  }
}
```

### 3. إنهاء الجلسة

```dart
// إنهاء الجلسة يدوياً
ChatSessionManager.instance.endChatSession();

// أو تلقائياً عند إغلاق الشات
@override
void onClose() {
  if (ChatSessionManager.instance.hasActiveSession) {
    ChatSessionManager.instance.endChatSession();
  }
  super.onClose();
}
```

## الملفات المضافة/المعدلة

### ملفات جديدة:
1. `lib/app/core/services/chat_session_manager.dart` - مدير جلسة الشات
2. `lib/app/modules/home/widgets/user_selection_widget.dart` - واجهة اختيار المستخدمين المحسنة

### ملفات معدلة:
1. `lib/app/modules/home/controllers/home_controller.dart` - تحديث طريقة إنشاء الشات
2. `lib/app/modules/chat/controllers/chat_controller.dart` - استخدام مدير الجلسة
3. `lib/app/modules/home/widgets/tabs_chat.dart` - استخدام الواجهة الجديدة
4. `lib/main.dart` - إضافة مدير الجلسة كـ dependency

## الفوائد

### 1. حل مشكلة تحديد المرسل والمستقبل
- تحديد واضح للمرسل والمستقبل من البداية
- تجنب الأخطاء في تحديد الأدوار
- تحسين موثوقية النظام

### 2. تحسين تجربة المستخدم
- واجهة مستخدم أكثر وضوحاً
- رسائل خطأ واضحة
- تجربة سلسة لبدء المحادثات

### 3. قابلية الصيانة
- كود منظم ومركزي
- سهولة إضافة ميزات جديدة
- توافق مع النظام الحالي

## استكشاف الأخطاء

### مشكلة: "User not loaded"
**الحل:** تأكد من تسجيل دخول المستخدم بشكل صحيح

### مشكلة: "Invalid chat session"
**الحل:** تحقق من صحة بيانات المرسل والمستقبل

### مشكلة: "Session not found"
**الحل:** تأكد من بدء الجلسة قبل الانتقال إلى الشات

## التطوير المستقبلي

1. **دعم المجموعات:** توسيع النظام لدعم المحادثات الجماعية
2. **حفظ الجلسات:** حفظ الجلسات في التخزين المحلي
3. **إشعارات:** إضافة إشعارات للجلسات النشطة
4. **إحصائيات:** تتبع إحصائيات استخدام الجلسات

## الدعم

لأي استفسارات أو مشاكل، يرجى التواصل مع فريق التطوير. 