import 'package:isar_community/isar.dart';

import '../models/sync_log.dart';
import '../../util/logger_service.dart';

/// 同步日志仓库
/// 
/// 管理与每个远程设备的同步状态
class SyncLogRepository {
  static const String _tag = 'SyncLogRepository';

  final Isar _isar;

  SyncLogRepository(this._isar);

  /// 获取指定 IP 的同步日志
  Future<SyncLog?> getByIp(String ip) async {
    try {
      return await _isar.syncLogs.filter().remoteIpEqualTo(ip).findFirst();
    } catch (e) {
      log.e(_tag, 'Failed to get sync log for $ip: $e');
      return null;
    }
  }

  /// 获取上次同步时间戳
  Future<int> getLastSyncTimestamp(String ip) async {
    final syncLog = await getByIp(ip);
    return syncLog?.lastSyncTimestamp ?? 0;
  }

  /// 更新同步日志
  Future<void> updateSyncLog({
    required String ip,
    String? deviceId,
    String? deviceName,
    required int timestamp,
    required SyncStatus status,
    String? error,
  }) async {
    try {
      await _isar.writeTxn(() async {
        var syncLog = await _isar.syncLogs.filter().remoteIpEqualTo(ip).findFirst();

        if (syncLog == null) {
          syncLog = SyncLog()
            ..remoteIp = ip
            ..createdTime = DateTime.now();
        }

        syncLog
          ..remoteDeviceId = deviceId ?? syncLog.remoteDeviceId
          ..remoteDeviceName = deviceName ?? syncLog.remoteDeviceName
          ..lastSyncTimestamp = timestamp
          ..lastSyncTime = DateTime.now()
          ..syncStatus = status.value
          ..lastError = error;

        await _isar.syncLogs.put(syncLog);
      });

      log.d(_tag, 'Updated sync log for $ip: timestamp=$timestamp, status=$status');
    } catch (e) {
      log.e(_tag, 'Failed to update sync log for $ip: $e');
      rethrow;
    }
  }

  /// 标记同步开始
  Future<void> markSyncing(String ip) async {
    try {
      await _isar.writeTxn(() async {
        var syncLog = await _isar.syncLogs.filter().remoteIpEqualTo(ip).findFirst();

        if (syncLog == null) {
          syncLog = SyncLog()
            ..remoteIp = ip
            ..createdTime = DateTime.now();
        }

        syncLog.syncStatus = SyncStatus.syncing.value;
        await _isar.syncLogs.put(syncLog);
      });
    } catch (e) {
      log.e(_tag, 'Failed to mark syncing for $ip: $e');
    }
  }

  /// 标记同步成功
  Future<void> markSuccess(String ip, int timestamp) async {
    await updateSyncLog(
      ip: ip,
      timestamp: timestamp,
      status: SyncStatus.success,
    );
  }

  /// 标记同步失败
  Future<void> markFailed(String ip, String error) async {
    final syncLog = await getByIp(ip);
    await updateSyncLog(
      ip: ip,
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
      log.e(_tag, 'Failed to get all sync logs: $e');
      return [];
    }
  }

  /// 删除同步日志
  Future<void> delete(String ip) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.syncLogs.filter().remoteIpEqualTo(ip).deleteAll();
      });
    } catch (e) {
      log.e(_tag, 'Failed to delete sync log for $ip: $e');
    }
  }

  /// 清空所有同步日志
  Future<void> clear() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.syncLogs.clear();
      });
    } catch (e) {
      log.e(_tag, 'Failed to clear sync logs: $e');
    }
  }
}
