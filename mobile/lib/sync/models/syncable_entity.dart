/// 可同步实体的基础混入类
/// 
/// 所有需要参与 P2P 同步的 Isar Collection 都应该包含这些字段
/// 使用 UUID 作为全局唯一标识符，而不是 Isar 的自增 ID
mixin SyncableEntityMixin {
  /// 全局唯一标识符 (UUID v4)
  /// 用于跨设备识别同一条记录
  abstract String uuid;

  /// 最后修改时间戳（毫秒）
  /// 用于增量同步和冲突解决 (Last-Write-Wins)
  abstract int updatedAt;

  /// 软删除标记
  /// true 表示已删除，但保留记录用于同步
  abstract bool isDeleted;
}

/// 可同步实体的 JSON 序列化接口
abstract class SyncableEntityJson {
  /// 将实体转换为 JSON Map（用于网络传输）
  Map<String, dynamic> toSyncJson();

  /// 从 JSON Map 创建实体（用于接收远程数据）
  static SyncableEntityJson fromSyncJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromSyncJson');
  }
}
