// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dio_network_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NetworkRequestBody {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(FormData data) fromData,
    required TResult Function(String data) text,
    required TResult Function(Map<String, dynamic> data) raw,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(FormData data)? fromData,
    TResult? Function(String data)? text,
    TResult? Function(Map<String, dynamic> data)? raw,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(FormData data)? fromData,
    TResult Function(String data)? text,
    TResult Function(Map<String, dynamic> data)? raw,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Empty value) empty,
    required TResult Function(Formdata value) fromData,
    required TResult Function(Text value) text,
    required TResult Function(Raw value) raw,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Empty value)? empty,
    TResult? Function(Formdata value)? fromData,
    TResult? Function(Text value)? text,
    TResult? Function(Raw value)? raw,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Empty value)? empty,
    TResult Function(Formdata value)? fromData,
    TResult Function(Text value)? text,
    TResult Function(Raw value)? raw,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkRequestBodyCopyWith<$Res> {
  factory $NetworkRequestBodyCopyWith(
          NetworkRequestBody value, $Res Function(NetworkRequestBody) then) =
      _$NetworkRequestBodyCopyWithImpl<$Res, NetworkRequestBody>;
}

/// @nodoc
class _$NetworkRequestBodyCopyWithImpl<$Res, $Val extends NetworkRequestBody>
    implements $NetworkRequestBodyCopyWith<$Res> {
  _$NetworkRequestBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EmptyImplCopyWith<$Res> {
  factory _$$EmptyImplCopyWith(
          _$EmptyImpl value, $Res Function(_$EmptyImpl) then) =
      __$$EmptyImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmptyImplCopyWithImpl<$Res>
    extends _$NetworkRequestBodyCopyWithImpl<$Res, _$EmptyImpl>
    implements _$$EmptyImplCopyWith<$Res> {
  __$$EmptyImplCopyWithImpl(
      _$EmptyImpl _value, $Res Function(_$EmptyImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmptyImpl with DiagnosticableTreeMixin implements Empty {
  const _$EmptyImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkRequestBody.empty()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'NetworkRequestBody.empty'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$EmptyImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(FormData data) fromData,
    required TResult Function(String data) text,
    required TResult Function(Map<String, dynamic> data) raw,
  }) {
    return empty();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(FormData data)? fromData,
    TResult? Function(String data)? text,
    TResult? Function(Map<String, dynamic> data)? raw,
  }) {
    return empty?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(FormData data)? fromData,
    TResult Function(String data)? text,
    TResult Function(Map<String, dynamic> data)? raw,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Empty value) empty,
    required TResult Function(Formdata value) fromData,
    required TResult Function(Text value) text,
    required TResult Function(Raw value) raw,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Empty value)? empty,
    TResult? Function(Formdata value)? fromData,
    TResult? Function(Text value)? text,
    TResult? Function(Raw value)? raw,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Empty value)? empty,
    TResult Function(Formdata value)? fromData,
    TResult Function(Text value)? text,
    TResult Function(Raw value)? raw,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class Empty implements NetworkRequestBody {
  const factory Empty() = _$EmptyImpl;
}

/// @nodoc
abstract class _$$FormdataImplCopyWith<$Res> {
  factory _$$FormdataImplCopyWith(
          _$FormdataImpl value, $Res Function(_$FormdataImpl) then) =
      __$$FormdataImplCopyWithImpl<$Res>;
  @useResult
  $Res call({FormData data});
}

/// @nodoc
class __$$FormdataImplCopyWithImpl<$Res>
    extends _$NetworkRequestBodyCopyWithImpl<$Res, _$FormdataImpl>
    implements _$$FormdataImplCopyWith<$Res> {
  __$$FormdataImplCopyWithImpl(
      _$FormdataImpl _value, $Res Function(_$FormdataImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_$FormdataImpl(
      null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as FormData,
    ));
  }
}

/// @nodoc

class _$FormdataImpl with DiagnosticableTreeMixin implements Formdata {
  const _$FormdataImpl(this.data);

  @override
  final FormData data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkRequestBody.fromData(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkRequestBody.fromData'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormdataImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormdataImplCopyWith<_$FormdataImpl> get copyWith =>
      __$$FormdataImplCopyWithImpl<_$FormdataImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(FormData data) fromData,
    required TResult Function(String data) text,
    required TResult Function(Map<String, dynamic> data) raw,
  }) {
    return fromData(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(FormData data)? fromData,
    TResult? Function(String data)? text,
    TResult? Function(Map<String, dynamic> data)? raw,
  }) {
    return fromData?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(FormData data)? fromData,
    TResult Function(String data)? text,
    TResult Function(Map<String, dynamic> data)? raw,
    required TResult orElse(),
  }) {
    if (fromData != null) {
      return fromData(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Empty value) empty,
    required TResult Function(Formdata value) fromData,
    required TResult Function(Text value) text,
    required TResult Function(Raw value) raw,
  }) {
    return fromData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Empty value)? empty,
    TResult? Function(Formdata value)? fromData,
    TResult? Function(Text value)? text,
    TResult? Function(Raw value)? raw,
  }) {
    return fromData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Empty value)? empty,
    TResult Function(Formdata value)? fromData,
    TResult Function(Text value)? text,
    TResult Function(Raw value)? raw,
    required TResult orElse(),
  }) {
    if (fromData != null) {
      return fromData(this);
    }
    return orElse();
  }
}

