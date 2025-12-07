import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:isar_community/isar.dart';

import 'models/device_info.dart';
import 'models/sync_log.dart';
import 'repository/sync_log_repository.dart';
import 'mappers/sync_data_mapper.dart';
import 'realtime/sync_websocket_client.dart';
import 'realtime/sync_websocket_server.dart';
import 'network_utils.dart';
import '../model/note.dart';
import '../model/category.dart';
import '../util/logger_service.dart';
import '../util/url_helper.dart';
import '../util/image_storage_helper.dart';

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
    PMlog.i(_tag, '通过 WebSocket 与 $ip 开始同步');

    if (!client.isConnected) {
      PMlog.w(_tag, 'WebSocket 客户端未连接');
      return const SyncResult(success: false, error: '未连接');
    }

    try {
      // 1. 获取上次同步时间戳
      final lastSyncTimestamp = await _syncLogRepository.getLastSyncTimestamp(
        ip,
      );
      PMlog.d(_tag, '上次同步时间戳: $lastSyncTimestamp');

      // 标记同步开始
      await _syncLogRepository.markSyncing(ip);

      // 2. 通过 WebSocket 请求同步数据
      final response = await client.requestSyncAndWait(
        since: lastSyncTimestamp,
      );

      if (response == null) {
        await _syncLogRepository.markFailed(ip, '获取更改失败');
        return const SyncResult(success: false, error: '获取更改失败');
      }

      // 3. 应用变更（传递 WebSocket 客户端以便请求图片）
      final result = await _applyChanges(response.changes, wsClient: client);

      // 4. 更新同步日志
      final remoteDevice = client.remoteDevice;
      await _syncLogRepository.updateSyncLog(
        ip: ip,
        deviceId: remoteDevice?.deviceId ?? 'unknown',
        deviceName: remoteDevice?.deviceName ?? ip,
        timestamp: response.timestamp,
        status: SyncStatus.success,
      );

      PMlog.i(_tag, '同步完成: $result');
      return result;
    } catch (e) {
      PMlog.e(_tag, '同步失败: $e');
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
    PMlog.i(_tag, '与 $targetIp:$port 开始同步');

    // 创建临时客户端
    final client = SyncWebSocketClient(localDevice: _localDevice);

    // 设置同步请求处理器（当服务端向我们请求数据时）
    client.onSyncRequestReceived = (since) async {
      PMlog.i(_tag, '📤 服务器请求自 $since 以来的同步数据');
      return await getLocalChangesSince(since);
    };

    try {
      // 1. 建立连接
      final connected = await client.connect(targetIp, port: port);
      if (!connected) {
        PMlog.w(_tag, '连接到 $targetIp 失败');
        await _syncLogRepository.markFailed(targetIp, '连接失败');
        return const SyncResult(success: false, error: '连接失败');
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
  Future<SyncResult> applyChanges(
    List<Map<String, dynamic>> changes, {
    SyncWebSocketClient? wsClient,
    SyncWebSocketServer? wsServer,
    String? clientIp,
  }) async {
    return _applyChanges(
      changes,
      wsClient: wsClient,
      wsServer: wsServer,
      clientIp: clientIp,
    );
  }

  /// 应用变更数据（内部实现）
  Future<SyncResult> _applyChanges(
    List<Map<String, dynamic>> changes, {
    SyncWebSocketClient? wsClient,
    SyncWebSocketServer? wsServer,
    String? clientIp,
  }) async {
    if (changes.isEmpty) {
      return const SyncResult(success: true);
    }

    int notesAdded = 0;
    int notesUpdated = 0;
    int categoriesAdded = 0;
    int categoriesUpdated = 0;

    try {
      // 首先收集所有需要同步的图片路径
      final imagePaths = <String>[];

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

            // 检查是否有本地图片路径
            final url = change['url'] as String?;
            if (url != null && UrlHelper.isLocalImagePath(url)) {
              // 检查本地是否已存在该图片
              final file = ImageStorageHelper().getFileByRelativePath(url);
              if (!await file.exists()) {
                imagePaths.add(url);
              }
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

      // 如果有需要同步的图片，请求从远程设备获取
      if (imagePaths.isNotEmpty) {
        PMlog.i(_tag, '📷 从远程请求 ${imagePaths.length} 张图片');
        for (final path in imagePaths) {
          if (wsClient != null) {
            // 作为客户端请求
            wsClient.requestImage(path);
          } else if (wsServer != null && clientIp != null) {
            // 作为服务端请求
            wsServer.requestImage(clientIp, path);
          }
        }
      }

      return SyncResult(
        success: true,
        notesAdded: notesAdded,
        notesUpdated: notesUpdated,
        categoriesAdded: categoriesAdded,
        categoriesUpdated: categoriesUpdated,
      );
    } catch (e) {
      PMlog.e(_tag, '应用更改失败: $e');
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
      PMlog.w(_tag, '跳过没有 UUID 的笔记');
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
        PMlog.d(_tag, '跳过本地不存在的已删除笔记: $remoteUuid');
        return _ChangeResult.ignored;
      }

      final note = SyncDataMapper.noteFromJson(change);
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      PMlog.d(_tag, '添加新笔记: $remoteUuid');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localNote.updatedAt) {
      // 远程版本更新，覆盖本地
      final note = SyncDataMapper.noteFromJson(change);
      note.id = localNote.id; // 保持本地 ID
      note.uuid = remoteUuid;
      await _isar.notes.put(note);
      PMlog.d(
        _tag,
        '更新笔记: $remoteUuid (远程: $remoteUpdatedAt > 本地: ${localNote.updatedAt})',
      );
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    PMlog.d(_tag, '忽略笔记: $remoteUuid (本地版本更新或相同)');
    return _ChangeResult.ignored;
  }

  /// 应用分类变更
  Future<_ChangeResult> _applyCategoryChange(
    Map<String, dynamic> change,
  ) async {
    final remoteUuid = change['uuid'] as String?;
    if (remoteUuid == null || remoteUuid.isEmpty) {
      PMlog.w(_tag, '跳过没有 UUID 的分类');
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
        PMlog.d(_tag, '跳过本地不存在的已删除分类: $remoteUuid');
        return _ChangeResult.ignored;
      }

      final category = SyncDataMapper.categoryFromJson(change);
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      PMlog.d(_tag, '添加新分类: $remoteName ($remoteUuid)');
      return _ChangeResult.added;
    }

    // 比较更新时间 (Last-Write-Wins)
    if (remoteUpdatedAt > localCategory.updatedAt) {
      // 远程版本更新，覆盖本地
      final category = SyncDataMapper.categoryFromJson(change);
      category.id = localCategory.id; // 保持本地 ID
      category.uuid = remoteUuid;
      await _isar.categorys.put(category);
      PMlog.d(
        _tag,
        '更新分类: $remoteName (远程: $remoteUpdatedAt > 本地: ${localCategory.updatedAt})',
      );
      return _ChangeResult.updated;
    }

    // 本地版本更新或相同，忽略
    PMlog.d(_tag, '忽略分类: $remoteName (本地版本更新或相同)');
    return _ChangeResult.ignored;
  }

  /// 扫描局域网中的设备
  ///
  /// 通过尝试 WebSocket 连接来发现设备
  /// [subnet] 子网前三段，如 "192.168.1"
  Future<List<DeviceInfo>> scanNetwork(
    String localIp, {
    String subnetMask = LanNetworkHelper.defaultSubnetMask,
    Duration timeout = const Duration(seconds: 3),
    int port = SyncWebSocketServer.defaultPort,
  }) async {
    PMlog.i(_tag, '=== 网络扫描开始 ===');
    PMlog.i(_tag, '本地 IP: $localIp');
    PMlog.i(_tag, '掩码: $subnetMask');
    PMlog.i(_tag, '端口: $port');
    PMlog.i(_tag, '超时: ${timeout.inMilliseconds}ms');

    final devices = <DeviceInfo>[];
    final futures = <Future<DeviceInfo?>>[];

    final hosts = LanNetworkHelper.hostsInSubnet(
      localIp,
      subnetMask: subnetMask,
    );
    PMlog.i(_tag, '扫描子网中的 ${hosts.length} 个主机...');

    for (final ip in hosts) {
      if (ip == localIp) continue; // skip self
      futures.add(_scanHost(ip, port, timeout));
    }

    // 并发执行扫描
    final results = await Future.wait(futures);

    for (final device in results) {
      if (device != null) {
        devices.add(device);
        PMlog.i(
          _tag,
          '✅ Found device at ${device.ipAddress}: ${device.deviceName}',
        );
      }
    }

    PMlog.i(_tag, '=== 网络扫描完成 ===');
    PMlog.i(_tag, '发现: ${devices.length} 个设备');
    PMlog.i(_tag, '==============================');

    return devices;
  }

  /// 扫描单个主机
  Future<DeviceInfo?> _scanHost(String ip, int port, Duration timeout) async {
    try {
      // PMlog.d(_tag, 'Scanning $ip:$port...');
      final socket = await WebSocket.connect(
        'ws://$ip:$port',
        headers: {'X-Device-Id': _localDevice.deviceId},
      ).timeout(timeout);

      PMlog.d(_tag, 'Connected to $ip:$port, sending discover message');

      // 发送发现请求（不触发设备注册）
      final msg = {
        'type': SyncMessageType.discover,
        'data': _localDevice.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      socket.add(jsonEncode(msg));

      // 等待接收 hello 或 discover_response 消息
      DeviceInfo? deviceInfo;

      // 使用Future.any来避免await for可能的阻塞问题
      final messagesFuture = socket.first;
      final timeoutFuture = Future.delayed(timeout);

      await Future.any([
        messagesFuture.then((data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final type = json['type'] as String?;
            PMlog.d(_tag, 'Received message from $ip: type=$type');

            if ((type == SyncMessageType.hello ||
                    type == SyncMessageType.discoverResponse) &&
                json['data'] != null) {
              final info = DeviceInfo.fromJson(
                json['data'] as Map<String, dynamic>,
              );
              deviceInfo = DeviceInfo(
                deviceId: info.deviceId,
                deviceName: info.deviceName,
                ipAddress: ip,
                port: port,
                platform: info.platform,
                lastSeen: DateTime.now(),
              );
              PMlog.d(
                _tag,
                'Got device info from $ip: ${deviceInfo!.deviceName}',
              );
            }
          } catch (e) {
            PMlog.w(_tag, 'Error parsing message from $ip: $e');
          }
        }),
        timeoutFuture,
      ]);

      await socket.close();
      return deviceInfo;
    } catch (e) {
      // 连接失败或超时，该 IP 没有运行同步服务
      if (e is TimeoutException) {
        // PMlog.d(_tag, '连接到 $ip:$port 超时');
      } else {
        PMlog.d(_tag, '连接到 $ip:$port 失败: ${e.toString()}');
      }
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
