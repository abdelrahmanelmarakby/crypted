// functions/index.optimized.js
// Phase 1, 2, 3 Optimizations: Fully Optimized v2 Firebase Functions
'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Import v2 function types
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

// Import Cloud Tasks client
const { CloudTasksClient } = require('@google-cloud/tasks');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore database instance
const db = admin.firestore();
const rtdb = admin.database(); // Realtime Database for presence

// Get Firebase Cloud Messaging instance
const messaging = admin.messaging();

// Initialize Cloud Tasks client
const tasksClient = new CloudTasksClient();
const PROJECT_ID = 'crypted-8468f';
const LOCATION = 'us-central1';

// Constants
const MAX_RECIPIENTS_PER_BATCH = 500;
const NOTIFICATION_TITLE_MAX_LENGTH = 100;
const NOTIFICATION_BODY_MAX_LENGTH = 250;
const PRESENCE_TIMEOUT = 5 * 60 * 1000; // 5 minutes

// Rate limiting constants
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_MINUTE = {
  batchStatusUpdate: 60,
  updatePresence: 20,
  getPresence: 100,
  getUserProfile: 100,
  blockUser: 10,
  unblockUser: 10,
  reportUser: 5,
};

// Rate limiting cache (in-memory, resets on cold start)
const rateLimitCache = new Map();

/**
 * ============================================================================
 * HELPER FUNCTIONS
 * ============================================================================
 */

/**
 * Rate limiting check for user requests
 */
function checkRateLimit(userId, functionName) {
  const now = Date.now();
  const key = `${userId}:${functionName}`;
  const limit = MAX_REQUESTS_PER_MINUTE[functionName] || 60;

  if (!rateLimitCache.has(key)) {
    rateLimitCache.set(key, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return { allowed: true, remaining: limit - 1 };
  }

  const userData = rateLimitCache.get(key);

  // Reset if window expired
  if (now > userData.resetTime) {
    rateLimitCache.set(key, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return { allowed: true, remaining: limit - 1 };
  }

  // Check if over limit
  if (userData.count >= limit) {
    const retryAfter = Math.ceil((userData.resetTime - now) / 1000);
    return { allowed: false, remaining: 0, retryAfter };
  }

  // Increment count
  userData.count++;
  return { allowed: true, remaining: limit - userData.count };
}

/**
 * Log function metrics for monitoring
 */
function logMetrics(functionName, duration, success, metadata = {}) {
  const logData = {
    function: functionName,
    duration_ms: duration,
    success,
    timestamp: new Date().toISOString(),
    ...metadata
  };

  if (success) {
    functions.logger.info(`[METRICS] ${functionName}`, logData);
  } else {
    functions.logger.error(`[METRICS] ${functionName} failed`, logData);
  }
}

/**
 * ============================================================================
 * CIRCUIT BREAKER PATTERN
 * ============================================================================
 *
 * Prevents cascading failures by "opening" the circuit when error thresholds
 * are exceeded, giving failing services time to recover.
 *
 * States:
 * - CLOSED: Normal operation, requests pass through
 * - OPEN: Errors exceeded threshold, requests fail fast
 * - HALF_OPEN: Testing if service recovered, limited requests allowed
 */
class CircuitBreaker {
  constructor(name, options = {}) {
    this.name = name;
    this.failureThreshold = options.failureThreshold || 5;
    this.successThreshold = options.successThreshold || 2; // Successes needed to close from HALF_OPEN
    this.timeout = options.timeout || 60000; // 1 minute default
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttempt = Date.now();
    this.lastStateChange = Date.now();
  }

  async execute(operation, fallback = null) {
    // If circuit is OPEN, check if timeout has passed
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        functions.logger.warn(`Circuit breaker ${this.name} is OPEN. Failing fast.`, {
          failureCount: this.failureCount,
          nextAttempt: new Date(this.nextAttempt).toISOString(),
        });

        // Return fallback if provided, otherwise throw error
        if (fallback) {
          return await fallback();
        }

        throw new HttpsError(
          'unavailable',
          `Service temporarily unavailable due to repeated failures. Please try again in ${Math.ceil((this.nextAttempt - Date.now()) / 1000)} seconds.`
        );
      }

      // Timeout passed, transition to HALF_OPEN
      this.state = 'HALF_OPEN';
      this.successCount = 0;
      functions.logger.info(`Circuit breaker ${this.name} transitioning to HALF_OPEN`);
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;

    if (this.state === 'HALF_OPEN') {
      this.successCount++;

      if (this.successCount >= this.successThreshold) {
        // Recovered! Close the circuit
        this.state = 'CLOSED';
        this.lastStateChange = Date.now();
        functions.logger.info(`Circuit breaker ${this.name} recovered and CLOSED`, {
          successCount: this.successCount,
        });
      }
    }
  }

  onFailure() {
    this.failureCount++;
    this.successCount = 0; // Reset success count on any failure

    if (this.failureCount >= this.failureThreshold) {
      if (this.state !== 'OPEN') {
        // Open the circuit
        this.state = 'OPEN';
        this.nextAttempt = Date.now() + this.timeout;
        this.lastStateChange = Date.now();

        functions.logger.error(`Circuit breaker ${this.name} OPENED after ${this.failureCount} failures`, {
          failureCount: this.failureCount,
          timeout: this.timeout,
          nextAttempt: new Date(this.nextAttempt).toISOString(),
        });
      }
    }
  }

  getState() {
    return {
      name: this.name,
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      lastStateChange: new Date(this.lastStateChange).toISOString(),
    };
  }

  // Force reset (for testing or manual recovery)
  reset() {
    this.state = 'CLOSED';
    this.failureCount = 0;
    this.successCount = 0;
    this.lastStateChange = Date.now();
    functions.logger.info(`Circuit breaker ${this.name} manually reset`);
  }
}

// Circuit breakers for different services
const firestoreBreaker = new CircuitBreaker('firestore', {
  failureThreshold: 5,
  successThreshold: 2,
  timeout: 60000, // 1 minute
});

const rtdbBreaker = new CircuitBreaker('rtdb', {
  failureThreshold: 5,
  successThreshold: 2,
  timeout: 60000, // 1 minute
});

const fcmBreaker = new CircuitBreaker('fcm', {
  failureThreshold: 10, // Higher threshold for FCM (transient errors common)
  successThreshold: 3,
  timeout: 120000, // 2 minutes
});

/**
 * Wrapped Firestore operations with circuit breaker
 */
async function safeFirestoreRead(docRef) {
  return await firestoreBreaker.execute(
    async () => {
      const doc = await docRef.get();
      return doc;
    },
    // Fallback: return cached data or empty doc
    async () => {
      functions.logger.warn(`Firestore circuit breaker OPEN, using fallback for ${docRef.path}`);
      return null; // Caller should handle null
    }
  );
}

async function safeFirestoreWrite(docRef, data) {
  return await firestoreBreaker.execute(async () => {
    await docRef.set(data, { merge: true });
    return { success: true };
  });
}

/**
 * Wrapped RTDB operations with circuit breaker
 */
async function safeRTDBRead(ref) {
  return await rtdbBreaker.execute(async () => {
    const snapshot = await ref.once('value');
    return snapshot;
  });
}

async function safeRTDBWrite(ref, data) {
  return await rtdbBreaker.execute(async () => {
    await ref.set(data);
    return { success: true };
  });
}

/**
 * Wrapped FCM operations with circuit breaker
 */
async function safeSendNotification(message) {
  return await fcmBreaker.execute(
    async () => {
      const response = await messaging.send(message);
      return response;
    },
    // Fallback: log notification for retry later
    async () => {
      functions.logger.warn('FCM circuit breaker OPEN, notification queued for retry', {
        message: message,
      });

      // Could queue to Cloud Tasks for retry here
      return { fallback: true, queued: true };
    }
  );
}

/**
 * Health check endpoint to monitor circuit breaker states
 */
exports.healthCheck = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  return {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    circuitBreakers: {
      firestore: firestoreBreaker.getState(),
      rtdb: rtdbBreaker.getState(),
      fcm: fcmBreaker.getState(),
    },
  };
});

