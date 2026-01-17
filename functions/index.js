// functions/index.js
'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore database instance
const db = admin.firestore();

// Get Firebase Cloud Messaging instance
const messaging = admin.messaging();

// Constants
const MAX_RECIPIENTS_PER_BATCH = 500;
const NOTIFICATION_TITLE_MAX_LENGTH = 100;
const NOTIFICATION_BODY_MAX_LENGTH = 250;


/**
 * Validates message data and returns an error message if invalid
 */
function validateMessageData(messageData) {
  if (!messageData) {
    return 'Message data is missing';
  }
  if (!messageData.chatId) {
    return 'Message missing chatId';
  }
  if (!messageData.senderId) {
    return 'Message missing senderId';
  }
  return null;
}

/**
 * Fetches chat document and validates its existence
 */
async function getChatDocument(chatId) {
  const chatDoc = await db.collection('chats').doc(chatId).get();
  if (!chatDoc.exists) {
    throw new Error(`Chat document for ID ${chatId} not found`);
  }
  return chatDoc;
}

/**
 * Fetches FCM tokens for the given user IDs in batches
 */
async function getRecipientTokens(userIds) {
  const tokens = new Set();
  const batchSize = 10; // Firestore 'in' query limit
  
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const snapshot = await db
      .collection('fcmTokens')
      .where('uid', 'in', batch)
      .get();
    
    snapshot.forEach(doc => tokens.add(doc.id));
  }
  
  return Array.from(tokens);
}

/**
 * Cleans up invalid FCM tokens
 */
async function cleanupInvalidTokens(tokens, results) {
  const tokensToRemove = [];
  
  results.forEach((result, index) => {
    if (result.error) {
      const error = result.error;
      const errorCodes = [
        'messaging/invalid-registration-token',
        'messaging/registration-token-not-registered',
        'messaging/not-found'
      ];
      
      if (errorCodes.includes(error.code)) {
        tokensToRemove.push(
          db.collection('fcmTokens').doc(tokens[index]).delete()
        );
      }
    }
  });
  
  if (tokensToRemove.length > 0) {
    await Promise.allSettled(tokensToRemove);
  }
  
  return tokensToRemove.length;
}

/**
 * Cloud Function triggered when a new message is created
 */
const sendNotifications = onDocumentCreated(
  { document: 'messages/{messageId}' },
  async (event) => {
    const snapshot = event.data;
    const context = event.params;
    const messageData = snapshot.data();
    const { text = '', name = 'A user', profilePicUrl = '/images/profile_placeholder.png', chatId, senderId } = messageData;

    try {
      // 1. Validate message data
      const validationError = validateMessageData(messageData);
      if (validationError) {
        functions.logger.warn(validationError);
        return null;
      }

      // 2. Get chat document and participants
      const chatDoc = await getChatDocument(chatId);
      const chatData = chatDoc.data();
      const participants = chatData.participants || [];
      
      // Filter out the sender
      const recipientUserIds = participants.filter(id => id !== senderId);
      
      if (recipientUserIds.length === 0) {
        functions.logger.log(`No recipients for chat ${chatId} after filtering sender.`);
        return null;
      }

      // 3. Filter recipients based on notification preferences
      const activeRecipients = [];
      for (const recipientId of recipientUserIds) {
        const shouldSend = await shouldSendNotification(recipientId, 'message');
        if (shouldSend) {
          activeRecipients.push(recipientId);
        } else {
          functions.logger.log(`Skipping notification for user ${recipientId} - notifications disabled`);
        }
      }

      if (activeRecipients.length === 0) {
        functions.logger.log('All recipients have disabled message notifications.');
        return null;
      }

      // 4. Get FCM tokens for active recipients
      const tokens = await getRecipientTokens(activeRecipients);

      if (tokens.length === 0) {
        functions.logger.log('No FCM tokens found for recipients.');
        return null;
      }

      // 5. Prepare notification payload
      const chatName = chatData.name || 'a chat';
      const truncatedText = text.length > NOTIFICATION_BODY_MAX_LENGTH 
        ? `${text.substring(0, NOTIFICATION_BODY_MAX_LENGTH - 3)}...`
        : text;
      
      const payload = {
        notification: {
          title: `${name} posted in ${chatName}`.substring(0, NOTIFICATION_TITLE_MAX_LENGTH),
          body: truncatedText,
          icon: profilePicUrl,
          click_action: `https://${process.env.GCLOUD_PROJECT}.firebaseapp.com/chat/${chatId}`,
        },
        data: {
          chatId,
          messageId: context.params.messageId,
          type: 'new_message'
        },
        apns: {
          payload: {
            aps: {
              'mutable-content': 1,
              'content-available': 1
            }
          }
        },
        android: {
          priority: 'high',
          ttl: 60 * 60 * 24, // 24 hours
          notification: {
            sound: 'default',
            tag: `chat_${chatId}`,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          }
        }
      };

      // 6. Send notifications in batches if needed
      const batchSize = MAX_RECIPIENTS_PER_BATCH;
      const batches = [];
      
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batchTokens = tokens.slice(i, i + batchSize);
        batches.push(
          messaging.sendEachForMulticast({
            tokens: batchTokens,
            ...payload
          })
        );
      }

      // 7. Process all batches
      const responses = await Promise.allSettled(batches);
      let successCount = 0;
      let failureCount = 0;
      let tokensToCleanup = [];

      responses.forEach((response, batchIndex) => {
        if (response.status === 'fulfilled') {
          const res = response.value;
          successCount += res.successCount;
          failureCount += res.failureCount;
          
          // Collect tokens that need cleanup
          const batchStart = batchIndex * batchSize;
          const batchEnd = Math.min((batchIndex + 1) * batchSize, tokens.length);
          const batchTokens = tokens.slice(batchStart, batchEnd);
          
          res.responses.forEach((result, resultIndex) => {
            if (result.error) {
              tokensToCleanup.push({
                token: batchTokens[resultIndex],
                error: result.error
              });
            }
          });
        } else {
          // Handle batch failure
          failureCount += Math.min(batchSize, tokens.length - (batchIndex * batchSize));
          functions.logger.error('Batch send failed:', response.reason);
        }
      });

      // 8. Clean up invalid tokens
      if (tokensToCleanup.length > 0) {
        const cleanedUpCount = await cleanupInvalidTokens(
          tokensToCleanup.map(t => t.token),
          tokensToCleanup.map(t => ({ error: t.error }))
        );
        functions.logger.log(`Cleaned up ${cleanedUpCount} invalid FCM tokens`);
      }

      functions.logger.log(`Successfully sent ${successCount} notifications with ${failureCount} failures`);
      return { success: true, successCount, failureCount };
    } catch (error) {
      functions.logger.error('Error in sendNotifications:', error);
      // Don't throw the error to prevent retries for transient issues
      if (process.env.NODE_ENV === 'development') {
        console.error('Detailed error:', error);
      }
      return null;
    }
  });

