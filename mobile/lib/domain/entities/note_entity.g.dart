// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteEntity _$NoteEntityFromJson(Map<String, dynamic> json) => _NoteEntity(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  content: json['content'] as String?,
  url: json['url'] as String?,
  time: json['time'] == null ? null : DateTime.parse(json['time'] as String),
  categoryId:
      (json['categoryId'] as num?)?.toInt() ?? AppConstants.homeCategoryId,
  tag: json['tag'] as String?,
  previewImageUrl: json['previewImageUrl'] as String?,
  previewTitle: json['previewTitle'] as String?,
  previewDescription: json['previewDescription'] as String?,
);

Map<String, dynamic> _$NoteEntityToJson(_NoteEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'url': instance.url,
      'time': instance.time?.toIso8601String(),
      'categoryId': instance.categoryId,
      'tag': instance.tag,
      'previewImageUrl': instance.previewImageUrl,
      'previewTitle': instance.previewTitle,
      'previewDescription': instance.previewDescription,
    };