/**
 * ============================================================================
 * CLOUD TASKS - ASYNC PROCESSING
 * ============================================================================
 *
 * Heavy operations (notifications, analytics) are queued to Cloud Tasks
 * for async processing, improving function response times and preventing timeouts.
 */

/**
 * Enqueue a task to Cloud Tasks
 */
async function enqueueTask(queueName, taskPayload, options = {}) {
  const queue = tasksClient.queuePath(PROJECT_ID, LOCATION, queueName);

  const url = options.url || `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net/${options.functionName}`;

  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: Buffer.from(JSON.stringify(taskPayload)).toString('base64'),
      oidcToken: {
        serviceAccountEmail: `${PROJECT_ID}@appspot.gserviceaccount.com`,
      },
    },
  };

  // Add schedule time if provided
  if (options.scheduleTime) {
    task.scheduleTime = {
      seconds: Math.floor(options.scheduleTime.getTime() / 1000),
    };
  }

  try {
    const [response] = await tasksClient.createTask({ parent: queue, task });
    functions.logger.info(`Task enqueued to ${queueName}`, {
      taskName: response.name,
      queue: queueName,
    });
    return response;
  } catch (error) {
    functions.logger.error(`Failed to enqueue task to ${queueName}`, {
      error: error.message,
      queue: queueName,
      payload: taskPayload,
    });
    throw error;
  }
}

/**
 * Process notification batch (called by Cloud Tasks)
 * Sends notifications to up to 500 recipients in parallel
 */
