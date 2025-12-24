// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncMessage _$SyncMessageFromJson(Map<String, dynamic> json) => _SyncMessage(
  type: json['type'] as String,
  data: json['data'] as Map<String, dynamic>?,
  timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SyncMessageToJson(_SyncMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
      'timestamp': instance.timestamp,
    };