// Export the function
exports.sendNotifications = sendNotifications;

// ============================================================================
// READ RECEIPTS & DELIVERY STATUS
// ============================================================================

/**
 * Update message delivery status when user comes online
 * Marks messages as delivered when recipient is online
 */
exports.updateDeliveryStatus = functions.firestore
  .document('users/{userId}/presence/{sessionId}')
  .onWrite(async (change, context) => {
    const { userId } = context.params;
    const after = change.after.exists ? change.after.data() : null;
    
    if (!after || after.status !== 'online') {
      return null;
    }

    try {
      // Get all undelivered messages for this user
      const messagesSnapshot = await db
        .collection('messages')
        .where('recipientId', '==', userId)
        .where('status', '==', 'sent')
        .limit(100)
        .get();

      if (messagesSnapshot.empty) {
        return null;
      }

      // Batch update messages to delivered
      const batch = db.batch();
      messagesSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          status: 'delivered',
          deliveredAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await batch.commit();
      functions.logger.log(`Updated ${messagesSnapshot.size} messages to delivered for user ${userId}`);
      
      return { updated: messagesSnapshot.size };
    } catch (error) {
      functions.logger.error('Error updating delivery status:', error);
      return null;
    }
  });

/**
 * Update read receipts when user reads messages
 * Triggered when readReceipts subcollection is updated
 */
exports.updateReadReceipts = functions.firestore
  .document('messages/{messageId}/readReceipts/{userId}')
  .onCreate(async (snap, context) => {
    const { messageId, userId } = context.params;
    const readData = snap.data();

    try {
      // Update the main message document
      await db.collection('messages').doc(messageId).update({
        status: 'read',
        readAt: readData.readAt || admin.firestore.FieldValue.serverTimestamp(),
        [`readBy.${userId}`]: true
      });

      // Get message data to notify sender
      const messageDoc = await db.collection('messages').doc(messageId).get();
      const messageData = messageDoc.data();

      if (!messageData || !messageData.senderId) {
        return null;
      }

      // Send read receipt notification to sender
      const senderTokens = await getRecipientTokens([messageData.senderId]);
      
      if (senderTokens.length > 0) {
        const payload = {
          data: {
            type: 'read_receipt',
            messageId,
            readBy: userId,
            readAt: new Date().toISOString()
          },
          android: {
            priority: 'normal',
            ttl: 60 * 5 // 5 minutes
          }
        };

        await messaging.sendEachForMulticast({
          tokens: senderTokens,
          ...payload
        });
      }

      functions.logger.log(`Read receipt updated for message ${messageId} by user ${userId}`);
      return { success: true };
    } catch (error) {
      functions.logger.error('Error updating read receipt:', error);
      return null;
    }
  });

// ============================================================================
// TYPING INDICATORS
// ============================================================================

/**
 * Broadcast typing indicator to chat participants
 * Triggered when user starts/stops typing
 */