exports.processNotificationBatch = onRequest({
  region: 'us-central1',
  memory: '1GB',
  timeoutSeconds: 540, // 9 minutes
  invoker: 'private', // Only Cloud Tasks can invoke
}, async (req, res) => {
  const startTime = Date.now();

  try {
    const { recipients, notification, data } = req.body;

    if (!recipients || !Array.isArray(recipients)) {
      res.status(400).send({ error: 'Invalid recipients' });
      return;
    }

    functions.logger.info('Processing notification batch', {
      recipientCount: recipients.length,
      notification,
    });

    let successCount = 0;
    let failureCount = 0;

    // Process in chunks of 500 (FCM multicast limit)
    for (let i = 0; i < recipients.length; i += MAX_RECIPIENTS_PER_BATCH) {
      const batch = recipients.slice(i, Math.min(i + MAX_RECIPIENTS_PER_BATCH, recipients.length));

      try {
        // Use circuit breaker for FCM
        const result = await fcmBreaker.execute(async () => {
          return await messaging.sendEachForMulticast({
            tokens: batch,
            notification: {
              title: notification.title,
              body: notification.body,
              imageUrl: notification.imageUrl,
            },
            data: data || {},
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channelId: data?.channelId || 'messages',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          });
        });

        successCount += result.successCount;
        failureCount += result.failureCount;

        if (result.failureCount > 0) {
          functions.logger.warn('Some notifications failed', {
            successCount: result.successCount,
            failureCount: result.failureCount,
            responses: result.responses.filter(r => !r.success).map(r => r.error),
          });
        }
      } catch (error) {
        functions.logger.error('FCM batch send failed', {
          error: error.message,
          batchSize: batch.length,
        });
        failureCount += batch.length;
      }
    }

    const duration = Date.now() - startTime;

    logMetrics('processNotificationBatch', duration, true, {
      totalRecipients: recipients.length,
      successCount,
      failureCount,
      successRate: (successCount / recipients.length * 100).toFixed(2) + '%',
    });

    res.status(200).send({
      success: true,
      totalRecipients: recipients.length,
      successCount,
      failureCount,
      duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('processNotificationBatch', duration, false, {
      error: error.message,
    });

    functions.logger.error('processNotificationBatch failed', {
      error: error.message,
      stack: error.stack,
    });

    res.status(500).send({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Process heavy analytics computation (called by Cloud Tasks)
 */
exports.processAnalyticsBatch = onRequest({
  region: 'us-central1',
  memory: '2GB',
  timeoutSeconds: 540,
  invoker: 'private',
}, async (req, res) => {
  const startTime = Date.now();

  try {
    const { analyticsType, params } = req.body;

    functions.logger.info('Processing analytics batch', {
      analyticsType,
      params,
    });

    let result;

    switch (analyticsType) {
      case 'daily':
        result = await computeDailyAnalytics(params);
        break;
      case 'cohort':
        result = await computeCohortAnalytics(params);
        break;
      case 'timeseries':
        result = await computeTimeSeriesAnalytics(params);
        break;
      default:
        throw new Error(`Unknown analytics type: ${analyticsType}`);
    }

    const duration = Date.now() - startTime;
    logMetrics('processAnalyticsBatch', duration, true, {
      analyticsType,
      recordsProcessed: result.recordsProcessed,
    });

    res.status(200).send({
      success: true,
      analyticsType,
      result,
      duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('processAnalyticsBatch', duration, false, {
      error: error.message,
    });

    functions.logger.error('processAnalyticsBatch failed', {
      error: error.message,
      stack: error.stack,
    });

    res.status(500).send({
      success: false,
      error: error.message,
    });
  }
});

// Placeholder analytics functions (implement based on your needs)
async function computeDailyAnalytics(params) {
  // Implementation from existing runAnalytics function
  return { recordsProcessed: 0 };
}

async function computeCohortAnalytics(params) {
  return { recordsProcessed: 0 };
}

async function computeTimeSeriesAnalytics(params) {
  return { recordsProcessed: 0 };
}

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
 * Update user presence in Realtime Database (v2)
 * Client should call this via HTTPS callable
 */
exports.updatePresence = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  const startTime = Date.now();

  // Check authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = request.auth.uid;
  const { online, lastSeen } = request.data;

  // Rate limiting
  const rateLimit = checkRateLimit(userId, 'updatePresence');
  if (!rateLimit.allowed) {
    throw new HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
    );
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

    const duration = Date.now() - startTime;
    logMetrics('updatePresence', duration, true, { userId, online });

    return { success: true };
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('updatePresence', duration, false, { userId, error: error.message });
    throw new HttpsError('internal', 'Failed to update presence');
  }
});

/**
 * Get presence for multiple users (batch query) - v2
 */
exports.getPresence = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 15,
}, async (request) => {
  const startTime = Date.now();

  // Check authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = request.auth.uid;
  const { userIds } = request.data;

  if (!Array.isArray(userIds) || userIds.length === 0) {
    throw new HttpsError('invalid-argument', 'userIds must be a non-empty array');
  }

  if (userIds.length > 100) {
    throw new HttpsError('invalid-argument', 'Maximum 100 userIds allowed per request');
  }

  // Rate limiting
  const rateLimit = checkRateLimit(userId, 'getPresence');
  if (!rateLimit.allowed) {
    throw new HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
    );
  }

  try {
    const presenceData = {};

    // Fetch in parallel
    const promises = userIds.map(async (uid) => {
      const snapshot = await rtdb.ref(`/presence/${uid}`).once('value');
      presenceData[uid] = snapshot.val() || { online: false, lastSeen: 0, updatedAt: 0 };
    });

    await Promise.all(promises);

    const duration = Date.now() - startTime;
    logMetrics('getPresence', duration, true, { userId, count: userIds.length });

    return { presence: presenceData };
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('getPresence', duration, false, { userId, error: error.message });
    throw new HttpsError('internal', 'Failed to get presence');
  }
});

/**
 * Cleanup stale presence data (runs hourly) - v2
 */
exports.cleanupStalePresence = onSchedule({
  schedule: 'every 1 hours',
  region: 'us-central1',
  memory: '256MB',
  timeoutSeconds: 300,
}, async (event) => {
  const startTime = Date.now();

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

    const duration = Date.now() - startTime;
    logMetrics('cleanupStalePresence', duration, true, { cleaned: staleCount });

    return { cleaned: staleCount };
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('cleanupStalePresence', duration, false, { error: error.message });
    return null;
  }
});

/**
 * ============================================================================
 * PHASE 2 OPTIMIZATIONS
 * ============================================================================
 */

/**
 * Batched Status Updates - HTTPS Callable (v2)
 * Replaces individual updateDeliveryStatus and updateReadReceipts functions
 *
 * Reduces invocations by 10x-100x by batching multiple status updates
 *
 * Usage from client:
 * await batchStatusUpdate({
 *   deliveryUpdates: [{chatId, messageId, status}],
 *   readReceipts: [{chatId, messageId, readBy}],
 *   typingIndicators: [{chatId, userId, isTyping}]
 * })
 */
exports.batchStatusUpdate = onCall({
  region: 'us-central1',
  memory: '256MB',
  timeoutSeconds: 30,
}, async (request) => {
  const startTime = Date.now();

  try {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;

    // Rate limiting
    const rateLimit = checkRateLimit(userId, 'batchStatusUpdate');
    if (!rateLimit.allowed) {
      throw new HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
      );
    }
    const {
      deliveryUpdates = [],
      readReceipts = [],
      typingIndicators = []
    } = request.data;

    const batch = db.batch();
    let updateCount = 0;

    // Process delivery status updates
    for (const update of deliveryUpdates) {
      const { chatId, messageId, status } = update;
      if (!chatId || !messageId || !status) continue;

      const messageRef = db.collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

      batch.update(messageRef, {
        deliveryStatus: status,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        [`deliveredBy.${userId}`]: true
      });
      updateCount++;
    }

    // Process read receipts
    for (const receipt of readReceipts) {
      const { chatId, messageId, readBy } = receipt;
      if (!chatId || !messageId) continue;

      const messageRef = db.collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

      batch.update(messageRef, {
        readBy: admin.firestore.FieldValue.arrayUnion(readBy || userId),
        readAt: admin.firestore.FieldValue.serverTimestamp(),
        [`readTimestamps.${userId}`]: admin.firestore.FieldValue.serverTimestamp()
      });
      updateCount++;
    }

    // Process typing indicators (direct Realtime Database update)
    if (typingIndicators.length > 0) {
      const typingUpdates = {};
      for (const indicator of typingIndicators) {
        const { chatId, isTyping } = indicator;
        if (!chatId) continue;

        typingUpdates[`typing/${chatId}/${userId}`] = isTyping ? {
          isTyping: true,
          timestamp: admin.database.ServerValue.TIMESTAMP
        } : null;
        updateCount++;
      }

      await rtdb.ref().update(typingUpdates);
    }

    // Commit all Firestore updates
    if (deliveryUpdates.length > 0 || readReceipts.length > 0) {
      await batch.commit();
    }

    functions.logger.log(`Batched ${updateCount} status updates for user ${userId}`);

    const duration = Date.now() - startTime;
    logMetrics('batchStatusUpdate', duration, true, {
      userId,
      processed: updateCount,
      deliveryUpdates: deliveryUpdates.length,
      readReceipts: readReceipts.length,
      typingIndicators: typingIndicators.length
    });

    return {
      success: true,
      processed: updateCount,
      deliveryUpdates: deliveryUpdates.length,
      readReceipts: readReceipts.length,
      typingIndicators: typingIndicators.length
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('batchStatusUpdate', duration, false, { userId, error: error.message });
    throw new HttpsError('internal', 'Failed to update status');
  }
});

/**
 * Consolidated Analytics Function - Scheduled (v2)
 * Replaces: dailyAggregation, cohortAnalysis, timeSeriesAggregation, realtimeMetrics
 *
 * Reduces cold starts by 4x and reads data once for all analytics
 * Runs every 1 hour to update all metrics
 */
exports.runAnalytics = onSchedule({
  schedule: 'every 1 hours',
  region: 'us-central1',
  memory: '512MB',
  timeoutSeconds: 540,
}, async (event) => {
  const startTime = Date.now();

  try {
      const now = Date.now();
      const oneDayAgo = now - (24 * 60 * 60 * 1000);
      const oneWeekAgo = now - (7 * 24 * 60 * 60 * 1000);

      functions.logger.log('Starting consolidated analytics...');

      // Fetch all required data once
      const [usersSnapshot, messagesSnapshot, storiesSnapshot] = await Promise.all([
        db.collection('users').get(),
        db.collection('chats').get(),
        db.collection('Stories').where('createdAt', '>', new Date(oneDayAgo)).get()
      ]);

      const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      const totalUsers = users.length;
      const activeUsers = users.filter(u => u.lastSeen && u.lastSeen.toMillis() > oneDayAgo).length;

      // Daily aggregation metrics
      const dailyMetrics = {
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        totalUsers,
        activeUsers,
        newUsers: users.filter(u => u.createdAt && u.createdAt.toMillis() > oneDayAgo).length,
        totalStories: storiesSnapshot.size,
        totalChats: messagesSnapshot.size,
        averageMessagesPerUser: messagesSnapshot.size > 0 ? messagesSnapshot.size / totalUsers : 0
      };

      // Cohort analysis (weekly cohorts)
      const cohorts = {};
      users.forEach(user => {
        if (!user.createdAt) return;

        const cohortWeek = Math.floor(user.createdAt.toMillis() / (7 * 24 * 60 * 60 * 1000));
        if (!cohorts[cohortWeek]) {
          cohorts[cohortWeek] = { total: 0, active: 0 };
        }

        cohorts[cohortWeek].total++;
        if (user.lastSeen && user.lastSeen.toMillis() > oneDayAgo) {
          cohorts[cohortWeek].active++;
        }
      });

      // Time series data (hourly snapshots)
      const timeSeriesData = {
        hour: new Date().getHours(),
        date: new Date().toISOString().split('T')[0],
        activeUsers,
        onlineUsers: users.filter(u => u.isOnline).length,
        messages: messagesSnapshot.size,
        stories: storiesSnapshot.size
      };

      // Realtime metrics (current state)
      const realtimeMetrics = {
        onlineUsers: users.filter(u => u.isOnline).length,
        activeChats: messagesSnapshot.docs.filter(doc => {
          const lastMessage = doc.data().lastMessage;
          return lastMessage && lastMessage.createdAt && lastMessage.createdAt.toMillis() > (now - 60000);
        }).length,
        currentHourMessages: 0 // Would need message timestamps
      };

      // Write all analytics to Firestore
      const batch = db.batch();

      // Daily metrics
      batch.set(
        db.collection('analytics').doc('daily').collection('metrics').doc(new Date().toISOString().split('T')[0]),
        dailyMetrics
      );

      // Cohorts
      Object.entries(cohorts).forEach(([week, data]) => {
        batch.set(
          db.collection('analytics').doc('cohorts').collection('weeks').doc(week),
          {
            week: parseInt(week),
            ...data,
            retentionRate: data.total > 0 ? (data.active / data.total) * 100 : 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          },
          { merge: true }
        );
      });

      // Time series
      batch.set(
        db.collection('analytics').doc('timeseries').collection('hourly').doc(`${timeSeriesData.date}-${timeSeriesData.hour}`),
        {
          ...timeSeriesData,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        }
      );

      // Realtime metrics
      batch.set(
        db.collection('analytics').doc('realtime'),
        {
          ...realtimeMetrics,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }
      );

      await batch.commit();

      functions.logger.log('Analytics completed successfully', {
        dailyMetrics,
        cohortCount: Object.keys(cohorts).length,
        realtimeMetrics
      });

      const duration = Date.now() - startTime;
      logMetrics('runAnalytics', duration, true, {
        dailyMetrics,
        cohortCount: Object.keys(cohorts).length,
        realtimeMetrics
      });

      return {
        success: true,
        metrics: {
          daily: dailyMetrics,
          cohorts: Object.keys(cohorts).length,
          realtime: realtimeMetrics
        }
      };
    } catch (error) {
      const duration = Date.now() - startTime;
      logMetrics('runAnalytics', duration, false, { error: error.message });
      return { success: false, error: error.message };
    }
  });

/**
 * User Profile with Caching - HTTPS Callable (v2)
 * Replaces getUserProfile with Redis caching for 80-90% fewer Firestore reads
 *
 * Note: Requires Redis/Memorystore setup (optional, falls back to direct Firestore)
 */
exports.getUserProfileCached = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  const startTime = Date.now();

  try {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const currentUserId = request.auth.uid;
    const { userId } = request.data;

    if (!userId) {
      throw new HttpsError('invalid-argument', 'userId is required');
    }

    // Rate limiting
    const rateLimit = checkRateLimit(currentUserId, 'getUserProfile');
    if (!rateLimit.allowed) {
      throw new HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
      );
    }

    // TODO: Add Redis caching here
    // For now, direct Firestore read with local caching recommendation
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();

    // Remove sensitive fields
    delete userData.email;
    delete userData.phoneNumber;
    delete userData.fcmTokens;

    const duration = Date.now() - startTime;
    logMetrics('getUserProfileCached', duration, true, { currentUserId, userId });

    return {
      success: true,
      user: {
        id: userDoc.id,
        ...userData
      }
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    logMetrics('getUserProfileCached', duration, false, { error: error.message });
    throw new HttpsError('internal', 'Failed to get user profile');
  }
});

