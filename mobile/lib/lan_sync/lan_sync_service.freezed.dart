// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lan_sync_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LanSyncState {

/// 服务是否正在运行
 bool get isRunning;/// 是否正在同步中
 bool get isSyncing;/// 本地设备信息
 DeviceInfo? get localDevice;/// 发现的对等节点列表
 List<LanPeer> get peers;/// 最后一次错误信息
 String? get lastError;/// 最后一次同步成功的时间
 DateTime? get lastSyncTime;
/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanSyncStateCopyWith<LanSyncState> get copyWith => _$LanSyncStateCopyWithImpl<LanSyncState>(this as LanSyncState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanSyncState&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.localDevice, localDevice) || other.localDevice == localDevice)&&const DeepCollectionEquality().equals(other.peers, peers)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime));
}


@override
int get hashCode => Object.hash(runtimeType,isRunning,isSyncing,localDevice,const DeepCollectionEquality().hash(peers),lastError,lastSyncTime);

@override
String toString() {
  return 'LanSyncState(isRunning: $isRunning, isSyncing: $isSyncing, localDevice: $localDevice, peers: $peers, lastError: $lastError, lastSyncTime: $lastSyncTime)';
}


}

/// @nodoc
abstract mixin class $LanSyncStateCopyWith<$Res>  {
  factory $LanSyncStateCopyWith(LanSyncState value, $Res Function(LanSyncState) _then) = _$LanSyncStateCopyWithImpl;
@useResult
$Res call({
 bool isRunning, bool isSyncing, DeviceInfo? localDevice, List<LanPeer> peers, String? lastError, DateTime? lastSyncTime
});


$DeviceInfoCopyWith<$Res>? get localDevice;

}
/// @nodoc
class _$LanSyncStateCopyWithImpl<$Res>
    implements $LanSyncStateCopyWith<$Res> {
  _$LanSyncStateCopyWithImpl(this._self, this._then);

  final LanSyncState _self;
  final $Res Function(LanSyncState) _then;

/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRunning = null,Object? isSyncing = null,Object? localDevice = freezed,Object? peers = null,Object? lastError = freezed,Object? lastSyncTime = freezed,}) {
  return _then(_self.copyWith(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,localDevice: freezed == localDevice ? _self.localDevice : localDevice // ignore: cast_nullable_to_non_nullable
as DeviceInfo?,peers: null == peers ? _self.peers : peers // ignore: cast_nullable_to_non_nullable
as List<LanPeer>,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res>? get localDevice {
    if (_self.localDevice == null) {
    return null;
  }

  return $DeviceInfoCopyWith<$Res>(_self.localDevice!, (value) {
    return _then(_self.copyWith(localDevice: value));
  });
}
}


/// Adds pattern-matching-related methods to [LanSyncState].
extension LanSyncStatePatterns on LanSyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanSyncState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanSyncState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanSyncState value)  $default,){
final _that = this;
switch (_that) {
case _LanSyncState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanSyncState value)?  $default,){
final _that = this;
switch (_that) {
case _LanSyncState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRunning,  bool isSyncing,  DeviceInfo? localDevice,  List<LanPeer> peers,  String? lastError,  DateTime? lastSyncTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanSyncState() when $default != null:
return $default(_that.isRunning,_that.isSyncing,_that.localDevice,_that.peers,_that.lastError,_that.lastSyncTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRunning,  bool isSyncing,  DeviceInfo? localDevice,  List<LanPeer> peers,  String? lastError,  DateTime? lastSyncTime)  $default,) {final _that = this;
switch (_that) {
case _LanSyncState():
return $default(_that.isRunning,_that.isSyncing,_that.localDevice,_that.peers,_that.lastError,_that.lastSyncTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRunning,  bool isSyncing,  DeviceInfo? localDevice,  List<LanPeer> peers,  String? lastError,  DateTime? lastSyncTime)?  $default,) {final _that = this;
switch (_that) {
case _LanSyncState() when $default != null:
return $default(_that.isRunning,_that.isSyncing,_that.localDevice,_that.peers,_that.lastError,_that.lastSyncTime);case _:
  return null;

}
}

}

/// @nodoc


class _LanSyncState extends LanSyncState {
  const _LanSyncState({required this.isRunning, required this.isSyncing, required this.localDevice, required final  List<LanPeer> peers, required this.lastError, required this.lastSyncTime}): _peers = peers,super._();
  

/// 服务是否正在运行
@override final  bool isRunning;
/// 是否正在同步中
@override final  bool isSyncing;
/// 本地设备信息
@override final  DeviceInfo? localDevice;
/// 发现的对等节点列表
 final  List<LanPeer> _peers;
/// 发现的对等节点列表
@override List<LanPeer> get peers {
  if (_peers is EqualUnmodifiableListView) return _peers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_peers);
}

/// 最后一次错误信息
@override final  String? lastError;
/// 最后一次同步成功的时间
@override final  DateTime? lastSyncTime;

/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanSyncStateCopyWith<_LanSyncState> get copyWith => __$LanSyncStateCopyWithImpl<_LanSyncState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanSyncState&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.localDevice, localDevice) || other.localDevice == localDevice)&&const DeepCollectionEquality().equals(other._peers, _peers)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime));
}


@override
int get hashCode => Object.hash(runtimeType,isRunning,isSyncing,localDevice,const DeepCollectionEquality().hash(_peers),lastError,lastSyncTime);

@override
String toString() {
  return 'LanSyncState(isRunning: $isRunning, isSyncing: $isSyncing, localDevice: $localDevice, peers: $peers, lastError: $lastError, lastSyncTime: $lastSyncTime)';
}


}

/// @nodoc
abstract mixin class _$LanSyncStateCopyWith<$Res> implements $LanSyncStateCopyWith<$Res> {
  factory _$LanSyncStateCopyWith(_LanSyncState value, $Res Function(_LanSyncState) _then) = __$LanSyncStateCopyWithImpl;
@override @useResult
$Res call({
 bool isRunning, bool isSyncing, DeviceInfo? localDevice, List<LanPeer> peers, String? lastError, DateTime? lastSyncTime
});


@override $DeviceInfoCopyWith<$Res>? get localDevice;

}
/// @nodoc
class __$LanSyncStateCopyWithImpl<$Res>
    implements _$LanSyncStateCopyWith<$Res> {
  __$LanSyncStateCopyWithImpl(this._self, this._then);

  final _LanSyncState _self;
  final $Res Function(_LanSyncState) _then;

/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRunning = null,Object? isSyncing = null,Object? localDevice = freezed,Object? peers = null,Object? lastError = freezed,Object? lastSyncTime = freezed,}) {
  return _then(_LanSyncState(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,localDevice: freezed == localDevice ? _self.localDevice : localDevice // ignore: cast_nullable_to_non_nullable
as DeviceInfo?,peers: null == peers ? _self._peers : peers // ignore: cast_nullable_to_non_nullable
as List<LanPeer>,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of LanSyncState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res>? get localDevice {
    if (_self.localDevice == null) {
    return null;
  }

  return $DeviceInfoCopyWith<$Res>(_self.localDevice!, (value) {
    return _then(_self.copyWith(localDevice: value));
  });
}
}

// dart format on
