import 'repository/i_sync_data_repository.dart';
import 'model/sync_log.dart';

import 'model/device_info.dart';
import 'realtime/sync_websocket_client.dart';
import 'realtime/sync_websocket_server.dart';
import 'sync_manager.dart';
import '../util/logger_service.dart';

/// 局域网同步引擎
///
/// 负责协调同步流程，包括从远程拉取数据和处理本地数据变更。
class LanSyncEngine {
  static const String _tag = 'LanSyncEngine';

  final DeviceInfo _localDevice;
  final SyncManager _syncManager;
  final ISyncDataRepository _repository;

  LanSyncEngine({
    required ISyncDataRepository repository,
    required DeviceInfo localDevice,
  }) : _localDevice = localDevice,
       _syncManager = SyncManager(
         repository: repository,
         localDevice: localDevice,
       ),
       _repository = repository;

  /// 获取与指定设备的最后同步时间戳
  Future<int> getLastSync(String deviceId) =>
      _repository.getLastSyncTimestamp(deviceId);

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

    final ip = client.remoteDevice?.ipAddress ?? 'unknown';

    final lastSync = await _repository.getLastSyncTimestamp(peerDeviceId);
    PMlog.i(_tag, '📥 从 $peerDeviceId ($ip) 拉取数据，起始时间戳: $lastSync');

    final response = await client.requestSyncAndWait(since: lastSync);
    if (response == null) {
      return const SyncResult(success: false, error: '获取更改失败');
    }

    final result = await _syncManager.applyChanges(
      response.changes,
      wsClient: client,
    );

    await _repository.updateSyncStatus(
      peerDeviceId,
      SyncStatus.success,
      timestamp: response.timestamp,
      ip: ip,
      deviceName: client.remoteDevice?.deviceName,
    );

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

    await _repository.updateSyncStatus(
      peerDeviceId,
      SyncStatus.success,
      timestamp: timestamp,
      ip: clientIp,
    );

    return result;
  }

  DeviceInfo get localDevice => _localDevice;
}
