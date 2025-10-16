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

      // 3. Get FCM tokens for recipients
      const tokens = await getRecipientTokens(recipientUserIds);
      
      if (tokens.length === 0) {
        functions.logger.log('No FCM tokens found for recipients.');
        return null;
      }

      // 4. Prepare notification payload
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

      // 5. Send notifications in batches if needed
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

      // 6. Process all batches
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

      // 7. Clean up invalid tokens
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
