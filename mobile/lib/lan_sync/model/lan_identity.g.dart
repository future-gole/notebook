// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lan_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanIdentity _$LanIdentityFromJson(Map<String, dynamic> json) => _LanIdentity(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  wsPort: (json['wsPort'] as num).toInt(),
  v: (json['v'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$LanIdentityToJson(_LanIdentity instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'wsPort': instance.wsPort,
      'v': instance.v,
    };
