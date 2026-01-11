import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_provider.dart';

/// ARCH-006: Firebase Implementation of Database Provider
/// Wraps Firebase Firestore to implement the IDatabaseProvider interface
class FirebaseDatabaseProvider implements IDatabaseProvider {
  final FirebaseFirestore _firestore;

  FirebaseDatabaseProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  ICollectionReference<Map<String, dynamic>> collection(String path) {
    return FirebaseCollectionReference(_firestore.collection(path));
  }

  @override
  IDocumentReference<Map<String, dynamic>> document(String path) {
    return FirebaseDocumentReference(_firestore.doc(path));
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(ITransaction transaction) transactionHandler,
  ) {
    return _firestore.runTransaction((firestoreTransaction) {
      return transactionHandler(FirebaseTransaction(firestoreTransaction));
    });
  }

  @override
  IWriteBatch batch() {
    return FirebaseWriteBatch(_firestore.batch());
  }

  @override
  dynamic get serverTimestamp => FieldValue.serverTimestamp();

  @override
  dynamic arrayUnion(List<dynamic> elements) => FieldValue.arrayUnion(elements);

  @override
  dynamic arrayRemove(List<dynamic> elements) => FieldValue.arrayRemove(elements);

  @override
  dynamic get deleteField => FieldValue.delete();
}

/// Firebase implementation of ICollectionReference
class FirebaseCollectionReference implements ICollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> _collection;

  FirebaseCollectionReference(this._collection);

  @override
  String get path => _collection.path;

  @override
  IDocumentReference<Map<String, dynamic>> doc([String? id]) {
    return FirebaseDocumentReference(_collection.doc(id));
  }

  @override
  Future<List<Map<String, dynamic>>> get() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> snapshots() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  IQuery<Map<String, dynamic>> where(
    String field, {
    dynamic isEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? isIn,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    if (arrayContains != null) {
      query = query.where(field, arrayContains: arrayContains);
    }
    if (arrayContainsAny != null) {
      query = query.where(field, arrayContainsAny: arrayContainsAny);
    }
    if (isIn != null) {
      query = query.where(field, whereIn: isIn);
    }

    return FirebaseQuery(query);
  }

  @override
  IQuery<Map<String, dynamic>> orderBy(String field, {bool descending = false}) {
    return FirebaseQuery(_collection.orderBy(field, descending: descending));
  }

  @override
  IQuery<Map<String, dynamic>> limit(int count) {
    return FirebaseQuery(_collection.limit(count));
  }

  @override
  IQuery<Map<String, dynamic>> startAfter(List<dynamic> values) {
    return FirebaseQuery(_collection.startAfter(values));
  }

  @override
  IQuery<Map<String, dynamic>> startAfterDocument(IDocumentReference<Map<String, dynamic>> document) {
    if (document is FirebaseDocumentReference) {
      // Need to get the snapshot first
      throw UnimplementedError('Use startAfter with values instead');
    }
    throw ArgumentError('Document must be a FirebaseDocumentReference');
  }
}

/// Firebase implementation of IDocumentReference
class FirebaseDocumentReference implements IDocumentReference<Map<String, dynamic>> {
  final DocumentReference<Map<String, dynamic>> _doc;

  FirebaseDocumentReference(this._doc);

  @override
  String get id => _doc.id;

  @override
  String get path => _doc.path;

  @override
  Future<Map<String, dynamic>?> get() async {
    final snapshot = await _doc.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null) {
        data['id'] = snapshot.id;
      }
      return data;
    }
    return null;
  }

  @override
  Future<void> set(Map<String, dynamic> data) {
    return _doc.set(data);
  }

  @override
  Future<void> update(Map<String, dynamic> data) {
    return _doc.update(data);
  }

  @override
  Future<void> delete() {
    return _doc.delete();
  }

  @override
  Stream<Map<String, dynamic>?> snapshots() {
    return _doc.snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          data['id'] = snapshot.id;
        }
        return data;
      }
      return null;
    });
  }
}

/// Firebase implementation of IQuery
class FirebaseQuery implements IQuery<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> _query;

  FirebaseQuery(this._query);

  @override
  Future<List<Map<String, dynamic>>> get() async {
    final snapshot = await _query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> snapshots() {
    return _query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  IQuery<Map<String, dynamic>> where(
    String field, {
    dynamic isEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? isIn,
  }) {
    Query<Map<String, dynamic>> query = _query;

    if (isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    if (arrayContains != null) {
      query = query.where(field, arrayContains: arrayContains);
    }
    if (arrayContainsAny != null) {
      query = query.where(field, arrayContainsAny: arrayContainsAny);
    }
    if (isIn != null) {
      query = query.where(field, whereIn: isIn);
    }

    return FirebaseQuery(query);
  }

  @override
  IQuery<Map<String, dynamic>> orderBy(String field, {bool descending = false}) {
    return FirebaseQuery(_query.orderBy(field, descending: descending));
  }

  @override
  IQuery<Map<String, dynamic>> limit(int count) {
    return FirebaseQuery(_query.limit(count));
  }

  @override
  IQuery<Map<String, dynamic>> startAfter(List<dynamic> values) {
    return FirebaseQuery(_query.startAfter(values));
  }

  @override
  IQuery<Map<String, dynamic>> startAfterDocument(IDocumentReference<Map<String, dynamic>> document) {
    throw UnimplementedError('Use startAfter with values instead');
  }
}

/// Firebase implementation of ITransaction
class FirebaseTransaction implements ITransaction {
  final Transaction _transaction;

  FirebaseTransaction(this._transaction);

  @override
  Future<T?> get<T>(IDocumentReference<T> documentReference) async {
    if (documentReference is FirebaseDocumentReference) {
      final snapshot = await _transaction.get(documentReference._doc);
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          data['id'] = snapshot.id;
        }
        return data as T?;
      }
    }
    return null;
  }

  @override
  void set<T>(IDocumentReference<T> documentReference, T data) {
    if (documentReference is FirebaseDocumentReference && data is Map<String, dynamic>) {
      _transaction.set(documentReference._doc, data);
    }
  }

  @override
  void update<T>(IDocumentReference<T> documentReference, Map<String, dynamic> data) {
    if (documentReference is FirebaseDocumentReference) {
      _transaction.update(documentReference._doc, data);
    }
  }

  @override
  void delete<T>(IDocumentReference<T> documentReference) {
    if (documentReference is FirebaseDocumentReference) {
      _transaction.delete(documentReference._doc);
    }
  }
}

/// Firebase implementation of IWriteBatch
class FirebaseWriteBatch implements IWriteBatch {
  final WriteBatch _batch;

  FirebaseWriteBatch(this._batch);

  @override
  void set<T>(IDocumentReference<T> documentReference, T data) {
    if (documentReference is FirebaseDocumentReference && data is Map<String, dynamic>) {
      _batch.set(documentReference._doc, data);
    }
  }

  @override
  void update<T>(IDocumentReference<T> documentReference, Map<String, dynamic> data) {
    if (documentReference is FirebaseDocumentReference) {
      _batch.update(documentReference._doc, data);
    }
  }

  @override
  void delete<T>(IDocumentReference<T> documentReference) {
    if (documentReference is FirebaseDocumentReference) {
      _batch.delete(documentReference._doc);
    }
  }

  @override
  Future<void> commit() {
    return _batch.commit();
  }
}
