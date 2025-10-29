# Flutter Integration Checklist for Firebase Functions

## 🎯 Overview
This checklist outlines all the Flutter-side implementations needed to integrate with the Firebase Cloud Functions.

---

## ✅ **1. FCM Setup & Token Management**

### **Dependencies to Add**
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

### **Implementation Needed**

#### **A. FCM Service** (`lib/app/core/services/fcm_service.dart`)
```dart
✅ Initialize Firebase Messaging
✅ Request notification permissions
✅ Get and save FCM token to Firestore
✅ Listen for token refresh
✅ Handle foreground messages
✅ Handle background messages
✅ Handle notification taps
✅ Route to appropriate screens based on notification type
```

#### **B. Token Storage**
```dart
✅ Save token to fcmTokens/{token} collection
✅ Include platform (android/ios)
✅ Update token on refresh
✅ Delete token on logout
```

---

## ✅ **2. Presence Management**

### **Implementation Needed**

#### **A. Presence Service** (`lib/app/core/services/presence_service.dart`)
```dart
✅ goOnline() - Set user online when app opens
✅ goOffline() - Set user offline when app closes
✅ Heartbeat timer (every 120 minutes)
✅ Update presence on app lifecycle changes
✅ Clean up on logout
```

#### **B. App Lifecycle Integration**
```dart
✅ Listen to AppLifecycleState changes
✅ Set online when app is resumed
✅ Set offline when app is paused/detached
✅ Handle background/foreground transitions
```

#### **C. Firestore Structure**
```dart
✅ Create users/{userId}/presence/{sessionId} documents
✅ Include status, lastUpdate, deviceId
✅ Generate unique session ID per device
```

---

## ✅ **3. Read Receipts**

### **Implementation Needed**

#### **A. Mark Messages as Read**
```dart
✅ Detect when message is visible on screen
✅ Create readReceipts/{userId} subcollection document
✅ Update only once per message per user
✅ Batch mark multiple messages as read
```

#### **B. Display Read Status**
```dart
✅ Show checkmarks: ✓ (sent), ✓✓ (delivered), ✓✓ (blue for read)
✅ Listen to message status changes
✅ Update UI in real-time
✅ Show "Read by" list for group chats
```

#### **C. Handle Read Receipt Notifications**
```dart
✅ Listen for 'read_receipt' type in FCM
✅ Update message status in local cache
✅ Update UI without full reload
```

---

## ✅ **4. Typing Indicators**

### **Implementation Needed**

#### **A. Typing Service** (`lib/app/core/services/typing_service.dart`)
```dart
✅ startTyping(chatId) - Called when user types
✅ stopTyping(chatId) - Called when user stops
✅ Auto-stop after 5 seconds of inactivity
✅ Debounce typing events (500ms)
✅ Clean up on screen disposal
```

#### **B. UI Integration**
```dart
✅ Show "User is typing..." indicator
✅ Animate typing dots (...)
✅ Handle multiple users typing
✅ Display in chat app bar or above input
```

#### **C. Listen for Typing Updates**
```dart
✅ Stream chats/{chatId}/typing collection
✅ Filter out current user
✅ Update UI in real-time
✅ Handle FCM typing notifications
```

---

## ✅ **5. Online/Offline Status**

### **Implementation Needed**

#### **A. Display User Status**
```dart
✅ Show green dot for online users
✅ Show "Last seen" for offline users
✅ Update in real-time
✅ Show in chat list and chat screen
```

#### **B. Listen for Status Updates**
```dart
✅ Stream users/{userId} document
✅ Listen for isOnline field changes
✅ Handle presence_update FCM notifications
✅ Update UI immediately
```

#### **C. Format Last Seen**
```dart
✅ "Online" for active users
✅ "Last seen just now" (< 1 min)
✅ "Last seen 5 minutes ago"
✅ "Last seen today at 3:45 PM"
✅ "Last seen yesterday at 10:30 AM"
✅ "Last seen on Jan 15"
```

---

## ✅ **6. Message Notifications**

### **Implementation Needed**

