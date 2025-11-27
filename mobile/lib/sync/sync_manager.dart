import 'package:isar_community/isar.dart';

import 'client/sync_client.dart';
import 'models/device_info.dart';
import 'models/sync_log.dart';
import 'repository/sync_log_repository.dart';
import '../model/note.dart';
import '../model/category.dart';
import '../util/logger_service.dart';

/// 同步结果
class SyncResult {
  final bool success;
  final int notesAdded;
  final int notesUpdated;
  final int categoriesAdded;
  final int categoriesUpdated;
  final String? error;

  const SyncResult({
    required this.success,
    this.notesAdded = 0,
    this.notesUpdated = 0,
    this.categoriesAdded = 0,
    this.categoriesUpdated = 0,
    this.error,
  });

  int get totalChanges =>
      notesAdded + notesUpdated + categoriesAdded + categoriesUpdated;

  @override
  String toString() {
    if (!success) return 'SyncResult(failed: $error)';
    return 'SyncResult(success: notes +$notesAdded ~$notesUpdated, categories +$categoriesAdded ~$categoriesUpdated)';
  }
}

/// 同步管理器
/// 
/// 核心调度类，协调 Client、Server 和 Isar 之间的数据同步
class SyncManager {
  static const String _tag = 'SyncManager';

  final Isar _isar;
  final SyncClient _client;
  final SyncLogRepository _syncLogRepository;

  SyncManager({
    required Isar isar,
    SyncClient? client,
  })  : _isar = isar,
        _client = client ?? SyncClient(),
        _syncLogRepository = SyncLogRepository(isar);

