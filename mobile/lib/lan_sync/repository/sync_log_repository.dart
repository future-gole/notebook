import 'package:isar_community/isar.dart';

import '../model/sync_log.dart';
import '../../util/logger_service.dart';

/// 同步日志仓库
///
/// 管理与每个远程设备的同步状态
class SyncLogRepository {
  static const String _tag = 'SyncLogRepository';

  final Isar _isar;

  SyncLogRepository(this._isar);

  /// 获取指定 DeviceID 的同步日志
  Future<SyncLog?> getByDeviceId(String deviceId) async {
    try {
      return await _isar.syncLogs
          .filter()
          .remoteDeviceIdEqualTo(deviceId)
          .findFirst();
    } catch (e) {
      PMlog.e(_tag, '获取 $deviceId 的同步日志失败: $e');
      return null;
    }
  }

  /// 获取上次同步时间戳
  Future<int> getLastSyncTimestamp(String deviceId) async {
    final syncLog = await getByDeviceId(deviceId);
    return syncLog?.lastSyncTimestamp ?? 0;
  }

  /// 更新同步日志
  Future<void> updateSyncLog({
    required String deviceId,
    String? ip,
    String? deviceName,
    required int timestamp,
    required SyncStatus status,
    String? error,
  }) async {
    try {
      await _isar.writeTxn(() async {
        var syncLog = await _isar.syncLogs
            .filter()
            .remoteDeviceIdEqualTo(deviceId)
            .findFirst();

        syncLog ??= SyncLog()
          ..remoteDeviceId = deviceId
          ..createdTime = DateTime.now();

        syncLog
          ..remoteIp = ip ?? syncLog.remoteIp
          ..remoteDeviceName = deviceName ?? syncLog.remoteDeviceName
          ..lastSyncTimestamp = timestamp
          ..lastSyncTime = DateTime.now()
          ..syncStatus = status.value
          ..lastError = error;

        await _isar.syncLogs.put(syncLog);
      });

      PMlog.d(_tag, '更新 $deviceId 的同步日志: 时间戳=$timestamp, 状态=$status');
    } catch (e) {
      PMlog.e(_tag, '更新 $deviceId 的同步日志失败: $e');
      rethrow;
    }
  }

  /// 标记同步开始
  Future<void> markSyncing(String deviceId, {String? ip}) async {
    try {
      await _isar.writeTxn(() async {
        var syncLog = await _isar.syncLogs
            .filter()
            .remoteDeviceIdEqualTo(deviceId)
            .findFirst();

        syncLog ??= SyncLog()
          ..remoteDeviceId = deviceId
          ..createdTime = DateTime.now();

        if (ip != null) {
          syncLog.remoteIp = ip;
        }

        syncLog.syncStatus = SyncStatus.syncing.value;
        await _isar.syncLogs.put(syncLog);
      });
    } catch (e) {
      PMlog.e(_tag, '标记 $deviceId 同步中失败: $e');
    }
  }

  /// 标记同步成功
  Future<void> markSuccess(String deviceId, int timestamp) async {
    await updateSyncLog(
      deviceId: deviceId,
      timestamp: timestamp,
      status: SyncStatus.success,
    );
  }

  /// 标记同步失败
  Future<void> markFailed(String deviceId, String error) async {
    final syncLog = await getByDeviceId(deviceId);
    await updateSyncLog(
      deviceId: deviceId,
      timestamp: syncLog?.lastSyncTimestamp ?? 0,
      status: SyncStatus.failed,
      error: error,
    );
  }

  /// 获取所有同步日志
  Future<List<SyncLog>> getAll() async {
    try {
      return await _isar.syncLogs.where().findAll();
    } catch (e) {
      PMlog.e(_tag, '获取所有同步日志失败: $e');
      return [];
    }
  }

  /// 删除同步日志
  Future<void> delete(String deviceId) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.syncLogs
            .filter()
            .remoteDeviceIdEqualTo(deviceId)
            .deleteAll();
      });
    } catch (e) {
      PMlog.e(_tag, '删除 $deviceId 的同步日志失败: $e');
    }
  }

  /// 清空所有同步日志
  Future<void> clear() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.syncLogs.clear();
      });
    } catch (e) {
      PMlog.e(_tag, '清除同步日志失败: $e');
    }
  }
}