abstract class Formdata implements NetworkRequestBody {
  const factory Formdata(final FormData data) = _$FormdataImpl;

  FormData get data;

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormdataImplCopyWith<_$FormdataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TextImplCopyWith<$Res> {
  factory _$$TextImplCopyWith(
          _$TextImpl value, $Res Function(_$TextImpl) then) =
      __$$TextImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String data});
}

/// @nodoc
class __$$TextImplCopyWithImpl<$Res>
    extends _$NetworkRequestBodyCopyWithImpl<$Res, _$TextImpl>
    implements _$$TextImplCopyWith<$Res> {
  __$$TextImplCopyWithImpl(_$TextImpl _value, $Res Function(_$TextImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_$TextImpl(
      null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TextImpl with DiagnosticableTreeMixin implements Text {
  const _$TextImpl(this.data);

  @override
  final String data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkRequestBody.text(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkRequestBody.text'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextImplCopyWith<_$TextImpl> get copyWith =>
      __$$TextImplCopyWithImpl<_$TextImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(FormData data) fromData,
    required TResult Function(String data) text,
    required TResult Function(Map<String, dynamic> data) raw,
  }) {
    return text(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(FormData data)? fromData,
    TResult? Function(String data)? text,
    TResult? Function(Map<String, dynamic> data)? raw,
  }) {
    return text?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(FormData data)? fromData,
    TResult Function(String data)? text,
    TResult Function(Map<String, dynamic> data)? raw,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Empty value) empty,
    required TResult Function(Formdata value) fromData,
    required TResult Function(Text value) text,
    required TResult Function(Raw value) raw,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Empty value)? empty,
    TResult? Function(Formdata value)? fromData,
    TResult? Function(Text value)? text,
    TResult? Function(Raw value)? raw,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Empty value)? empty,
    TResult Function(Formdata value)? fromData,
    TResult Function(Text value)? text,
    TResult Function(Raw value)? raw,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }
}

abstract class Text implements NetworkRequestBody {
  const factory Text(final String data) = _$TextImpl;

  String get data;

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextImplCopyWith<_$TextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RawImplCopyWith<$Res> {
  factory _$$RawImplCopyWith(_$RawImpl value, $Res Function(_$RawImpl) then) =
      __$$RawImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> data});
}

