import 'package:json_annotation/json_annotation.dart';

part 'resource_models.g.dart';

@JsonSerializable()
class ResourceSubmitRequest {
  final String url;

  const ResourceSubmitRequest({required this.url});

  Map<String, dynamic> toJson() => _$ResourceSubmitRequestToJson(this);
}

@JsonSerializable()
class ResourceStatusRequest {
  final List<String> urls;

  const ResourceStatusRequest({required this.urls});

  Map<String, dynamic> toJson() => _$ResourceStatusRequestToJson(this);
}

@JsonSerializable()
class ResourceStatusItem {
  /// 以 url 为资源主键（后端已改为 url 查询）
  final String url;
  final String? title;
  final String? previewContent;
  final String? aiSummary;

  /// PENDING / CRAWLED / EMBEDDED / FAILED
  final String status;

  const ResourceStatusItem({
    required this.url,
    required this.status,
    this.title,
    this.previewContent,
    this.aiSummary,
  });

  factory ResourceStatusItem.fromJson(Map<String, dynamic> json) =>
      _$ResourceStatusItemFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceStatusItemToJson(this);
}
