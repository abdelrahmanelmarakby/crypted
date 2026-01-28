// functions/index.optimized.js
// Phase 1 Optimizations: Consolidated & Cost-Effective Firebase Functions
'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore database instance
const db = admin.firestore();
const rtdb = admin.database(); // Realtime Database for presence

// Get Firebase Cloud Messaging instance
const messaging = admin.messaging();

// Constants
const MAX_RECIPIENTS_PER_BATCH = 500;
const NOTIFICATION_TITLE_MAX_LENGTH = 100;
const NOTIFICATION_BODY_MAX_LENGTH = 250;
const PRESENCE_TIMEOUT = 5 * 60 * 1000; // 5 minutes

/**
 * ============================================================================
 * HELPER FUNCTIONS
 * ============================================================================
 */

/**
 * Validates message data
 */
function validateMessageData(messageData) {
  if (!messageData) return 'Message data is missing';
  if (!messageData.chatId) return 'Message missing chatId';
  if (!messageData.senderId) return 'Message missing senderId';
  return null;
}

/**
 * Fetches FCM tokens for the given user IDs in batches (optimized)
 */
async function getRecipientTokens(userIds) {
  if (userIds.length === 0) return [];

  const tokens = new Set();
  const batchSize = 10; // Firestore 'in' query limit

  // Process in parallel batches for better performance
  const batchPromises = [];
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    batchPromises.push(
      db.collection('fcmTokens')
        .where('uid', 'in', batch)
        .get()
        .then(snapshot => snapshot.docs.map(doc => doc.id))
    );
  }

  const results = await Promise.all(batchPromises);
  results.flat().forEach(token => tokens.add(token));

  return Array.from(tokens);
}

/**
 * Cleans up invalid FCM tokens (optimized with batch operations)
 */
async function cleanupInvalidTokens(tokensWithErrors) {
  const tokensToRemove = [];
  const errorCodes = [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/not-found'
  ];

  tokensWithErrors.forEach(({ token, error }) => {
    if (error && errorCodes.includes(error.code)) {
      tokensToRemove.push(token);
    }
  });

  if (tokensToRemove.length === 0) return 0;

  // Batch delete for better performance
  const batch = db.batch();
  tokensToRemove.forEach(token => {
    batch.delete(db.collection('fcmTokens').doc(token));
  });

  await batch.commit();
  return tokensToRemove.length;
}

/**
 * Check if notification should be sent based on user preferences
 */
async function shouldSendNotification(userId, type) {
  try {
    const settingsDoc = await db
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('notifications')
      .get();

    if (!settingsDoc.exists) return true;

    const settings = settingsDoc.data();
    const typeMap = {
      'message': 'messages',
      'call': 'calls',
      'story': 'stories',
      'backup': 'backups'
    };

    const settingKey = typeMap[type] || type;
    return settings[settingKey] !== false;
  } catch (error) {
    functions.logger.error('Error checking notification settings:', error);
    return true; // Default to enabled if error
  }
}

/**
 * Send notifications with optimized batching (500 tokens at once)
 */
async function sendBatchedNotifications(tokens, payload) {
  if (tokens.length === 0) return { successCount: 0, failureCount: 0 };

  const batchSize = MAX_RECIPIENTS_PER_BATCH;
  const batches = [];

  // Create all batches
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batchTokens = tokens.slice(i, i + batchSize);
    batches.push({
      tokens: batchTokens,
      startIndex: i
    });
  }

  // Send all batches in parallel
  const responses = await Promise.allSettled(
    batches.map(batch =>
      messaging.sendEachForMulticast({
        tokens: batch.tokens,
        ...payload
      })
    )
  );

  // Aggregate results
  let successCount = 0;
  let failureCount = 0;
  const tokensToCleanup = [];

  responses.forEach((response, batchIndex) => {
    if (response.status === 'fulfilled') {
      const res = response.value;
      successCount += res.successCount;
      failureCount += res.failureCount;

      // Collect failed tokens
      const batch = batches[batchIndex];
      res.responses.forEach((result, resultIndex) => {
        if (result.error) {
          tokensToCleanup.push({
            token: batch.tokens[resultIndex],
            error: result.error
          });
        }
      });
    } else {
      const batch = batches[batchIndex];
      failureCount += batch.tokens.length;
      functions.logger.error('Batch send failed:', response.reason);
    }
  });

  // Cleanup invalid tokens
  if (tokensToCleanup.length > 0) {
    const cleanedUpCount = await cleanupInvalidTokens(tokensToCleanup);
    functions.logger.log(`Cleaned up ${cleanedUpCount} invalid FCM tokens`);
  }

  return { successCount, failureCount };
}

