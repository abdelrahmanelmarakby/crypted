# Chat Module Refactoring Plan - Technical Debt Resolution

## Overview
This document outlines the systematic refactoring of the chat module to resolve technical debt before implementing new features. This approach ensures a solid foundation for future enhancements.

**Priority:** Fix technical debt FIRST, then implement new features (reactions, encryption, etc.)

---

## Phase 1: Code Organization & Structure

### 1.1 Split ChatController (CRITICAL)

**Current State:**
- `ChatController` is 1,430 lines - way too large
- Violates Single Responsibility Principle
- Hard to maintain and test
- All chat functionality in one file

**Goal:** Split into focused, maintainable controllers

**New Structure:**
```
lib/app/modules/chat/controllers/
├── chat_controller.dart (Main coordinator - 300 lines max)
├── message_controller.dart (CRUD operations)
├── media_controller.dart (Image/video/file handling)
├── reaction_controller.dart (Reactions - prep for future)
├── group_controller.dart (Group-specific operations)
└── typing_controller.dart (Typing indicators & presence)
```

**Implementation Steps:**

#### Step 1: Create MessageController
```dart
// lib/app/modules/chat/controllers/message_controller.dart

class MessageController extends GetxController {
  final ChatDataSources chatDataSource;
  final String roomId;

  // Message list management
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoadingMessages = false.obs;

  MessageController({
    required this.chatDataSource,
    required this.roomId,
  });

  // Message Operations
  Future<void> sendTextMessage(String text);
  Future<void> sendImageMessage(File image);
  Future<void> sendVideoMessage(File video);
  Future<void> sendAudioMessage(File audio);
  Future<void> sendFileMessage(File file);
  Future<void> sendLocationMessage(Position position);
  Future<void> sendContactMessage(Contact contact);
  Future<void> sendPollMessage(PollData poll);

  // Message Management
  Future<void> deleteMessage(String messageId);
  Future<void> pinMessage(String messageId);
  Future<void> favoriteMessage(String messageId);
  Future<void> reportMessage(String messageId, String reason);

  // Reply functionality
  void setReplyToMessage(Message? message);
  void clearReply();

  // Message loading
  void _loadMessages();
  void loadMoreMessages(); // Pagination support
}
```

**Files to Create:**
- `lib/app/modules/chat/controllers/message_controller.dart` (~400 lines)

**Files to Extract From:**
- `lib/app/modules/chat/controllers/chat_controller.dart` (lines 200-800)

---

#### Step 2: Create MediaController
```dart
// lib/app/modules/chat/controllers/media_controller.dart

class MediaController extends GetxController {
  // Media upload state
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxString uploadStatus = ''.obs;

  // Compression settings
  final int imageQuality = 85;
  final int maxImageDimension = 1920;

  // Media Operations
  Future<String?> uploadImage(File image, String roomId);
  Future<String?> uploadVideo(File video, String roomId);
  Future<String?> uploadAudio(File audio, String roomId);
  Future<String?> uploadFile(File file, String roomId);

  // Media Compression
  Future<File> compressImage(File image);
  Future<File> compressVideo(File video);
  Future<File> generateVideoThumbnail(File video);

  // Media Picker
  Future<File?> pickImage(ImageSource source);
  Future<File?> pickVideo();
  Future<File?> pickFile();
  Future<List<File>?> pickMultipleImages();

  // Progress tracking
  void _updateProgress(double progress, String status);
}
```

**Files to Create:**
- `lib/app/modules/chat/controllers/media_controller.dart` (~300 lines)
- `lib/app/core/services/media_compression_service.dart` (~200 lines)

**Files to Extract From:**
- `lib/app/modules/chat/controllers/chat_controller.dart` (lines 800-1100)

---

