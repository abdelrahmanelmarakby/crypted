import 'package:cloud_firestore/cloud_firestore.dart';

/// QUALITY-004: Consistent Null Handling Utilities
/// Provides standardized null handling patterns across the app
/// Reduces inconsistency between !, ?., ?? and default values

// ============================================================================
// SAFE ACCESSORS
// ============================================================================

/// Safely access a value with a default fallback
T safeValue<T>(T? value, T defaultValue) {
  return value ?? defaultValue;
}

/// Safely access a string with empty string default
String safeString(String? value) {
  return value ?? '';
}

/// Safely access an int with zero default
int safeInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safely access a double with zero default
double safeDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safely access a bool with false default
bool safeBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is int) return value != 0;
  return defaultValue;
}

/// Safely access a DateTime
DateTime? safeDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

/// Safely access a DateTime with default to now
DateTime safeDateTimeNow(dynamic value) {
  return safeDateTime(value) ?? DateTime.now();
}

/// Safely access a list
List<T> safeList<T>(dynamic value, {List<T>? defaultValue}) {
  if (value == null) return defaultValue ?? <T>[];
  if (value is List<T>) return value;
  if (value is List) {
    try {
      return value.cast<T>();
    } catch (e) {
      return defaultValue ?? <T>[];
    }
  }
  return defaultValue ?? <T>[];
}

/// Safely access a map
Map<K, V> safeMap<K, V>(dynamic value, {Map<K, V>? defaultValue}) {
  if (value == null) return defaultValue ?? <K, V>{};
  if (value is Map<K, V>) return value;
  if (value is Map) {
    try {
      return Map<K, V>.from(value);
    } catch (e) {
      return defaultValue ?? <K, V>{};
    }
  }
  return defaultValue ?? <K, V>{};
}

// ============================================================================
// MAP ACCESSORS
// ============================================================================

/// Safely access a value from a map
T? safeMapValue<T>(Map<String, dynamic>? map, String key) {
  if (map == null) return null;
  final value = map[key];
  if (value is T) return value;
  return null;
}

/// Safely access a string from a map
String safeMapString(Map<String, dynamic>? map, String key,
    {String defaultValue = ''}) {
  if (map == null) return defaultValue;
  final value = map[key];
  if (value is String) return value;
  if (value != null) return value.toString();
  return defaultValue;
}

/// Safely access an int from a map
int safeMapInt(Map<String, dynamic>? map, String key, {int defaultValue = 0}) {
  if (map == null) return defaultValue;
  return safeInt(map[key], defaultValue: defaultValue);
}

/// Safely access a double from a map
double safeMapDouble(Map<String, dynamic>? map, String key,
    {double defaultValue = 0.0}) {
  if (map == null) return defaultValue;
  return safeDouble(map[key], defaultValue: defaultValue);
}

/// Safely access a bool from a map
bool safeMapBool(Map<String, dynamic>? map, String key,
    {bool defaultValue = false}) {
  if (map == null) return defaultValue;
  return safeBool(map[key], defaultValue: defaultValue);
}

/// Safely access a DateTime from a map
DateTime? safeMapDateTime(Map<String, dynamic>? map, String key) {
  if (map == null) return null;
  return safeDateTime(map[key]);
}

/// Safely access a list from a map
List<T> safeMapList<T>(Map<String, dynamic>? map, String key) {
  if (map == null) return <T>[];
  return safeList<T>(map[key]);
}

/// Safely access a nested map
Map<String, dynamic> safeMapNested(Map<String, dynamic>? map, String key) {
  if (map == null) return {};
  return safeMap<String, dynamic>(map[key]);
}

// ============================================================================
// OPTIONAL OPERATIONS
// ============================================================================

/// Execute a function only if value is not null
R? ifNotNull<T, R>(T? value, R Function(T) fn) {
  if (value == null) return null;
  return fn(value);
}

/// Execute async function only if value is not null
Future<R?> ifNotNullAsync<T, R>(T? value, Future<R> Function(T) fn) async {
  if (value == null) return null;
  return await fn(value);
}