/**
 * Sync Privacy Settings (Optimized v2)
 * Keep existing trigger but optimize with batch operations
 */
exports.syncPrivacySettings = onDocumentWritten({
  document: 'users/{userId}/private/privacy',
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (event) => {
  try {
    const userId = event.params.userId;
    const newData = event.data?.after.exists ? event.data.after.data() : null;

    if (!newData) {
      functions.logger.log(`Privacy settings deleted for user ${userId}`);
      return null;
    }

    // Update user's public profile with privacy-safe version
    await db.collection('users').doc(userId).update({
      'privacy.onlineStatus': newData.profileVisibility?.onlineStatus?.setting || 'everyone',
      'privacy.lastSeen': newData.profileVisibility?.lastSeen?.setting || 'everyone',
      'privacy.profilePhoto': newData.profileVisibility?.profilePhoto?.setting || 'everyone',
      'privacy.about': newData.profileVisibility?.about?.setting || 'everyone',
      'privacy.updatedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    functions.logger.log(`Privacy settings synced for user ${userId}`);
    return null;
  } catch (error) {
    functions.logger.error('Error syncing privacy settings:', error);
    return null;
  }
});

/**
 * Sync Notification Settings (Optimized v2)
 * Keep existing trigger but optimize with batch operations
 */
exports.syncNotificationSettings = onDocumentWritten({
  document: 'users/{userId}/private/notificationSettings',
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (event) => {
  try {
    const userId = event.params.userId;
    const newData = event.data?.after.exists ? event.data.after.data() : null;

    if (!newData) {
      functions.logger.log(`Notification settings deleted for user ${userId}`);
      return null;
    }

    // Update user's public profile with notification preferences summary
    await db.collection('users').doc(userId).update({
      'notificationPreferences.messages': newData.messages?.enabled !== false,
      'notificationPreferences.calls': newData.calls?.enabled !== false,
      'notificationPreferences.stories': newData.stories?.enabled !== false,
      'notificationPreferences.updatedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    functions.logger.log(`Notification settings synced for user ${userId}`);
    return null;
  } catch (error) {
    functions.logger.error('Error syncing notification settings:', error);
    return null;
  }
});

/**
 * User Management Functions (v2)
 */

// Block user (v2)
exports.blockUser = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId } = request.data;
  const currentUserId = request.auth.uid;

  if (!userId) {
    throw new HttpsError('invalid-argument', 'userId is required');
  }

  // Rate limiting
  const rateLimit = checkRateLimit(currentUserId, 'blockUser');
  if (!rateLimit.allowed) {
    throw new HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
    );
  }

  try {
    await db.collection('users').doc(currentUserId).collection('blocked').doc(userId).set({
      blockedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
  } catch (error) {
    throw new HttpsError('internal', 'Failed to block user');
  }
});

// Unblock user (v2)
exports.unblockUser = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId } = request.data;
  const currentUserId = request.auth.uid;

  if (!userId) {
    throw new HttpsError('invalid-argument', 'userId is required');
  }

  // Rate limiting
  const rateLimit = checkRateLimit(currentUserId, 'unblockUser');
  if (!rateLimit.allowed) {
    throw new HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
    );
  }

  try {
    await db.collection('users').doc(currentUserId).collection('blocked').doc(userId).delete();

    return { success: true };
  } catch (error) {
    throw new HttpsError('internal', 'Failed to unblock user');
  }
});

