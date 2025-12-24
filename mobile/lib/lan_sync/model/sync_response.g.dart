// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) =>
    _SyncResponse(
      timestamp: (json['timestamp'] as num).toInt(),
      changes: (json['changes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      entityType: json['entityType'] as String?,
    );

Map<String, dynamic> _$SyncResponseToJson(_SyncResponse instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'changes': instance.changes,
      'entityType': instance.entityType,
    };

_SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) => _SyncRequest(
  since: (json['since'] as num).toInt(),
  entityType: json['entityType'] as String?,
);

Map<String, dynamic> _$SyncRequestToJson(_SyncRequest instance) =>
    <String, dynamic>{
      'since': instance.since,
      'entityType': instance.entityType,
    };