/**
 * ============================================================================
 * CONSOLIDATED NOTIFICATION HANDLER
 * Handles messages, calls, stories, and backups in ONE function
 * ============================================================================
 */

/**
 * Handle message notifications
 */
async function handleMessageNotification(snapshot, context) {
  const messageData = snapshot.data();
  const { text = '', name = 'A user', profilePicUrl = '', chatId, senderId } = messageData;

  // Validate
  const validationError = validateMessageData(messageData);
  if (validationError) {
    functions.logger.warn(validationError);
    return null;
  }

  // Get chat and participants
  const chatDoc = await db.collection('chats').doc(chatId).get();
  if (!chatDoc.exists) {
    return null;
  }

  const chatData = chatDoc.data();
  const participants = chatData.participants || [];
  const recipientUserIds = participants.filter(id => id !== senderId);

  if (recipientUserIds.length === 0) return null;

  // Filter by preferences
  const activeRecipients = [];
  for (const recipientId of recipientUserIds) {
    if (await shouldSendNotification(recipientId, 'message')) {
      activeRecipients.push(recipientId);
    }
  }

  if (activeRecipients.length === 0) return null;

  // Get tokens
  const tokens = await getRecipientTokens(activeRecipients);
  if (tokens.length === 0) return null;

  // Build payload
  const chatName = chatData.name || 'a chat';
  const truncatedText = text.length > NOTIFICATION_BODY_MAX_LENGTH
    ? `${text.substring(0, NOTIFICATION_BODY_MAX_LENGTH - 3)}...`
    : text;

  const payload = {
    notification: {
      title: `${name} in ${chatName}`.substring(0, NOTIFICATION_TITLE_MAX_LENGTH),
      body: truncatedText,
      icon: profilePicUrl,
    },
    data: {
      type: 'new_message',
      chatId,
      messageId: context.params.messageId || snapshot.id,
      senderId,
      senderName: name
    },
    android: {
      priority: 'high',
      ttl: 60 * 60 * 24,
      notification: {
        sound: 'default',
        tag: `chat_${chatId}`,
        channelId: 'direct_messages',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    },
    apns: {
      payload: {
        aps: {
          'mutable-content': 1,
          'content-available': 1,
          sound: 'default'
        }
      }
    }
  };

  // Send
  const result = await sendBatchedNotifications(tokens, payload);
  functions.logger.log(`Message notification: ${result.successCount} success, ${result.failureCount} failures`);
  return result;
}

/**
 * Handle call notifications
 */
async function handleCallNotification(snapshot, context) {
  const callData = snapshot.data();
  const { calleeId, callerId, type, status } = callData;

  if (status !== 'ringing') return null;

  // Get caller info
  const callerDoc = await db.collection('users').doc(callerId).get();
  const callerData = callerDoc.exists ? callerDoc.data() : {};

  // Get tokens
  const tokens = await getRecipientTokens([calleeId]);
  if (tokens.length === 0) return null;

  const payload = {
    notification: {
      title: `${callerData.fullName || 'Someone'} is calling`,
      body: `Incoming ${type} call`,
      sound: 'call_ringtone',
    },
    data: {
      type: 'incoming_call',
      callId: context.params.callId || snapshot.id,
      callerId,
      callerName: callerData.fullName || 'Unknown',
      callerImage: callerData.imageUrl || '',
      callType: type
    },
    android: {
      priority: 'high',
      ttl: 30,
      notification: {
        sound: 'call_ringtone',
        channelId: 'incoming_calls',
        priority: 'max',
        visibility: 'public'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'call_ringtone.caf',
          'content-available': 1,
          category: 'CALL'
        }
      }
    }
  };

  const result = await sendBatchedNotifications(tokens, payload);
  functions.logger.log(`Call notification: ${result.successCount} success`);
  return result;
}