#### Step 3: Create GroupController
```dart
// lib/app/modules/chat/controllers/group_controller.dart

class GroupController extends GetxController {
  final String roomId;
  final UserService userService;

  // Group state
  final RxBool isGroupChat = false.obs;
  final RxString groupName = ''.obs;
  final RxString groupDescription = ''.obs;
  final RxString groupImageUrl = ''.obs;
  final RxList<SocialMediaUser> members = <SocialMediaUser>[].obs;
  final RxList<String> adminIds = <String>[].obs;

  GroupController({
    required this.roomId,
    required this.userService,
  });

  // Group Management
  Future<void> addMember(String userId);
  Future<void> removeMember(String userId);
  Future<void> makeAdmin(String userId);
  Future<void> removeAdmin(String userId);

  // Group Info
  Future<void> updateGroupName(String name);
  Future<void> updateGroupDescription(String description);
  Future<void> updateGroupImage(File image);

  // Permissions
  bool isUserAdmin(String userId);
  bool canUserSendMessages(String userId);
  bool canUserAddMembers(String userId);

  // Group Events
  Future<void> sendMemberAddedEvent(String userId);
  Future<void> sendMemberRemovedEvent(String userId);
  Future<void> sendGroupNameChangedEvent(String oldName, String newName);
}
```

**Files to Create:**
- `lib/app/modules/chat/controllers/group_controller.dart` (~250 lines)

**Files to Extract From:**
- `lib/app/modules/chat/controllers/chat_controller.dart` (lines 1100-1300)

---

#### Step 4: Refactor Main ChatController
```dart
// lib/app/modules/chat/controllers/chat_controller.dart (NEW VERSION)

class ChatController extends GetxController {
  // Sub-controllers
  late final MessageController messageController;
  late final MediaController mediaController;
  late final GroupController? groupController;
  late final TypingService typingService;
  late final ReadReceiptService readReceiptService;
  late final PresenceService presenceService;

  // Basic chat info
  late final String roomId;
  final RxBool isLoading = true.obs;
  final TextEditingController messageInputController = TextEditingController();

  // Current user and members
  SocialMediaUser? get currentUser => UserService.currentUser.value;
  SocialMediaUser? get sender => messageController.members.isNotEmpty
      ? messageController.members.first : null;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _initializeChat();
  }

  void _initializeControllers() {
    final arguments = Get.arguments;
    roomId = arguments?['roomId'] ?? '';

    // Initialize sub-controllers
    messageController = Get.put(
      MessageController(
        chatDataSource: ChatDataSources(),
        roomId: roomId,
      ),
      tag: roomId,
    );

    mediaController = Get.put(MediaController(), tag: roomId);

    if (ChatSessionManager.instance.isGroupChat) {
      groupController = Get.put(
        GroupController(
          roomId: roomId,
          userService: UserService(),
        ),
        tag: roomId,
      );
    }

    typingService = TypingService();
    readReceiptService = ReadReceiptService();
    presenceService = PresenceService();
  }

  // Delegate to sub-controllers
  Future<void> sendMessage(String text) => messageController.sendTextMessage(text);
  Future<void> sendImage(File image) => messageController.sendImageMessage(image);

  @override
  void onClose() {
    _cleanupControllers();
    messageInputController.dispose();
    super.onClose();
  }

  void _cleanupControllers() {
    Get.delete<MessageController>(tag: roomId);
    Get.delete<MediaController>(tag: roomId);
    if (groupController != null) {
      Get.delete<GroupController>(tag: roomId);
    }
  }
}
```

**Files to Modify:**
- `lib/app/modules/chat/controllers/chat_controller.dart` (reduce to ~300 lines)

---

### 1.2 Create Service Layer

**Current State:**
- Business logic mixed with UI logic
- No clear separation of concerns
- Hard to test in isolation

**New Services:**

```
lib/app/core/services/chat/
├── message_service.dart (Message CRUD)
├── media_upload_service.dart (Upload handling)
├── compression_service.dart (Media compression)
├── encryption_service.dart (Future E2E encryption)
└── cache_service.dart (Local message caching)
```

#### MessageService
```dart
// lib/app/core/services/chat/message_service.dart

class MessageService {
  final ChatDataSources _dataSource;

  MessageService(this._dataSource);

  // Send operations
  Future<bool> sendTextMessage({
    required String roomId,
    required String text,
    required String senderId,
    Message? replyTo,
  });

  Future<bool> sendMediaMessage({
    required String roomId,
    required String mediaUrl,
    required MessageType type,
    required String senderId,
    Map<String, dynamic>? metadata,
  });

  // CRUD operations
  Future<bool> deleteMessage(String roomId, String messageId);
  Future<bool> updateMessage(String roomId, String messageId, Map<String, dynamic> updates);

  // Batch operations
  Future<List<Message>> fetchMessagesPaginated({
    required String roomId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  });

  // Search
  Future<List<Message>> searchMessages({
    required String roomId,
    required String query,
    MessageType? type,
  });
}
```

