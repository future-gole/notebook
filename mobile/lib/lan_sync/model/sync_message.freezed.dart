// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncMessage {

 String get type; Map<String, dynamic>? get data; int get timestamp;
/// Create a copy of SyncMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncMessageCopyWith<SyncMessage> get copyWith => _$SyncMessageCopyWithImpl<SyncMessage>(this as SyncMessage, _$identity);

  /// Serializes this SyncMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(data),timestamp);

@override
String toString() {
  return 'SyncMessage(type: $type, data: $data, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $SyncMessageCopyWith<$Res>  {
  factory $SyncMessageCopyWith(SyncMessage value, $Res Function(SyncMessage) _then) = _$SyncMessageCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic>? data, int timestamp
});




}
/// @nodoc
class _$SyncMessageCopyWithImpl<$Res>
    implements $SyncMessageCopyWith<$Res> {
  _$SyncMessageCopyWithImpl(this._self, this._then);

  final SyncMessage _self;
  final $Res Function(SyncMessage) _then;

/// Create a copy of SyncMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? data = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncMessage].
extension SyncMessagePatterns on SyncMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncMessage value)  $default,){
final _that = this;
switch (_that) {
case _SyncMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SyncMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? data,  int timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncMessage() when $default != null:
return $default(_that.type,_that.data,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? data,  int timestamp)  $default,) {final _that = this;
switch (_that) {
case _SyncMessage():
return $default(_that.type,_that.data,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  Map<String, dynamic>? data,  int timestamp)?  $default,) {final _that = this;
switch (_that) {
case _SyncMessage() when $default != null:
return $default(_that.type,_that.data,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncMessage implements SyncMessage {
  const _SyncMessage({required this.type, final  Map<String, dynamic>? data, this.timestamp = 0}): _data = data;
  factory _SyncMessage.fromJson(Map<String, dynamic> json) => _$SyncMessageFromJson(json);

@override final  String type;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  int timestamp;

/// Create a copy of SyncMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncMessageCopyWith<_SyncMessage> get copyWith => __$SyncMessageCopyWithImpl<_SyncMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncMessage&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_data),timestamp);

@override
String toString() {
  return 'SyncMessage(type: $type, data: $data, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$SyncMessageCopyWith<$Res> implements $SyncMessageCopyWith<$Res> {
  factory _$SyncMessageCopyWith(_SyncMessage value, $Res Function(_SyncMessage) _then) = __$SyncMessageCopyWithImpl;
@override @useResult
$Res call({
 String type, Map<String, dynamic>? data, int timestamp
});




}
/// @nodoc
class __$SyncMessageCopyWithImpl<$Res>
    implements _$SyncMessageCopyWith<$Res> {
  __$SyncMessageCopyWithImpl(this._self, this._then);

  final _SyncMessage _self;
  final $Res Function(_SyncMessage) _then;

/// Create a copy of SyncMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = freezed,Object? timestamp = null,}) {
  return _then(_SyncMessage(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