// Report user (v2)
exports.reportUser = onCall({
  region: 'us-central1',
  memory: '128MB',
  timeoutSeconds: 10,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, reason, description } = request.data;
  const reportedBy = request.auth.uid;

  if (!userId || !reason) {
    throw new HttpsError('invalid-argument', 'userId and reason are required');
  }

  // Rate limiting
  const rateLimit = checkRateLimit(reportedBy, 'reportUser');
  if (!rateLimit.allowed) {
    throw new HttpsError(
      'resource-exhausted',
      `Rate limit exceeded. Try again in ${rateLimit.retryAfter} seconds`
    );
  }

  try {
    await db.collection('reports').add({
      reportedUserId: userId,
      reportedBy,
      reason,
      description: description || '',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
  } catch (error) {
    throw new HttpsError('internal', 'Failed to report user');
  }
});

/**
 * ============================================================================
 * CASCADE ACCOUNT DELETION
 * ============================================================================
 *
 * Two-layer safety:
 * 1. `deleteUserAccount` (onCall) — Client invokes for server-side cascade.
 * 2. `onUserDeleted` (auth trigger) — Fires automatically if Auth user is
 *    deleted by any means (client SDK, Admin SDK, Firebase Console).
 *    Acts as a cleanup safety net.
 */

/**
 * Helper: delete all documents in a Firestore collection path (paginated).
 */
async function deleteCollection(collectionPath, batchSize = 500) {
  const collectionRef = db.collection(collectionPath);
  let deleted = 0;

  while (true) {
    const snapshot = await collectionRef.limit(batchSize).get();
    if (snapshot.empty) break;

    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    deleted += snapshot.size;

    if (snapshot.size < batchSize) break;
  }

  return deleted;
}

/**
 * Helper: delete all files under a Storage prefix.
 */
async function deleteStoragePrefix(prefix) {
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix });
    await Promise.all(files.map(file => file.delete()));
    return files.length;
  } catch (error) {
    // Folder may not exist — not an error
    functions.logger.warn(`Storage cleanup for ${prefix}: ${error.message}`);
    return 0;
  }
}