#### **A. Handle New Message Notifications**
```dart
✅ Show notification with message preview
✅ Include sender name and avatar
✅ Group notifications by chat
✅ Play notification sound
✅ Vibrate device
✅ Show badge count
```

#### **B. Notification Actions**
```dart
✅ Tap to open chat
✅ Reply from notification (Android)
✅ Mark as read action
✅ Mute chat action
```

#### **C. Foreground Handling**
```dart
✅ Show in-app notification banner
✅ Update chat list in real-time
✅ Auto-scroll to new message if chat is open
✅ Play subtle sound
```

---

## ✅ **7. Call Notifications**

### **Implementation Needed**

#### **A. Incoming Call UI**
```dart
✅ Full-screen incoming call screen
✅ Show caller name and avatar
✅ Answer/Decline buttons
✅ Play ringtone
✅ Vibrate continuously
```

#### **B. Handle Call Notifications**
```dart
✅ Parse incoming_call notification
✅ Navigate to call screen
✅ Pass caller info
✅ Handle missed calls
✅ Show call history
```

#### **C. Call State Management**
```dart
✅ Track call status (ringing, answered, ended)
✅ Update Firestore call document
✅ Handle call timeout (30 seconds)
✅ Clean up on call end
```

---

## ✅ **8. Story Notifications**

### **Implementation Needed**

#### **A. Handle Story Notifications**
```dart
✅ Show notification for new stories
✅ Navigate to story viewer
✅ Mark story as viewed
✅ Update story ring indicator
```

#### **B. Story Ring Indicator**
```dart
✅ Show colored ring for unviewed stories
✅ Gray ring for viewed stories
✅ Animate ring on new story
✅ Update in real-time
```

---

## ✅ **9. Backup Notifications**

### **Implementation Needed**

#### **A. Backup Progress**
```dart
✅ Show progress notification during backup
✅ Update progress percentage
✅ Show completion notification
✅ Handle backup errors
```

#### **B. Handle Completion Notification**
```dart
✅ Show success message
✅ Display backup size and item count
✅ Navigate to backup history
```

---

## ✅ **10. Scheduled Notifications**

### **Implementation Needed**

#### **A. Create Scheduled Notifications**
```dart
✅ Schedule reminder notifications
✅ Schedule message sends
✅ Store in scheduledNotifications collection
✅ Include scheduledFor timestamp
```

#### **B. Handle Scheduled Notifications**
```dart
✅ Receive notification at scheduled time
✅ Execute scheduled action
✅ Update UI accordingly
```

---

## 📱 **Code Templates**

### **1. FCM Service Template**
```dart
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // TODO: Request permissions
    // TODO: Get FCM token
    // TODO: Save token to Firestore
    // TODO: Listen for token refresh
    // TODO: Handle foreground messages
    // TODO: Handle background messages
    // TODO: Handle notification taps
  }
  
  static Future<void> saveFCMToken(String token) async {
    // TODO: Save to fcmTokens collection
  }
  
  static void handleForegroundMessage(RemoteMessage message) {
    // TODO: Route based on message.data['type']
  }
}
```

### **2. Presence Service Template**
```dart
class PresenceService {
  static Timer? _heartbeatTimer;
  static String? _sessionId;
  
  static Future<void> goOnline() async {
    // TODO: Create presence document
    // TODO: Start heartbeat timer
  }
  
  static Future<void> goOffline() async {
    // TODO: Update presence to offline
    // TODO: Cancel heartbeat timer
  }
  
  static Future<void> _updateHeartbeat(String userId) async {
    // TODO: Update lastUpdate timestamp
  }
}
```

### **3. Typing Service Template**
```dart
class TypingService {
  static Timer? _typingTimer;
  
  static Future<void> startTyping(String chatId) async {
    // TODO: Create typing document
    // TODO: Auto-stop after 5 seconds
  }
  
  static Future<void> stopTyping(String chatId) async {
    // TODO: Delete typing document
  }
}
```

---

## 🔧 **Configuration Files**

### **1. Android Configuration**

#### **AndroidManifest.xml**
```xml
<!-- Add inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorPrimary" />
```

