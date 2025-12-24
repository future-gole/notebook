// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncResponse {

/// 服务端当前时间戳
 int get timestamp;/// 变更记录列表
 List<Map<String, dynamic>> get changes;/// 数据类型 (note, category, etc.)
 String? get entityType;
/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncResponseCopyWith<SyncResponse> get copyWith => _$SyncResponseCopyWithImpl<SyncResponse>(this as SyncResponse, _$identity);

  /// Serializes this SyncResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncResponse&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.changes, changes)&&(identical(other.entityType, entityType) || other.entityType == entityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,const DeepCollectionEquality().hash(changes),entityType);

@override
String toString() {
  return 'SyncResponse(timestamp: $timestamp, changes: $changes, entityType: $entityType)';
}


}

/// @nodoc
abstract mixin class $SyncResponseCopyWith<$Res>  {
  factory $SyncResponseCopyWith(SyncResponse value, $Res Function(SyncResponse) _then) = _$SyncResponseCopyWithImpl;
@useResult
$Res call({
 int timestamp, List<Map<String, dynamic>> changes, String? entityType
});




}
/// @nodoc
class _$SyncResponseCopyWithImpl<$Res>
    implements $SyncResponseCopyWith<$Res> {
  _$SyncResponseCopyWithImpl(this._self, this._then);

  final SyncResponse _self;
  final $Res Function(SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? changes = null,Object? entityType = freezed,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncResponse].
extension SyncResponsePatterns on SyncResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int timestamp,  List<Map<String, dynamic>> changes,  String? entityType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.timestamp,_that.changes,_that.entityType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int timestamp,  List<Map<String, dynamic>> changes,  String? entityType)  $default,) {final _that = this;
switch (_that) {
case _SyncResponse():
return $default(_that.timestamp,_that.changes,_that.entityType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int timestamp,  List<Map<String, dynamic>> changes,  String? entityType)?  $default,) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.timestamp,_that.changes,_that.entityType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncResponse extends SyncResponse {
  const _SyncResponse({required this.timestamp, required final  List<Map<String, dynamic>> changes, this.entityType}): _changes = changes,super._();
  factory _SyncResponse.fromJson(Map<String, dynamic> json) => _$SyncResponseFromJson(json);

/// 服务端当前时间戳
@override final  int timestamp;
/// 变更记录列表
 final  List<Map<String, dynamic>> _changes;
/// 变更记录列表
@override List<Map<String, dynamic>> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

/// 数据类型 (note, category, etc.)
@override final  String? entityType;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncResponseCopyWith<_SyncResponse> get copyWith => __$SyncResponseCopyWithImpl<_SyncResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncResponse&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._changes, _changes)&&(identical(other.entityType, entityType) || other.entityType == entityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,const DeepCollectionEquality().hash(_changes),entityType);

@override
String toString() {
  return 'SyncResponse(timestamp: $timestamp, changes: $changes, entityType: $entityType)';
}


}

/// @nodoc
abstract mixin class _$SyncResponseCopyWith<$Res> implements $SyncResponseCopyWith<$Res> {
  factory _$SyncResponseCopyWith(_SyncResponse value, $Res Function(_SyncResponse) _then) = __$SyncResponseCopyWithImpl;
@override @useResult
$Res call({
 int timestamp, List<Map<String, dynamic>> changes, String? entityType
});




}
/// @nodoc
class __$SyncResponseCopyWithImpl<$Res>
    implements _$SyncResponseCopyWith<$Res> {
  __$SyncResponseCopyWithImpl(this._self, this._then);

  final _SyncResponse _self;
  final $Res Function(_SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? changes = null,Object? entityType = freezed,}) {
  return _then(_SyncResponse(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SyncRequest {

/// 上次同步时间戳
 int get since;/// 请求的实体类型 (note, category, all)
 String? get entityType;
/// Create a copy of SyncRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRequestCopyWith<SyncRequest> get copyWith => _$SyncRequestCopyWithImpl<SyncRequest>(this as SyncRequest, _$identity);

  /// Serializes this SyncRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRequest&&(identical(other.since, since) || other.since == since)&&(identical(other.entityType, entityType) || other.entityType == entityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,since,entityType);

@override
String toString() {
  return 'SyncRequest(since: $since, entityType: $entityType)';
}


}

/// @nodoc
abstract mixin class $SyncRequestCopyWith<$Res>  {
  factory $SyncRequestCopyWith(SyncRequest value, $Res Function(SyncRequest) _then) = _$SyncRequestCopyWithImpl;
@useResult
$Res call({
 int since, String? entityType
});




}
/// @nodoc
class _$SyncRequestCopyWithImpl<$Res>
    implements $SyncRequestCopyWith<$Res> {
  _$SyncRequestCopyWithImpl(this._self, this._then);

  final SyncRequest _self;
  final $Res Function(SyncRequest) _then;

/// Create a copy of SyncRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? since = null,Object? entityType = freezed,}) {
  return _then(_self.copyWith(
since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncRequest].
extension SyncRequestPatterns on SyncRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncRequest value)  $default,){
final _that = this;
switch (_that) {
case _SyncRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SyncRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int since,  String? entityType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncRequest() when $default != null:
return $default(_that.since,_that.entityType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int since,  String? entityType)  $default,) {final _that = this;
switch (_that) {
case _SyncRequest():
return $default(_that.since,_that.entityType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int since,  String? entityType)?  $default,) {final _that = this;
switch (_that) {
case _SyncRequest() when $default != null:
return $default(_that.since,_that.entityType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncRequest extends SyncRequest {
  const _SyncRequest({required this.since, this.entityType}): super._();
  factory _SyncRequest.fromJson(Map<String, dynamic> json) => _$SyncRequestFromJson(json);

/// 上次同步时间戳
@override final  int since;
/// 请求的实体类型 (note, category, all)
@override final  String? entityType;

/// Create a copy of SyncRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncRequestCopyWith<_SyncRequest> get copyWith => __$SyncRequestCopyWithImpl<_SyncRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncRequest&&(identical(other.since, since) || other.since == since)&&(identical(other.entityType, entityType) || other.entityType == entityType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,since,entityType);

@override
String toString() {
  return 'SyncRequest(since: $since, entityType: $entityType)';
}


}

/// @nodoc
abstract mixin class _$SyncRequestCopyWith<$Res> implements $SyncRequestCopyWith<$Res> {
  factory _$SyncRequestCopyWith(_SyncRequest value, $Res Function(_SyncRequest) _then) = __$SyncRequestCopyWithImpl;
@override @useResult
$Res call({
 int since, String? entityType
});




}
/// @nodoc
class __$SyncRequestCopyWithImpl<$Res>
    implements _$SyncRequestCopyWith<$Res> {
  __$SyncRequestCopyWithImpl(this._self, this._then);

  final _SyncRequest _self;
  final $Res Function(_SyncRequest) _then;

/// Create a copy of SyncRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? since = null,Object? entityType = freezed,}) {
  return _then(_SyncRequest(
since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