---

## Phase 2: Error Handling & Logging

### 2.1 Implement Comprehensive Error Handling

**Current State:**
- Minimal try-catch blocks
- Generic error messages
- No error tracking
- Poor user feedback

**Goal:** Robust error handling with user-friendly messages

#### Create Error Handler Service
```dart
// lib/app/core/services/error_handler_service.dart

enum ErrorType {
  network,
  permission,
  storage,
  firebase,
  validation,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'No internet connection. Please check your network.';
      case ErrorType.permission:
        return 'Permission denied. Please grant necessary permissions.';
      case ErrorType.storage:
        return 'Storage full. Please free up some space.';
      case ErrorType.firebase:
        return 'Server error. Please try again later.';
      case ErrorType.validation:
        return message; // Use custom validation message
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class ErrorHandlerService {
  static final ErrorHandlerService instance = ErrorHandlerService._();
  ErrorHandlerService._();

  // Error queue for batch reporting
  final List<AppError> _errorQueue = [];

  /// Handle error with appropriate user feedback
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = true,
  }) {
    final appError = _parseError(error, stackTrace, context);

    // Log error
    LoggerService.instance.logError(
      appError.message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Show to user if needed
    if (showToUser) {
      Get.snackbar(
        'Error',
        appError.userFriendlyMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }

    // Track for analytics
    _errorQueue.add(appError);
    if (_errorQueue.length >= 10) {
      _reportErrorBatch();
    }
  }

  AppError _parseError(dynamic error, StackTrace? stackTrace, String? context) {
    if (error is FirebaseException) {
      return AppError(
        type: ErrorType.firebase,
        message: 'Firebase error: ${error.code}',
        technicalDetails: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network error',
        technicalDetails: error.toString(),
        stackTrace: stackTrace,
      );
    }

    if (error is PermissionException) {
      return AppError(
        type: ErrorType.permission,
        message: 'Permission error',
        technicalDetails: error.toString(),
        stackTrace: stackTrace,
      );
    }

    // Default unknown error
    return AppError(
      type: ErrorType.unknown,
      message: error.toString(),
      stackTrace: stackTrace,
    );
  }

  Future<void> _reportErrorBatch() async {
    // Send errors to analytics service
    // Clear queue after reporting
    _errorQueue.clear();
  }
}
```

**Usage Example:**
```dart
// In MessageController
Future<void> sendTextMessage(String text) async {
  try {
    if (text.trim().isEmpty) {
      throw ValidationException('Message cannot be empty');
    }

    await _messageService.sendTextMessage(
      roomId: roomId,
      text: text,
      senderId: currentUser!.id,
    );
  } catch (e, stackTrace) {
    ErrorHandlerService.instance.handleError(
      e,
      stackTrace: stackTrace,
      context: 'sendTextMessage',
      showToUser: true,
    );
  }
}
```

**Files to Create:**
- `lib/app/core/services/error_handler_service.dart`
- `lib/app/core/exceptions/app_exceptions.dart`

---

### 2.2 Implement Structured Logging

**Current State:**
- Using `print()` and `log()` inconsistently
- No log levels
- No remote logging
- Cluttered console output

**Goal:** Professional logging system with levels and remote capability

