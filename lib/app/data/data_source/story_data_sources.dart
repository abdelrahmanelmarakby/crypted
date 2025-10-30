import 'dart:io';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class StoryDataSources {
  final CollectionReference<Map<String, dynamic>> storiesCollection =
      FirebaseFirestore.instance.collection('Stories');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // رفع story جديدة (صورة أو فيديو)
  Future<bool> uploadStory(StoryModel story, File file) async {
    try {
      final userId = UserService.currentUser.value?.uid;
      if (userId == null) {
        log('❌ User ID is null');
        return false;
      }

      log('🚀 Starting story upload for user: $userId');

      // رفع الملف إلى Firebase Storage
      final fileName =
          'stories/${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child(fileName);

      log('📤 Uploading file to storage: $fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log('✅ File uploaded successfully: $downloadUrl');

      // إنشاء story جديدة
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));

      final currentUser = UserService.currentUser.value;
      final storyData = story.copyWith(
        uid: userId,
        user: currentUser,
        storyFileUrl: downloadUrl,
        createdAt: now,
        expiresAt: expiresAt,
        status: StoryStatus.active,
        viewedBy: [],
      );

      log('📝 Story data prepared: ${storyData.toMap()}');
      log('👤 User data: ${currentUser?.toMap()}');

      // حفظ في Firestore
      final docRef = await storiesCollection.add(storyData.toMap());
      await storiesCollection.doc(docRef.id).update({'id': docRef.id});

      log('✅ Story uploaded successfully to Firestore: ${docRef.id}');
      return true;
    } catch (e) {
      log('❌ Error uploading story: $e');
      return false;
    }
  }

  // رفع story نصية
  Future<bool> uploadTextStory(StoryModel story) async {
    try {
      final userId = UserService.currentUser.value?.uid;
      if (userId == null) {
        log('❌ User ID is null');
        return false;
      }

      log('🚀 Starting text story upload for user: $userId');

      // إنشاء story نصية
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));

      final currentUser = UserService.currentUser.value;
      final storyData = story.copyWith(
        uid: userId,
        user: currentUser,
        createdAt: now,
        expiresAt: expiresAt,
        status: StoryStatus.active,
        viewedBy: [],
        storyType: StoryType.text,
      );

      log('📝 Text story data prepared: ${storyData.toMap()}');
      log('👤 User data: ${currentUser?.toMap()}');

      // حفظ في Firestore
      final docRef = await storiesCollection.add(storyData.toMap());
      await storiesCollection.doc(docRef.id).update({'id': docRef.id});

      log('✅ Text story uploaded successfully to Firestore: ${docRef.id}');
      return true;
    } catch (e) {
      log('❌ Error uploading text story: $e');
      return false;
    }
  }

  // جلب جميع الـ stories (مبسط)
  Stream<List<StoryModel>> getAllStories() {
    log('📱 Fetching all stories...');

    return storiesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      log('📱 Raw stories count: ${snapshot.docs.length}');

      final stories = snapshot.docs
          .map((doc) {
            try {
              log('📱 Parsing story ${doc.id}: ${doc.data()}');
              final story = StoryModel.fromQuery(doc);
              log('👤 Story user: ${story.user?.fullName} (${story.uid})');
              return story;
            } catch (e) {
              log('❌ Error parsing story ${doc.id}: $e');
              log('📱 Story data: ${doc.data()}');
              return null;
            }
          })
          .where((story) => story != null)
          .cast<StoryModel>()
          .toList();

      // فلترة الستوريز المنتهية الصلاحية
      final now = DateTime.now();
      final activeStories = stories.where((story) {
        if (story.expiresAt == null) {
          log('📱 Story ${story.id} has no expiresAt, keeping it');
          return true;
        }
        final isActive = story.expiresAt!.isAfter(now);
        log('📱 Story ${story.id} expiresAt: ${story.expiresAt}, isActive: $isActive');
        return isActive;
      }).toList();

      log('📱 Found ${activeStories.length} active stories out of ${stories.length} total');
      return activeStories;
    });
  }

  // جلب stories مستخدم محدد (مبسط)
  Stream<List<StoryModel>> getUserStories(String userId) {
    log('👤 Fetching stories for user: $userId');
    return storiesCollection
        .where('uid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      log('👤 Raw stories count for user $userId: ${snapshot.docs.length}');

      final stories = snapshot.docs
          .map((doc) {
            try {
              log('👤 Parsing story ${doc.id}: ${doc.data()}');
              final story = StoryModel.fromQuery(doc);
              log('👤 Story user: ${story.user?.fullName} (${story.uid})');
              return story;
            } catch (e) {
              log('❌ Error parsing story ${doc.id}: $e');
              log('👤 Story data: ${doc.data()}');
              return null;
            }
          })
          .where((story) => story != null)
          .cast<StoryModel>()
          .toList()
        ..sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));

      // فلترة الستوريز المنتهية الصلاحية
      final now = DateTime.now();
      final activeStories = stories.where((story) {
        if (story.expiresAt == null) {
          log('👤 Story ${story.id} has no expiresAt, keeping it');
          return true;
        }
        final isActive = story.expiresAt!.isAfter(now);
        log('👤 Story ${story.id} expiresAt: ${story.expiresAt}, isActive: $isActive');
        return isActive;
      }).toList();

      log('👤 Found ${activeStories.length} active stories for user $userId');
      return activeStories;
    });
  }

  // تحديث حالة مشاهدة story
  Future<bool> markStoryAsViewed(String storyId, String userId) async {
    try {
      await storiesCollection.doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([userId]),
      });
      log('✅ Story marked as viewed: $storyId by $userId');
      return true;
    } catch (e) {
      log('❌ Error marking story as viewed: $e');
      return false;
    }
  }

  // حذف story
  Future<bool> deleteStory(String storyId) async {
    try {
      final doc = await storiesCollection.doc(storyId).get();
      if (doc.exists) {
        final storyData = doc.data();
        final storyFileUrl = storyData?['storyFileUrl'];

        // حذف الملف من Storage إذا كان موجود
        if (storyFileUrl != null && storyFileUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(storyFileUrl).delete();
            log('🗑️ File deleted from storage: $storyFileUrl');
          } catch (e) {
            log('⚠️ Could not delete file from storage: $e');
          }
        }
      }

      // حذف من Firestore
      await storiesCollection.doc(storyId).delete();
      log('✅ Story deleted successfully: $storyId');
      return true;
    } catch (e) {
      log('❌ Error deleting story: $e');
      return false;
    }
  }

  // حذف الـ stories المنتهية الصلاحية
  Future<void> deleteExpiredStories() async {
    try {
      final now = DateTime.now();
      final query = storiesCollection.where('expiresAt',
          isLessThan: Timestamp.fromDate(now));

      final snapshot = await query.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('✅ Deleted ${snapshot.docs.length} expired stories');
    } catch (e) {
      log('❌ Error deleting expired stories: $e');
    }
  }

  // إرسال رد على story
  Future<bool> sendStoryReply({
    required String storyId,
    required String storyOwnerId,
    required String replyText,
  }) async {
    try {
      final currentUser = UserService.currentUser.value;
      if (currentUser?.uid == null) {
        log('❌ Current user ID is null');
        return false;
      }

      log('💬 Sending reply to story $storyId from ${currentUser!.uid}');

      // إنشاء مرجع لمجموعة الردود تحت الـ story
      final repliesRef = storiesCollection.doc(storyId).collection('replies');

      final replyData = {
        'uid': currentUser.uid,
        'userName': currentUser.fullName,
        'userImageUrl': currentUser.imageUrl,
        'replyText': replyText,
        'createdAt': Timestamp.now(),
      };

      await repliesRef.add(replyData);

      // إرسال إشعار لصاحب الـ story (يمكن تنفيذه لاحقاً)
      // TODO: Send notification to story owner

      log('✅ Reply sent successfully to story $storyId');
      return true;
    } catch (e) {
      log('❌ Error sending story reply: $e');
      return false;
    }
  }

  // إرسال تفاعل على story
  Future<bool> sendStoryReaction({
    required String storyId,
    required String storyOwnerId,
    required String emoji,
  }) async {
    try {
      final currentUser = UserService.currentUser.value;
      if (currentUser?.uid == null) {
        log('❌ Current user ID is null');
        return false;
      }

      log('❤️ Sending reaction $emoji to story $storyId from ${currentUser!.uid}');

      // إنشاء مرجع لمجموعة التفاعلات تحت الـ story
      final reactionsRef =
          storiesCollection.doc(storyId).collection('reactions');

      // التحقق من وجود تفاعل سابق لنفس المستخدم
      final existingReaction = await reactionsRef
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingReaction.docs.isNotEmpty) {
        // تحديث التفاعل الحالي
        await existingReaction.docs.first.reference.update({
          'emoji': emoji,
          'updatedAt': Timestamp.now(),
        });
        log('✅ Reaction updated for story $storyId');
      } else {
        // إضافة تفاعل جديد
        final reactionData = {
          'uid': currentUser.uid,
          'userName': currentUser.fullName,
          'userImageUrl': currentUser.imageUrl,
          'emoji': emoji,
          'createdAt': Timestamp.now(),
        };

        await reactionsRef.add(reactionData);
        log('✅ New reaction added to story $storyId');
      }

      // إرسال إشعار لصاحب الـ story (يمكن تنفيذه لاحقاً)
      // TODO: Send notification to story owner

      return true;
    } catch (e) {
      log('❌ Error sending story reaction: $e');
      return false;
    }
  }

  // جلب ردود story
  Stream<List<Map<String, dynamic>>> getStoryReplies(String storyId) {
    return storiesCollection
        .doc(storyId)
        .collection('replies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // جلب تفاعلات story
  Stream<List<Map<String, dynamic>>> getStoryReactions(String storyId) {
    return storiesCollection
        .doc(storyId)
        .collection('reactions')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // حذف رد
  Future<bool> deleteStoryReply(String storyId, String replyId) async {
    try {
      await storiesCollection
          .doc(storyId)
          .collection('replies')
          .doc(replyId)
          .delete();
      log('✅ Reply deleted successfully: $replyId');
      return true;
    } catch (e) {
      log('❌ Error deleting reply: $e');
      return false;
    }
  }

  // حذف تفاعل
  Future<bool> deleteStoryReaction(String storyId, String reactionId) async {
    try {
      await storiesCollection
          .doc(storyId)
          .collection('reactions')
          .doc(reactionId)
          .delete();
      log('✅ Reaction deleted successfully: $reactionId');
      return true;
    } catch (e) {
      log('❌ Error deleting reaction: $e');
      return false;
    }
  }
}
