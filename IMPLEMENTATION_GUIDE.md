# Crypted App - Real-time Indicators Implementation Guide
**Version:** 2.0
**Date:** November 8, 2025
**Author:** Claude Code

---

## 📚 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Service Integration](#service-integration)
4. [ChatController Integration](#chatcontroller-integration)
5. [UI Implementation](#ui-implementation)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This guide shows you how to integrate the new real-time indicator services into your Crypted app:

- ✅ **TypingService** - "Alice is typing..."
- ✅ **RecordingService** - "🎙️ Bob is recording audio..."
- ✅ **ActivityStatusService** - "👁️ Carol is viewing"
- ✅ **PresenceService** - "Online" / "Last seen 2 minutes ago"
- ✅ **FirebaseOptimizationService** - Enhanced with metrics

---

## Quick Start

### Step 1: Initialize Services in `main.dart`

```dart
import 'package:crypted_app/app/core/services/firebase_optimization_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/typing_service.dart';
import 'package:crypted_app/app/core/services/recording_service.dart';
import 'package:crypted_app/app/core/services/activity_status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // IMPORTANT: Initialize Firebase Optimization Service FIRST
  FirebaseOptimizationService.initializeFirebase();

  // Initialize Presence Service
  await PresenceService().initialize();

  // Set user online after login
  await PresenceService().goOnline();

  runApp(MyApp());
}
```

### Step 2: Import Services in ChatController

```dart
import 'package:crypted_app/app/core/services/recording_service.dart';
import 'package:crypted_app/app/core/services/activity_status_service.dart';

class ChatController extends GetxController {
  // ... existing code ...

  // Add new services
  final recordingService = RecordingService();
  final activityService = ActivityStatusService();

  // Add observable state for indicators
  final RxList<String> recordingUsers = <String>[].obs;
  final RxList<String> viewingUsers = <String>[].obs;
  final RxString recordingText = ''.obs;
  final RxString viewingText = ''.obs;

  // ... rest of controller ...
}
```

---

## Service Integration

### 1. TypingService Integration

**Already implemented!** The typing service is already integrated in ChatController.

**How it works:**
- When user types: `typingService.startTyping(roomId)`
- When user stops: `typingService.stopTyping(roomId)`
- Listen to others: `typingService.listenToTypingUsers(roomId)`

### 2. RecordingService Integration

**Add to ChatController:**

```dart
// In onInit()
@override
void onInit() {
  super.onInit();
  _initializeApp();
  _setupSessionListeners();
  _setupRecordingListener(); // Add this
}

// Add this method
void _setupRecordingListener() {
  if (roomId.isEmpty) return;

  _streamSubscriptions.add(
    recordingService.listenToRecordingUsers(roomId).listen((users) async {
      if (users.isEmpty) {
        recordingUsers.clear();
        recordingText.value = '';
        return;
      }

      final userIds = users.map((u) => u.userId).toList();
      final names = await recordingService.getRecordingUsersNames(roomId, userIds);
      recordingUsers.value = names;
      recordingText.value = recordingService.formatRecordingText(names);
    })
  );
}

// When starting voice recording
void startVoiceRecording() {
  isRecording.value = true;
  recordingService.startRecording(roomId);
  // ... your recording logic ...
}

// When stopping voice recording
void stopVoiceRecording() {
  isRecording.value = false;
  recordingService.stopRecording(roomId);
  // ... your recording logic ...
}
```

**Update cleanup method (already done in phase 2):**

```dart
void _cleanupRealtimeServices() {
  // ... existing typing cleanup ...

  // Add recording cleanup
  try {
    recordingService.cleanupRecording(roomId);
    _logger.debug('Recording service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up recording service', context: 'ChatController', data: {'error': e.toString()});
  }
}
```

### 3. ActivityStatusService Integration

**Add to ChatController:**

```dart
// In onInit()
@override
void onInit() {
  super.onInit();
  _initializeApp();
  _setupSessionListeners();
  _setupRecordingListener();
  _setupActivityListener(); // Add this

  // Mark user as viewing this chat
  activityService.setViewing(roomId);
}

// Add this method
void _setupActivityListener() {
  if (roomId.isEmpty) return;

  _streamSubscriptions.add(
    activityService.listenToViewers(roomId).listen((viewers) async {
      if (viewers.isEmpty) {
        viewingUsers.clear();
        viewingText.value = '';
        return;
      }

      final userIds = viewers.map((v) => v.userId).toList();
      final names = await activityService.getViewerNames(userIds);
      viewingUsers.value = names;
      viewingText.value = activityService.formatViewingText(names);
    })
  );
}

// Record user interaction (call this on scroll, tap, etc.)
void recordUserActivity() {
  activityService.recordInteraction(roomId);
}
```

**Update cleanup method:**

```dart
void _cleanupRealtimeServices() {
  // ... existing cleanup ...

  // Add activity cleanup
  try {
    activityService.setAway(roomId);
    _logger.debug('Activity service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up activity service', context: 'ChatController', data: {'error': e.toString()});
  }
}
```

---

## ChatController Integration

### Complete Enhanced onInit()

```dart
@override
void onInit() {
  super.onInit();
  _initializeApp();
  _setupSessionListeners();
  _setupTypingListener(); // Already exists
  _setupRecordingListener(); // NEW
  _setupActivityListener(); // NEW
  _setupPresenceListener(); // NEW (optional)

  // Mark user as viewing this chat
  activityService.setViewing(roomId);
}
```

### Complete Enhanced onClose()

```dart
@override
void onClose() {
  _logger.info('ChatController disposing - cleaning up resources', context: 'ChatController', data: {
    'roomId': roomId,
    'streamSubscriptions': _streamSubscriptions.length,
  });

  // Dispose MessageController
  messageControllerService.onClose();
  messageController.dispose();

  // Stop all real-time indicators
  _cleanupRealtimeServices();

  // Cancel all stream subscriptions to prevent memory leaks
  for (final subscription in _streamSubscriptions) {
    subscription.cancel();
  }
  _streamSubscriptions.clear();

  // End chat session
  if (ChatSessionManager.instance.hasActiveSession) {
    _logger.info('Chat screen closed, ending session', context: 'ChatController');
    ChatSessionManager.instance.endChatSession();
  }

  _logger.info('ChatController disposed successfully', context: 'ChatController');
  super.onClose();
}

void _cleanupRealtimeServices() {
  // Typing
  try {
    typingService.stopTyping(roomId);
    _logger.debug('Typing service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up typing service', context: 'ChatController', data: {'error': e.toString()});
  }

  // Recording
  try {
    recordingService.cleanupRecording(roomId);
    _logger.debug('Recording service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up recording service', context: 'ChatController', data: {'error': e.toString()});
  }

  // Activity
  try {
    activityService.setAway(roomId);
    _logger.debug('Activity service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up activity service', context: 'ChatController', data: {'error': e.toString()});
  }

  // Read receipts
  try {
    readReceiptService.stopTracking(roomId);
    _logger.debug('Read receipt service cleaned up', context: 'ChatController');
  } catch (e) {
    _logger.warning('Error cleaning up read receipt service', context: 'ChatController', data: {'error': e.toString()});
  }
}
```

---

## UI Implementation

### 1. Create Indicator Widget

Create `lib/app/modules/chat/widgets/chat_indicators_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';

class ChatIndicatorsWidget extends GetView<ChatController> {
  const ChatIndicatorsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Typing Indicator
        Obx(() {
          if (controller.typingText.value.isNotEmpty) {
            return _buildIndicator(
              controller.typingText.value,
              Colors.blue,
              Icons.edit,
            );
          }
          return const SizedBox.shrink();
        }),

        // Recording Indicator
        Obx(() {
          if (controller.recordingText.value.isNotEmpty) {
            return _buildIndicator(
              controller.recordingText.value,
              Colors.red,
              Icons.mic,
              animated: true,
            );
          }
          return const SizedBox.shrink();
        }),

        // Viewing Indicator (optional, can be shown in app bar)
        Obx(() {
          if (controller.viewingText.value.isNotEmpty) {
            return _buildIndicator(
              controller.viewingText.value,
              Colors.green,
              Icons.visibility,
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildIndicator(
    String text,
    Color color,
    IconData icon, {
    bool animated = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          animated
              ? _AnimatedIcon(icon: icon, color: color)
              : Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: FontSize.small,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({required this.icon, required this.color});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Icon(widget.icon, size: 16, color: widget.color),
    );
  }
}
```

### 2. Add to Chat Screen

In `lib/app/modules/chat/views/chat_view.dart`:

```dart
import 'package:crypted_app/app/modules/chat/widgets/chat_indicators_widget.dart';

// In your Scaffold body, add the indicators widget above the message list:

Column(
  children: [
    // Chat app bar here...

    // Add indicators
    const ChatIndicatorsWidget(),

    // Message list
    Expanded(
      child: MessageListView(),
    ),

    // Input field
    MessageInputField(),
  ],
)
```

### 3. Show Presence in App Bar

```dart
// In chat app bar
Obx(() {
  final otherUser = controller.receiver; // For 1-on-1 chats
  if (otherUser == null) return const SizedBox();

  return StreamBuilder<bool>(
    stream: presenceService.listenToUserOnlineStatus(otherUser.uid!),
    builder: (context, snapshot) {
      final isOnline = snapshot.data ?? false;

      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      );
    },
  );
})
```

---

## Testing

### 1. Test Typing Indicators

**Test Case 1: Single User Typing**
1. Open chat with User A
2. User A types → should show "Alice is typing..."
3. User A stops → indicator disappears after 5 seconds

**Test Case 2: Multiple Users Typing**
1. Open group chat
2. User A types → "Alice is typing..."
3. User B types → "Alice and Bob are typing..."
4. User C types → "Alice, Bob and 1 other are typing..."

### 2. Test Recording Indicators

**Test Case 1: Voice Recording**
1. Start recording voice message
2. Other users should see "🎙️ You is recording audio..."
3. Stop recording → indicator disappears

**Test Case 2: Auto-Stop After 10 Minutes**
1. Start recording
2. Wait 10 minutes
3. Indicator should auto-clear

### 3. Test Activity Status

**Test Case 1: Viewing Status**
1. User A opens chat
2. User B should see "👁️ Alice is viewing"
3. User A navigates away → indicator disappears

**Test Case 2: Idle Detection**
1. User A opens chat but doesn't interact
2. After 30 seconds → status changes to idle
3. User A scrolls → status back to viewing

### 4. Test Memory Leaks

**Test Case: Multiple Chat Sessions**
1. Open chat with User A
2. Back to home
3. Open chat with User B
4. Repeat 10 times
5. Check memory usage (should not increase significantly)

**Verify:**
- Stream subscriptions are cancelled
- Services are cleaned up
- No "setState after dispose" errors

---

## Troubleshooting

### Problem: Typing indicator doesn't disappear

**Cause:** Auto-stop timer not working
**Solution:** Check that `stopTyping()` is called in `onClose()`

```dart
@override
void onClose() {
  typingService.stopTyping(roomId);
  super.onClose();
}
```

### Problem: Recording indicator shows for too long

**Cause:** Cleanup not called
**Solution:** Ensure `cleanupRecording()` is called on dispose

```dart
recordingService.cleanupRecording(roomId);
```

### Problem: Memory leak warnings

**Cause:** Stream subscriptions not disposed
**Solution:** Verify all listeners are added to `_streamSubscriptions`:

```dart
_streamSubscriptions.add(
  service.listen(...).listen((data) {
    // handle data
  })
);
```

### Problem: Presence shows "Online" after user disconnects

**Cause:** Heartbeat interval too long
**Solution:** Already fixed in Phase 2 (reduced from 2 min to 30 sec)

### Problem: Firebase quota exceeded

**Cause:** Too many writes for indicators
**Solution:** Indicators are debounced and rate-limited. Check:

```dart
// Typing is debounced by 300ms
// Recording is debounced by 200ms
// Activity heartbeat is only every 10 seconds
```

---

## Performance Optimization

### 1. Firestore Indexes

Create composite indexes for better performance:

```
Collection: chats/{chatId}/typing
Indexes:
- isTyping (Ascending) + timestamp (Descending)

Collection: chats/{chatId}/recording
Indexes:
- isRecording (Ascending) + timestamp (Descending)

Collection: chats/{chatId}/activity
Indexes:
- activityType (Ascending) + lastUpdate (Descending)
```

### 2. Firebase Rules

Update security rules:

```javascript
match /chats/{chatId}/typing/{userId} {
  allow read: if isSignedIn() && isChatMember(chatId);
  allow write: if isSignedIn() && request.auth.uid == userId;
}

match /chats/{chatId}/recording/{userId} {
  allow read: if isSignedIn() && isChatMember(chatId);
  allow write: if isSignedIn() && request.auth.uid == userId;
}

match /chats/{chatId}/activity/{userId} {
  allow read: if isSignedIn() && isChatMember(chatId);
  allow write: if isSignedIn() && request.auth.uid == userId;
}
```

### 3. Monitoring

Check Firebase metrics:

```dart
// Get optimization metrics
final metrics = FirebaseOptimizationService().getMetrics();
print('Cache hit rate: ${metrics['hitRate']}');
print('Avg query time: ${metrics['avgQueryTime']}ms');
print('Rate limit blocks: ${metrics['rateLimitBlocks']}');
```

---

## Next Steps

1. ✅ Integrate services into ChatController
2. ✅ Add indicator widgets to UI
3. ✅ Test all scenarios
4. ✅ Monitor Firebase usage
5. ⏭️ Deploy to production

---

**Questions?** Check the bug report in `BUGS_AND_IMPROVEMENTS_REPORT.md`

**End of Guide**