```dart
// lib/app/core/services/logger_service.dart

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggerService {
  static final LoggerService instance = LoggerService._();
  LoggerService._();

  // Configuration
  bool enableConsoleLogging = true;
  bool enableRemoteLogging = false; // Enable in production
  LogLevel minimumLevel = LogLevel.debug; // Set to info in production

  // Remote logging endpoint (Firebase/Crashlytics)
  final FirebaseCrashlytics? _crashlytics = FirebaseCrashlytics.instance;

  // Log queue for batch sending
  final List<LogEntry> _logQueue = [];
  Timer? _batchTimer;

  void initialize({
    LogLevel? minLevel,
    bool? console,
    bool? remote,
  }) {
    minimumLevel = minLevel ?? LogLevel.debug;
    enableConsoleLogging = console ?? true;
    enableRemoteLogging = remote ?? false;

    // Start batch timer
    _batchTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _sendLogBatch(),
    );
  }

  /// Log debug message
  void debug(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, context: context, data: data);
  }

  /// Log info message
  void info(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, context: context, data: data);
  }

  /// Log warning
  void warning(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, context: context, data: data);
  }

  /// Log error
  void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // Send critical errors immediately to Crashlytics
    if (enableRemoteLogging && error != null) {
      _crashlytics?.recordError(error, stackTrace, reason: message);
    }
  }

  /// Log critical error
  void critical(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    _log(
      LogLevel.critical,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    // Always send critical to Crashlytics
    if (error != null) {
      _crashlytics?.recordError(error, stackTrace, reason: message, fatal: true);
    }
  }

  void _log(
    LogLevel level,
    String message, {
    String? context,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Check minimum level
    if (level.index < minimumLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      context: context,
      data: data,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Console logging
    if (enableConsoleLogging) {
      _printToConsole(entry);
    }

    // Queue for remote logging
    if (enableRemoteLogging) {
      _logQueue.add(entry);
    }
  }

  void _printToConsole(LogEntry entry) {
    final emoji = _getLevelEmoji(entry.level);
    final timestamp = entry.timestamp.toIso8601String();
    final context = entry.context != null ? ' [${entry.context}]' : '';

    print('$emoji $timestamp$context: ${entry.message}');

    if (entry.data != null) {
      print('  Data: ${entry.data}');
    }

    if (entry.error != null) {
      print('  Error: ${entry.error}');
    }

    if (entry.stackTrace != null) {
      print('  Stack: ${entry.stackTrace}');
    }
  }

  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return '📘';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔥';
    }
  }

  Future<void> _sendLogBatch() async {
    if (_logQueue.isEmpty) return;

    try {
      // Send to remote logging service
      // Implementation depends on your backend
      _logQueue.clear();
    } catch (e) {
      print('Failed to send log batch: $e');
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _sendLogBatch(); // Send remaining logs
  }
}

class LogEntry {
  final LogLevel level;
  final String message;
  final String? context;
  final Map<String, dynamic>? data;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.context,
    this.data,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    if (context != null) 'context': context,
    if (data != null) 'data': data,
    if (error != null) 'error': error.toString(),
  };
}
```

**Usage Example:**
```dart
// Replace old logging
// OLD:
// print('Sending message...');
// log('Message sent: $messageId');

// NEW:
LoggerService.instance.info('Sending message', context: 'MessageController');
LoggerService.instance.debug('Message sent', context: 'MessageController', data: {
  'messageId': messageId,
  'roomId': roomId,
  'senderId': senderId,
});

// Error logging
try {
  await sendMessage();
} catch (e, stackTrace) {
  LoggerService.instance.logError(
    'Failed to send message',
    error: e,
    stackTrace: stackTrace,
    context: 'MessageController.sendMessage',
  );
}
```

**Files to Create:**
- `lib/app/core/services/logger_service.dart`

---

## Phase 3: State Management Optimization

### 3.1 Reduce Unnecessary Rebuilds

**Current Issues:**
- Too many `Obx()` wrappers
- Entire lists rebuilding for single item changes
- No use of `GetBuilder` for non-reactive updates

**Solutions:**

#### Use GetBuilder for Specific Updates
```dart
// Instead of:
Obx(() => ListView.builder(
  itemCount: controller.messages.length,
  itemBuilder: (context, index) {
    final message = controller.messages[index];
    return MessageBubble(message: message);
  },
))

// Use:
GetBuilder<ChatController>(
  id: 'messages', // Specific ID
  builder: (controller) => ListView.builder(
    itemCount: controller.messages.length,
    itemBuilder: (context, index) {
      final message = controller.messages[index];
      return MessageBubble(message: message);
    },
  ),
)

// Update only when needed:
void addMessage(Message message) {
  messages.add(message);
  update(['messages']); // Only rebuild 'messages' ID
}
```