/// @nodoc
class __$$RawImplCopyWithImpl<$Res>
    extends _$NetworkRequestBodyCopyWithImpl<$Res, _$RawImpl>
    implements _$$RawImplCopyWith<$Res> {
  __$$RawImplCopyWithImpl(_$RawImpl _value, $Res Function(_$RawImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_$RawImpl(
      null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$RawImpl with DiagnosticableTreeMixin implements Raw {
  const _$RawImpl(final Map<String, dynamic> data) : _data = data;

  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkRequestBody.raw(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkRequestBody.raw'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawImpl &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawImplCopyWith<_$RawImpl> get copyWith =>
      __$$RawImplCopyWithImpl<_$RawImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(FormData data) fromData,
    required TResult Function(String data) text,
    required TResult Function(Map<String, dynamic> data) raw,
  }) {
    return raw(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(FormData data)? fromData,
    TResult? Function(String data)? text,
    TResult? Function(Map<String, dynamic> data)? raw,
  }) {
    return raw?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(FormData data)? fromData,
    TResult Function(String data)? text,
    TResult Function(Map<String, dynamic> data)? raw,
    required TResult orElse(),
  }) {
    if (raw != null) {
      return raw(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Empty value) empty,
    required TResult Function(Formdata value) fromData,
    required TResult Function(Text value) text,
    required TResult Function(Raw value) raw,
  }) {
    return raw(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Empty value)? empty,
    TResult? Function(Formdata value)? fromData,
    TResult? Function(Text value)? text,
    TResult? Function(Raw value)? raw,
  }) {
    return raw?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Empty value)? empty,
    TResult Function(Formdata value)? fromData,
    TResult Function(Text value)? text,
    TResult Function(Raw value)? raw,
    required TResult orElse(),
  }) {
    if (raw != null) {
      return raw(this);
    }
    return orElse();
  }
}

abstract class Raw implements NetworkRequestBody {
  const factory Raw(final Map<String, dynamic> data) = _$RawImpl;

  Map<String, dynamic> get data;

  /// Create a copy of NetworkRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawImplCopyWith<_$RawImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NetworkResponse<Model> {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkResponseCopyWith<Model, $Res> {
  factory $NetworkResponseCopyWith(NetworkResponse<Model> value,
          $Res Function(NetworkResponse<Model>) then) =
      _$NetworkResponseCopyWithImpl<Model, $Res, NetworkResponse<Model>>;
}

