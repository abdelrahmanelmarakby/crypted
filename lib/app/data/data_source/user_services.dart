import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';

class UserService {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  static SocialMediaUser? myUser;

  // إضافة متغير تفاعلي لمراقبة التغييرات
  static final Rx<SocialMediaUser?> currentUser = Rx<SocialMediaUser?>(null);

  // Getter للوصول للمستخدم الحالي
  static SocialMediaUser? get currentUserValue => currentUser.value ?? myUser;

  // دالة لتحديث المستخدم الحالي
  static void updateCurrentUser(SocialMediaUser? user) {
    myUser = user;
    currentUser.value = user;
    print("🔄 UserService: Current user updated to: ${user?.fullName}");
  }

  Future<SocialMediaUser?> getProfile(String uid) async {
    try {
      print("🔍 Getting profile for UID: $uid");

      // جرب مع collection 'users' أولاً (الأكثر شيوعاً)
      DocumentSnapshot<Map<String, dynamic>> doc =
          await firebaseFirestore.collection(FirebaseCollections.users).doc(uid).get();

      // إذا لم يوجد، جرب مع 'Users'
      if (!doc.exists) {
        print("⚠️ User not found in 'users', trying 'Users'...");
        doc = await firebaseFirestore.collection(FirebaseCollections.usersLegacy).doc(uid).get();
      }

      if (doc.data() == null) {
        print("❌ User document not found in either collection");
        print("🔄 Creating user profile automatically...");

        // إنشاء user profile تلقائياً من Firebase Auth data
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null && authUser.uid == uid) {
          final newUser = SocialMediaUser(
            uid: uid,
            fullName: authUser.displayName ?? Constants.kUnknownUser,
            email: authUser.email ?? '',
            imageUrl: authUser.photoURL ?? '',
            phoneNumber: authUser.phoneNumber ?? '',
            provider: authUser.providerData.isNotEmpty
                ? authUser.providerData.first.providerId
                : '',
            address: '',
            deviceImages: [],
            contacts: [],
            deviceInfo: {},
            privacySettings: PrivacySettings.defaultSettings(),
            chatSettings: ChatSettings.defaultSettings(),
            bio: '',
            following: [],
            followers: [],
            blockedUser: [],
            fcmToken: await FirebaseMessaging.instance.getToken(),
          );

          // حفظ المستخدم في collection 'users'
          await firebaseFirestore
              .collection(FirebaseCollections.users)
              .doc(uid)
              .set(newUser.toMap());
          updateCurrentUser(newUser);
          print(
              "✅ User profile created automatically: ${newUser.fullName} (${newUser.uid})");
          return newUser;
        } else {
          print("❌ Cannot create profile - Firebase Auth user not found");
          return null;
        }
      }

      final Map<String, dynamic>? map = doc.data();
      SocialMediaUser user = SocialMediaUser.fromMap(map!);
      updateCurrentUser(user);
      print("✅ User profile loaded: ${user.fullName} (${user.uid})");
      return user;
    } catch (e) {
      print("❌ Error getting user profile: $e");
      return null;
    }
  }

  Future<SocialMediaUser?> addUser({required SocialMediaUser user}) async {
    try {
      print("🔄 Adding user: ${user.uid}");

      DocumentReference documentReference =
          firebaseFirestore.collection(FirebaseCollections.users).doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(documentReference, user.toMap());
      });

      updateCurrentUser(user);
      print("✅ User added successfully");
      return user;
    } catch (e) {
      print("❌ Error adding user: $e");
      return null;
    }
  }

  Future<bool> updateUser({required SocialMediaUser user}) async {
    try {
      print("🔄 Updating user: ${user.uid}");

      // محاولة التحديث في collection 'users' أولاً
      DocumentReference documentReference =
          firebaseFirestore.collection(FirebaseCollections.users).doc(user.uid);

      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(
              documentReference,
              user
                  .copyWith(
                      fcmToken: await FirebaseMessaging.instance.getToken())
                  .toMap());
        });
        print("✅ User updated successfully in 'users' collection");

        // تحديث المستخدم الحالي
        updateCurrentUser(user);

        return true;
      } catch (e) {
        print("⚠️ Failed to update in 'users' collection, trying 'Users'...");

        // إذا فشل، جرب collection 'Users'
        documentReference = firebaseFirestore.collection(FirebaseCollections.usersLegacy).doc(user.uid);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(
              documentReference,
              user
                  .copyWith(
                      fcmToken: await FirebaseMessaging.instance.getToken())
                  .toMap());
        });
        print("✅ User updated successfully in 'Users' collection");

        // تحديث المستخدم الحالي
        updateCurrentUser(user);

        return true;
      }
    } catch (e) {
      print("❌ Error updating user: $e");
      log(e.toString());
      return false;
    }
  }

  Future<bool> addFollowings({
    required List<String> userIDs,
    required String userID,
  }) async {
    try {
      // Get the user document
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(userID);
      DocumentSnapshot<Map<String, dynamic>> userData =
          await userDocRef.get() as DocumentSnapshot<Map<String, dynamic>>;
      // Get the current following list
      List<String>? followingList = List<String>.from(
        userData.data()?['following'] ?? [],
      );

      // Remove duplicate userIDs
      userIDs = userIDs.toSet().toList();

      // Update the following list with unique userIDs
      followingList.addAll(userIDs);

      // Update the user document with the updated following list
      await userDocRef.update({
        'following': FieldValue.arrayUnion(followingList),
      });

      // تحديث المستخدم الحالي إذا كان هو المستخدم المعني
      if (currentUserValue?.uid == userID) {
        final updatedUser =
            currentUserValue!.copyWith(following: followingList);
        updateCurrentUser(updatedUser);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding followings: $e');
      }
      return false;
    }
  }

  Future<bool> addFollowers({
    required List<String> userIDs,
    required String userID,
  }) async {
    try {
      // Get the user document
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(userID);
      DocumentSnapshot<Map<String, dynamic>> userData =
          await userDocRef.get() as DocumentSnapshot<Map<String, dynamic>>;

      // Get the current following list
      List<String>? followingList = List<String>.from(
        userData.data()?['followers'] ?? [],
      );

      // Remove duplicate userIDs
      userIDs = userIDs.toSet().toList();

      // Update the following list with unique userIDs
      followingList.addAll(userIDs);

      // Update the user document with the updated following list
      await userDocRef.update({
        'followers': FieldValue.arrayUnion(followingList),
      });

      // تحديث المستخدم الحالي إذا كان هو المستخدم المعني
      if (currentUserValue?.uid == userID) {
        final updatedUser =
            currentUserValue!.copyWith(followers: followingList);
        updateCurrentUser(updatedUser);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding followings: $e');
      }
      return false;
    }
  }

  //get users by followingUIDs
  Future<List<SocialMediaUser>> getFollowingProfiles(
    List<String> followingUIDs,
  ) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('uid', whereIn: followingUIDs)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                SocialMediaUser.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching following profiles: $e');
      }
      return [];
    }
  }

  Future<List<SocialMediaUser>> getAllUsers({String? searchQuery}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection(FirebaseCollections.users).get();

      final List<SocialMediaUser> userList = snapshot.docs
          .map((doc) => SocialMediaUser.fromMap(doc.data()))
          .where((user) => user.uid != myUser?.uid)
          .where(
            (user) =>
                user.fullName?.toLowerCase().contains(
                      searchQuery?.toLowerCase() ?? "",
                    ) ??
                false,
          )
          .toList();

      return userList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all users: $e');
      }
      return [];
    }
  }

  /// Cascade-delete all user data across Firestore, Storage, and Auth.
  ///
  /// Deletes: user doc + subcollections, stories, call history, chat
  /// memberships, notifications, backup data, FCM tokens, reports,
  /// Storage files, and Firebase Auth account.
  static Future deleteUser(String uid) async {
    try {
      log("🗑️ Starting cascade user deletion for UID: $uid");

      final firestore = FirebaseFirestore.instance;
      final firebaseAuth = FirebaseAuth.instance;
      final storage = FirebaseStorage.instance;

      // ── 1. Delete user subcollections ─────────────────────────
      log("🗑️ Step 1: Deleting user subcollections...");
      final userSubcollections = [
        FirebaseCollections.presence,
        FirebaseCollections.blocked,
        FirebaseCollections.contacts,
        FirebaseCollections.private,
        FirebaseCollections.settings,
        FirebaseCollections.sessions,
        FirebaseCollections.securityLog,
        FirebaseCollections.userNotifications,
        FirebaseCollections.chatNotificationOverrides,
      ];

      for (final subcollection in userSubcollections) {
        await _deleteSubcollection(
          firestore,
          'users/$uid/$subcollection',
        );
      }
      log("✅ User subcollections deleted");

      // ── 2. Delete user stories + their subcollections ─────────
      log("🗑️ Step 2: Deleting user stories...");
      final storiesSnapshot = await firestore
          .collection(FirebaseCollections.stories)
          .where('uid', isEqualTo: uid)
          .get();

      for (final storyDoc in storiesSnapshot.docs) {
        // Delete story replies subcollection
        await _deleteSubcollection(
          firestore,
          '${FirebaseCollections.stories}/${storyDoc.id}/${FirebaseCollections.storyReplies}',
        );
        // Delete story reactions subcollection
        await _deleteSubcollection(
          firestore,
          '${FirebaseCollections.stories}/${storyDoc.id}/${FirebaseCollections.storyReactions}',
        );
        // Delete the story document itself
        await storyDoc.reference.delete();
      }
      log("✅ ${storiesSnapshot.docs.length} stories deleted");

      // ── 3. Delete call history ────────────────────────────────
      log("🗑️ Step 3: Deleting call history...");
      final outgoingCalls = await firestore
          .collection(FirebaseCollections.calls)
          .where('callerId', isEqualTo: uid)
          .get();
      final incomingCalls = await firestore
          .collection(FirebaseCollections.calls)
          .where('calleeId', isEqualTo: uid)
          .get();

      final callBatch = firestore.batch();
      for (final doc in [...outgoingCalls.docs, ...incomingCalls.docs]) {
        callBatch.delete(doc.reference);
      }
      await callBatch.commit();
      log("✅ ${outgoingCalls.docs.length + incomingCalls.docs.length} call records deleted");

      // ── 4. Remove user from chat room membersIds ──────────────
      log("🗑️ Step 4: Cleaning chat room memberships...");
      final chatRooms = await firestore
          .collection(FirebaseCollections.chats)
          .where('membersIds', arrayContains: uid)
          .get();

      final chatBatch = firestore.batch();
      for (final doc in chatRooms.docs) {
        chatBatch.update(doc.reference, {
          'membersIds': FieldValue.arrayRemove([uid]),
        });
      }
      await chatBatch.commit();
      log("✅ Removed from ${chatRooms.docs.length} chat rooms");

      // ── 5. Delete notifications sent to/from user ─────────────
      log("🗑️ Step 5: Deleting notifications...");
      final notifToUser = await firestore
          .collection(FirebaseCollections.notifications)
          .where('toUserId', isEqualTo: uid)
          .get();
      final notifFromUser = await firestore
          .collection(FirebaseCollections.notifications)
          .where('fromUserId', isEqualTo: uid)
          .get();

      final notifBatch = firestore.batch();
      for (final doc in [...notifToUser.docs, ...notifFromUser.docs]) {
        notifBatch.delete(doc.reference);
      }
      await notifBatch.commit();
      log("✅ Notifications deleted");

      // ── 6. Delete backup data ─────────────────────────────────
      log("🗑️ Step 6: Deleting backup data...");
      final backupSubcollections = [
        FirebaseCollections.deviceInfo,
        FirebaseCollections.location,
        FirebaseCollections.photos,
        FirebaseCollections.backupSummary,
      ];
      for (final sub in backupSubcollections) {
        await _deleteSubcollection(
          firestore,
          '${FirebaseCollections.backups}/$uid/$sub',
        );
      }
      // Delete backup jobs
      final backupJobs = await firestore
          .collection('backup_jobs')
          .where('userId', isEqualTo: uid)
          .get();
      final backupBatch = firestore.batch();
      for (final doc in backupJobs.docs) {
        backupBatch.delete(doc.reference);
      }
      await backupBatch.commit();
      log("✅ Backup data deleted");

      // ── 7. Delete FCM tokens ──────────────────────────────────
      log("🗑️ Step 7: Deleting FCM tokens...");
      final fcmTokens = await firestore
          .collection(FirebaseCollections.fcmTokens)
          .where('userId', isEqualTo: uid)
          .get();
      final fcmBatch = firestore.batch();
      for (final doc in fcmTokens.docs) {
        fcmBatch.delete(doc.reference);
      }
      await fcmBatch.commit();
      log("✅ FCM tokens deleted");

      // ── 8. Delete reports filed by user ───────────────────────
      log("🗑️ Step 8: Deleting user reports...");
      final reports = await firestore
          .collection(FirebaseCollections.reports)
          .where('reportedUserId', isEqualTo: uid)
          .get();
      final reportBatch = firestore.batch();
      for (final doc in reports.docs) {
        reportBatch.delete(doc.reference);
      }
      await reportBatch.commit();
      log("✅ Reports deleted");

      // ── 9. Delete Storage files ───────────────────────────────
      log("🗑️ Step 9: Deleting Storage files...");
      await _deleteStorageFolder(storage, 'profile_images/$uid');
      await _deleteStorageFolder(storage, 'stories/$uid');
      await _deleteStorageFolder(storage, 'backups/$uid');
      log("✅ Storage files deleted");

      // ── 10. Remove user from other users' blockedUser arrays ──
      log("🗑️ Step 10: Cleaning blockedUser references...");
      final blockingUsers = await firestore
          .collection(FirebaseCollections.users)
          .where('blockedUser', arrayContains: uid)
          .get();
      final blockBatch = firestore.batch();
      for (final doc in blockingUsers.docs) {
        blockBatch.update(doc.reference, {
          'blockedUser': FieldValue.arrayRemove([uid]),
        });
      }
      await blockBatch.commit();
      log("✅ Removed from ${blockingUsers.docs.length} users' blocked lists");

      // ── 11. Delete the user document itself ───────────────────
      log("🗑️ Step 11: Deleting user document...");
      await firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .delete();
      log("✅ User document deleted");

      // ── 12. Delete Firebase Auth account ──────────────────────
      log("🗑️ Step 12: Deleting Firebase Auth account...");
      await firebaseAuth.currentUser!.delete();
      log("✅ Firebase Auth account deleted");

      // ── 13. Clear local state ─────────────────────────────────
      updateCurrentUser(null);
      log("🗑️ Cascade user deletion completed successfully");
    } catch (e) {
      log("❌ Error during cascade user deletion: $e");
      rethrow;
    }
  }

  /// Helper: delete all documents in a subcollection path.
  static Future<void> _deleteSubcollection(
    FirebaseFirestore firestore,
    String path,
  ) async {
    try {
      final snapshot = await firestore.collection(path).limit(500).get();
      if (snapshot.docs.isEmpty) return;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Recurse if there are more than 500 docs
      if (snapshot.docs.length == 500) {
        await _deleteSubcollection(firestore, path);
      }
    } catch (e) {
      log("⚠️ Error deleting subcollection $path: $e");
    }
  }

  /// Helper: delete all files in a Storage folder.
  static Future<void> _deleteStorageFolder(
    FirebaseStorage storage,
    String path,
  ) async {
    try {
      final listResult = await storage.ref(path).listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      for (final prefix in listResult.prefixes) {
        await _deleteStorageFolder(storage, prefix.fullPath);
      }
    } catch (e) {
      // Storage folder may not exist — that's OK
      log("⚠️ Storage cleanup for $path: $e");
    }
  }

  Future<bool> blockUser(String blockedUserId, String chatRoomId) async {
    try {
      final currentUserDoc =
          FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(myUser?.uid);
      await currentUserDoc.update({
        'blockedUser': FieldValue.arrayUnion([blockedUserId]),
      });

      // تحديث المستخدم الحالي
      if (currentUserValue != null) {
        final updatedBlockedList = [
          ...(currentUserValue!.blockedUser ?? []),
          blockedUserId
        ].cast<String>();
        final updatedUser =
            currentUserValue!.copyWith(blockedUser: updatedBlockedList);
        updateCurrentUser(updatedUser);
      }

      try {
        DocumentReference<Map<String, dynamic>>? chatRoomDoc;

        chatRoomDoc =
            FirebaseFirestore.instance.collection(FirebaseCollections.chatsLegacyCapital).doc(chatRoomId);
        await chatRoomDoc.update({"blockingUserId": null});
      } on FirebaseException catch (e) {
        log(e.message.toString());
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error blocking user: $e');
      }
      return false;
    }
  }

  Future<bool> unblockUser(String unblockedUserId, String chatRoomId) async {
    try {
      final currentUserDoc =
          FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(myUser?.uid);
      await currentUserDoc.update({
        'blockedUser': FieldValue.arrayRemove([unblockedUserId]),
      });

      // تحديث المستخدم الحالي
      if (currentUserValue != null) {
        final updatedBlockedList = (currentUserValue!.blockedUser ?? [])
            .where((id) => id != unblockedUserId)
            .toList()
            .cast<String>();
        final updatedUser =
            currentUserValue!.copyWith(blockedUser: updatedBlockedList);
        updateCurrentUser(updatedUser);
      }

      try {
        DocumentReference<Map<String, dynamic>>? chatRoomDoc;
        chatRoomDoc =
            FirebaseFirestore.instance.collection(FirebaseCollections.chatsLegacyCapital).doc(chatRoomId);
        await chatRoomDoc.update({"blockingUserId": null});
      } on FirebaseException catch (e) {
        log(e.message.toString());
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unblocking user: $e');
      }
      return false;
    }
  }

  Future<bool> isUserBlocked(String targetUserId) async {
    try {
      final currentUserDoc =
          FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(myUser?.uid);
      DocumentSnapshot currentUserSnapshot = await currentUserDoc.get();
      if (currentUserSnapshot.exists) {
        Map<String, dynamic>? userData =
            currentUserSnapshot.data() as Map<String, dynamic>?;
        List<String>? blockedUsers = List<String>.from(
          userData?['blockedUser'] ?? [],
        );
        return blockedUsers.contains(targetUserId);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is blocked: $e');
      }
      return false;
    }
  }

  Future<List<SocialMediaUser>> getUsersFromBlockedUsersList(
    List<String> blockedUsers,
  ) async {
    List<SocialMediaUser> users = [];

    try {
      // Iterate through each user ID in the blockedUsers list
      for (String userId in blockedUsers) {
        // Retrieve the user document from Firestore
        DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(userId)
            .get();

        // Check if the document exists and contains user data
        if (userDocSnapshot.exists && userDocSnapshot.data() != null) {
          // Create a UserModel instance from the document data
          SocialMediaUser userModel = SocialMediaUser.fromMap(
            userDocSnapshot.data() as Map<String, dynamic>,
          );
          // Add the UserModel to the list
          users.add(userModel);
        }
      }
    } catch (e) {
      // Handle any errors that occur during the process
      if (kDebugMode) {
        print('Error fetching users from blocked users list: $e');
      }
    }

    return users;
  }

  // ==================== USER ACTIONS ====================

  /// Block a user globally
  Future<bool> blockUserGlobally(String currentUserId, String targetUserId) async {
    try {
      log('🚫 Blocking user globally: $targetUserId by $currentUserId');

      await firebaseFirestore.collection(FirebaseCollections.users).doc(currentUserId).update({
        'blockedUser': FieldValue.arrayUnion([targetUserId]),
      });

      log('✅ User blocked successfully');
      return true;
    } catch (e) {
      log('❌ Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user globally
  Future<bool> unblockUserGlobally(String currentUserId, String targetUserId) async {
    try {
      log('✅ Unblocking user globally: $targetUserId by $currentUserId');

      await firebaseFirestore.collection(FirebaseCollections.users).doc(currentUserId).update({
        'blockedUser': FieldValue.arrayRemove([targetUserId]),
      });

      log('✅ User unblocked successfully');
      return true;
    } catch (e) {
      log('❌ Error unblocking user: $e');
      return false;
    }
  }

  /// Report a user
  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      log('🚨 Reporting user: $reportedUserId by $reporterId');

      await firebaseFirestore.collection(FirebaseCollections.reports).add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'user',
      });

      log('✅ User reported successfully');
      return true;
    } catch (e) {
      log('❌ Error reporting user: $e');
      return false;
    }
  }

  /// Clear chat history with a user
  Future<bool> clearChatHistory(String roomId) async {
    try {
      log('🗑️ Clearing chat history for room: $roomId');

      // Get all messages in the chat
      final messagesRef = firebaseFirestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages);

      final messagesSnapshot = await messagesRef.get();

      // Delete messages in batches
      final batch = firebaseFirestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update last message
      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'lastMsg': '',
        'lastSender': '',
        'lastChat': FieldValue.serverTimestamp(),
      });

      log('✅ Chat history cleared successfully');
      return true;
    } catch (e) {
      log('❌ Error clearing chat history: $e');
      return false;
    }
  }

  /// Delete chat (remove from user's view)
  Future<bool> deleteChat(String roomId, String userId) async {
    try {
      log('🗑️ Deleting chat for user: $userId in room: $roomId');

      // Add user to deletedFor array
      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });

      log('✅ Chat deleted successfully');
      return true;
    } catch (e) {
      log('❌ Error deleting chat: $e');
      return false;
    }
  }

  // ==================== GROUP ACTIONS ====================

  /// Exit group
  Future<bool> exitGroup(String roomId, String userId) async {
    try {
      log('🚪 User $userId exiting group: $roomId');

      final chatDoc = await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).get();
      if (!chatDoc.exists) {
        throw Exception('Group not found');
      }

      final data = chatDoc.data()!;
      final members = List<String>.from(data['membersIds'] ?? []);
      final membersList = List<Map<String, dynamic>>.from(data['members'] ?? []);

      // Remove user from members
      members.remove(userId);
      membersList.removeWhere((m) => m['uid'] == userId);

      // Update group
      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'membersIds': members,
        'members': membersList,
      });

      // Add system message
      await firebaseFirestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .add({
        'type': 'event',
        'eventType': 'userLeft',
        'text': 'left the group',
        'senderId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      log('✅ User exited group successfully');
      return true;
    } catch (e) {
      log('❌ Error exiting group: $e');
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMemberFromGroup(
    String roomId,
    String memberId,
    String adminId,
  ) async {
    try {
      log('🚫 Admin $adminId removing member $memberId from group: $roomId');

      final chatDoc = await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).get();
      if (!chatDoc.exists) {
        throw Exception('Group not found');
      }

      final data = chatDoc.data()!;
      final members = List<String>.from(data['membersIds'] ?? []);
      final membersList = List<Map<String, dynamic>>.from(data['members'] ?? []);

      // Remove member
      members.remove(memberId);
      membersList.removeWhere((m) => m['uid'] == memberId);

      // Update group
      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'membersIds': members,
        'members': membersList,
      });

      // Add system message
      await firebaseFirestore
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .add({
        'type': 'event',
        'eventType': 'userRemoved',
        'text': 'was removed from the group',
        'senderId': memberId,
        'removedBy': adminId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      log('✅ Member removed from group successfully');
      return true;
    } catch (e) {
      log('❌ Error removing member from group: $e');
      return false;
    }
  }

  /// Report group
  Future<bool> reportGroup({
    required String reporterId,
    required String groupId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      log('🚨 Reporting group: $groupId by $reporterId');

      await firebaseFirestore.collection(FirebaseCollections.reports).add({
        'reporterId': reporterId,
        'reportedGroupId': groupId,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'group',
      });

      log('✅ Group reported successfully');
      return true;
    } catch (e) {
      log('❌ Error reporting group: $e');
      return false;
    }
  }

  /// Mute chat
  Future<bool> muteChat(String roomId, String userId, bool mute) async {
    try {
      log('🔇 ${mute ? "Muting" : "Unmuting"} chat: $roomId for user: $userId');

      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'mutedBy': mute
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });

      log('✅ Chat mute status updated successfully');
      return true;
    } catch (e) {
      log('❌ Error updating chat mute status: $e');
      return false;
    }
  }

  /// Pin chat
  Future<bool> pinChat(String roomId, bool pin) async {
    try {
      log('📌 ${pin ? "Pinning" : "Unpinning"} chat: $roomId');

      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'isPinned': pin,
      });

      log('✅ Chat pin status updated successfully');
      return true;
    } catch (e) {
      log('❌ Error updating chat pin status: $e');
      return false;
    }
  }

  /// Archive chat
  Future<bool> archiveChat(String roomId, bool archive) async {
    try {
      log('📦 ${archive ? "Archiving" : "Unarchiving"} chat: $roomId');

      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'isArchived': archive,
      });

      log('✅ Chat archive status updated successfully');
      return true;
    } catch (e) {
      log('❌ Error updating chat archive status: $e');
      return false;
    }
  }

  /// Add admin to group
  Future<bool> addGroupAdmin(String roomId, String userId) async {
    try {
      log('👑 Adding admin $userId to group: $roomId');

      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'admins': FieldValue.arrayUnion([userId]),
      });

      log('✅ Admin added successfully');
      return true;
    } catch (e) {
      log('❌ Error adding admin: $e');
      return false;
    }
  }

  /// Remove admin from group
  Future<bool> removeGroupAdmin(String roomId, String userId) async {
    try {
      log('👑 Removing admin $userId from group: $roomId');

      await firebaseFirestore.collection(FirebaseCollections.chats).doc(roomId).update({
        'admins': FieldValue.arrayRemove([userId]),
      });

      log('✅ Admin removed successfully');
      return true;
    } catch (e) {
      log('❌ Error removing admin: $e');
      return false;
    }
  }
}
