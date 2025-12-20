import 'package:isar_community/isar.dart';

import 'model/device_info.dart';
import 'realtime/sync_websocket_client.dart';
import 'realtime/sync_websocket_server.dart';
import 'sync_manager.dart';
import '../util/logger_service.dart';

import 'storage/lan_sync_log_store.dart';

/// 局域网同步引擎
/// 
/// 负责协调同步流程，包括从远程拉取数据和处理本地数据变更。
class LanSyncEngine {
  static const String _tag = 'LanSyncEngine';

  final DeviceInfo _localDevice;
  final SyncManager _syncManager;
  final LanSyncLogStore _logStore;

  LanSyncEngine({
    required Isar isar,
    required DeviceInfo localDevice,
    LanSyncLogStore? logStore,
  }) : _localDevice = localDevice,
       _syncManager = SyncManager(isar: isar, localDevice: localDevice),
       _logStore = logStore ?? LanSyncLogStore();

  /// 获取与指定设备的最后同步时间戳
  Future<int> getLastSync(String peerDeviceId) =>
      _logStore.getLastSync(peerDeviceId);

  /// 处理远程同步请求，返回自指定时间戳以来的本地变更
  Future<List<Map<String, dynamic>>> handleRemoteSyncRequest(int since) async {
    return _syncManager.getLocalChangesSince(since);
  }

  /// 从远程客户端拉取数据并应用到本地
  Future<SyncResult> pullFromClient(
    String peerDeviceId,
    SyncWebSocketClient client,
  ) async {
    if (!client.isConnected) {
      return const SyncResult(success: false, error: '未连接');
    }

    final lastSync = await _logStore.getLastSync(peerDeviceId);
    PMlog.i(_tag, '📥 从 $peerDeviceId 拉取数据，起始时间戳: $lastSync');

    final response = await client.requestSyncAndWait(since: lastSync);
    if (response == null) {
      return const SyncResult(success: false, error: '获取更改失败');
    }

    final result = await _syncManager.applyChanges(
      response.changes,
      wsClient: client,
    );

    await _logStore.setLastSync(peerDeviceId, response.timestamp);

    return result;
  }

  /// 应用来自入站连接的同步响应
  Future<SyncResult> applyInboundSyncResponse({
    required String peerDeviceId,
    required List<Map<String, dynamic>> changes,
    required int timestamp,
    SyncWebSocketServer? wsServer,
    String? clientIp,
  }) async {
    final result = await _syncManager.applyChanges(
      changes,
      wsServer: wsServer,
      clientIp: clientIp,
    );
    await _logStore.setLastSync(peerDeviceId, timestamp);
    return result;
  }

  DeviceInfo get localDevice => _localDevice;
}
