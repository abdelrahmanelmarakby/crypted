import 'dart:async';

/// ARCH-006: Firebase Abstraction Layer
/// Provides an interface to abstract database operations from Firebase implementation
/// This allows for easier testing and potential backend switching

/// Generic document reference interface
abstract class IDocumentReference<T> {
  String get id;
  String get path;
  Future<T?> get();
  Future<void> set(T data);
  Future<void> update(Map<String, dynamic> data);
  Future<void> delete();
  Stream<T?> snapshots();
}

/// Generic collection reference interface
abstract class ICollectionReference<T> {
  String get path;
  IDocumentReference<T> doc([String? id]);
  Future<List<T>> get();
  Stream<List<T>> snapshots();
  IQuery<T> where(String field, {dynamic isEqualTo, dynamic arrayContains, List<dynamic>? arrayContainsAny, List<dynamic>? isIn});
  IQuery<T> orderBy(String field, {bool descending = false});
  IQuery<T> limit(int count);
  IQuery<T> startAfter(List<dynamic> values);
  IQuery<T> startAfterDocument(IDocumentReference<T> document);
}

/// Generic query interface
abstract class IQuery<T> {
  Future<List<T>> get();
  Stream<List<T>> snapshots();
  IQuery<T> where(String field, {dynamic isEqualTo, dynamic arrayContains, List<dynamic>? arrayContainsAny, List<dynamic>? isIn});
  IQuery<T> orderBy(String field, {bool descending = false});
  IQuery<T> limit(int count);
  IQuery<T> startAfter(List<dynamic> values);
  IQuery<T> startAfterDocument(IDocumentReference<T> document);
}

/// Database transaction interface
abstract class ITransaction {
  Future<T?> get<T>(IDocumentReference<T> documentReference);
  void set<T>(IDocumentReference<T> documentReference, T data);
  void update<T>(IDocumentReference<T> documentReference, Map<String, dynamic> data);
  void delete<T>(IDocumentReference<T> documentReference);
}

/// Main database provider interface
/// ARCH-006: This abstracts Firebase from the rest of the application
abstract class IDatabaseProvider {
  /// Get a collection reference
  ICollectionReference<Map<String, dynamic>> collection(String path);

  /// Get a document reference
  IDocumentReference<Map<String, dynamic>> document(String path);

  /// Run a transaction
  Future<T> runTransaction<T>(Future<T> Function(ITransaction transaction) transactionHandler);

  /// Write batch operations
  IWriteBatch batch();

  /// Get server timestamp
  dynamic get serverTimestamp;

  /// Array union operation
  dynamic arrayUnion(List<dynamic> elements);

  /// Array remove operation
  dynamic arrayRemove(List<dynamic> elements);

  /// Delete field marker
  dynamic get deleteField;
}

/// Batch write interface
abstract class IWriteBatch {
  void set<T>(IDocumentReference<T> documentReference, T data);
  void update<T>(IDocumentReference<T> documentReference, Map<String, dynamic> data);
  void delete<T>(IDocumentReference<T> documentReference);
  Future<void> commit();
}

/// Pagination result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final IDocumentReference? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Query options for filtering and sorting
class QueryOptions {
  final List<WhereClause> whereClauses;
  final List<OrderByClause> orderByClauses;
  final int? limit;
  final dynamic startAfter;

  const QueryOptions({
    this.whereClauses = const [],
    this.orderByClauses = const [],
    this.limit,
    this.startAfter,
  });

  QueryOptions copyWith({
    List<WhereClause>? whereClauses,
    List<OrderByClause>? orderByClauses,
    int? limit,
    dynamic startAfter,
  }) {
    return QueryOptions(
      whereClauses: whereClauses ?? this.whereClauses,
      orderByClauses: orderByClauses ?? this.orderByClauses,
      limit: limit ?? this.limit,
      startAfter: startAfter ?? this.startAfter,
    );
  }
}

/// Where clause for queries
class WhereClause {
  final String field;
  final WhereOperator operator;
  final dynamic value;

  const WhereClause(this.field, this.operator, this.value);
}

/// Where operators
enum WhereOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// Order by clause for queries
class OrderByClause {
  final String field;
  final bool descending;

  const OrderByClause(this.field, {this.descending = false});
}