  /// 与指定设备同步
  /// 
  /// 主要流程:
  /// 1. 握手 & 获取上次同步时间戳
  /// 2. 拉取远程变更数据
  /// 3. 应用变更（冲突解决：Last-Write-Wins）
  /// 4. 更新同步日志
  Future<SyncResult> synchronize(
    String targetIp, {
    int port = SyncClient.defaultPort,
  }) async {
    log.i(_tag, 'Starting sync with $targetIp:$port');

    try {
      // 1. 握手 - 获取远程设备信息
      final deviceInfo = await _client.getDeviceInfo(targetIp, port: port);
      if (deviceInfo == null) {
        log.w(_tag, 'Failed to connect to $targetIp');
        await _syncLogRepository.markFailed(targetIp, 'Connection failed');
        return const SyncResult(success: false, error: 'Connection failed');
      }

      // 2. 获取上次同步时间戳
      final lastSyncTimestamp = await _syncLogRepository.getLastSyncTimestamp(targetIp);
      log.d(_tag, 'Last sync timestamp: $lastSyncTimestamp');

      // 标记同步开始
      await _syncLogRepository.markSyncing(targetIp);

      // 3. 拉取变更数据
      final response = await _client.fetchAllChanges(
        targetIp,
        since: lastSyncTimestamp,
        port: port,
      );

      if (response == null) {
        await _syncLogRepository.markFailed(targetIp, 'Failed to fetch changes');
        return const SyncResult(success: false, error: 'Failed to fetch changes');
      }

      // 4. 应用变更
      final result = await _applyChanges(response.changes);

      // 5. 更新同步日志
      await _syncLogRepository.updateSyncLog(
        ip: targetIp,
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        timestamp: response.timestamp,
        status: SyncStatus.success,
      );

      log.i(_tag, 'Sync completed: $result');
      return result;
    } catch (e) {
      log.e(_tag, 'Sync failed: $e');
      await _syncLogRepository.markFailed(targetIp, e.toString());
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 应用变更数据
  Future<SyncResult> _applyChanges(List<Map<String, dynamic>> changes) async {
    if (changes.isEmpty) {
      return const SyncResult(success: true);
    }

    int notesAdded = 0;
    int notesUpdated = 0;
    int categoriesAdded = 0;
    int categoriesUpdated = 0;

    try {
      await _isar.writeTxn(() async {
        for (final change in changes) {
          final entityType = change['_entityType'] as String?;

          if (entityType == 'note') {
            final result = await _applyNoteChange(change);
            if (result == _ChangeResult.added) {
              notesAdded++;
            } else if (result == _ChangeResult.updated) {
              notesUpdated++;
            }
          } else if (entityType == 'category') {
            final result = await _applyCategoryChange(change);
            if (result == _ChangeResult.added) {
              categoriesAdded++;
            } else if (result == _ChangeResult.updated) {
              categoriesUpdated++;
            }
          }
        }
      });

      return SyncResult(
        success: true,
        notesAdded: notesAdded,
        notesUpdated: notesUpdated,
        categoriesAdded: categoriesAdded,
        categoriesUpdated: categoriesUpdated,
      );
    } catch (e) {
      log.e(_tag, 'Failed to apply changes: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 应用笔记变更
  /// 
  /// 冲突解决逻辑 (Last-Write-Wins):
  /// - 使用 UUID 作为跨设备的唯一标识
  /// - 本地不存在该 UUID -> 插入新记录
  /// - 远程 updatedAt > 本地 updatedAt -> 覆盖
  /// - 否则 -> 忽略（本地版本更新）
  Future<_ChangeResult> _applyNoteChange(Map<String, dynamic> change) async {
    final remoteUuid = change['uuid'] as String?;
    if (remoteUuid == null || remoteUuid.isEmpty) {
      log.w(_tag, 'Skipping note without UUID');
      return _ChangeResult.ignored;
    }

    final remoteUpdatedAt = change['updatedAt'] as int? ?? 0;
    final remoteIsDeleted = change['isDeleted'] as bool? ?? false;
    
    // 使用 UUID 查询本地记录
    final localNote = await _isar.notes
        .filter()
        .uuidEqualTo(remoteUuid)
        .findFirst();

    if (localNote == null) {
      // 本地不存在，插入新记录（如果远程未删除）
      if (remoteIsDeleted) {
        log.d(_tag, 'Skipping deleted note that does not exist locally: $remoteUuid');
        return _ChangeResult.ignored;
      }
      
      final note = _noteFromJson(change);
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      log.d(_tag, 'Added new note: $remoteUuid');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localNote.updatedAt) {
      // 远程版本更新，覆盖本地
      final note = _noteFromJson(change);
      note.id = localNote.id; // 保持本地 ID
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      log.d(_tag, 'Updated note: $remoteUuid (remote: $remoteUpdatedAt > local: ${localNote.updatedAt})');
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    log.d(_tag, 'Ignored note: $remoteUuid (local version is newer or equal)');
    return _ChangeResult.ignored;
  }

  /// 应用分类变更
  Future<_ChangeResult> _applyCategoryChange(Map<String, dynamic> change) async {
    final remoteUuid = change['uuid'] as String?;
    if (remoteUuid == null || remoteUuid.isEmpty) {
      log.w(_tag, 'Skipping category without UUID');
      return _ChangeResult.ignored;
    }

    final remoteUpdatedAt = change['updatedAt'] as int? ?? 0;
    final remoteIsDeleted = change['isDeleted'] as bool? ?? false;
    final remoteName = change['name'] as String?;

    // 使用 UUID 查询本地记录
    var localCategory = await _isar.categorys
        .filter()
        .uuidEqualTo(remoteUuid)
        .findFirst();
    
    // 如果通过 UUID 找不到，尝试通过 name 查找（处理旧数据）
    if (localCategory == null && remoteName != null) {
      localCategory = await _isar.categorys
          .filter()
          .nameEqualTo(remoteName)
          .findFirst();
    }

    if (localCategory == null) {
      // 本地不存在，插入新记录（如果远程未删除）
      if (remoteIsDeleted) {
        log.d(_tag, 'Skipping deleted category that does not exist locally: $remoteUuid');
        return _ChangeResult.ignored;
      }
      
      final category = _categoryFromJson(change);
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      log.d(_tag, 'Added new category: $remoteName ($remoteUuid)');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localCategory.updatedAt) {
      // 远程版本更新，覆盖本地
      final category = _categoryFromJson(change);
      category.id = localCategory.id; // 保持本地 ID
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      log.d(_tag, 'Updated category: $remoteName (remote: $remoteUpdatedAt > local: ${localCategory.updatedAt})');
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    log.d(_tag, 'Ignored category: $remoteName (local version is newer or equal)');
    return _ChangeResult.ignored;
  }

  /// 从 JSON 创建 Note
  Note _noteFromJson(Map<String, dynamic> json) {
    final note = Note()
      ..uuid = json['uuid'] as String?
      ..title = json['title'] as String?
      ..content = json['content'] as String?
      ..url = json['url'] as String?
      ..categoryId = json['categoryId'] as int? ?? 1
      ..tag = json['tag'] as String?
      ..updatedAt = json['updatedAt'] as int? ?? 0
      ..isDeleted = json['isDeleted'] as bool? ?? false;

    if (json['time'] != null) {
      note.time = DateTime.fromMillisecondsSinceEpoch(json['time'] as int);
    }

    return note;
  }

  /// 从 JSON 创建 Category
  Category _categoryFromJson(Map<String, dynamic> json) {
    final category = Category()
      ..uuid = json['uuid'] as String?
      ..name = json['name'] as String
      ..description = json['description'] as String?
      ..updatedAt = json['updatedAt'] as int? ?? 0
      ..isDeleted = json['isDeleted'] as bool? ?? false;

    if (json['createdTime'] != null) {
      category.createdTime = DateTime.fromMillisecondsSinceEpoch(json['createdTime'] as int);
    }

    return category;
  }

  /// 扫描并发现局域网设备
  Future<List<DeviceInfo>> discoverDevices(String subnet) async {
    return _client.scanNetwork(subnet);
  }

  /// 与所有已知设备同步
  Future<Map<String, SyncResult>> synchronizeAll() async {
    final syncLogs = await _syncLogRepository.getAll();
    final results = <String, SyncResult>{};

    for (final syncLog in syncLogs) {
      final result = await synchronize(syncLog.remoteIp);
      results[syncLog.remoteIp] = result;
    }

    return results;
  }

  /// 关闭管理器
  void dispose() {
    _client.close();
  }
}

/// 变更应用结果
enum _ChangeResult {
  added,
  updated,
  ignored,
}
