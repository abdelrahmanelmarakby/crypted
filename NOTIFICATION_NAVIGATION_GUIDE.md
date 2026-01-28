# Notification Navigation Testing Guide

This guide explains how to test the notification navigation system after migrating to awesome_notifications.

## Navigation Flow

When a notification is tapped or an action button is pressed, the app navigates to the appropriate screen based on the notification type.

## Notification Types & Navigation

### 1. Message Notifications (Direct & Group)

**Payload Structure:**
```dart
{
  'type': 'direct_message' or 'group_message',
  'chatId': 'chat123',
  'conversationId': 'chat123',
  'senderId': 'user456',
  'isGroup': 'true' or 'false'
}
```

**Navigation:**
- Tapping notification → Opens chat screen with `roomId` (extracted from chatId/conversationId)
- Uses legacy arguments method to avoid requiring full user objects
- ChatController loads member details automatically

**Test Cases:**
```dart
// Test 1: Tap direct message notification
// Expected: Opens 1-on-1 chat with sender
Get.toNamed(Routes.CHAT, arguments: {
  'roomId': 'chat123',
  'useSessionManager': false,
  'members': [],
  'isGroupChat': false,
});

// Test 2: Tap group message notification
// Expected: Opens group chat
Get.toNamed(Routes.CHAT, arguments: {
  'roomId': 'group456',
  'useSessionManager': false,
  'members': [],
  'isGroupChat': true,
});
```

### 2. Call Notifications

**Payload Structure:**
```dart
{
  'type': 'incoming_call',
  'callId': 'call123',
  'callerId': 'user456',
  'callerName': 'John Doe',
  'callType': 'video' or 'voice'
}
```

**Navigation:**
- Tapping notification → Opens call screen
- Accept button → Opens call screen and updates call status
- Decline button → Updates call status and dismisses notification

**Test Cases:**
```dart
// Test: Tap incoming call notification
Get.toNamed(Routes.CALL, arguments: {
  'callId': 'call123',
  'callerId': 'user456',
  'callerName': 'John Doe',
  'callType': 'video',
});
```

### 3. Story Notifications

**Payload Structure:**
```dart
{
  'type': 'new_story',
  'storyId': 'story123',
  'userId': 'user456'
}
```

**Navigation:**
- Tapping notification → Opens stories viewer for that user
- Reaction buttons → Save reaction to Firebase (no navigation)

**Test Cases:**
```dart
// Test: Tap story notification
Get.toNamed(Routes.STORIES, arguments: {
  'userId': 'user456'
});
```

## Action Buttons Navigation

### Reply Action (Messages)
- **Action:** REPLY or REPLY_GROUP
- **Navigation:** None (silent action)
- **Behavior:**
  1. Text input appears in notification
  2. User types reply
  3. Message sent to Firebase
  4. No screen navigation

### Mark as Read Action
- **Action:** MARK_READ
- **Navigation:** None (silent background action)
- **Behavior:** Updates Firestore `lastReadAt` field

### Mute Action
- **Action:** MUTE
- **Navigation:** None (silent background action)
- **Behavior:** Adds conversation to user's muted list

### Accept/Decline Call Actions
- **Accept Action:** ACCEPT_CALL
  - Navigation: Opens call screen (Routes.CALL)
  - Updates call status to 'accepted'

- **Decline Action:** DECLINE_CALL
  - Navigation: None
  - Updates call status to 'declined'
  - Dismisses notification

### React to Story Actions
- **Actions:** REACT_LIKE, REACT_LOVE, REACT_LAUGH
- **Navigation:** None (silent background actions)
- **Behavior:** Saves emoji reaction to Firebase

## Testing Checklist

### Manual Testing Steps

1. **Setup:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Message Notification Navigation:**
   - [ ] Send message from Device B to Device A
   - [ ] Notification appears on Device A
   - [ ] Tap notification → Correct chat opens
   - [ ] Messages are visible
   - [ ] Can send reply from chat screen

3. **Test Message Reply from Notification:**
   - [ ] Receive message notification
   - [ ] Tap "Reply" button
   - [ ] Text input appears
   - [ ] Type message and send
   - [ ] Message appears in Firebase
   - [ ] Check other device - reply is visible

4. **Test Group Message Navigation:**
   - [ ] Send group message
   - [ ] Notification appears
   - [ ] Tap notification → Group chat opens
   - [ ] All members visible
   - [ ] Can send message

5. **Test Story Navigation:**
   - [ ] Post story from Device B
   - [ ] Notification appears on Device A
   - [ ] Tap notification → Story viewer opens
   - [ ] Correct user's story is shown