exports.broadcastTypingIndicator = functions.firestore
  .document('chats/{chatId}/typing/{userId}')
  .onWrite(async (change, context) => {
    const { chatId, userId } = context.params;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    // Only process if typing status changed
    if (before?.isTyping === after?.isTyping) {
      return null;
    }

    try {
      // Get chat participants
      const chatDoc = await db.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        return null;
      }

      const chatData = chatDoc.data();
      const participants = (chatData.participants || []).filter(id => id !== userId);

      if (participants.length === 0) {
        return null;
      }

      // Get user info
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.exists ? userDoc.data() : {};

      // Get FCM tokens for participants
      const tokens = await getRecipientTokens(participants);

      if (tokens.length === 0) {
        return null;
      }

      // Send typing indicator
      const payload = {
        data: {
          type: 'typing_indicator',
          chatId,
          userId,
          userName: userData.fullName || 'Someone',
          isTyping: after?.isTyping ? 'true' : 'false',
          timestamp: new Date().toISOString()
        },
        android: {
          priority: 'high',
          ttl: 10 // 10 seconds
        }
      };

      await messaging.sendEachForMulticast({
        tokens,
        ...payload
      });

      functions.logger.log(`Typing indicator sent for chat ${chatId}, user ${userId}: ${after?.isTyping}`);
      return { success: true };
    } catch (error) {
      functions.logger.error('Error broadcasting typing indicator:', error);
      return null;
    }
  });

/**
 * Clean up stale typing indicators
 * Runs every minute to remove old typing indicators
 */
exports.cleanupTypingIndicators = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    try {
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30000) // 30 seconds ago
      );

      // Query all typing indicators older than cutoff
      const chatsSnapshot = await db.collection('chats').get();
      const batch = db.batch();
      let cleanupCount = 0;

      for (const chatDoc of chatsSnapshot.docs) {
        const typingSnapshot = await chatDoc.ref
          .collection('typing')
          .where('timestamp', '<', cutoffTime)
          .get();

        typingSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          cleanupCount++;
        });
      }

      if (cleanupCount > 0) {
        await batch.commit();
        functions.logger.log(`Cleaned up ${cleanupCount} stale typing indicators`);
      }

      return { cleaned: cleanupCount };
    } catch (error) {
      functions.logger.error('Error cleaning up typing indicators:', error);
      return null;
    }
  });

// ============================================================================
// ONLINE/OFFLINE STATUS
// ============================================================================

/**
 * Update user online status
 * Triggered when user presence changes
 */
exports.updateOnlineStatus = functions.firestore
  .document('users/{userId}/presence/{sessionId}')
  .onWrite(async (change, context) => {
    const { userId } = context.params;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    // Only process if status changed
    if (before?.status === after?.status) {
      return null;
    }

    try {
      const isOnline = after?.status === 'online';
      const lastSeen = isOnline ? null : admin.firestore.FieldValue.serverTimestamp();

      // Update user's main document
      await db.collection('users').doc(userId).update({
        isOnline,
        lastSeen: lastSeen || admin.firestore.FieldValue.serverTimestamp()
      });

      // Get user's active chats
      const chatsSnapshot = await db
        .collection('chats')
        .where('participants', 'array-contains', userId)
        .get();

      if (chatsSnapshot.empty) {
        return null;
      }

      // Notify participants in each chat
      const notificationPromises = [];

      for (const chatDoc of chatsSnapshot.docs) {
        const chatData = chatDoc.data();
        const participants = (chatData.participants || []).filter(id => id !== userId);

        if (participants.length === 0) continue;

        const tokens = await getRecipientTokens(participants);

        if (tokens.length > 0) {
          const payload = {
            data: {
              type: 'presence_update',
              userId,
              status: isOnline ? 'online' : 'offline',
              lastSeen: lastSeen ? new Date().toISOString() : '',
              chatId: chatDoc.id
            },
            android: {
              priority: 'normal',
              ttl: 60 * 5 // 5 minutes
            }
          };

          notificationPromises.push(
            messaging.sendEachForMulticast({
              tokens,
              ...payload
            })
          );
        }
      }

      await Promise.allSettled(notificationPromises);
      functions.logger.log(`Online status updated for user ${userId}: ${isOnline ? 'online' : 'offline'}`);
      
      return { success: true, chatsNotified: chatsSnapshot.size };
    } catch (error) {
      functions.logger.error('Error updating online status:', error);
      return null;
    }
  });

/**
 * Set user offline after timeout
 * Runs every 5 minutes to check for inactive sessions
 */
exports.setInactiveUsersOffline = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 5 * 60 * 1000) // 5 minutes ago
      );

      // Query all users with stale presence
      const usersSnapshot = await db.collection('users').get();
      const batch = db.batch();
      let offlineCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const presenceSnapshot = await userDoc.ref
          .collection('presence')
          .where('lastUpdate', '<', cutoffTime)
          .where('status', '==', 'online')
          .get();

        if (!presenceSnapshot.empty) {
          // Set user offline
          batch.update(userDoc.ref, {
            isOnline: false,
            lastSeen: admin.firestore.FieldValue.serverTimestamp()
          });

          // Update presence documents
          presenceSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, {
              status: 'offline',
              lastUpdate: admin.firestore.FieldValue.serverTimestamp()
            });
          });

          offlineCount++;
        }
      }

      if (offlineCount > 0) {
        await batch.commit();
        functions.logger.log(`Set ${offlineCount} inactive users offline`);
      }

      return { offlineCount };
    } catch (error) {
      functions.logger.error('Error setting inactive users offline:', error);
      return null;
    }
  });

// ============================================================================
// ENHANCED NOTIFICATIONS
// ============================================================================

