import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_response.freezed.dart';
part 'sync_response.g.dart';

/// 同步响应数据
///
/// 服务端返回的同步数据格式
@freezed
abstract class SyncResponse with _$SyncResponse {
  const SyncResponse._();

  const factory SyncResponse({
    /// 服务端当前时间戳
    required int timestamp,

    /// 变更记录列表
    required List<Map<String, dynamic>> changes,

    /// 数据类型 (note, category, etc.)
    String? entityType,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);

  /// 是否有变更
  bool get hasChanges => changes.isNotEmpty;

  /// 变更数量
  int get changeCount => changes.length;
}

/// 同步请求数据
@freezed
abstract class SyncRequest with _$SyncRequest {
  const SyncRequest._();

  const factory SyncRequest({
    /// 上次同步时间戳
    required int since,

    /// 请求的实体类型 (note, category, all)
    String? entityType,
  }) = _SyncRequest;

  factory SyncRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncRequestFromJson(json);

  /// 转换为查询参数
  Map<String, String> toQueryParameters() {
    return {
      'since': since.toString(),
      if (entityType != null) 'entityType': entityType!,
    };
  }
}