/// @nodoc
class _$NetworkResponseCopyWithImpl<Model, $Res,
        $Val extends NetworkResponse<Model>>
    implements $NetworkResponseCopyWith<Model, $Res> {
  _$NetworkResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OkImplCopyWith<Model, $Res> {
  factory _$$OkImplCopyWith(
          _$OkImpl<Model> value, $Res Function(_$OkImpl<Model>) then) =
      __$$OkImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$OkImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$OkImpl<Model>>
    implements _$$OkImplCopyWith<Model, $Res> {
  __$$OkImplCopyWithImpl(
      _$OkImpl<Model> _value, $Res Function(_$OkImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$OkImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$OkImpl<Model> with DiagnosticableTreeMixin implements Ok<Model> {
  const _$OkImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.ok(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.ok'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkImplCopyWith<Model, _$OkImpl<Model>> get copyWith =>
      __$$OkImplCopyWithImpl<Model, _$OkImpl<Model>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return ok(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return ok?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (ok != null) {
      return ok(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return ok(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return ok?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (ok != null) {
      return ok(this);
    }
    return orElse();
  }
}

abstract class Ok<Model> implements NetworkResponse<Model> {
  const factory Ok(final Model data) = _$OkImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkImplCopyWith<Model, _$OkImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CreatedImplCopyWith<Model, $Res> {
  factory _$$CreatedImplCopyWith(_$CreatedImpl<Model> value,
          $Res Function(_$CreatedImpl<Model>) then) =
      __$$CreatedImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$CreatedImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$CreatedImpl<Model>>
    implements _$$CreatedImplCopyWith<Model, $Res> {
  __$$CreatedImplCopyWithImpl(
      _$CreatedImpl<Model> _value, $Res Function(_$CreatedImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$CreatedImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$CreatedImpl<Model>
    with DiagnosticableTreeMixin
    implements Created<Model> {
  const _$CreatedImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.created(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.created'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatedImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatedImplCopyWith<Model, _$CreatedImpl<Model>> get copyWith =>
      __$$CreatedImplCopyWithImpl<Model, _$CreatedImpl<Model>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return created(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return created?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (created != null) {
      return created(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return created(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return created?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (created != null) {
      return created(this);
    }
    return orElse();
  }
}

abstract class Created<Model> implements NetworkResponse<Model> {
  const factory Created(final Model data) = _$CreatedImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatedImplCopyWith<Model, _$CreatedImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvalidParametersImplCopyWith<Model, $Res> {
  factory _$$InvalidParametersImplCopyWith(_$InvalidParametersImpl<Model> value,
          $Res Function(_$InvalidParametersImpl<Model>) then) =
      __$$InvalidParametersImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$InvalidParametersImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res,
        _$InvalidParametersImpl<Model>>
    implements _$$InvalidParametersImplCopyWith<Model, $Res> {
  __$$InvalidParametersImplCopyWithImpl(_$InvalidParametersImpl<Model> _value,
      $Res Function(_$InvalidParametersImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$InvalidParametersImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$InvalidParametersImpl<Model>
    with DiagnosticableTreeMixin
    implements InvalidParameters<Model> {
  const _$InvalidParametersImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.invalidParameters(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty(
          'type', 'NetworkResponse<$Model>.invalidParameters'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvalidParametersImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvalidParametersImplCopyWith<Model, _$InvalidParametersImpl<Model>>
      get copyWith => __$$InvalidParametersImplCopyWithImpl<Model,
          _$InvalidParametersImpl<Model>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return invalidParameters(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return invalidParameters?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (invalidParameters != null) {
      return invalidParameters(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return invalidParameters(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return invalidParameters?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (invalidParameters != null) {
      return invalidParameters(this);
    }
    return orElse();
  }
}

abstract class InvalidParameters<Model> implements NetworkResponse<Model> {
  const factory InvalidParameters(final Model data) =
      _$InvalidParametersImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvalidParametersImplCopyWith<Model, _$InvalidParametersImpl<Model>>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnprocessableEntityImplCopyWith<Model, $Res> {
  factory _$$UnprocessableEntityImplCopyWith(
          _$UnprocessableEntityImpl<Model> value,
          $Res Function(_$UnprocessableEntityImpl<Model>) then) =
      __$$UnprocessableEntityImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$UnprocessableEntityImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res,
        _$UnprocessableEntityImpl<Model>>
    implements _$$UnprocessableEntityImplCopyWith<Model, $Res> {
  __$$UnprocessableEntityImplCopyWithImpl(
      _$UnprocessableEntityImpl<Model> _value,
      $Res Function(_$UnprocessableEntityImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$UnprocessableEntityImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$UnprocessableEntityImpl<Model>
    with DiagnosticableTreeMixin
    implements UnprocessableEntity<Model> {
  const _$UnprocessableEntityImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.unprocessableEntity(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty(
          'type', 'NetworkResponse<$Model>.unprocessableEntity'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnprocessableEntityImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnprocessableEntityImplCopyWith<Model, _$UnprocessableEntityImpl<Model>>
      get copyWith => __$$UnprocessableEntityImplCopyWithImpl<Model,
          _$UnprocessableEntityImpl<Model>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return unprocessableEntity(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return unprocessableEntity?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (unprocessableEntity != null) {
      return unprocessableEntity(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return unprocessableEntity(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return unprocessableEntity?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (unprocessableEntity != null) {
      return unprocessableEntity(this);
    }
    return orElse();
  }
}

abstract class UnprocessableEntity<Model> implements NetworkResponse<Model> {
  const factory UnprocessableEntity(final Model data) =
      _$UnprocessableEntityImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnprocessableEntityImplCopyWith<Model, _$UnprocessableEntityImpl<Model>>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoAuthImplCopyWith<Model, $Res> {
  factory _$$NoAuthImplCopyWith(
          _$NoAuthImpl<Model> value, $Res Function(_$NoAuthImpl<Model>) then) =
      __$$NoAuthImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$NoAuthImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$NoAuthImpl<Model>>
    implements _$$NoAuthImplCopyWith<Model, $Res> {
  __$$NoAuthImplCopyWithImpl(
      _$NoAuthImpl<Model> _value, $Res Function(_$NoAuthImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$NoAuthImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$NoAuthImpl<Model>
    with DiagnosticableTreeMixin
    implements NoAuth<Model> {
  const _$NoAuthImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.noAuth(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.noAuth'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoAuthImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoAuthImplCopyWith<Model, _$NoAuthImpl<Model>> get copyWith =>
      __$$NoAuthImplCopyWithImpl<Model, _$NoAuthImpl<Model>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return noAuth(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return noAuth?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (noAuth != null) {
      return noAuth(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return noAuth(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return noAuth?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (noAuth != null) {
      return noAuth(this);
    }
    return orElse();
  }
}

abstract class NoAuth<Model> implements NetworkResponse<Model> {
  const factory NoAuth(final Model data) = _$NoAuthImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoAuthImplCopyWith<Model, _$NoAuthImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoAccessImplCopyWith<Model, $Res> {
  factory _$$NoAccessImplCopyWith(_$NoAccessImpl<Model> value,
          $Res Function(_$NoAccessImpl<Model>) then) =
      __$$NoAccessImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$NoAccessImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$NoAccessImpl<Model>>
    implements _$$NoAccessImplCopyWith<Model, $Res> {
  __$$NoAccessImplCopyWithImpl(
      _$NoAccessImpl<Model> _value, $Res Function(_$NoAccessImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$NoAccessImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$NoAccessImpl<Model>
    with DiagnosticableTreeMixin
    implements NoAccess<Model> {
  const _$NoAccessImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.noAccess(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.noAccess'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoAccessImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoAccessImplCopyWith<Model, _$NoAccessImpl<Model>> get copyWith =>
      __$$NoAccessImplCopyWithImpl<Model, _$NoAccessImpl<Model>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return noAccess(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return noAccess?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (noAccess != null) {
      return noAccess(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return noAccess(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return noAccess?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (noAccess != null) {
      return noAccess(this);
    }
    return orElse();
  }
}

abstract class NoAccess<Model> implements NetworkResponse<Model> {
  const factory NoAccess(final Model data) = _$NoAccessImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoAccessImplCopyWith<Model, _$NoAccessImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BadRequestImplCopyWith<Model, $Res> {
  factory _$$BadRequestImplCopyWith(_$BadRequestImpl<Model> value,
          $Res Function(_$BadRequestImpl<Model>) then) =
      __$$BadRequestImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$BadRequestImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$BadRequestImpl<Model>>
    implements _$$BadRequestImplCopyWith<Model, $Res> {
  __$$BadRequestImplCopyWithImpl(_$BadRequestImpl<Model> _value,
      $Res Function(_$BadRequestImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$BadRequestImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$BadRequestImpl<Model>
    with DiagnosticableTreeMixin
    implements BadRequest<Model> {
  const _$BadRequestImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.badRequest(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.badRequest'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BadRequestImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BadRequestImplCopyWith<Model, _$BadRequestImpl<Model>> get copyWith =>
      __$$BadRequestImplCopyWithImpl<Model, _$BadRequestImpl<Model>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return badRequest(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return badRequest?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (badRequest != null) {
      return badRequest(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return badRequest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return badRequest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (badRequest != null) {
      return badRequest(this);
    }
    return orElse();
  }
}

abstract class BadRequest<Model> implements NetworkResponse<Model> {
  const factory BadRequest(final Model data) = _$BadRequestImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BadRequestImplCopyWith<Model, _$BadRequestImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotFoundImplCopyWith<Model, $Res> {
  factory _$$NotFoundImplCopyWith(_$NotFoundImpl<Model> value,
          $Res Function(_$NotFoundImpl<Model>) then) =
      __$$NotFoundImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$NotFoundImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$NotFoundImpl<Model>>
    implements _$$NotFoundImplCopyWith<Model, $Res> {
  __$$NotFoundImplCopyWithImpl(
      _$NotFoundImpl<Model> _value, $Res Function(_$NotFoundImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$NotFoundImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$NotFoundImpl<Model>
    with DiagnosticableTreeMixin
    implements NotFound<Model> {
  const _$NotFoundImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.notFound(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.notFound'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotFoundImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotFoundImplCopyWith<Model, _$NotFoundImpl<Model>> get copyWith =>
      __$$NotFoundImplCopyWithImpl<Model, _$NotFoundImpl<Model>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return notFound(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return notFound?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class NotFound<Model> implements NetworkResponse<Model> {
  const factory NotFound(final Model data) = _$NotFoundImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotFoundImplCopyWith<Model, _$NotFoundImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConflictImplCopyWith<Model, $Res> {
  factory _$$ConflictImplCopyWith(_$ConflictImpl<Model> value,
          $Res Function(_$ConflictImpl<Model>) then) =
      __$$ConflictImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({Model data});
}

/// @nodoc
class __$$ConflictImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$ConflictImpl<Model>>
    implements _$$ConflictImplCopyWith<Model, $Res> {
  __$$ConflictImplCopyWithImpl(
      _$ConflictImpl<Model> _value, $Res Function(_$ConflictImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
  }) {
    return _then(_$ConflictImpl<Model>(
      freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Model,
    ));
  }
}

/// @nodoc

class _$ConflictImpl<Model>
    with DiagnosticableTreeMixin
    implements Conflict<Model> {
  const _$ConflictImpl(this.data);

  @override
  final Model data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.conflict(data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.conflict'))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConflictImpl<Model> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConflictImplCopyWith<Model, _$ConflictImpl<Model>> get copyWith =>
      __$$ConflictImplCopyWithImpl<Model, _$ConflictImpl<Model>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return conflict(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return conflict?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (conflict != null) {
      return conflict(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return conflict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return conflict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (conflict != null) {
      return conflict(this);
    }
    return orElse();
  }
}

abstract class Conflict<Model> implements NetworkResponse<Model> {
  const factory Conflict(final Model data) = _$ConflictImpl<Model>;

  Model get data;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConflictImplCopyWith<Model, _$ConflictImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoDataImplCopyWith<Model, $Res> {
  factory _$$NoDataImplCopyWith(
          _$NoDataImpl<Model> value, $Res Function(_$NoDataImpl<Model>) then) =
      __$$NoDataImplCopyWithImpl<Model, $Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NoDataImplCopyWithImpl<Model, $Res>
    extends _$NetworkResponseCopyWithImpl<Model, $Res, _$NoDataImpl<Model>>
    implements _$$NoDataImplCopyWith<Model, $Res> {
  __$$NoDataImplCopyWithImpl(
      _$NoDataImpl<Model> _value, $Res Function(_$NoDataImpl<Model>) _then)
      : super(_value, _then);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$NoDataImpl<Model>(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$NoDataImpl<Model>
    with DiagnosticableTreeMixin
    implements NoData<Model> {
  const _$NoDataImpl(this.message);

  @override
  final String message;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NetworkResponse<$Model>.noData(message: $message)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NetworkResponse<$Model>.noData'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoDataImpl<Model> &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoDataImplCopyWith<Model, _$NoDataImpl<Model>> get copyWith =>
      __$$NoDataImplCopyWithImpl<Model, _$NoDataImpl<Model>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Model data) ok,
    required TResult Function(Model data) created,
    required TResult Function(Model data) invalidParameters,
    required TResult Function(Model data) unprocessableEntity,
    required TResult Function(Model data) noAuth,
    required TResult Function(Model data) noAccess,
    required TResult Function(Model data) badRequest,
    required TResult Function(Model data) notFound,
    required TResult Function(Model data) conflict,
    required TResult Function(String message) noData,
  }) {
    return noData(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Model data)? ok,
    TResult? Function(Model data)? created,
    TResult? Function(Model data)? invalidParameters,
    TResult? Function(Model data)? unprocessableEntity,
    TResult? Function(Model data)? noAuth,
    TResult? Function(Model data)? noAccess,
    TResult? Function(Model data)? badRequest,
    TResult? Function(Model data)? notFound,
    TResult? Function(Model data)? conflict,
    TResult? Function(String message)? noData,
  }) {
    return noData?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Model data)? ok,
    TResult Function(Model data)? created,
    TResult Function(Model data)? invalidParameters,
    TResult Function(Model data)? unprocessableEntity,
    TResult Function(Model data)? noAuth,
    TResult Function(Model data)? noAccess,
    TResult Function(Model data)? badRequest,
    TResult Function(Model data)? notFound,
    TResult Function(Model data)? conflict,
    TResult Function(String message)? noData,
    required TResult orElse(),
  }) {
    if (noData != null) {
      return noData(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Ok<Model> value) ok,
    required TResult Function(Created<Model> value) created,
    required TResult Function(InvalidParameters<Model> value) invalidParameters,
    required TResult Function(UnprocessableEntity<Model> value)
        unprocessableEntity,
    required TResult Function(NoAuth<Model> value) noAuth,
    required TResult Function(NoAccess<Model> value) noAccess,
    required TResult Function(BadRequest<Model> value) badRequest,
    required TResult Function(NotFound<Model> value) notFound,
    required TResult Function(Conflict<Model> value) conflict,
    required TResult Function(NoData<Model> value) noData,
  }) {
    return noData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Ok<Model> value)? ok,
    TResult? Function(Created<Model> value)? created,
    TResult? Function(InvalidParameters<Model> value)? invalidParameters,
    TResult? Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult? Function(NoAuth<Model> value)? noAuth,
    TResult? Function(NoAccess<Model> value)? noAccess,
    TResult? Function(BadRequest<Model> value)? badRequest,
    TResult? Function(NotFound<Model> value)? notFound,
    TResult? Function(Conflict<Model> value)? conflict,
    TResult? Function(NoData<Model> value)? noData,
  }) {
    return noData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Ok<Model> value)? ok,
    TResult Function(Created<Model> value)? created,
    TResult Function(InvalidParameters<Model> value)? invalidParameters,
    TResult Function(UnprocessableEntity<Model> value)? unprocessableEntity,
    TResult Function(NoAuth<Model> value)? noAuth,
    TResult Function(NoAccess<Model> value)? noAccess,
    TResult Function(BadRequest<Model> value)? badRequest,
    TResult Function(NotFound<Model> value)? notFound,
    TResult Function(Conflict<Model> value)? conflict,
    TResult Function(NoData<Model> value)? noData,
    required TResult orElse(),
  }) {
    if (noData != null) {
      return noData(this);
    }
    return orElse();
  }
}

abstract class NoData<Model> implements NetworkResponse<Model> {
  const factory NoData(final String message) = _$NoDataImpl<Model>;

  String get message;

  /// Create a copy of NetworkResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoDataImplCopyWith<Model, _$NoDataImpl<Model>> get copyWith =>
      throw _privateConstructorUsedError;
}