/**
 * Send notification for new call
 */
exports.sendCallNotification = functions.firestore
  .document('calls/{callId}')
  .onCreate(async (snap, context) => {
    const callData = snap.data();
    const { calleeId, callerId, type, status } = callData;

    if (status !== 'ringing') {
      return null;
    }

    try {
      // Get caller info
      const callerDoc = await db.collection('users').doc(callerId).get();
      const callerData = callerDoc.exists ? callerDoc.data() : {};

      // Get callee tokens
      const tokens = await getRecipientTokens([calleeId]);

      if (tokens.length === 0) {
        return null;
      }

      const payload = {
        notification: {
          title: `${callerData.fullName || 'Someone'} is calling`,
          body: `Incoming ${type} call`,
          sound: 'call_ringtone',
          priority: 'high'
        },
        data: {
          type: 'incoming_call',
          callId: context.params.callId,
          callerId,
          callerName: callerData.fullName || 'Unknown',
          callerImage: callerData.imageUrl || '',
          callType: type
        },
        android: {
          priority: 'high',
          ttl: 30, // 30 seconds
          notification: {
            sound: 'call_ringtone',
            channelId: 'calls',
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

      await messaging.sendEachForMulticast({
        tokens,
        ...payload
      });

      functions.logger.log(`Call notification sent for call ${context.params.callId}`);
      return { success: true };
    } catch (error) {
      functions.logger.error('Error sending call notification:', error);
      return null;
    }
  });

/**
 * Send notification for new story
 */
exports.sendStoryNotification = functions.firestore
  .document('stories/{storyId}')
  .onCreate(async (snap, context) => {
    const storyData = snap.data();
    const { userId, type } = storyData;

    try {
      // Get user info
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.exists ? userDoc.data() : {};

      // Get user's followers
      const followersSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();

      if (followersSnapshot.empty) {
        return null;
      }

      const followerIds = followersSnapshot.docs.map(doc => doc.id);

      // Filter followers based on notification preferences
      const activeFollowers = [];
      for (const followerId of followerIds) {
        const shouldSend = await shouldSendNotification(followerId, 'story');
        if (shouldSend) {
          activeFollowers.push(followerId);
        }
      }

      if (activeFollowers.length === 0) {
        functions.logger.log('All followers have disabled story notifications.');
        return null;
      }

      const tokens = await getRecipientTokens(activeFollowers);

      if (tokens.length === 0) {
        return null;
      }

      const payload = {
        notification: {
          title: `${userData.fullName || 'Someone'} posted a story`,
          body: `Check out their new ${type} story`,
          icon: userData.imageUrl || ''
        },
        data: {
          type: 'new_story',
          storyId: context.params.storyId,
          userId,
          userName: userData.fullName || 'Unknown'
        },
        android: {
          priority: 'normal',
          ttl: 60 * 60 * 24 // 24 hours
        }
      };

      // Send in batches
      const batchSize = MAX_RECIPIENTS_PER_BATCH;
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batchTokens = tokens.slice(i, i + batchSize);
        await messaging.sendEachForMulticast({
          tokens: batchTokens,
          ...payload
        });
      }

      functions.logger.log(`Story notification sent to ${tokens.length} followers`);
      return { success: true, recipientCount: tokens.length };
    } catch (error) {
      functions.logger.error('Error sending story notification:', error);
      return null;
    }
  });

/**
 * Send notification for backup completion
 */
exports.sendBackupNotification = functions.firestore
  .document('backups/{backupId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only notify when backup completes
    if (before.status !== 'completed' && after.status === 'completed') {
      const { userId, type, itemCount, size } = after;

      try {
        const tokens = await getRecipientTokens([userId]);

        if (tokens.length === 0) {
          return null;
        }

        const sizeInMB = (size / (1024 * 1024)).toFixed(2);

        const payload = {
          notification: {
            title: 'Backup Completed',
            body: `Your ${type} backup is complete. ${itemCount} items (${sizeInMB} MB) backed up successfully.`
          },
          data: {
            type: 'backup_completed',
            backupId: context.params.backupId,
            backupType: type,
            itemCount: itemCount.toString(),
            size: size.toString()
          },
          android: {
            priority: 'normal'
          }
        };

        await messaging.sendEachForMulticast({
          tokens,
          ...payload
        });

        functions.logger.log(`Backup completion notification sent for backup ${context.params.backupId}`);
        return { success: true };
      } catch (error) {
        functions.logger.error('Error sending backup notification:', error);
        return null;
      }
    }

    return null;
  });

// ============================================================================
// PRIVACY & NOTIFICATION SETTINGS
// ============================================================================

/**
 * Sync privacy settings changes to related documents
 * Triggered when user updates their privacy settings
 */
exports.syncPrivacySettings = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const { userId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    // Check if privacy settings changed
    const privacyBefore = before.privacySettings;
    const privacyAfter = after.privacySettings;

    if (!privacyAfter || JSON.stringify(privacyBefore) === JSON.stringify(privacyAfter)) {
      return null;
    }

    try {
      functions.logger.log(`Privacy settings changed for user ${userId}`);

      // Handle profile photo visibility changes
      if (privacyBefore?.showProfilePhotoToNonContacts !== privacyAfter.showProfilePhotoToNonContacts) {
        functions.logger.log(`Profile photo visibility changed to: ${privacyAfter.showProfilePhotoToNonContacts ? 'Everyone' : 'Contacts Only'}`);

        // Notify all active chat participants about visibility change
        const chatsSnapshot = await db
          .collection('chats')
          .where('participants', 'array-contains', userId)
          .get();

        const notificationPromises = [];

        for (const chatDoc of chatsSnapshot.docs) {
          const chatData = chatDoc.data();
          const participants = (chatData.participants || []).filter(id => id !== userId);

          if (participants.length > 0) {
            const tokens = await getRecipientTokens(participants);

            if (tokens.length > 0) {
              notificationPromises.push(
                messaging.sendEachForMulticast({
                  tokens,
                  data: {
                    type: 'privacy_update',
                    userId,
                    setting: 'profile_photo',
                    value: privacyAfter.showProfilePhotoToNonContacts.toString()
                  },
                  android: { priority: 'normal', ttl: 60 * 5 }
                })
              );
            }
          }
        }

        await Promise.allSettled(notificationPromises);
      }

      // Handle last seen visibility changes
      if (privacyBefore?.showLastSeenInOneToOne !== privacyAfter.showLastSeenInOneToOne) {
        functions.logger.log(`Last seen visibility changed for user ${userId}`);

        // Update user's presence visibility based on new settings
        const presenceSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('presence')
          .get();

        const batch = db.batch();
        presenceSnapshot.docs.forEach(doc => {
          batch.update(doc.ref, {
            visible: privacyAfter.showLastSeenInOneToOne,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        if (!presenceSnapshot.empty) {
          await batch.commit();
        }
      }

      // Handle read receipts changes
      if (privacyBefore?.readReceiptsEnabled !== privacyAfter.readReceiptsEnabled) {
        functions.logger.log(`Read receipts ${privacyAfter.readReceiptsEnabled ? 'enabled' : 'disabled'} for user ${userId}`);

        // If disabled, stop broadcasting read receipts
        if (!privacyAfter.readReceiptsEnabled) {
          // Delete pending read receipt updates for this user
          const readReceiptsSnapshot = await db
            .collectionGroup('readReceipts')
            .where('userId', '==', userId)
            .where('broadcasted', '==', false)
            .get();

          const batch = db.batch();
          readReceiptsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
          });

          if (!readReceiptsSnapshot.empty) {
            await batch.commit();
          }
        }
      }

      // Handle message forwarding settings
      if (privacyBefore?.allowForwardingMessages !== privacyAfter.allowForwardingMessages) {
        functions.logger.log(`Message forwarding ${privacyAfter.allowForwardingMessages ? 'enabled' : 'disabled'} for user ${userId}`);
      }

      // Handle group invites settings
      if (privacyBefore?.allowGroupInvitesFromAnyone !== privacyAfter.allowGroupInvitesFromAnyone) {
        functions.logger.log(`Group invites from anyone ${privacyAfter.allowGroupInvitesFromAnyone ? 'enabled' : 'disabled'} for user ${userId}`);
      }

      return { success: true, settingsUpdated: true };
    } catch (error) {
      functions.logger.error('Error syncing privacy settings:', error);
      return null;
    }
  });

/**
 * Handle notification settings changes
 * Triggered when user updates notification preferences
 */
exports.syncNotificationSettings = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const { userId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    // Check if notification settings changed
    const notifBefore = before.notificationSettings;
    const notifAfter = after.notificationSettings;

    if (!notifAfter || JSON.stringify(notifBefore) === JSON.stringify(notifAfter)) {
      return null;
    }

    try {
      functions.logger.log(`Notification settings changed for user ${userId}`);

      // Update FCM token subscription topics based on notification preferences
      const tokensSnapshot = await db
        .collection('fcmTokens')
        .where('uid', '==', userId)
        .get();

      if (tokensSnapshot.empty) {
        return null;
      }

      const tokens = tokensSnapshot.docs.map(doc => doc.id);
      const topicPromises = [];

      // Subscribe/unsubscribe from message notifications
      if (notifAfter.showMessageNotification !== notifBefore?.showMessageNotification) {
        if (notifAfter.showMessageNotification) {
          topicPromises.push(messaging.subscribeToTopic(tokens, 'messages'));
          functions.logger.log(`Subscribed user ${userId} to message notifications`);
        } else {
          topicPromises.push(messaging.unsubscribeFromTopic(tokens, 'messages'));
          functions.logger.log(`Unsubscribed user ${userId} from message notifications`);
        }
      }

      // Subscribe/unsubscribe from group notifications
      if (notifAfter.showGroupNotification !== notifBefore?.showGroupNotification) {
        if (notifAfter.showGroupNotification) {
          topicPromises.push(messaging.subscribeToTopic(tokens, 'groups'));
          functions.logger.log(`Subscribed user ${userId} to group notifications`);
        } else {
          topicPromises.push(messaging.unsubscribeFromTopic(tokens, 'groups'));
          functions.logger.log(`Unsubscribed user ${userId} from group notifications`);
        }
      }

      // Subscribe/unsubscribe from story notifications
      if (notifAfter.reactionStatusNotification !== notifBefore?.reactionStatusNotification) {
        if (notifAfter.reactionStatusNotification) {
          topicPromises.push(messaging.subscribeToTopic(tokens, 'stories'));
          functions.logger.log(`Subscribed user ${userId} to story notifications`);
        } else {
          topicPromises.push(messaging.unsubscribeFromTopic(tokens, 'stories'));
          functions.logger.log(`Unsubscribed user ${userId} from story notifications`);
        }
      }

      // Subscribe/unsubscribe from reminder notifications
      if (notifAfter.reminderNotification !== notifBefore?.reminderNotification) {
        if (notifAfter.reminderNotification) {
          topicPromises.push(messaging.subscribeToTopic(tokens, 'reminders'));
          functions.logger.log(`Subscribed user ${userId} to reminder notifications`);
        } else {
          topicPromises.push(messaging.unsubscribeFromTopic(tokens, 'reminders'));
          functions.logger.log(`Unsubscribed user ${userId} from reminder notifications`);
        }
      }

      await Promise.allSettled(topicPromises);

      // Store notification preferences for analytics
      await db.collection('notificationPreferences').doc(userId).set({
        ...notifAfter,
        userId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      return { success: true, preferencesUpdated: true };
    } catch (error) {
      functions.logger.error('Error syncing notification settings:', error);
      return null;
    }
  });

/**
 * Send notification based on user preferences
 * Helper function to check notification settings before sending
 */
async function shouldSendNotification(userId, notificationType) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return true; // Default to sending if user not found
    }

    const userData = userDoc.data();
    const notifSettings = userData.notificationSettings;

    if (!notifSettings) {
      return true; // Default to sending if no settings
    }

    // Check notification type and user preferences
    switch (notificationType) {
      case 'message':
        return notifSettings.showMessageNotification !== false;
      case 'group':
        return notifSettings.showGroupNotification !== false;
      case 'story':
        return notifSettings.reactionStatusNotification !== false;
      case 'reminder':
        return notifSettings.reminderNotification !== false;
      default:
        return true;
    }
  } catch (error) {
    functions.logger.error('Error checking notification preferences:', error);
    return true; // Default to sending on error
  }
}

