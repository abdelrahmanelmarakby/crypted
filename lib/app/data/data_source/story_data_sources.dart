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
}
