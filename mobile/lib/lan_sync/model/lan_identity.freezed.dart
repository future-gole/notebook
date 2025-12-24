// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lan_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LanIdentity {

 String get deviceId; String get deviceName; int get wsPort; int get v;
/// Create a copy of LanIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanIdentityCopyWith<LanIdentity> get copyWith => _$LanIdentityCopyWithImpl<LanIdentity>(this as LanIdentity, _$identity);

  /// Serializes this LanIdentity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanIdentity&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.wsPort, wsPort) || other.wsPort == wsPort)&&(identical(other.v, v) || other.v == v));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,wsPort,v);

@override
String toString() {
  return 'LanIdentity(deviceId: $deviceId, deviceName: $deviceName, wsPort: $wsPort, v: $v)';
}


}

/// @nodoc
abstract mixin class $LanIdentityCopyWith<$Res>  {
  factory $LanIdentityCopyWith(LanIdentity value, $Res Function(LanIdentity) _then) = _$LanIdentityCopyWithImpl;
@useResult
$Res call({
 String deviceId, String deviceName, int wsPort, int v
});




}
/// @nodoc
class _$LanIdentityCopyWithImpl<$Res>
    implements $LanIdentityCopyWith<$Res> {
  _$LanIdentityCopyWithImpl(this._self, this._then);

  final LanIdentity _self;
  final $Res Function(LanIdentity) _then;

/// Create a copy of LanIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceName = null,Object? wsPort = null,Object? v = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,wsPort: null == wsPort ? _self.wsPort : wsPort // ignore: cast_nullable_to_non_nullable
as int,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LanIdentity].
extension LanIdentityPatterns on LanIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanIdentity value)  $default,){
final _that = this;
switch (_that) {
case _LanIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _LanIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  int wsPort,  int v)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanIdentity() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.wsPort,_that.v);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  int wsPort,  int v)  $default,) {final _that = this;
switch (_that) {
case _LanIdentity():
return $default(_that.deviceId,_that.deviceName,_that.wsPort,_that.v);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String deviceName,  int wsPort,  int v)?  $default,) {final _that = this;
switch (_that) {
case _LanIdentity() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.wsPort,_that.v);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LanIdentity implements LanIdentity {
  const _LanIdentity({required this.deviceId, required this.deviceName, required this.wsPort, this.v = 1});
  factory _LanIdentity.fromJson(Map<String, dynamic> json) => _$LanIdentityFromJson(json);

@override final  String deviceId;
@override final  String deviceName;
@override final  int wsPort;
@override@JsonKey() final  int v;

/// Create a copy of LanIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanIdentityCopyWith<_LanIdentity> get copyWith => __$LanIdentityCopyWithImpl<_LanIdentity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanIdentityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanIdentity&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.wsPort, wsPort) || other.wsPort == wsPort)&&(identical(other.v, v) || other.v == v));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,wsPort,v);

@override
String toString() {
  return 'LanIdentity(deviceId: $deviceId, deviceName: $deviceName, wsPort: $wsPort, v: $v)';
}


}

/// @nodoc
abstract mixin class _$LanIdentityCopyWith<$Res> implements $LanIdentityCopyWith<$Res> {
  factory _$LanIdentityCopyWith(_LanIdentity value, $Res Function(_LanIdentity) _then) = __$LanIdentityCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String deviceName, int wsPort, int v
});




}
/// @nodoc
class __$LanIdentityCopyWithImpl<$Res>
    implements _$LanIdentityCopyWith<$Res> {
  __$LanIdentityCopyWithImpl(this._self, this._then);

  final _LanIdentity _self;
  final $Res Function(_LanIdentity) _then;

/// Create a copy of LanIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceName = null,Object? wsPort = null,Object? v = null,}) {
  return _then(_LanIdentity(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,wsPort: null == wsPort ? _self.wsPort : wsPort // ignore: cast_nullable_to_non_nullable
as int,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