// ============================================================================
// PRIVACY-AWARE DATA ACCESS (Phase 2)
// ============================================================================

/**
 * Get user profile with privacy enforcement
 * Returns filtered user data based on privacy settings and blocking status
 */
exports.getUserProfile = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const viewerId = context.auth.uid;
  const targetUserId = data.userId;

  if (!targetUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
  }

  try {
    // Get target user document
    const targetUserDoc = await db.collection('users').doc(targetUserId).get();
    if (!targetUserDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const targetUserData = targetUserDoc.data();

    // Check if viewer is blocked by target user
    const blockedUsers = targetUserData.blockedUser || targetUserData.blockedUsers || [];
    if (blockedUsers.includes(viewerId)) {
      throw new functions.https.HttpsError('permission-denied', 'User not found');
    }

    // Get privacy settings
    const privacySettings = targetUserData.privacySettings || {};

    // Check if viewer is a contact
    const contacts = targetUserData.contacts || [];
    const isContact = contacts.includes(viewerId);

    // Check if viewer is blocked by viewer (reciprocal check)
    const viewerDoc = await db.collection('users').doc(viewerId).get();
    const viewerBlockedUsers = viewerDoc.exists ?
      (viewerDoc.data().blockedUser || viewerDoc.data().blockedUsers || []) : [];
    const hasViewerBlocked = viewerBlockedUsers.includes(targetUserId);

    // Build filtered profile based on privacy settings
    const profile = {
      uid: targetUserId,
      fullName: targetUserData.fullName,
      // Always include basic info
    };

    // Apply privacy filters
    const visibilityLevel = getVisibilityLevel(privacySettings, isContact, viewerId);

    // Profile photo
    if (shouldShowField(privacySettings.profilePhoto, visibilityLevel)) {
      profile.imageUrl = targetUserData.imageUrl;
      profile.photoUrl = targetUserData.photoUrl;
    }

    // Bio/About
    if (shouldShowField(privacySettings.about, visibilityLevel)) {
      profile.bio = targetUserData.bio;
      profile.about = targetUserData.about;
    }

    // Online status
    if (shouldShowField(privacySettings.onlineStatus, visibilityLevel)) {
      profile.isOnline = targetUserData.isOnline;
    }

    // Last seen
    if (shouldShowField(privacySettings.lastSeen, visibilityLevel)) {
      profile.lastSeen = targetUserData.lastSeen;
    }

    // Phone number (contacts only by default)
    if (isContact) {
      profile.phoneNumber = targetUserData.phoneNumber;
    }

    // Add relationship flags
    profile.isContact = isContact;
    profile.isBlocked = hasViewerBlocked;

    functions.logger.log(`Profile accessed: ${viewerId} viewed ${targetUserId}`);
    return profile;
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    functions.logger.error('Error getting user profile:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get user profile');
  }
});