#### **Notification Channels** (`MainActivity.kt`)
```kotlin
private fun createNotificationChannels() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        // Messages channel
        val messagesChannel = NotificationChannel(
            "messages",
            "Messages",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "New message notifications"
            enableVibration(true)
            setShowBadge(true)
        }
        
        // Calls channel
        val callsChannel = NotificationChannel(
            "calls",
            "Calls",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Incoming call notifications"
            enableVibration(true)
            setShowBadge(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(messagesChannel)
        manager.createNotificationChannel(callsChannel)
    }
}
```

### **2. iOS Configuration**

#### **AppDelegate.swift**
```swift
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: {_, _ in })
    
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🧪 **Testing Checklist**

### **Notifications**
- [ ] Foreground message received and displayed
- [ ] Background message received
- [ ] Notification tap opens correct screen
- [ ] Sound plays correctly
- [ ] Badge count updates
- [ ] Notification grouped by chat

### **Read Receipts**
- [ ] Messages marked as read when visible
- [ ] Sender receives read receipt
- [ ] Checkmarks update correctly
- [ ] Group chat shows all readers

### **Typing Indicators**
- [ ] Typing indicator shows when user types
- [ ] Indicator disappears after 5 seconds
- [ ] Multiple users typing handled correctly
- [ ] Indicator updates in real-time

### **Online Status**
- [ ] User shows online when app is active
- [ ] User shows offline when app is closed
- [ ] Last seen updates correctly
- [ ] Status updates in real-time

### **Calls**
- [ ] Incoming call notification received
- [ ] Full-screen call UI appears
- [ ] Ringtone plays
- [ ] Answer/decline works correctly
- [ ] Missed calls logged

---

## 📊 **Performance Considerations**

### **Optimization Tips**
1. ✅ Debounce typing events (300ms)
2. ✅ Batch read receipts (mark multiple at once)
3. ✅ Use local cache for presence status
4. ✅ Limit Firestore listeners
5. ✅ Clean up listeners on dispose
6. ✅ Use efficient queries with indexes
7. ✅ Implement pagination for messages
8. ✅ Compress notification payloads

### **Battery Optimization**
1. ✅ Use data-only notifications when possible
2. ✅ Reduce heartbeat frequency (2-5 minutes)
3. ✅ Stop typing timer when not needed
4. ✅ Clean up presence on app background
5. ✅ Use WorkManager for scheduled tasks

---

## 🔒 **Security Checklist**

- [ ] Validate user authentication before operations
- [ ] Check user permissions for chat access
- [ ] Sanitize notification content
- [ ] Verify FCM token ownership
- [ ] Implement rate limiting on client
- [ ] Handle token expiration
- [ ] Secure sensitive data in notifications

---

## 📈 **Monitoring**

### **Track These Metrics**
- Notification delivery rate
- Read receipt accuracy
- Typing indicator latency
- Presence update speed
- FCM token refresh rate
- Error rates for each feature

### **Analytics Events**
```dart
// Log important events
Analytics.logEvent('notification_received', {
  'type': notificationType,
  'timestamp': DateTime.now().toIso8601String(),
});

Analytics.logEvent('message_read', {
  'chatId': chatId,
  'messageId': messageId,
});

Analytics.logEvent('typing_started', {
  'chatId': chatId,
});
```

---

## ✅ **Final Checklist**

- [ ] All services implemented
- [ ] FCM tokens saved correctly
- [ ] Presence management working
- [ ] Read receipts functional
- [ ] Typing indicators real-time
- [ ] All notification types handled
- [ ] UI updates in real-time
- [ ] Error handling implemented
- [ ] Performance optimized
- [ ] Security measures in place
- [ ] Testing completed
- [ ] Documentation updated

---

## 🚀 **Deployment Steps**

1. ✅ Deploy Firebase Functions
2. ✅ Test with Firebase Emulators
3. ✅ Implement Flutter services
4. ✅ Test on real devices
5. ✅ Monitor logs and metrics
6. ✅ Fix any issues
7. ✅ Deploy to production
8. ✅ Monitor production metrics

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Status**: ✅ Ready for Implementation