6. **Test Story Reactions:**
   - [ ] Receive story notification
   - [ ] Tap 👍 reaction button
   - [ ] Check Firebase - reaction saved
   - [ ] No navigation occurs

7. **Test Call Navigation:**
   - [ ] Initiate call from Device B
   - [ ] Full-screen notification appears on Device A
   - [ ] Tap "Accept" → Call screen opens
   - [ ] Verify call connects

8. **Test Call Decline:**
   - [ ] Receive incoming call
   - [ ] Tap "Decline"
   - [ ] Notification dismisses
   - [ ] Check Firebase - call status = 'declined'

9. **Test Background Navigation:**
   - [ ] Kill app completely (swipe from recent apps)
   - [ ] Send message notification
   - [ ] Tap notification
   - [ ] App opens to correct chat

10. **Test Invalid Data Handling:**
    - [ ] Send notification with missing chatId
    - [ ] App doesn't crash
    - [ ] Falls back to home screen

## Debugging Navigation Issues

### Enable Debug Logging

Add this to notification_controller.dart:
```dart
if (kDebugMode) {
  developer.log(
    'Navigation Debug:\n'
    'Type: $type\n'
    'ChatId: $chatId\n'
    'ConversationId: $conversationId\n'
    'RoomId: ${conversationId ?? chatId}\n'
    'IsGroup: $isGroup',
    name: 'NotificationController',
  );
}
```

### Check Logcat/Console

**For Android:**
```bash
adb logcat | grep "NotificationController"
```

**For iOS:**
```bash
# In Xcode, filter console for "NotificationController"
```

### Common Issues & Solutions

#### Issue 1: Chat opens but shows "Invalid chat parameters"
**Cause:** ChatController not receiving valid roomId
**Solution:** Check payload has 'chatId' or 'conversationId' field

#### Issue 2: Notification tap does nothing
**Cause:** onActionReceivedMethod not registered
**Solution:** Verify main.dart has:
```dart
AwesomeNotifications().setListeners(
  onActionReceivedMethod: NotificationController.onActionReceivedMethod,
);
```

#### Issue 3: App crashes when tapping notification
**Cause:** Route not defined or missing arguments
**Solution:** Verify route exists in app_pages.dart and accepts correct arguments

#### Issue 4: Navigation works in foreground but not background
**Cause:** Background isolate not initialized
**Solution:** Verify main.dart has:
```dart
await NotificationController.initializeIsolateReceivePort();
```

## Cloud Functions Integration

Your Cloud Functions should send FCM messages with this structure:

### For Messages:
```javascript
const message = {
  data: {
    type: 'new_message', // or 'direct_message', 'group_message'
    chatId: 'chat123',
    conversationId: 'chat123', // Same as chatId
    senderId: 'user456',
    senderName: 'John Doe',
    senderAvatar: 'https://...',
    message: 'Hello!',
    isGroup: 'false', // 'true' for groups
  },
  token: deviceFcmToken,
};
```

### For Calls:
```javascript
const message = {
  data: {
    type: 'incoming_call',
    callId: 'call123',
    callerId: 'user456',
    callerName: 'John Doe',
    callerAvatar: 'https://...',
    callType: 'video', // or 'voice'
  },
  token: deviceFcmToken,
};
```

### For Stories:
```javascript
const message = {
  data: {
    type: 'new_story',
    storyId: 'story123',
    userId: 'user456',
    userName: 'John Doe',
    userAvatar: 'https://...',
    storyType: 'photo', // or 'video'
  },
  token: deviceFcmToken,
};
```

## Success Criteria

✅ **All navigation paths work correctly:**
- Tapping message notification opens correct chat
- Tapping call notification opens call screen
- Tapping story notification opens story viewer
- Reply from notification sends to correct chat
- Reactions save to correct story
- Background navigation works (app killed)

✅ **Error handling:**
- Missing data doesn't crash app
- Invalid IDs fall back to home screen
- Network errors handled gracefully

✅ **Performance:**
- Navigation is instant (< 500ms)
- No lag when opening from background
- Smooth transitions between screens

## Additional Notes

- **ChatController Legacy Mode:** Notifications use `useSessionManager: false` to avoid requiring full user objects. The controller loads member details from Firebase automatically.

- **Empty Members Array:** Passing an empty members array is intentional. ChatController will query Firebase to load the member details based on the roomId.

- **Background Isolate:** The `@pragma("vm:entry-point")` annotation ensures navigation works even when the app is completely killed.

---

Last Updated: 2026-01-27