#### Optimize Observable Lists
```dart
// Instead of observable list:
final RxList<Message> messages = <Message>[].obs;

// Use regular list + manual updates:
final List<Message> _messages = [];
List<Message> get messages => _messages;

void addMessage(Message message) {
  _messages.add(message);
  update(['messages']);
}

// For real-time updates, still use streams but update manually:
void _listenToMessages() {
  chatDataSource.getMessagesStream(roomId).listen((newMessages) {
    _messages.clear();
    _messages.addAll(newMessages);
    update(['messages']);
  });
}
```

---

### 3.2 Improve Memory Management

**Current Issues:**
- Stream subscriptions not always cancelled
- Controllers not properly disposed
- Large images kept in memory

**Solutions:**

```dart
class MessageController extends GetxController {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  void _setupListeners() {
    // Store all subscriptions
    _subscriptions.add(
      chatDataSource.getMessagesStream(roomId).listen(_handleNewMessages)
    );

    _subscriptions.add(
      typingService.listenToTyping(roomId).listen(_handleTyping)
    );
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Clear cached images
    _clearImageCache();

    super.onClose();
  }

  void _clearImageCache() {
    // Clear cached network images
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
```

---

## Phase 4: Testing Infrastructure

### 4.1 Unit Tests Setup

```dart
// test/app/modules/chat/controllers/message_controller_test.dart

void main() {
  group('MessageController', () {
    late MessageController controller;
    late MockChatDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockChatDataSource();
      controller = MessageController(
        chatDataSource: mockDataSource,
        roomId: 'test_room',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should send text message successfully', () async {
      // Arrange
      when(mockDataSource.sendTextMessage(any, any, any))
          .thenAnswer((_) async => true);

      // Act
      await controller.sendTextMessage('Hello');

      // Assert
      verify(mockDataSource.sendTextMessage(any, any, any)).called(1);
      expect(controller.messages.length, 1);
    });

    test('should handle send message error', () async {
      // Arrange
      when(mockDataSource.sendTextMessage(any, any, any))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => controller.sendTextMessage('Hello'),
        throwsException,
      );
    });
  });
}
```

**Files to Create:**
- `test/app/modules/chat/controllers/message_controller_test.dart`
- `test/app/modules/chat/controllers/media_controller_test.dart`
- `test/app/core/services/error_handler_service_test.dart`
- `test/mocks/mock_chat_data_source.dart`

---

## Implementation Roadmap

### Week 1: Controller Refactoring
- [ ] Day 1-2: Create MessageController
- [ ] Day 3: Create MediaController
- [ ] Day 4: Create GroupController
- [ ] Day 5: Refactor main ChatController

### Week 2: Services & Error Handling
- [ ] Day 1-2: Create service layer (MessageService, MediaUploadService)
- [ ] Day 3: Implement ErrorHandlerService
- [ ] Day 4: Implement LoggerService
- [ ] Day 5: Integration and testing

### Week 3: State Management & Memory
- [ ] Day 1-2: Optimize state management
- [ ] Day 3: Improve memory management
- [ ] Day 4: Add caching layer
- [ ] Day 5: Performance testing

### Week 4: Testing & Documentation
- [ ] Day 1-3: Write unit tests
- [ ] Day 4: Integration tests
- [ ] Day 5: Update documentation

---

## Success Metrics

### Code Quality
- ✅ No file > 500 lines
- ✅ All controllers < 300 lines
- ✅ Test coverage > 70%
- ✅ 0 linter warnings

### Performance
- ✅ < 50ms UI response time
- ✅ < 100MB memory usage
- ✅ No memory leaks
- ✅ < 5% CPU usage idle

### Developer Experience
- ✅ Clear separation of concerns
- ✅ Easy to add new features
- ✅ Comprehensive logging
- ✅ Good error messages

---

## After Refactoring: Ready for New Features

Once technical debt is resolved, we can implement:
1. ✅ Message Reactions (clean codebase makes it easy)
2. ✅ End-to-End Encryption (with proper service layer)
3. ✅ Message Editing (with proper error handling)
4. ✅ Advanced search (with optimized state management)

---

## Next Steps

1. **Review this plan** with the team
2. **Start with MessageController** refactoring (biggest impact)
3. **Create unit tests** as we refactor (TDD approach)
4. **Measure improvements** (performance, memory, etc.)
5. **Document as we go** (code comments, README updates)

---

**Document Version:** 1.0
**Status:** Ready for Implementation
**Priority:** HIGH - Must complete before adding features
