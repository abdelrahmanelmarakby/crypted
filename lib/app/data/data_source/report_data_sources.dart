import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/report_user_model.dart';

class ReportDataSources {
  final CollectionReference reportsCollection = FirebaseFirestore.instance
      .collection(FirebaseCollections.reports);

  Future<bool> reportUser(ReportUserModel reportUserModel) async {
    try {
      DocumentReference documentReference = reportsCollection.doc();
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          reportUserModel.copyWith(id: documentReference.id).toMap(),
        );
      });
      return true;
    } catch (e) {
      log('Error storing report: $e');
      return false;
    }
  }
}