/**
 * Handle story notifications
 */
async function handleStoryNotification(snapshot, context) {
  const storyData = snapshot.data();
  const { userId, type } = storyData;

  // Get user info
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.exists ? userDoc.data() : {};

  // Get followers
  const followersSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('followers')
    .get();

  if (followersSnapshot.empty) return null;

  const followerIds = followersSnapshot.docs.map(doc => doc.id);

  // Filter by preferences (parallel for speed)
  const preferenceChecks = await Promise.all(
    followerIds.map(async (followerId) => ({
      followerId,
      shouldSend: await shouldSendNotification(followerId, 'story')
    }))
  );

  const activeFollowers = preferenceChecks
    .filter(check => check.shouldSend)
    .map(check => check.followerId);

  if (activeFollowers.length === 0) return null;

  // Get tokens
  const tokens = await getRecipientTokens(activeFollowers);
  if (tokens.length === 0) return null;

  const payload = {
    notification: {
      title: `${userData.fullName || 'Someone'} posted a story`,
      body: `Check out their new ${type} story`,
      icon: userData.imageUrl || ''
    },
    data: {
      type: 'new_story',
      storyId: context.params.storyId || snapshot.id,
      userId,
      userName: userData.fullName || 'Unknown'
    },
    android: {
      priority: 'normal',
      ttl: 60 * 60 * 24,
      notification: {
        channelId: 'stories'
      }
    }
  };

  const result = await sendBatchedNotifications(tokens, payload);
  functions.logger.log(`Story notification: sent to ${result.successCount} followers`);
  return result;
}

/**
 * Handle backup notifications
 */
async function handleBackupNotification(change, context) {
  const before = change.before.data();
  const after = change.after.data();

  // Only notify when backup completes
  if (before.status !== 'completed' && after.status === 'completed') {
    const { userId, type, itemCount, size } = after;

    const tokens = await getRecipientTokens([userId]);
    if (tokens.length === 0) return null;

    const sizeInMB = (size / (1024 * 1024)).toFixed(2);

    const payload = {
      notification: {
        title: 'Backup Completed',
        body: `Your ${type} backup is complete. ${itemCount} items (${sizeInMB} MB) backed up.`
      },
      data: {
        type: 'backup_completed',
        backupId: context.params.backupId || change.after.id,
        backupType: type,
        itemCount: itemCount.toString(),
        size: size.toString()
      },
      android: {
        priority: 'normal',
        notification: {
          channelId: 'general'
        }
      }
    };

    const result = await sendBatchedNotifications(tokens, payload);
    functions.logger.log(`Backup notification sent: ${result.successCount} success`);
    return result;
  }

  return null;
}

/**
 * ============================================================================
 * EXPORTED FUNCTIONS - V2 for better performance
 * ============================================================================
 */

/**
 * CONSOLIDATED: Message notifications (replaces old sendNotifications)
 */
exports.sendMessageNotifications = onDocumentCreated({
  document: 'messages/{messageId}',
  region: 'us-central1',
  memory: '256MB',
  timeoutSeconds: 60,
}, async (event) => {
  try {
    return await handleMessageNotification(event.data, event.params);
  } catch (error) {
    functions.logger.error('Error in sendMessageNotifications:', error);
    return null;
  }
});