/**
 * Helper: Determine visibility level for user
 */
function getVisibilityLevel(privacySettings, isContact, viewerId) {
  return {
    isContact,
    isEveryone: true,
    isNobody: false,
    viewerId,
  };
}

/**
 * Helper: Check if field should be shown based on visibility setting
 */
function shouldShowField(setting, visibility) {
  if (!setting) return true; // Default to showing

  const level = setting.level || 'everyone';

  switch (level) {
    case 'nobody':
      // Check exceptions
      const allowExceptions = setting.allowExceptions || [];
      return allowExceptions.includes(visibility.viewerId);
    case 'contacts':
      return visibility.isContact;
    case 'contactsExcept':
      const blockExceptions = setting.blockExceptions || [];
      return visibility.isContact && !blockExceptions.includes(visibility.viewerId);
    case 'nobodyExcept':
      const nobodyExceptions = setting.allowExceptions || [];
      return nobodyExceptions.includes(visibility.viewerId);
    case 'everyone':
    default:
      return true;
  }
}

/**
 * Block a user with proper enforcement
 */
exports.blockUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const blockerId = context.auth.uid;
  const blockedUserId = data.userId;

  if (!blockedUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
  }

  if (blockerId === blockedUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'Cannot block yourself');
  }

  try {
    const batch = db.batch();

    // Add to blocker's blocked list
    const blockerRef = db.collection('users').doc(blockerId);
    batch.update(blockerRef, {
      blockedUser: admin.firestore.FieldValue.arrayUnion(blockedUserId),
      blockedUsers: admin.firestore.FieldValue.arrayUnion(blockedUserId)
    });

    // Update any shared chat rooms
    const chatsSnapshot = await db
      .collection('chat_rooms')
      .where('membersIds', 'array-contains', blockerId)
      .get();

    for (const chatDoc of chatsSnapshot.docs) {
      const chatData = chatDoc.data();
      if (chatData.membersIds && chatData.membersIds.includes(blockedUserId)) {
        // If it's a private chat, add blocking info
        if (!chatData.isGroupChat) {
          batch.update(chatDoc.ref, {
            blockedUsers: admin.firestore.FieldValue.arrayUnion(blockedUserId),
            blockingUserId: blockerId
          });
        }
      }
    }

    // Log the block action for security audit
    const auditRef = db.collection('securityAuditLogs').doc();
    batch.set(auditRef, {
      action: 'block_user',
      actorId: blockerId,
      targetId: blockedUserId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        chatsAffected: chatsSnapshot.size
      }
    });

    await batch.commit();

    functions.logger.log(`User ${blockerId} blocked ${blockedUserId}`);
    return { success: true, blockedUserId };
  } catch (error) {
    functions.logger.error('Error blocking user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to block user');
  }
});