/// Get first non-null value
T coalesce<T>(List<T?> values, T defaultValue) {
  for (final value in values) {
    if (value != null) return value;
  }
  return defaultValue;
}

/// Transform nullable value
T? transform<S, T>(S? value, T Function(S) transformer) {
  if (value == null) return null;
  return transformer(value);
}

// ============================================================================
// EXTENSIONS
// ============================================================================

/// Extension for nullable strings
extension NullableStringExtension on String? {
  /// Get value or empty string
  String get orEmpty => this ?? '';

  /// Get value or default
  String or(String defaultValue) => this ?? defaultValue;

  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Get trimmed value or null if empty
  String? get trimmedOrNull {
    final trimmed = this?.trim();
    return (trimmed?.isEmpty ?? true) ? null : trimmed;
  }
}

/// Extension for nullable integers
extension NullableIntExtension on int? {
  /// Get value or zero
  int get orZero => this ?? 0;

  /// Get value or default
  int or(int defaultValue) => this ?? defaultValue;

  /// Check if positive
  bool get isPositive => (this ?? 0) > 0;
}

/// Extension for nullable doubles
extension NullableDoubleExtension on double? {
  /// Get value or zero
  double get orZero => this ?? 0.0;

  /// Get value or default
  double or(double defaultValue) => this ?? defaultValue;
}

/// Extension for nullable booleans
extension NullableBoolExtension on bool? {
  /// Get value or false
  bool get orFalse => this ?? false;

  /// Get value or true
  bool get orTrue => this ?? true;

  /// Get value or default
  bool or(bool defaultValue) => this ?? defaultValue;
}

/// Extension for nullable lists
extension NullableListExtension<T> on List<T>? {
  /// Get value or empty list
  List<T> get orEmpty => this ?? <T>[];

  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Safe first element
  T? get safeFirst => (this?.isNotEmpty ?? false) ? this!.first : null;

  /// Safe last element
  T? get safeLast => (this?.isNotEmpty ?? false) ? this!.last : null;

  /// Safe element at index
  T? safeAt(int index) {
    if (this == null || index < 0 || index >= this!.length) return null;
    return this![index];
  }
}

/// Extension for nullable maps
extension NullableMapExtension<K, V> on Map<K, V>? {
  /// Get value or empty map
  Map<K, V> get orEmpty => this ?? <K, V>{};

  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Safe key access
  V? safeGet(K key) => this?[key];
}

/// Extension for nullable DateTime
extension NullableDateTimeExtension on DateTime? {
  /// Get value or now
  DateTime get orNow => this ?? DateTime.now();

  /// Get value or default
  DateTime or(DateTime defaultValue) => this ?? defaultValue;

  /// Check if in future
  bool get isInFuture => this != null && this!.isAfter(DateTime.now());

  /// Check if in past
  bool get isInPast => this != null && this!.isBefore(DateTime.now());
}

// ============================================================================
// SAFE PARSER
// ============================================================================

/// Safe JSON/Map parser with null handling
class SafeParser {
  final Map<String, dynamic>? _data;

  SafeParser(this._data);

  factory SafeParser.from(dynamic data) {
    if (data == null) return SafeParser(null);
    if (data is Map<String, dynamic>) return SafeParser(data);
    if (data is Map) return SafeParser(Map<String, dynamic>.from(data));
    return SafeParser(null);
  }

  String getString(String key, {String defaultValue = ''}) {
    return safeMapString(_data, key, defaultValue: defaultValue);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return safeMapInt(_data, key, defaultValue: defaultValue);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return safeMapDouble(_data, key, defaultValue: defaultValue);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return safeMapBool(_data, key, defaultValue: defaultValue);
  }

  DateTime? getDateTime(String key) {
    return safeMapDateTime(_data, key);
  }

  List<T> getList<T>(String key) {
    return safeMapList<T>(_data, key);
  }

  SafeParser getNested(String key) {
    return SafeParser(safeMapNested(_data, key));
  }

  bool get isValid => _data != null;
}
