import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/help_message_model.dart';
import 'user_services.dart';

class HelpDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for help messages
  CollectionReference get _helpCollection => _firestore.collection('help_messages');

  /// Submit a new help message
  Future<bool> submitHelpMessage({
    required String fullName,
    required String email,
    required String message,
    required RequestType requestType,
    required String priority,
    List<String>? attachmentUrls,
  }) async {
    try {
      // Enhanced authentication check
      final currentUser = UserService.currentUser.value ?? UserService.currentUserValue;
      final authUser = _auth.currentUser;

      if (currentUser == null && authUser == null) {
        throw Exception('User must be authenticated to submit help messages');
      }

      // Get user ID from either source
      final userId = currentUser?.uid ?? authUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('Unable to determine user ID');
      }

      // Create help message
      final helpMessage = HelpMessage(
        fullName: fullName,
        email: email,
        message: message,
        requestType: requestType,
        status: 'pending',
        userId: userId,
        attachmentUrls: attachmentUrls,
        priority: priority,
      );

      // Save to Firestore
      final docRef = await _helpCollection.add(helpMessage.toMap());

      if (kDebugMode) {
        log('✅ Help message submitted successfully: ${docRef.id}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error submitting help message: $e');
      }
      rethrow;
    }
  }

  /// Get help messages for current user
  Stream<List<HelpMessage>> getUserHelpMessages() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _helpCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HelpMessage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
              .toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            log('❌ Error getting user help messages: $error');
          }
          throw error;
        });
  }

  /// Get all help messages (for admin use)
  Stream<List<HelpMessage>> getAllHelpMessages() {
    return _helpCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HelpMessage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
              .toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            log('❌ Error getting all help messages: $error');
          }
          throw error;
        });
  }

  /// Update help message status (for admin use)
  Future<bool> updateHelpMessageStatus({
    required String messageId,
    required String status,
    String? response,
    String? adminId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        updateData['response'] = response;
      }

      if (adminId != null) {
        updateData['adminId'] = adminId;
      }

      await _helpCollection.doc(messageId).update(updateData);

      if (kDebugMode) {
        log('✅ Help message status updated: $messageId -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error updating help message status: $e');
      }
      rethrow;
    }
  }

  /// Delete a help message
  Future<bool> deleteHelpMessage(String messageId) async {
    try {
      await _helpCollection.doc(messageId).delete();

      if (kDebugMode) {
        log('✅ Help message deleted: $messageId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error deleting help message: $e');
      }
      rethrow;
    }
  }

  /// Get help message by ID
  Future<HelpMessage?> getHelpMessageById(String messageId) async {
    try {
      final doc = await _helpCollection.doc(messageId).get();

      if (doc.exists) {
        return HelpMessage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error getting help message by ID: $e');
      }
      rethrow;
    }
  }

  /// Get help messages by status
  Stream<List<HelpMessage>> getHelpMessagesByStatus(String status) {
    return _helpCollection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HelpMessage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
              .toList();
        })
        .handleError((error) {
          if (kDebugMode) {
            log('❌ Error getting help messages by status: $error');
          }
          throw error;
        });
  }
}
