# Firebase Cloud Functions - Complete Implementation Guide

## Overview
This document provides comprehensive documentation for all Firebase Cloud Functions implemented for the Crypted app, including real-time features, notifications, and backend automation.

---

## 📋 Table of Contents
1. [Functions Overview](#functions-overview)
2. [Setup & Deployment](#setup--deployment)
3. [Read Receipts & Delivery Status](#read-receipts--delivery-status)
4. [Typing Indicators](#typing-indicators)
5. [Online/Offline Status](#onlineoffline-status)
6. [Push Notifications](#push-notifications)
7. [Database Structure](#database-structure)
8. [Flutter Integration](#flutter-integration)
9. [Testing](#testing)
10. [Monitoring & Debugging](#monitoring--debugging)

---

## 🎯 Functions Overview

### **Implemented Functions** (13 Total)

#### **Real-Time Features**
1. ✅ `updateDeliveryStatus` - Auto-update message delivery when user comes online
2. ✅ `updateReadReceipts` - Handle read receipts and notify senders
3. ✅ `broadcastTypingIndicator` - Real-time typing indicators
4. ✅ `cleanupTypingIndicators` - Remove stale typing indicators (scheduled)
5. ✅ `updateOnlineStatus` - Broadcast user online/offline status
6. ✅ `setInactiveUsersOffline` - Auto-set inactive users offline (scheduled)

#### **Notifications**
7. ✅ `sendNotifications` - Send push notifications for new messages
8. ✅ `sendCallNotification` - Notify users of incoming calls
9. ✅ `sendStoryNotification` - Notify followers of new stories
10. ✅ `sendBackupNotification` - Notify users of backup completion

#### **Utility Functions**
11. ✅ `cleanupOldNotifications` - Remove old notification logs (scheduled)
12. ✅ `sendScheduledNotifications` - Send scheduled/reminder notifications

---

## 🚀 Setup & Deployment

### **Prerequisites**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase Functions (if not already done)
firebase init functions
```

### **Install Dependencies**
```bash
cd functions
npm install firebase-functions firebase-admin
```

### **Environment Configuration**
```bash
# Set environment variables
firebase functions:config:set app.name="Crypted"
firebase functions:config:set notifications.enabled="true"
```

### **Deploy Functions**
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendNotifications

# Deploy with specific region
firebase deploy --only functions --region us-central1
```

### **Local Testing**
```bash
# Start Firebase emulators
firebase emulators:start

# Test specific function
firebase functions:shell
```

---

## 📨 Read Receipts & Delivery Status

### **1. Update Delivery Status**

**Trigger**: When user comes online  
**Function**: `updateDeliveryStatus`

**How it works:**
1. Monitors `users/{userId}/presence/{sessionId}` collection
2. When user status changes to "online"
3. Finds all undelivered messages for that user
4. Updates message status from "sent" to "delivered"
5. Adds `deliveredAt` timestamp

**Firestore Structure:**
```javascript
// User presence
users/{userId}/presence/{sessionId}
{
  status: 'online' | 'offline',
  lastUpdate: Timestamp,
  deviceId: string
}

// Message with delivery status
messages/{messageId}
{
  senderId: string,
  recipientId: string,
  status: 'sending' | 'sent' | 'delivered' | 'read',
  sentAt: Timestamp,
  deliveredAt: Timestamp | null,
  readAt: Timestamp | null
}
```

**Flutter Integration:**
```dart
// Update user presence when app becomes active
Future<void> setUserOnline() async {
  final sessionId = generateSessionId();
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('presence')
      .doc(sessionId)
      .set({
    'status': 'online',
    'lastUpdate': FieldValue.serverTimestamp(),
    'deviceId': await getDeviceId(),
  });
}

// Listen for delivery status updates
Stream<Message> listenToMessageStatus(String messageId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .doc(messageId)
      .snapshots()
      .map((doc) => Message.fromMap(doc.data()!));
}
```

---

### **2. Read Receipts**

**Trigger**: When user reads a message  
**Function**: `updateReadReceipts`

**How it works:**
1. App creates document in `messages/{messageId}/readReceipts/{userId}`
2. Function updates main message with read status
3. Sends silent notification to sender
4. Updates `readBy` map with user ID

**Firestore Structure:**
```javascript
// Read receipt
messages/{messageId}/readReceipts/{userId}
{
  readAt: Timestamp,
  userId: string
}

// Updated message
messages/{messageId}
{
  status: 'read',
  readAt: Timestamp,
  readBy: {
    [userId]: true
  }
}
```

**Flutter Integration:**
```dart
// Mark message as read
Future<void> markMessageAsRead(String messageId) async {
  await FirebaseFirestore.instance
      .collection('messages')
      .doc(messageId)
      .collection('readReceipts')
      .doc(currentUserId)
      .set({
    'readAt': FieldValue.serverTimestamp(),
    'userId': currentUserId,
  });
}

// Listen for read receipts
Stream<Map<String, bool>> listenToReadReceipts(String messageId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .doc(messageId)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    return (data?['readBy'] as Map<String, dynamic>?)
        ?.map((key, value) => MapEntry(key, value as bool)) ?? {};
  });
}
```

---

## ⌨️ Typing Indicators

### **Broadcast Typing Indicator**

**Trigger**: When user starts/stops typing  
**Function**: `broadcastTypingIndicator`

**How it works:**
1. App updates `chats/{chatId}/typing/{userId}` document
2. Function detects change
3. Broadcasts to all chat participants
4. Sends data-only notification (no UI notification)
5. Auto-cleanup after 30 seconds

**Firestore Structure:**
```javascript
// Typing indicator
chats/{chatId}/typing/{userId}
{
  isTyping: boolean,
  timestamp: Timestamp,
  userId: string
}
```

**Flutter Integration:**
```dart
// Start typing
Future<void> startTyping(String chatId) async {
  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('typing')
      .doc(currentUserId)
      .set({
    'isTyping': true,
    'timestamp': FieldValue.serverTimestamp(),
    'userId': currentUserId,
  });
}

// Stop typing
Future<void> stopTyping(String chatId) async {
  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('typing')
      .doc(currentUserId)
      .delete();
}

// Listen for typing indicators
Stream<List<String>> listenToTypingUsers(String chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('typing')
      .where('isTyping', isEqualTo: true)
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => doc.id).toList()
      );
}

// Handle FCM typing notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'typing_indicator') {
    final chatId = message.data['chatId'];
    final userId = message.data['userId'];
    final isTyping = message.data['isTyping'] == 'true';
    
    // Update UI
    updateTypingIndicator(chatId, userId, isTyping);
  }
});
```

---

## 🟢 Online/Offline Status

### **Update Online Status**

**Trigger**: When user presence changes  
**Function**: `updateOnlineStatus`

**How it works:**
1. Monitors `users/{userId}/presence/{sessionId}`
2. Updates user's main document with online status
3. Broadcasts to all chat participants
4. Includes last seen timestamp when offline

**Firestore Structure:**
```javascript
// User document
users/{userId}
{
  isOnline: boolean,
  lastSeen: Timestamp | null,
  fullName: string,
  imageUrl: string
}
```

**Flutter Integration:**
```dart
// Set user online
Future<void> setOnline() async {
  final sessionId = generateSessionId();
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('presence')
      .doc(sessionId)
      .set({
    'status': 'online',
    'lastUpdate': FieldValue.serverTimestamp(),
  });
}

// Set user offline
Future<void> setOffline() async {
  final presenceSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('presence')
      .get();
  
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in presenceSnapshot.docs) {
    batch.update(doc.reference, {
      'status': 'offline',
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

// Listen for user online status
Stream<bool> listenToUserOnlineStatus(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['isOnline'] ?? false);
}

// Handle presence updates from FCM
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'presence_update') {
    final userId = message.data['userId'];
    final status = message.data['status'];
    
    // Update UI
    updateUserPresence(userId, status == 'online');
  }
});
```

---

## 🔔 Push Notifications

### **1. Message Notifications**

**Function**: `sendNotifications`

**Features:**
- Sends to all chat participants except sender
- Batches notifications (500 per batch)
- Includes message preview
- Deep links to chat
- Auto-cleanup of invalid tokens

**Notification Payload:**
```javascript
{
  notification: {
    title: "John posted in Family Chat",
    body: "Hey everyone! How are you?",
    icon: "https://...",
    click_action: "https://..."
  },
  data: {
    chatId: "chat123",
    messageId: "msg456",
    type: "new_message"
  },
  android: {
    priority: "high",
    ttl: 86400,
    notification: {
      sound: "default",
      tag: "chat_chat123",
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    }
  }
}
```

---

### **2. Call Notifications**

**Function**: `sendCallNotification`

**Features:**
- High priority for immediate delivery
- Custom ringtone
- Full-screen intent on Android
- VoIP push on iOS

**Notification Payload:**
```javascript
{
  notification: {
    title: "John is calling",
    body: "Incoming video call",
    sound: "call_ringtone",
    priority: "high"
  },
  data: {
    type: "incoming_call",
    callId: "call123",
    callerId: "user456",
    callerName: "John Doe",
    callerImage: "https://...",
    callType: "video"
  },
  android: {
    priority: "high",
    ttl: 30,
    notification: {
      sound: "call_ringtone",
      channelId: "calls",
      priority: "max",
      visibility: "public"
    }
  }
}
```

---

### **3. Story Notifications**

**Function**: `sendStoryNotification`

**Features:**
- Sends to all followers
- Batched delivery
- 24-hour TTL
- Includes story type

---

### **4. Backup Notifications**

**Function**: `sendBackupNotification`

**Features:**
- Notifies on completion
- Shows backup size and item count
- Silent notification (no sound)

---

## 🗄️ Database Structure

### **Required Collections**

```javascript
// Users
users/{userId}
{
  uid: string,
  fullName: string,
  email: string,
  imageUrl: string,
  isOnline: boolean,
  lastSeen: Timestamp,
  fcmTokens: string[]
}

// User Presence (subcollection)
users/{userId}/presence/{sessionId}
{
  status: 'online' | 'offline',
  lastUpdate: Timestamp,
  deviceId: string
}

// FCM Tokens
fcmTokens/{token}
{
  uid: string,
  token: string,
  platform: 'android' | 'ios' | 'web',
  createdAt: Timestamp
}

// Chats
chats/{chatId}
{
  participants: string[],
  name: string,
  lastMessage: string,
  lastMessageTime: Timestamp
}

// Typing Indicators (subcollection)
chats/{chatId}/typing/{userId}
{
  isTyping: boolean,
  timestamp: Timestamp,
  userId: string
}

// Messages
messages/{messageId}
{
  chatId: string,
  senderId: string,
  recipientId: string,
  text: string,
  status: 'sending' | 'sent' | 'delivered' | 'read',
  sentAt: Timestamp,
  deliveredAt: Timestamp,
  readAt: Timestamp,
  readBy: { [userId]: boolean }
}

// Read Receipts (subcollection)
messages/{messageId}/readReceipts/{userId}
{
  readAt: Timestamp,
  userId: string
}

// Calls
calls/{callId}
{
  callerId: string,
  calleeId: string,
  type: 'audio' | 'video',
  status: 'ringing' | 'answered' | 'ended' | 'missed',
  startedAt: Timestamp
}

// Stories
stories/{storyId}
{
  userId: string,
  type: 'image' | 'video' | 'text',
  url: string,
  createdAt: Timestamp,
  expiresAt: Timestamp
}

// Backups
backups/{backupId}
{
  userId: string,
  type: string,
  status: 'pending' | 'in_progress' | 'completed' | 'failed',
  itemCount: number,
  size: number,
  completedAt: Timestamp
}

// Scheduled Notifications
scheduledNotifications/{notificationId}
{
  userId: string,
  title: string,
  body: string,
  data: object,
  scheduledFor: Timestamp,
  sent: boolean,
  sentAt: Timestamp
}
```

---

## 📱 Flutter Integration

### **1. Setup FCM**

```dart
// Initialize Firebase Messaging
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await saveFCMToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);
  }

  static Future<void> saveFCMToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('fcmTokens')
        .doc(token)
        .set({
      'uid': userId,
      'token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void handleForegroundMessage(RemoteMessage message) {
    final type = message.data['type'];
    
    switch (type) {
      case 'new_message':
        handleNewMessage(message);
        break;
      case 'incoming_call':
        handleIncomingCall(message);
        break;
      case 'typing_indicator':
        handleTypingIndicator(message);
        break;
      case 'presence_update':
        handlePresenceUpdate(message);
        break;
      case 'read_receipt':
        handleReadReceipt(message);
        break;
    }
  }
}
```

### **2. Presence Management**

```dart
class PresenceService {
  static String? _sessionId;
  static Timer? _heartbeatTimer;

  static Future<void> goOnline() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _sessionId = generateSessionId();
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('presence')
        .doc(_sessionId)
        .set({
      'status': 'online',
      'lastUpdate': FieldValue.serverTimestamp(),
      'deviceId': await getDeviceId(),
    });

    // Start heartbeat
    _heartbeatTimer = Timer.periodic(
      Duration(minutes: 2),
      (_) => _updateHeartbeat(userId),
    );
  }

  static Future<void> goOffline() async {
    _heartbeatTimer?.cancel();
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _sessionId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('presence')
        .doc(_sessionId)
        .update({
      'status': 'offline',
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _updateHeartbeat(String userId) async {
    if (_sessionId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('presence')
        .doc(_sessionId)
        .update({
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
}
```

### **3. Typing Indicators**

```dart
class TypingIndicatorService {
  static Timer? _typingTimer;

  static Future<void> startTyping(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({
      'isTyping': true,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
    });

    // Auto-stop after 5 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(
      Duration(seconds: 5),
      () => stopTyping(chatId),
    );
  }

  static Future<void> stopTyping(String chatId) async {
    _typingTimer?.cancel();
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .delete();
  }
}
```

---

## 🧪 Testing

### **Local Testing with Emulators**

```bash
# Start emulators
firebase emulators:start

# Test functions
firebase functions:shell
```

### **Test Read Receipts**
```javascript
// In Firebase Functions Shell
updateReadReceipts({
  params: {
    messageId: 'test_message_123',
    userId: 'test_user_456'
  },
  data: {
    readAt: new Date(),
    userId: 'test_user_456'
  }
})
```

### **Test Typing Indicators**
```javascript
broadcastTypingIndicator({
  params: {
    chatId: 'test_chat_123',
    userId: 'test_user_456'
  },
  after: {
    exists: true,
    data: () => ({
      isTyping: true,
      timestamp: new Date()
    })
  },
  before: {
    exists: false
  }
})
```

---

## 📊 Monitoring & Debugging

### **View Logs**
```bash
# View all logs
firebase functions:log

# View specific function logs
firebase functions:log --only sendNotifications

# Stream logs in real-time
firebase functions:log --follow
```

### **Monitor Performance**
- Go to Firebase Console → Functions
- View execution count, errors, and latency
- Set up alerts for errors

### **Common Issues**

**1. Notifications not received**
- Check FCM token is saved correctly
- Verify user has granted notification permissions
- Check function logs for errors
- Ensure device is not in Do Not Disturb mode

**2. Typing indicators delayed**
- Check network connectivity
- Verify Firestore indexes are created
- Monitor function execution time

**3. Read receipts not updating**
- Ensure subcollection path is correct
- Check user permissions
- Verify message document exists

---

## 🔒 Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own presence
    match /users/{userId}/presence/{sessionId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Typing indicators
    match /chats/{chatId}/typing/{userId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      allow write: if request.auth.uid == userId;
    }

    // Read receipts
    match /messages/{messageId}/readReceipts/{userId} {
      allow read: if request.auth.uid != null;
      allow create: if request.auth.uid == userId;
    }

    // FCM Tokens
    match /fcmTokens/{token} {
      allow read, write: if request.auth.uid == resource.data.uid;
    }
  }
}
```

---

## 📈 Performance Optimization

### **Best Practices**
1. ✅ Use batched writes (up to 500 operations)
2. ✅ Implement rate limiting
3. ✅ Clean up stale data regularly
4. ✅ Use TTL for temporary data
5. ✅ Index frequently queried fields
6. ✅ Limit query results
7. ✅ Use data-only notifications when possible
8. ✅ Implement exponential backoff for retries

### **Cost Optimization**
- Use scheduled functions for cleanup
- Batch notification sends
- Clean up invalid FCM tokens
- Set appropriate TTL values
- Use Firestore offline persistence

---

## ✅ Checklist for Production

- [ ] All functions deployed successfully
- [ ] FCM tokens are being saved
- [ ] Notifications are received on all platforms
- [ ] Read receipts working correctly
- [ ] Typing indicators showing in real-time
- [ ] Online/offline status updating
- [ ] Scheduled cleanup functions running
- [ ] Security rules configured
- [ ] Monitoring and alerts set up
- [ ] Error handling tested
- [ ] Performance optimized
- [ ] Documentation complete

---

## 📞 Support

For issues or questions:
- Check Firebase Console logs
- Review function execution metrics
- Test with Firebase Emulators
- Monitor Crashlytics for client-side errors

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Status**: ✅ Production Ready