/**
 * Unblock a user
 */
exports.unblockUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const unblockerId = context.auth.uid;
  const unblockedUserId = data.userId;

  if (!unblockedUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
  }

  try {
    const batch = db.batch();

    // Remove from unblocker's blocked list
    const unblockerRef = db.collection('users').doc(unblockerId);
    batch.update(unblockerRef, {
      blockedUser: admin.firestore.FieldValue.arrayRemove(unblockedUserId),
      blockedUsers: admin.firestore.FieldValue.arrayRemove(unblockedUserId)
    });

    // Update any shared chat rooms
    const chatsSnapshot = await db
      .collection('chat_rooms')
      .where('blockingUserId', '==', unblockerId)
      .get();

    for (const chatDoc of chatsSnapshot.docs) {
      batch.update(chatDoc.ref, {
        blockedUsers: admin.firestore.FieldValue.arrayRemove(unblockedUserId),
        blockingUserId: admin.firestore.FieldValue.delete()
      });
    }

    // Log the unblock action
    const auditRef = db.collection('securityAuditLogs').doc();
    batch.set(auditRef, {
      action: 'unblock_user',
      actorId: unblockerId,
      targetId: unblockedUserId,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();

    functions.logger.log(`User ${unblockerId} unblocked ${unblockedUserId}`);
    return { success: true, unblockedUserId };
  } catch (error) {
    functions.logger.error('Error unblocking user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to unblock user');
  }
});

/**
 * Validate message before sending (privacy check)
 */
