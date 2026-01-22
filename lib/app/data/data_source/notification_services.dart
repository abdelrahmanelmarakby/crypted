import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/notification_model.dart';

class NotificationService {
  static final CollectionReference notificationCollection =
      FirebaseFirestore.instance.collection(FirebaseCollections.notifications);

  static Future sendNotification(NotificationModel notification) {
    DocumentReference docRef = notificationCollection.doc();
    return docRef.set(
      notification.copyWith(id: docRef.id, createdAt: DateTime.now()).toMap(),
    );
  }

  static Stream getAllNotifications() {
    return notificationCollection
        .orderBy('createdAt', descending: true)
        //.where('toUsers', arrayContains: UserService.currentUser.value?.uid)
        .snapshots();
  }
}
