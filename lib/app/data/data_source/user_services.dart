import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          await firebaseFirestore.collection('users').doc(uid).get();

      // إذا لم يوجد، جرب مع 'Users'
      if (!doc.exists) {
        print("⚠️ User not found in 'users', trying 'Users'...");
        doc = await firebaseFirestore.collection('Users').doc(uid).get();
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
              .collection('users')
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
          firebaseFirestore.collection("users").doc(user.uid);

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
          firebaseFirestore.collection("users").doc(user.uid);

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
        documentReference = firebaseFirestore.collection("Users").doc(user.uid);

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
          FirebaseFirestore.instance.collection('users').doc(userID);
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
          FirebaseFirestore.instance.collection('users').doc(userID);
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
          .collection('users')
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
          await FirebaseFirestore.instance.collection('users').get();

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

  static Future deleteUser(String uid) async {
    try {
      print("🗑️ Starting user deletion process for UID: $uid");

      // Use FirebaseFirestore instance directly since we're in a static method
      final firebaseFirestore = FirebaseFirestore.instance;
      final firebaseAuth = FirebaseAuth.instance;

      // Delete user data from Firestore
      await firebaseFirestore.collection("users").doc(uid).delete();
      print("✅ User data deleted from Firestore");

      // Delete user authentication
      await firebaseAuth.currentUser!.delete();
      print("✅ User authentication deleted");

      // Clear current user
      updateCurrentUser(null);
      print("✅ Current user cleared");

      print("🗑️ User deletion completed successfully");
    } catch (e) {
      print("❌ Error deleting user: $e");
      rethrow;
    }
  }

  Future<bool> blockUser(String blockedUserId, String chatRoomId) async {
    try {
      final currentUserDoc =
          FirebaseFirestore.instance.collection('users').doc(myUser?.uid);
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
            FirebaseFirestore.instance.collection('Chats').doc(chatRoomId);
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
          FirebaseFirestore.instance.collection('users').doc(myUser?.uid);
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
            FirebaseFirestore.instance.collection('Chats').doc(chatRoomId);
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
          FirebaseFirestore.instance.collection('users').doc(myUser?.uid);
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
            .collection('users')
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
}