exports.validateMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const senderId = context.auth.uid;
  const { recipientId, chatId } = data;

  if (!recipientId && !chatId) {
    throw new functions.https.HttpsError('invalid-argument', 'Recipient or chat ID required');
  }

  try {
    // If direct message, check if blocked
    if (recipientId) {
      const recipientDoc = await db.collection('users').doc(recipientId).get();
      if (recipientDoc.exists) {
        const recipientData = recipientDoc.data();
        const blockedUsers = recipientData.blockedUser || recipientData.blockedUsers || [];

        if (blockedUsers.includes(senderId)) {
          return {
            allowed: false,
            reason: 'blocked',
            message: 'Cannot send message to this user'
          };
        }

        // Check who can message setting
        const privacySettings = recipientData.privacySettings || {};
        const whoCanMessage = privacySettings.whoCanMessage || 'everyone';
        const contacts = recipientData.contacts || [];
        const isContact = contacts.includes(senderId);

        if (whoCanMessage === 'nobody') {
          return {
            allowed: false,
            reason: 'privacy_setting',
            message: 'User does not accept messages'
          };
        }

        if (whoCanMessage === 'contacts' && !isContact) {
          return {
            allowed: false,
            reason: 'contacts_only',
            message: 'User only accepts messages from contacts'
          };
        }
      }
    }

    // If group message, check membership
    if (chatId) {
      const chatDoc = await db.collection('chat_rooms').doc(chatId).get();
      if (chatDoc.exists) {
        const chatData = chatDoc.data();
        const membersIds = chatData.membersIds || [];

        if (!membersIds.includes(senderId)) {
          return {
            allowed: false,
            reason: 'not_member',
            message: 'Not a member of this chat'
          };
        }

        // Check if blocked in chat
        const blockedUsers = chatData.blockedUsers || [];
        if (blockedUsers.includes(senderId)) {
          return {
            allowed: false,
            reason: 'blocked_in_chat',
            message: 'Cannot send messages in this chat'
          };
        }
      }
    }

    return { allowed: true };
  } catch (error) {
    functions.logger.error('Error validating message:', error);
    throw new functions.https.HttpsError('internal', 'Failed to validate message');
  }
});

/**
 * Check if read receipts should be sent based on privacy
 */
exports.shouldSendReadReceipt = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const readerId = context.auth.uid;
  const { messageId, chatId } = data;

  try {
    // Get reader's privacy settings
    const readerDoc = await db.collection('users').doc(readerId).get();
    if (!readerDoc.exists) {
      return { shouldSend: true };
    }

    const readerData = readerDoc.data();
    const privacySettings = readerData.privacySettings || {};

    // Check if read receipts are enabled
    if (privacySettings.readReceipts === false) {
      return { shouldSend: false, reason: 'read_receipts_disabled' };
    }

    // Check typing indicators setting as well
    const showTyping = privacySettings.typingIndicators !== false;

    return {
      shouldSend: true,
      showTypingIndicators: showTyping
    };
  } catch (error) {
    functions.logger.error('Error checking read receipt settings:', error);
    return { shouldSend: true }; // Default to sending on error
  }
});

/**
 * Report user with validation
 */
exports.reportUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const reporterId = context.auth.uid;
  const { reportedUserId, reason, details, type } = data;

  if (!reportedUserId || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID and reason are required');
  }

  // Validate reason is in allowed list
  const validReasons = [
    'inappropriate_content',
    'spam',
    'harassment',
    'fake_account',
    'other'
  ];

  if (!validReasons.includes(reason)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid report reason');
  }

  try {
    // Check if user has already reported this user recently (prevent spam)
    const recentReports = await db
      .collection('reports')
      .where('reporterId', '==', reporterId)
      .where('reportedUserId', '==', reportedUserId)
      .where('createdAt', '>', admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 24 * 60 * 60 * 1000) // 24 hours ago
      ))
      .get();

    if (!recentReports.empty) {
      throw new functions.https.HttpsError(
        'already-exists',
        'You have already reported this user recently'
      );
    }

    // Create report
    const reportRef = db.collection('reports').doc();
    await reportRef.set({
      reporterId,
      reportedUserId,
      reason,
      details: details || '',
      type: type || 'user',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        reporterIp: context.rawRequest?.ip || 'unknown',
        userAgent: context.rawRequest?.headers?.['user-agent'] || 'unknown'
      }
    });

    functions.logger.log(`User ${reporterId} reported ${reportedUserId} for ${reason}`);
    return { success: true, reportId: reportRef.id };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    functions.logger.error('Error creating report:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit report');
  }
});

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Clean up old notifications
 * Runs daily to remove old notification logs
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 days ago

      const snapshot = await db
        .collection('notificationLogs')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .limit(500)
        .get();

      if (snapshot.empty) {
        return null;
      }

      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      functions.logger.log(`Deleted ${snapshot.size} old notification logs`);
      
      return { deleted: snapshot.size };
    } catch (error) {
      functions.logger.error('Error cleaning up old notifications:', error);
      return null;
    }
  });

/**
 * Send scheduled notifications
 * For reminders, scheduled messages, etc.
 */
exports.sendScheduledNotifications = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();

      const snapshot = await db
        .collection('scheduledNotifications')
        .where('scheduledFor', '<=', now)
        .where('sent', '==', false)
        .limit(100)
        .get();

      if (snapshot.empty) {
        return null;
      }

      const batch = db.batch();
      const sendPromises = [];

      for (const doc of snapshot.docs) {
        const notificationData = doc.data();
        const { userId, title, body, data } = notificationData;

        const tokens = await getRecipientTokens([userId]);

        if (tokens.length > 0) {
          sendPromises.push(
            messaging.sendEachForMulticast({
              tokens,
              notification: { title, body },
              data: data || {}
            })
          );
        }

        // Mark as sent
        batch.update(doc.ref, {
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      await Promise.all([
        batch.commit(),
        ...sendPromises
      ]);

      functions.logger.log(`Sent ${snapshot.size} scheduled notifications`);
      return { sent: snapshot.size };
    } catch (error) {
      functions.logger.error('Error sending scheduled notifications:', error);
      return null;
    }
  });
