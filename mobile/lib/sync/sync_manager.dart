import 'dart:convert';
import 'dart:io';

import 'package:isar_community/isar.dart';

import 'models/device_info.dart';
import 'models/sync_log.dart';
import 'repository/sync_log_repository.dart';
import 'mappers/sync_data_mapper.dart';
import 'realtime/sync_websocket_client.dart';
import 'realtime/sync_websocket_server.dart';
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
/// 核心调度类，通过 WebSocket 协调设备间的数据同步
class SyncManager {
  static const String _tag = 'SyncManager';
  static const int defaultPort = SyncWebSocketServer.defaultPort;

  final Isar _isar;
  final SyncLogRepository _syncLogRepository;
  final DeviceInfo _localDevice;

  SyncManager({required Isar isar, required DeviceInfo localDevice})
    : _isar = isar,
      _localDevice = localDevice,
      _syncLogRepository = SyncLogRepository(isar);

  /// 通过现有的 WebSocket 客户端同步
  ///
  /// 主要流程:
  /// 1. 获取上次同步时间戳
  /// 2. 通过 WebSocket 请求变更数据
  /// 3. 应用变更（冲突解决：Last-Write-Wins）
  /// 4. 更新同步日志
  Future<SyncResult> synchronizeViaClient(
    SyncWebSocketClient client, {
    String? targetIp,
  }) async {
    final ip = targetIp ?? client.remoteDevice?.ipAddress ?? 'unknown';
    log.i(_tag, 'Starting sync with $ip via WebSocket');

    if (!client.isConnected) {
      log.w(_tag, 'WebSocket client not connected');
      return const SyncResult(success: false, error: 'Not connected');
    }

    try {
      // 1. 获取上次同步时间戳
      final lastSyncTimestamp = await _syncLogRepository.getLastSyncTimestamp(
        ip,
      );
      log.d(_tag, 'Last sync timestamp: $lastSyncTimestamp');

      // 标记同步开始
      await _syncLogRepository.markSyncing(ip);

      // 2. 通过 WebSocket 请求同步数据
      final response = await client.requestSyncAndWait(
        since: lastSyncTimestamp,
      );

      if (response == null) {
        await _syncLogRepository.markFailed(ip, 'Failed to fetch changes');
        return const SyncResult(
          success: false,
          error: 'Failed to fetch changes',
        );
      }

      // 3. 应用变更
      final result = await _applyChanges(response.changes);

      // 4. 更新同步日志
      final remoteDevice = client.remoteDevice;
      await _syncLogRepository.updateSyncLog(
        ip: ip,
        deviceId: remoteDevice?.deviceId ?? 'unknown',
        deviceName: remoteDevice?.deviceName ?? ip,
        timestamp: response.timestamp,
        status: SyncStatus.success,
      );

      log.i(_tag, 'Sync completed: $result');
      return result;
    } catch (e) {
      log.e(_tag, 'Sync failed: $e');
      await _syncLogRepository.markFailed(ip, e.toString());
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 与指定设备同步（创建临时 WebSocket 连接）
  ///
  /// 主要流程:
  /// 1. 建立 WebSocket 连接
  /// 2. 获取上次同步时间戳
  /// 3. 请求变更数据
  /// 4. 应用变更（冲突解决：Last-Write-Wins）
  /// 5. 更新同步日志
  /// 6. 关闭连接
  Future<SyncResult> synchronize(
    String targetIp, {
    int port = SyncWebSocketServer.defaultPort,
  }) async {
    log.i(_tag, 'Starting sync with $targetIp:$port');

    // 创建临时客户端
    final client = SyncWebSocketClient(localDevice: _localDevice);

    // 设置同步请求处理器（当服务端向我们请求数据时）
    client.onSyncRequestReceived = (since) async {
      log.i(_tag, '📤 Server requested sync data since $since');
      return await getLocalChangesSince(since);
    };

    try {
      // 1. 建立连接
      final connected = await client.connect(targetIp, port: port);
      if (!connected) {
        log.w(_tag, 'Failed to connect to $targetIp');
        await _syncLogRepository.markFailed(targetIp, 'Connection failed');
        return const SyncResult(success: false, error: 'Connection failed');
      }

      // 等待握手完成
      await Future.delayed(const Duration(milliseconds: 200));

      // 2. 执行同步
      final result = await synchronizeViaClient(client, targetIp: targetIp);

      return result;
    } finally {
      // 关闭临时连接
      client.dispose();
    }
  }

  /// 应用变更数据（公共方法，供外部调用）
  Future<SyncResult> applyChanges(List<Map<String, dynamic>> changes) async {
    return _applyChanges(changes);
  }

  /// 应用变更数据（内部实现）
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
        log.d(
          _tag,
          'Skipping deleted note that does not exist locally: $remoteUuid',
        );
        return _ChangeResult.ignored;
      }

      final note = SyncDataMapper.noteFromJson(change);
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      log.d(_tag, 'Added new note: $remoteUuid');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localNote.updatedAt) {
      // 远程版本更新，覆盖本地
      final note = SyncDataMapper.noteFromJson(change);
      note.id = localNote.id; // 保持本地 ID
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      log.d(
        _tag,
        'Updated note: $remoteUuid (remote: $remoteUpdatedAt > local: ${localNote.updatedAt})',
      );
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    log.d(_tag, 'Ignored note: $remoteUuid (local version is newer or equal)');
    return _ChangeResult.ignored;
  }

