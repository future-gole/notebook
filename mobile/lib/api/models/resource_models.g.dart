// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceSubmitRequest _$ResourceSubmitRequestFromJson(
  Map<String, dynamic> json,
) => ResourceSubmitRequest(url: json['url'] as String);

Map<String, dynamic> _$ResourceSubmitRequestToJson(
  ResourceSubmitRequest instance,
) => <String, dynamic>{'url': instance.url};

ResourceStatusRequest _$ResourceStatusRequestFromJson(
  Map<String, dynamic> json,
) => ResourceStatusRequest(
  urls: (json['urls'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ResourceStatusRequestToJson(
  ResourceStatusRequest instance,
) => <String, dynamic>{'urls': instance.urls};

ResourceStatusItem _$ResourceStatusItemFromJson(Map<String, dynamic> json) =>
    ResourceStatusItem(
      url: json['url'] as String,
      status: json['status'] as String,
      title: json['title'] as String?,
      previewContent: json['previewContent'] as String?,
      aiSummary: json['aiSummary'] as String?,
    );

Map<String, dynamic> _$ResourceStatusItemToJson(ResourceStatusItem instance) =>
    <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'previewContent': instance.previewContent,
      'aiSummary': instance.aiSummary,
      'status': instance.status,
    };
