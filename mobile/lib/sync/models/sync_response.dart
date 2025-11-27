/// 同步响应数据
///
/// 服务端返回的同步数据格式
class SyncResponse {
  /// 服务端当前时间戳
  final int timestamp;

  /// 变更记录列表
  final List<Map<String, dynamic>> changes;

  /// 数据类型 (note, category, etc.)
  final String? entityType;

  const SyncResponse({
    required this.timestamp,
    required this.changes,
    this.entityType,
  });

  /// 从 JSON 创建
  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      timestamp: json['timestamp'] as int,
      changes: (json['changes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      entityType: json['entityType'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'changes': changes,
      if (entityType != null) 'entityType': entityType,
    };
  }

  /// 是否有变更
  bool get hasChanges => changes.isNotEmpty;

  /// 变更数量
  int get changeCount => changes.length;
}

/// 同步请求数据
class SyncRequest {
  /// 上次同步时间戳
  final int since;

  /// 请求的实体类型 (note, category, all)
  final String? entityType;

  const SyncRequest({required this.since, this.entityType});

  /// 转换为查询参数
  Map<String, String> toQueryParameters() {
    return {
      'since': since.toString(),
      if (entityType != null) 'entityType': entityType!,
    };
  }
}
