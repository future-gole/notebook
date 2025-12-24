// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => _DeviceInfo(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  ipAddress: json['ipAddress'] as String?,
  port: (json['port'] as num?)?.toInt() ?? 54322,
  platform: json['platform'] as String?,
  appVersion: json['appVersion'] as String?,
  lastSeen: _dateTimeFromMillis((json['lastSeen'] as num?)?.toInt()),
);

Map<String, dynamic> _$DeviceInfoToJson(_DeviceInfo instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'ipAddress': instance.ipAddress,
      'port': instance.port,
      'platform': instance.platform,
      'appVersion': instance.appVersion,
      'lastSeen': _dateTimeToMillis(instance.lastSeen),
    };
