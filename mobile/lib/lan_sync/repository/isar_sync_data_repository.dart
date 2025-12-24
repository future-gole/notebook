import 'package:isar_community/isar.dart';

import '../../model/note.dart';
import '../../model/category.dart';
import '../model/sync_log.dart';
import '../model/device_info.dart';
import '../../util/logger_service.dart';
import 'i_sync_data_repository.dart';

/// 基于 Isar 的同步数据仓库实现
class IsarSyncDataRepository implements ISyncDataRepository {
  static const String _tag = 'IsarSyncDataRepository';

  final Isar _isar;

  IsarSyncDataRepository(this._isar);

  @override
  Future<List<Note>> getNoteChanges(int sinceTimestamp) async {
    return await _isar.notes
        .filter()
        .updatedAtGreaterThan(sinceTimestamp)
        .findAll();
  }

  @override
  Future<List<Category>> getCategoryChanges(int sinceTimestamp) async {
    return await _isar.categorys
        .filter()
        .updatedAtGreaterThan(sinceTimestamp)
        .findAll();
  }

  @override
  Future<Note?> getNoteByUuid(String uuid) async {
    return await _isar.notes.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<Category?> getCategoryByUuid(String uuid) async {
    return await _isar.categorys.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<Category?> getCategoryByName(String name) async {
    return await _isar.categorys.filter().nameEqualTo(name).findFirst();
  }

  @override
  Future<void> saveNote(Note note) async {
    await _isar.writeTxn(() async {
      // 1. 尝试通过 UUID 查找本地记录
      final localNote = await _isar.notes
          .filter()
          .uuidEqualTo(note.uuid)
          .findFirst();

      // 2. 如果存在，复用本地 ID，确保是更新操作而不是插入
      if (localNote != null) {
        note.id = localNote.id;
      }

      // 3. 保存 (Isar 会自动处理 Insert 或 Update)
      await _isar.notes.put(note);
    });
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _isar.writeTxn(() async {
      final localCategory = await _isar.categorys
          .filter()
          .uuidEqualTo(category.uuid)
          .findFirst();

      if (localCategory != null) {
        category.id = localCategory.id;
      }

      await _isar.categorys.put(category);
    });
  }

  @override
  Stream<void> watchNotes() {
    return _isar.notes.watchLazy();
  }

  @override
  Stream<void> watchCategories() {
    return _isar.categorys.watchLazy();
  }

  @override
  Future<int> getLastSyncTimestamp(String deviceId) async {
    final syncLog = await _isar.syncLogs
        .filter()
        .remoteDeviceIdEqualTo(deviceId)
        .findFirst();
    return syncLog?.lastSyncTimestamp ?? 0;
  }

  @override
  Future<void> updateSyncStatus(
    String deviceId,
    SyncStatus status, {
    int? timestamp,
    String? error,
    String? ip,
    String? deviceName,
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

        syncLog.syncStatus = status.value;
        syncLog.lastSyncTime = DateTime.now();

        if (ip != null) {
          syncLog.remoteIp = ip;
        }

        if (timestamp != null) {
          syncLog.lastSyncTimestamp = timestamp;
        }

        if (error != null) {
          syncLog.lastError = error;
        }

        if (deviceName != null) {
          syncLog.remoteDeviceName = deviceName;
        }

        await _isar.syncLogs.put(syncLog);
      });

      PMlog.d(_tag, '更新 $deviceId 状态: $status');
    } catch (e) {
      PMlog.e(_tag, '更新同步状态失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<DeviceInfo>> getKnownDevices() async {
    final logs = await _isar.syncLogs.where().findAll();
    return logs
        .map(
          (log) => DeviceInfo(
            deviceId: log.remoteDeviceId,
            deviceName: log.remoteDeviceName ?? 'Unknown',
            ipAddress: log.remoteIp,
            lastSeen: log.lastSyncTime,
          ),
        )
        .toList();
  }
}