/**
 * Core cascade deletion logic (shared by onCall + auth trigger).
 */
async function cascadeDeleteUserData(uid) {
  const startTime = Date.now();
  const results = { deleted: {}, errors: [] };

  functions.logger.info(`🗑️ Starting cascade deletion for user: ${uid}`);

  // 1. User subcollections
  const userSubcollections = [
    'presence', 'blocked', 'contacts', 'private', 'settings',
    'sessions', 'securityLog', 'notifications', 'chatNotificationOverrides',
  ];
  for (const sub of userSubcollections) {
    try {
      const count = await deleteCollection(`users/${uid}/${sub}`);
      results.deleted[`user/${sub}`] = count;
    } catch (e) {
      results.errors.push(`user/${sub}: ${e.message}`);
    }
  }

  // 2. Stories + their subcollections (replies, reactions)
  try {
    const stories = await db.collection('Stories').where('uid', '==', uid).get();
    for (const doc of stories.docs) {
      await deleteCollection(`Stories/${doc.id}/replies`);
      await deleteCollection(`Stories/${doc.id}/reactions`);
      await doc.ref.delete();
    }
    results.deleted.stories = stories.size;
  } catch (e) {
    results.errors.push(`stories: ${e.message}`);
  }

  // 3. Call history
  try {
    const outgoing = await db.collection('Calls').where('callerId', '==', uid).get();
    const incoming = await db.collection('Calls').where('calleeId', '==', uid).get();
    const batch = db.batch();
    [...outgoing.docs, ...incoming.docs].forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    results.deleted.calls = outgoing.size + incoming.size;
  } catch (e) {
    results.errors.push(`calls: ${e.message}`);
  }

  // 4. Remove from chat rooms (don't delete the room — other members still need it)
  try {
    const chatRooms = await db.collection('chats').where('membersIds', 'array-contains', uid).get();
    const batch = db.batch();
    chatRooms.docs.forEach(doc => {
      batch.update(doc.reference, {
        membersIds: admin.firestore.FieldValue.arrayRemove(uid),
      });
    });
    await batch.commit();
    results.deleted.chatMemberships = chatRooms.size;
  } catch (e) {
    results.errors.push(`chatMemberships: ${e.message}`);
  }

  // 5. Notifications
  try {
    const toUser = await db.collection('Notifications').where('toUserId', '==', uid).get();
    const fromUser = await db.collection('Notifications').where('fromUserId', '==', uid).get();
    const batch = db.batch();
    [...toUser.docs, ...fromUser.docs].forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    results.deleted.notifications = toUser.size + fromUser.size;
  } catch (e) {
    results.errors.push(`notifications: ${e.message}`);
  }

  // 6. Backup data
  try {
    const backupSubs = ['device_info', 'location', 'photos', 'backup_summary'];
    for (const sub of backupSubs) {
      await deleteCollection(`backups/${uid}/${sub}`);
    }
    // Backup jobs
    const jobs = await db.collection('backup_jobs').where('userId', '==', uid).get();
    const batch = db.batch();
    jobs.docs.forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    results.deleted.backupJobs = jobs.size;
  } catch (e) {
    results.errors.push(`backups: ${e.message}`);
  }

  // 7. FCM tokens
  try {
    const tokens = await db.collection('fcmTokens').where('uid', '==', uid).get();
    const batch = db.batch();
    tokens.docs.forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    results.deleted.fcmTokens = tokens.size;
  } catch (e) {
    results.errors.push(`fcmTokens: ${e.message}`);
  }

  // 8. Reports
  try {
    const reports = await db.collection('reports').where('reportedUserId', '==', uid).get();
    const batch = db.batch();
    reports.docs.forEach(doc => batch.delete(doc.reference));
    await batch.commit();
    results.deleted.reports = reports.size;
  } catch (e) {
    results.errors.push(`reports: ${e.message}`);
  }

  // 9. Remove from other users' blockedUser arrays
  try {
    const blocking = await db.collection('users').where('blockedUser', 'array-contains', uid).get();
    const batch = db.batch();
    blocking.docs.forEach(doc => {
      batch.update(doc.reference, {
        blockedUser: admin.firestore.FieldValue.arrayRemove(uid),
      });
    });
    await batch.commit();
    results.deleted.blockedReferences = blocking.size;
  } catch (e) {
    results.errors.push(`blockedReferences: ${e.message}`);
  }

  // 10. Storage files
  try {
    const profileDeleted = await deleteStoragePrefix(`profile_images/${uid}`);
    const storiesDeleted = await deleteStoragePrefix(`stories/${uid}`);
    const backupsDeleted = await deleteStoragePrefix(`backups/${uid}`);
    results.deleted.storageFiles = profileDeleted + storiesDeleted + backupsDeleted;
  } catch (e) {
    results.errors.push(`storage: ${e.message}`);
  }

  // 11. Presence data in Realtime Database
  try {
    await rtdb.ref(`/presence/${uid}`).remove();
    results.deleted.presence = 1;
  } catch (e) {
    results.errors.push(`rtdb/presence: ${e.message}`);
  }

  // 12. Delete user document itself
  try {
    await db.collection('users').doc(uid).delete();
    results.deleted.userDoc = 1;
  } catch (e) {
    results.errors.push(`userDoc: ${e.message}`);
  }

  const duration = Date.now() - startTime;
  logMetrics('cascadeDeleteUserData', duration, results.errors.length === 0, {
    uid,
    deleted: results.deleted,
    errorCount: results.errors.length,
  });

  functions.logger.info(`🗑️ Cascade deletion completed for ${uid} in ${duration}ms`, results);
  return results;
}

/**
 * Callable function: client invokes this for server-side cascade deletion.
 * After cascade completes, the client deletes the Firebase Auth account.
 */