/**
 * CONSOLIDATED: Call notifications (replaces old sendCallNotification)
 */
exports.sendCallNotifications = onDocumentCreated({
  document: 'calls/{callId}',
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 30,
}, async (event) => {
  try {
    return await handleCallNotification(event.data, event.params);
  } catch (error) {
    functions.logger.error('Error in sendCallNotifications:', error);
    return null;
  }
});

/**
 * CONSOLIDATED: Story notifications (replaces old sendStoryNotification)
 */
exports.sendStoryNotifications = onDocumentCreated({
  document: 'Stories/{storyId}',
  region: 'us-central1',
  memory: '256MB',
  timeoutSeconds: 60,
}, async (event) => {
  try {
    return await handleStoryNotification(event.data, event.params);
  } catch (error) {
    functions.logger.error('Error in sendStoryNotifications:', error);
    return null;
  }
});

/**
 * CONSOLIDATED: Backup notifications (replaces old sendBackupNotification)
 */
exports.sendBackupNotifications = onDocumentWritten({
  document: 'backups/{backupId}',
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 30,
}, async (event) => {
  try {
    return await handleBackupNotification(event, event.params);
  } catch (error) {
    functions.logger.error('Error in sendBackupNotifications:', error);
    return null;
  }
});

/**
 * ============================================================================
 * PRESENCE SYSTEM - Using Realtime Database (MUCH cheaper than Firestore)
 * ============================================================================
 */

/**
 * Update user presence in Realtime Database
 * Client should call this via HTTPS callable
 */
exports.updatePresence = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, online, lastSeen } = data;

  if (userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
  }

  try {
    const presenceRef = rtdb.ref(`/presence/${userId}`);

    await presenceRef.set({
      online: online !== undefined ? online : true,
      lastSeen: lastSeen || Date.now(),
      updatedAt: Date.now()
    });

    // Set up automatic offline when disconnected
    if (online) {
      await presenceRef.onDisconnect().set({
        online: false,
        lastSeen: Date.now(),
        updatedAt: Date.now()
      });
    }

    return { success: true };
  } catch (error) {
    functions.logger.error('Error updating presence:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update presence');
  }
});

/**
 * Get presence for multiple users (batch query)
 */
exports.getPresence = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userIds } = data;

  if (!Array.isArray(userIds) || userIds.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'userIds must be a non-empty array');
  }

  try {
    const presenceData = {};

    // Fetch in parallel
    const promises = userIds.map(async (userId) => {
      const snapshot = await rtdb.ref(`/presence/${userId}`).once('value');
      presenceData[userId] = snapshot.val() || { online: false, lastSeen: 0 };
    });

    await Promise.all(promises);

    return { presence: presenceData };
  } catch (error) {
    functions.logger.error('Error getting presence:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get presence');
  }
});

/**
 * Cleanup stale presence data (runs hourly)
 */
exports.cleanupStalePresence = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    try {
      const presenceRef = rtdb.ref('/presence');
      const snapshot = await presenceRef.once('value');
      const presenceData = snapshot.val() || {};

      const now = Date.now();
      const staleThreshold = now - PRESENCE_TIMEOUT;
      const updates = {};
      let staleCount = 0;

      Object.keys(presenceData).forEach(userId => {
        const presence = presenceData[userId];
        if (presence.online && presence.updatedAt < staleThreshold) {
          updates[`${userId}/online`] = false;
          updates[`${userId}/lastSeen`] = presence.updatedAt;
          staleCount++;
        }
      });

      if (staleCount > 0) {
        await presenceRef.update(updates);
        functions.logger.log(`Cleaned up ${staleCount} stale presence records`);
      }

      return { cleaned: staleCount };
    } catch (error) {
      functions.logger.error('Error cleaning up presence:', error);
      return null;
    }
  });

functions.logger.log('✅ Optimized Firebase Functions loaded successfully');