  /// 应用分类变更
  Future<_ChangeResult> _applyCategoryChange(
    Map<String, dynamic> change,
  ) async {
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
        log.d(
          _tag,
          'Skipping deleted category that does not exist locally: $remoteUuid',
        );
        return _ChangeResult.ignored;
      }

      final category = SyncDataMapper.categoryFromJson(change);
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      log.d(_tag, 'Added new category: $remoteName ($remoteUuid)');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localCategory.updatedAt) {
      // 远程版本更新，覆盖本地
      final category = SyncDataMapper.categoryFromJson(change);
      category.id = localCategory.id; // 保持本地 ID
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      log.d(
        _tag,
        'Updated category: $remoteName (remote: $remoteUpdatedAt > local: ${localCategory.updatedAt})',
      );
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    log.d(
      _tag,
      'Ignored category: $remoteName (local version is newer or equal)',
    );
    return _ChangeResult.ignored;
  }

  /// 扫描局域网中的设备
  ///
  /// 通过尝试 WebSocket 连接来发现设备
  /// [subnet] 子网前三段，如 "192.168.1"
  Future<List<DeviceInfo>> scanNetwork(
    String subnet, {
    Duration timeout = const Duration(seconds: 2),
    int port = SyncWebSocketServer.defaultPort,
  }) async {
    log.i(_tag, '=== Network Scan Started ===');
    log.i(_tag, 'Subnet: $subnet.*');
    log.i(_tag, 'Port: $port');
    log.i(_tag, 'Timeout: ${timeout.inMilliseconds}ms');

    final devices = <DeviceInfo>[];
    final futures = <Future<DeviceInfo?>>[];

    // 扫描 1-254
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_scanHost(ip, port, timeout));
    }

    // 并发执行扫描
    log.i(_tag, 'Scanning 254 hosts concurrently...');
    final results = await Future.wait(futures);

    for (final device in results) {
      if (device != null) {
        devices.add(device);
        log.i(
          _tag,
          '✅ Found device at ${device.ipAddress}: ${device.deviceName}',
        );
      }
    }

    log.i(_tag, '=== Network Scan Completed ===');
    log.i(_tag, 'Found: ${devices.length} devices');
    log.i(_tag, '==============================');

    return devices;
  }

  /// 扫描单个主机
  Future<DeviceInfo?> _scanHost(String ip, int port, Duration timeout) async {
    try {
      final socket = await WebSocket.connect(
        'ws://$ip:$port',
        headers: {'X-Device-Id': _localDevice.deviceId},
      ).timeout(timeout);

      // 发送发现请求（不触发设备注册）
      final msg = {
        'type': SyncMessageType.discover,
        'data': _localDevice.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      socket.add(jsonEncode(msg));

      // 等待接收 hello 或 discover_response 消息
      DeviceInfo? deviceInfo;

      await for (final data in socket.timeout(timeout)) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final type = json['type'] as String?;
          if ((type == SyncMessageType.hello ||
                  type == SyncMessageType.discoverResponse) &&
              json['data'] != null) {
            deviceInfo = DeviceInfo.fromJson(
              json['data'] as Map<String, dynamic>,
            );
            deviceInfo = DeviceInfo(
              deviceId: deviceInfo.deviceId,
              deviceName: deviceInfo.deviceName,
              ipAddress: ip,
              port: port,
              platform: deviceInfo.platform,
              lastSeen: DateTime.now(),
            );
            break;
          }
        } catch (_) {}
      }

      await socket.close();
      return deviceInfo;
    } catch (_) {
      // 连接失败或超时，该 IP 没有运行同步服务
      return null;
    }
  }

  /// 与所有已知设备同步
  Future<Map<String, SyncResult>> synchronizeAll({
    List<String>? targetIps,
  }) async {
    final ips = targetIps ?? await _getKnownDeviceIps();
    final results = <String, SyncResult>{};

    for (final ip in ips) {
      results[ip] = await synchronize(ip);
    }

    return results;
  }

  /// 获取已知设备 IP 列表
  Future<List<String>> _getKnownDeviceIps() async {
    final logs = await _isar.syncLogs.where().findAll();
    return logs.map((log) => log.remoteIp).toList();
  }

  /// 关闭管理器
  void dispose() {
    // 无需关闭持久资源
  }

  /// 获取自指定时间戳以来的本地变更
  ///
  /// 用于响应来自服务端的同步请求
  Future<List<Map<String, dynamic>>> getLocalChangesSince(int since) async {
    final notes = await _isar.notes
        .filter()
        .updatedAtGreaterThan(since)
        .findAll();

    final categories = await _isar.categorys
        .filter()
        .updatedAtGreaterThan(since)
        .findAll();

    return SyncDataMapper.combineChanges(notes: notes, categories: categories);
  }
}

/// 变更应用结果
enum _ChangeResult { added, updated, ignored }