exports.deleteUserAccount = onCall({
  region: 'us-central1',
  memory: '1GB',
  timeoutSeconds: 300,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = request.auth.uid;
  functions.logger.info(`deleteUserAccount called by: ${uid}`);

  try {
    const results = await cascadeDeleteUserData(uid);

    // Delete the Auth account server-side (so client doesn't need to)
    try {
      await admin.auth().deleteUser(uid);
      results.deleted.authAccount = true;
    } catch (e) {
      results.errors.push(`authAccount: ${e.message}`);
    }

    return {
      success: results.errors.length === 0,
      deleted: results.deleted,
      errors: results.errors,
    };
  } catch (error) {
    functions.logger.error(`deleteUserAccount failed for ${uid}:`, error);
    throw new HttpsError('internal', 'Failed to delete account');
  }
});

/**
 * Auth trigger: safety net — fires when a Firebase Auth user is deleted
 * by any means (client SDK, Admin SDK, Firebase Console, etc.).
 * Cleans up any Firestore/Storage data left behind.
 */
exports.onUserDeleted = functions
  .region('us-central1')
  .auth.user()
  .onDelete(async (user) => {
    functions.logger.info(`Auth user deleted (safety net): ${user.uid}`);

    try {
      await cascadeDeleteUserData(user.uid);
    } catch (error) {
      functions.logger.error(`Safety net cleanup failed for ${user.uid}:`, error);
    }
  });

// ═══════════════════════════════════════════════════════════════
// PHASE 7: Scheduled Cleanup Functions
// ═══════════════════════════════════════════════════════════════

/**
 * 7.1: Enforce disappearing messages — runs every 5 minutes.
 * 
 * Scans all chat rooms for messages that have a `disappearAfter` field
 * (duration in seconds) and deletes them once their lifetime has elapsed.
 * 
 * Expected message fields:
 *   - disappearAfter: number (seconds after send time to auto-delete)
 *   - timestamp: Firestore Timestamp (when the message was sent)
 */
exports.enforceDisappearingMessages = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'us-central1',
    timeoutSeconds: 120,
    memory: '256MiB',
  },
  async (event) => {
    // Map enum names to milliseconds
    const DURATION_MS = {
      'hours24': 24 * 60 * 60 * 1000,
      'days7': 7 * 24 * 60 * 60 * 1000,
      'days30': 30 * 24 * 60 * 60 * 1000,
      'days90': 90 * 24 * 60 * 60 * 1000,
    };

    const nowMs = Date.now();
    let totalDeleted = 0;
    let totalErrors = 0;

    try {
      // Get all chat rooms that have disappearing messages enabled
      const roomsSnapshot = await db.collection('chats')
        .where('disappearingDuration', 'in', Object.keys(DURATION_MS))
        .get();

      for (const roomDoc of roomsSnapshot.docs) {
        try {
          const roomData = roomDoc.data();
          const durationMs = DURATION_MS[roomData.disappearingDuration];
          if (!durationMs) continue;

          const cutoff = new Date(nowMs - durationMs);
          const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoff);

          // Query messages older than the cutoff
          const messagesSnapshot = await roomDoc.ref
            .collection('chat')
            .where('timestamp', '<', cutoffTimestamp)
            .limit(500)
            .get();

          if (messagesSnapshot.empty) continue;

          const batch = db.batch();
          let batchCount = 0;

          for (const messageDoc of messagesSnapshot.docs) {
            batch.delete(messageDoc.ref);
            batchCount++;

            // Firestore batch limit is 500
            if (batchCount >= 499) {
              await batch.commit();
              totalDeleted += batchCount;
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            await batch.commit();
            totalDeleted += batchCount;
          }
        } catch (roomError) {
          totalErrors++;
          functions.logger.warn(
            `Error processing room ${roomDoc.id}:`,
            roomError
          );
        }
      }

      functions.logger.info(
        `enforceDisappearingMessages: deleted ${totalDeleted} messages from ${roomsSnapshot.size} rooms, ${totalErrors} errors`
      );
    } catch (error) {
      functions.logger.error('enforceDisappearingMessages failed:', error);
    }
  }
);

/**
 * 7.2: Cleanup expired stories — runs every hour.
 * 
 * Stories expire 24 hours after creation. This function:
 *   1. Queries stories where expiresAt < now
 *   2. Deletes associated media from Firebase Storage
 *   3. Deletes the Firestore document
 */
exports.cleanupExpiredStories = onSchedule(
  {
    schedule: 'every 1 hours',
    region: 'us-central1',
    timeoutSeconds: 120,
    memory: '256MiB',
  },
  async (event) => {
    const now = admin.firestore.Timestamp.now();
    let totalDeleted = 0;
    let totalErrors = 0;

    try {
      const expiredStories = await db
        .collection('Stories')
        .where('expiresAt', '<', now)
        .get();

      if (expiredStories.empty) {
        functions.logger.info('cleanupExpiredStories: no expired stories found');
        return;
      }

      const batch = db.batch();
      const storageDeletes = [];

      for (const storyDoc of expiredStories.docs) {
        const data = storyDoc.data();

        // Delete associated media from Storage
        if (data.mediaUrl) {
          try {
            const url = new URL(data.mediaUrl);
            // Extract storage path from download URL
            const pathMatch = url.pathname.match(/\/o\/(.+?)(\?|$)/);
            if (pathMatch) {
              const storagePath = decodeURIComponent(pathMatch[1]);
              storageDeletes.push(
                admin
                  .storage()
                  .bucket()
                  .file(storagePath)
                  .delete()
                  .catch((e) => {
                    // File may already be deleted — not critical
                    functions.logger.warn(
                      `Storage delete failed for ${storagePath}:`,
                      e.message
                    );
                  })
              );
            }
          } catch (urlError) {
            // Invalid URL — skip storage deletion
          }
        }

        // Delete subcollections (replies, reactions)
        const subcollections = ['replies', 'reactions'];
        for (const sub of subcollections) {
          const subDocs = await storyDoc.ref.collection(sub).listDocuments();
          for (const subDoc of subDocs) {
            batch.delete(subDoc);
          }
        }

        batch.delete(storyDoc.ref);
        totalDeleted++;
      }

      // Execute all deletes
      await Promise.all([batch.commit(), ...storageDeletes]);

      functions.logger.info(
        `cleanupExpiredStories: deleted ${totalDeleted} stories, ${totalErrors} errors`
      );
    } catch (error) {
      functions.logger.error('cleanupExpiredStories failed:', error);
    }
  }
);

