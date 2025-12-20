import 'package:isar_community/isar.dart';

part 'sync_log.g.dart';

/// 同步日志记录
///
/// 记录与每个远程设备的同步状态，用于增量同步时确定起始时间戳
@collection
class SyncLog {
  Id id = Isar.autoIncrement;

  /// 远程设备的 IP 地址
  @Index(unique: true)
  late String remoteIp;

  /// 远程设备的唯一标识符
  String? remoteDeviceId;

  /// 远程设备的名称
  String? remoteDeviceName;

  /// 上次同步时间戳（毫秒）
  /// 下次同步时，只拉取 updatedAt > lastSyncTimestamp 的记录
  int lastSyncTimestamp = 0;

  /// 上次同步的本地时间
  DateTime? lastSyncTime;

  /// 同步状态
  /// 0: 未同步, 1: 同步中, 2: 同步成功, 3: 同步失败
  int syncStatus = 0;

  /// 最后一次同步的错误信息（如果有）
  String? lastError;

  /// 创建时间
  DateTime? createdTime;
}

/// 同步状态枚举
enum SyncStatus {
  notSynced(0),
  syncing(1),
  success(2),
  failed(3);

  final int value;
  const SyncStatus(this.value);

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SyncStatus.notSynced,
    );
  }
}