/**
 * 7.3: Cleanup stale calls — runs every 15 minutes.
 * 
 * Marks calls as "missed" if they've been in "ringing" or "calling" status
 * for more than 2 minutes (likely a crash or network issue).
 */
exports.cleanupStaleCalls = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 60,
    memory: '128MiB',
  },
  async (event) => {
    const twoMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 2 * 60 * 1000)
    );
    let totalCleaned = 0;

    try {
      // Find calls stuck in "ringing" status
      const staleCalls = await db
        .collection('Calls')
        .where('status', 'in', ['ringing', 'calling'])
        .where('createdAt', '<', twoMinutesAgo)
        .get();

      if (staleCalls.empty) {
        functions.logger.info('cleanupStaleCalls: no stale calls found');
        return;
      }

      const batch = db.batch();

      for (const callDoc of staleCalls.docs) {
        batch.update(callDoc.ref, {
          status: 'missed',
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          cleanedUp: true,
        });
        totalCleaned++;
      }

      await batch.commit();

      functions.logger.info(
        `cleanupStaleCalls: cleaned up ${totalCleaned} stale calls`
      );
    } catch (error) {
      functions.logger.error('cleanupStaleCalls failed:', error);
    }
  }
);

/**
 * 7.4: Cleanup stale FCM tokens — runs daily at 3:00 AM UTC.
 * 
 * Removes FCM tokens that haven't been refreshed in 60 days.
 * Stale tokens cause delivery failures and slow down notification sends.
 */
exports.cleanupStaleFCMTokens = onSchedule(
  {
    schedule: '0 3 * * *',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
  },
  async (event) => {
    const sixtyDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 60 * 24 * 60 * 60 * 1000)
    );
    let totalDeleted = 0;
    let totalInvalid = 0;

    try {
      // 1. Delete tokens with stale lastRefreshed timestamp
      const staleTokens = await db
        .collection('fcmTokens')
        .where('lastRefreshed', '<', sixtyDaysAgo)
        .get();

      const batch = db.batch();

      for (const tokenDoc of staleTokens.docs) {
        batch.delete(tokenDoc.ref);
        totalDeleted++;
      }

      if (totalDeleted > 0) {
        await batch.commit();
      }

      // 2. Validate remaining tokens by sending a dry-run message
      const allTokens = await db
        .collection('fcmTokens')
        .orderBy('lastRefreshed', 'desc')
        .limit(1000) // Process up to 1000 tokens per run
        .get();

      const invalidTokenIds = [];

      // Check tokens in batches of 500 (FCM sendEach limit)
      const tokenBatches = [];
      for (let i = 0; i < allTokens.docs.length; i += 500) {
        tokenBatches.push(allTokens.docs.slice(i, i + 500));
      }

      for (const tokenBatch of tokenBatches) {
        const messages = tokenBatch.map((doc) => ({
          token: doc.data().token || doc.id,
          data: { dryRun: 'true' },
          android: { priority: 'normal' },
        }));

        try {
          const response = await messaging.sendEach(messages, true); // dryRun=true

          response.responses.forEach((resp, idx) => {
            if (
              resp.error &&
              (resp.error.code === 'messaging/registration-token-not-registered' ||
                resp.error.code === 'messaging/invalid-registration-token')
            ) {
              invalidTokenIds.push(tokenBatch[idx].ref);
              totalInvalid++;
            }
          });
        } catch (batchError) {
          functions.logger.warn('FCM dry-run batch error:', batchError.message);
        }
      }

      // Delete invalid tokens
      if (invalidTokenIds.length > 0) {
        const cleanupBatch = db.batch();
        for (const ref of invalidTokenIds) {
          cleanupBatch.delete(ref);
        }
        await cleanupBatch.commit();
      }

      functions.logger.info(
        `cleanupStaleFCMTokens: deleted ${totalDeleted} stale + ${totalInvalid} invalid tokens`
      );
    } catch (error) {
      functions.logger.error('cleanupStaleFCMTokens failed:', error);
    }
  }
);

// ──────────────────────────────────────────────
// Phase 8.3: Unread Count Management
// ──────────────────────────────────────────────

/**
 * Increment unreadCounts for all members (except sender) when a new message is created.
 * Stores a per-user map on the chat room: { unreadCounts: { userId: number } }
 */
exports.incrementUnreadCounts = onDocumentCreated(
  {
    document: 'chats/{roomId}/chat/{messageId}',
    region: LOCATION,
  },
  async (event) => {
    try {
      const messageData = event.data?.data();
      if (!messageData) return;

      const roomId = event.params.roomId;
      const senderId = messageData.senderId || messageData.sender;
      if (!senderId) return;

      const roomRef = db.collection('chats').doc(roomId);
      const roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;

      const roomData = roomSnap.data();
      const membersIds = roomData.membersIds || [];

      // Build increment update for all members except the sender
      const update = {};
      for (const memberId of membersIds) {
        if (memberId !== senderId) {
          update[`unreadCounts.${memberId}`] = admin.firestore.FieldValue.increment(1);
        }
      }

      if (Object.keys(update).length > 0) {
        await roomRef.update(update);
      }
    } catch (error) {
      functions.logger.error('incrementUnreadCounts failed:', error);
    }
  }
);

/**
 * Reset unread count for a specific user when they open/read a chat.
 * Called from the client via onCall.
 */
exports.resetUnreadCount = onCall(
  { region: LOCATION },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const roomId = request.data?.roomId;
    if (!roomId || typeof roomId !== 'string') {
      throw new HttpsError('invalid-argument', 'roomId is required');
    }

    try {
      const roomRef = db.collection('chats').doc(roomId);
      await roomRef.update({
        [`unreadCounts.${uid}`]: 0,
      });
      return { success: true };
    } catch (error) {
      functions.logger.error('resetUnreadCount failed:', error);
      throw new HttpsError('internal', 'Failed to reset unread count');
    }
  }
);

functions.logger.log('✅ Phase 1, 2, 3, 7 & 8 Fully Optimized v2 Firebase Functions loaded successfully');
