import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'models/device_info.dart';
import 'models/sync_log.dart';
import 'sync_manager.dart';
import 'repository/sync_log_repository.dart';
import 'realtime/sync_websocket_server.dart';
import 'realtime/sync_websocket_client.dart';
import '../model/note.dart';
import '../model/category.dart';
import '../providers/infrastructure_providers.dart';
import '../util/logger_service.dart';
import '../util/app_config.dart';

/// 同步服务状态
class SyncServiceState {
  final bool isServerRunning;
  final bool isSyncing;
  final DeviceInfo? localDevice;
  final List<DeviceInfo> discoveredDevices;
  final String? lastError;
  final DateTime? lastSyncTime;

  const SyncServiceState({
    this.isServerRunning = false,
    this.isSyncing = false,
    this.localDevice,
    this.discoveredDevices = const [],
    this.lastError,
    this.lastSyncTime,
  });

  SyncServiceState copyWith({
    bool? isServerRunning,
    bool? isSyncing,
    DeviceInfo? localDevice,
    List<DeviceInfo>? discoveredDevices,
    String? lastError,
    DateTime? lastSyncTime,
  }) {
    return SyncServiceState(
      isServerRunning: isServerRunning ?? this.isServerRunning,
      isSyncing: isSyncing ?? this.isSyncing,
      localDevice: localDevice ?? this.localDevice,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      lastError: lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// 同步服务 Notifier
class SyncServiceNotifier extends StateNotifier<SyncServiceState> {
  static const String _tag = 'SyncService';
  static const int defaultPort = SyncWebSocketServer.defaultPort;

  final Isar _isar;
  SyncManager? _manager;
  DeviceInfo? _localDevice;

  // WebSocket 服务器（唯一的服务端）
  SyncWebSocketServer? _wsServer;
  final Map<String, SyncWebSocketClient> _wsClients = {};

  // 数据库变化监听
  StreamSubscription? _notesWatcher;
  StreamSubscription? _categoriesWatcher;

  // 防抖：避免频繁同步
  Timer? _syncDebounceTimer;

  SyncServiceNotifier(this._isar) : super(const SyncServiceState()) {
    _initLocalDevice().then((_) {
      // 根据设置决定是否自动启动同步服务
      _checkAndAutoStartServer();
    });
  }

  /// 检查并自动启动同步服务（根据用户设置）
  Future<void> _checkAndAutoStartServer() async {
    final config = AppConfig();
    if (config.syncAutoStart) {
      log.i(_tag, '🚀 Auto-starting sync server (enabled in settings)...');
      try {
        await startServer();
        log.i(_tag, '✅ Sync server auto-started successfully');
      } catch (e) {
        log.w(_tag, '⚠️ Failed to auto-start sync server: $e');
      }
    } else {
      log.d(_tag, 'Sync auto-start is disabled in settings');
    }
  }

  /// 初始化本地设备信息
  Future<void> _initLocalDevice() async {
    try {
      final uuid = const Uuid();
      final deviceId = uuid.v4();
      final deviceName = await _getDeviceName();
      final ipAddress = await _getLocalIpAddress();

      _localDevice = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        ipAddress: ipAddress,
        port: defaultPort,
        platform: Platform.operatingSystem,
        lastSeen: DateTime.now(),
      );

      state = state.copyWith(localDevice: _localDevice);
      log.d(_tag, 'Local device initialized: $_localDevice');
    } catch (e) {
      log.e(_tag, 'Failed to initialize local device: $e');
    }
  }

  /// 获取设备名称
  Future<String> _getDeviceName() async {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'PocketMind Device';
    }
  }

  /// 获取本地 IP 地址
  Future<String?> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      if (wifiIP != null) return wifiIP;

      // 备用方案：遍历网络接口
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      log.e(_tag, 'Failed to get local IP: $e');
    }
    return null;
  }

  /// 启动同步服务端（纯 WebSocket）
  Future<bool> startServer() async {
    if (_localDevice == null) {
      await _initLocalDevice();
    }

    if (_wsServer != null && _wsServer!.isRunning) {
      log.w(_tag, 'Server is already running');
      return true;
    }

    try {
      // 启动 WebSocket 服务器
      _wsServer = SyncWebSocketServer(isar: _isar, localDevice: _localDevice!);

      // 设置回调
      _wsServer!.onDeviceConnected = (device) {
        log.i(_tag, '🔗 Device connected via WebSocket: ${device.deviceName}');
        _addDiscoveredDevice(device);

        // 当有新设备连接时，通过已有连接请求同步数据（不创建新连接）
        if (device.ipAddress != null) {
          log.i(
            _tag,
            '🔄 New device connected, requesting sync via existing connection...',
          );
          _requestSyncViaServer(device.ipAddress!);
        }
      };

      _wsServer!.onDeviceDisconnected = (device) {
        log.i(_tag, '🔌 Device disconnected: ${device.deviceName}');
        _removeDiscoveredDevice(device);
      };

      _wsServer!.onRemoteDataChanged = () {
        log.i(_tag, '📥 Remote data changed, triggering sync...');
        _onRemoteDataChanged();
      };

      // 当收到同步响应时，应用变更
      _wsServer!.onSyncResponseReceived = (clientIp, changes) {
        log.i(_tag, '📥 Received ${changes.length} changes from $clientIp');
        _applyChangesFromServer(clientIp, changes);
      };

      await _wsServer!.start();

      // 开始监听本地数据库变化
      _startLocalDataWatchers();

      state = state.copyWith(isServerRunning: true);
      log.i(_tag, 'Sync server started (WebSocket only, port: $defaultPort)');
      return true;
    } catch (e) {
      log.e(_tag, 'Failed to start server: $e');
      state = state.copyWith(lastError: e.toString());
      return false;
    }
  }

  /// 停止同步服务端
  Future<void> stopServer() async {
    // 停止数据库监听
    await _notesWatcher?.cancel();
    await _categoriesWatcher?.cancel();
    _notesWatcher = null;
    _categoriesWatcher = null;

    // 断开所有 WebSocket 客户端连接，并停止自动重连
    for (final client in _wsClients.values) {
      client.stopReconnecting();
      client.dispose();
    }
    _wsClients.clear();

    // 停止 WebSocket 服务器
    if (_wsServer == null || !_wsServer!.isRunning) {
      state = state.copyWith(isServerRunning: false, discoveredDevices: []);
      return;
    }

    try {
      await _wsServer!.stop();
      _wsServer = null;
      state = state.copyWith(isServerRunning: false, discoveredDevices: []);
      log.i(_tag, 'Sync server stopped');
    } catch (e) {
      log.e(_tag, 'Failed to stop server: $e');
    }
  }

  /// 开始监听本地数据库变化
  void _startLocalDataWatchers() {
    // 监听 Notes 变化
    _notesWatcher = _isar.notes.watchLazy().listen((_) {
      log.d(_tag, '📤 Local notes changed');
      _onLocalDataChanged();
    });

    // 监听 Categories 变化
    _categoriesWatcher = _isar.categorys.watchLazy().listen((_) {
      log.d(_tag, '📤 Local categories changed');
      _onLocalDataChanged();
    });
  }

  /// 当本地数据变化时
  void _onLocalDataChanged() {
    // 通知所有已连接的 WebSocket 客户端
    for (final client in _wsClients.values) {
      client.notifyDataChanged();
    }
  }

  /// 当远程数据变化时（收到 WebSocket 通知）
  void _onRemoteDataChanged() {
    // 防抖：500ms 内只触发一次同步
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncAllConnectedDevices();
    });
  }

  /// 与所有已连接的设备同步
  Future<void> _syncAllConnectedDevices() async {
    if (state.isSyncing) return;

    final devices = state.discoveredDevices;
    if (devices.isEmpty) return;

    log.i(_tag, '🔄 Auto-syncing with ${devices.length} devices...');

    for (final device in devices) {
      if (device.ipAddress != null) {
        await syncWithDevice(device.ipAddress!, port: device.port);
      }
    }
  }

  /// 添加发现的设备到列表
  void _addDiscoveredDevice(DeviceInfo device) {
    final currentDevices = List<DeviceInfo>.from(state.discoveredDevices);

    // 检查是否已存在
    final existingIndex = currentDevices.indexWhere(
      (d) => d.deviceId == device.deviceId || d.ipAddress == device.ipAddress,
    );

    if (existingIndex >= 0) {
      currentDevices[existingIndex] = device;
    } else {
      currentDevices.add(device);
    }

    state = state.copyWith(discoveredDevices: currentDevices);
  }

  /// 从列表中移除设备
  void _removeDiscoveredDevice(DeviceInfo device) {
    final currentDevices = List<DeviceInfo>.from(state.discoveredDevices);
    currentDevices.removeWhere(
      (d) => d.deviceId == device.deviceId || d.ipAddress == device.ipAddress,
    );
    state = state.copyWith(discoveredDevices: currentDevices);
  }

  /// 测试本机服务器是否正常运行
  Future<bool> testLocalServer() async {
    if (_wsServer == null || !_wsServer!.isRunning) {
      log.w(_tag, 'Server is not running');
      return false;
    }

    // WebSocket 服务器运行中即为正常
    log.i(_tag, '✅ WebSocket server is running on port $defaultPort');
    return true;
  }

  /// 发现局域网设备
  Future<List<DeviceInfo>> discoverDevices() async {
    log.i(_tag, '=== Starting Device Discovery ===');

    // 检查本机服务状态
    log.i(_tag, 'Local server running: ${_wsServer?.isRunning ?? false}');
    if (_wsServer?.isRunning != true) {
      log.w(_tag, '⚠️ WARNING: Local server is NOT running!');
      log.w(_tag, 'Other devices cannot discover this device.');
      log.w(_tag, 'Please start the server first.');
    }

    final ipAddress = _localDevice?.ipAddress ?? await _getLocalIpAddress();
    if (ipAddress == null) {
      log.e(_tag, '❌ Cannot discover devices: no local IP address');
      log.e(_tag, 'Please check WiFi connection.');
      return [];
    }

    log.i(_tag, 'Local IP: $ipAddress');

    // 获取子网
    final parts = ipAddress.split('.');
    if (parts.length != 4) {
      log.e(_tag, '❌ Invalid IP format: $ipAddress');
      return [];
    }
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    log.i(_tag, 'Discovering devices on subnet: $subnet.*');

    _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);
    final devices = await _manager!.scanNetwork(subnet);

    // 过滤掉自己
    final filteredDevices = devices
        .where((d) => d.deviceId != _localDevice?.deviceId)
        .toList();

    log.i(
      _tag,
      'Found ${filteredDevices.length} other devices (excluded self)',
    );
    log.i(_tag, '=================================');

    state = state.copyWith(discoveredDevices: filteredDevices);

    // 自动与发现的设备建立 WebSocket 连接
    for (final device in filteredDevices) {
      if (device.ipAddress != null) {
        await _connectWebSocket(device);
      }
    }

    return filteredDevices;
  }

  /// 与设备建立 WebSocket 连接
  Future<void> _connectWebSocket(DeviceInfo device) async {
    if (device.ipAddress == null) return;

    final ip = device.ipAddress!;

    // 检查是否已连接
    if (_wsClients.containsKey(ip) && _wsClients[ip]!.isConnected) {
      return;
    }

    log.i(_tag, '🔗 Establishing WebSocket connection to ${device.deviceName}');

    final client = SyncWebSocketClient(localDevice: _localDevice!);

    client.onConnectionChanged = (connected, remoteDevice) {
      if (connected && remoteDevice != null) {
        log.i(_tag, '✅ WebSocket connected to ${remoteDevice.deviceName}');
        _addDiscoveredDevice(remoteDevice);
      } else if (!connected) {
        // 连接断开时，从列表中移除设备
        if (remoteDevice != null) {
          log.i(
            _tag,
            '🔌 WebSocket disconnected from ${remoteDevice.deviceName}',
          );
          _removeDiscoveredDevice(remoteDevice);
        }
      }
    };

    client.onRemoteDataChanged = () {
      log.i(_tag, '📥 Remote data changed from ${device.deviceName}');
      _onRemoteDataChanged();
    };

    // 当服务器主动关闭时的处理
    client.onServerShutdown = (remoteDevice) {
      if (remoteDevice != null) {
        log.w(_tag, '⚠️ Server ${remoteDevice.deviceName} is shutting down');
        _removeDiscoveredDevice(remoteDevice);
      }
    };

    // 当重连成功时，请求同步（通过客户端连接）
    client.onReconnected = () {
      log.i(_tag, '🔄 Reconnected to ${device.deviceName}, requesting sync');
      // 使用客户端请求同步
      _syncViaClient(client, ip);
    };

    // 当服务端请求同步时，返回本地变更数据
    client.onSyncRequestReceived = (since) async {
      log.i(
        _tag,
        '📤 Server requested sync since $since, providing local changes',
      );
      _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);
      return await _manager!.getLocalChangesSince(since);
    };

    // 当收到同步响应时（客户端请求同步的结果）
    client.onSyncResponse = (changes) {
      log.i(_tag, '📥 Received ${changes.length} changes via client');
      _applyChangesFromClient(ip, changes);
    };

    _wsClients[ip] = client;
    await client.connect(ip);
  }

  /// 通过服务端请求同步（不创建新连接）
  Future<void> _requestSyncViaServer(String clientIp) async {
    if (_wsServer == null || !_wsServer!.isRunning) return;

    // 获取上次同步时间戳
    final syncLogRepo = SyncLogRepository(_isar);
    final lastSyncTimestamp = await syncLogRepo.getLastSyncTimestamp(clientIp);

    log.i(
      _tag,
      '📤 Requesting sync from $clientIp via server (since: $lastSyncTimestamp)',
    );
    _wsServer!.requestSyncFromClient(clientIp, since: lastSyncTimestamp);
  }

  /// 应用从服务端收到的变更数据
  Future<void> _applyChangesFromServer(
    String clientIp,
    List<Map<String, dynamic>> changes,
  ) async {
    await _applyChanges(clientIp, changes, 'server');
  }

  /// 应用从客户端收到的变更数据
  Future<void> _applyChangesFromClient(
    String serverIp,
    List<Map<String, dynamic>> changes,
  ) async {
    await _applyChanges(serverIp, changes, 'client');
  }

  /// 应用变更数据（通用方法）
  Future<void> _applyChanges(
    String remoteIp,
    List<Map<String, dynamic>> changes,
    String source,
  ) async {
    if (changes.isEmpty) {
      log.d(_tag, 'No changes to apply from $remoteIp ($source)');
      return;
    }

    _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);

    try {
      final result = await _manager!.applyChanges(changes);

      // 更新同步日志
      final syncLogRepo = SyncLogRepository(_isar);
      await syncLogRepo.updateSyncLog(
        ip: remoteIp,
        deviceId: '$source-sync',
        deviceName: remoteIp,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: SyncStatus.success,
      );

      log.i(_tag, '✅ Applied changes from $remoteIp ($source): $result');
      state = state.copyWith(lastSyncTime: DateTime.now());
    } catch (e) {
      log.e(_tag, 'Failed to apply changes from $remoteIp ($source): $e');
    }
  }

  /// 通过客户端连接请求同步
  Future<void> _syncViaClient(
    SyncWebSocketClient client,
    String serverIp,
  ) async {
    final syncLogRepo = SyncLogRepository(_isar);
    final lastSyncTimestamp = await syncLogRepo.getLastSyncTimestamp(serverIp);

    log.i(
      _tag,
      '📤 Requesting sync from $serverIp via client (since: $lastSyncTimestamp)',
    );
    client.requestSync(since: lastSyncTimestamp);
  }

  /// 自动发现并同步所有设备
  ///
  /// 这是一个一键操作，自动执行：
  /// 1. 扫描局域网设备
  /// 2. 与所有发现的设备逐一同步
  Future<Map<String, SyncResult>> discoverAndSyncAll() async {
    log.i(_tag, '=== Auto Discover and Sync ===');

    final results = <String, SyncResult>{};

    // 1. 发现设备
    final devices = await discoverDevices();

    if (devices.isEmpty) {
      log.i(_tag, 'No devices found, skipping sync');
      return results;
    }

    log.i(_tag, 'Found ${devices.length} devices, starting sync...');

    // 2. 逐一同步
    for (final device in devices) {
      if (device.ipAddress == null) continue;

      log.i(_tag, 'Syncing with: ${device.deviceName} (${device.ipAddress})');
      final result = await syncWithDevice(device.ipAddress!, port: device.port);
      results[device.ipAddress!] = result;

      if (result.success) {
        log.i(_tag, '✅ Sync success: ${result.totalChanges} changes');
      } else {
        log.w(_tag, '❌ Sync failed: ${result.error}');
      }
    }

    log.i(_tag, '=== Auto Sync Completed ===');
    return results;
  }

  /// 与指定设备同步
  Future<SyncResult> syncWithDevice(String ip, {int? port}) async {
    if (state.isSyncing) {
      return const SyncResult(success: false, error: 'Already syncing');
    }

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);

      // 检查是否已有活跃的 WebSocket 客户端连接
      final existingClient = _wsClients[ip];
      if (existingClient != null && existingClient.isConnected) {
        // 使用现有连接进行同步
        log.i(_tag, '🔄 Using existing WebSocket connection for sync with $ip');
        final result = await _manager!.synchronizeViaClient(
          existingClient,
          targetIp: ip,
        );

        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: DateTime.now(),
          lastError: result.error,
        );

        return result;
      }

      // 没有现有连接，创建临时连接同步
      final result = await _manager!.synchronize(ip, port: port ?? defaultPort);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastError: result.error,
      );

      // 同步成功后，尝试建立 WebSocket 连接以实现实时同步
      if (result.success) {
        // 查找或创建设备信息
        final existingDevice = state.discoveredDevices.firstWhere(
          (d) => d.ipAddress == ip,
          orElse: () => DeviceInfo(
            deviceId: 'unknown',
            deviceName: ip,
            ipAddress: ip,
            port: port ?? defaultPort,
          ),
        );
        await _connectWebSocket(existingDevice);
      } else {
        // 同步失败，从设备列表中移除该设备，清理 WebSocket 连接
        _removeDeviceByIp(ip);
      }

      return result;
    } catch (e) {
      log.e(_tag, 'Sync failed: $e');
      // 同步异常，从设备列表中移除该设备
      _removeDeviceByIp(ip);
      state = state.copyWith(isSyncing: false, lastError: e.toString());
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 根据 IP 移除设备并清理 WebSocket 连接
  void _removeDeviceByIp(String ip) {
    // 断开 WebSocket 连接
    final client = _wsClients.remove(ip);
    client?.dispose();

    // 从设备列表移除
    final currentDevices = List<DeviceInfo>.from(state.discoveredDevices);
    currentDevices.removeWhere((d) => d.ipAddress == ip);
    state = state.copyWith(discoveredDevices: currentDevices);

    log.d(_tag, 'Removed device with IP: $ip');
  }

  /// 与所有已发现设备同步
  Future<void> syncAll() async {
    for (final device in state.discoveredDevices) {
      if (device.ipAddress != null) {
        await syncWithDevice(device.ipAddress!, port: device.port);
      }
    }
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _notesWatcher?.cancel();
    _categoriesWatcher?.cancel();

    for (final client in _wsClients.values) {
      client.dispose();
    }
    _wsClients.clear();

    _wsServer?.stop();
    _manager?.dispose();
    super.dispose();
  }
}

/// 同步服务 Provider
final syncServiceProvider =
    StateNotifierProvider<SyncServiceNotifier, SyncServiceState>((ref) {
      final isar = ref.watch(isarProvider);
      return SyncServiceNotifier(isar);
    });

/// 便捷的 Provider 访问
final isSyncServerRunningProvider = Provider<bool>((ref) {
  return ref.watch(syncServiceProvider).isServerRunning;
});

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncServiceProvider).isSyncing;
});

final discoveredDevicesProvider = Provider<List<DeviceInfo>>((ref) {
  return ref.watch(syncServiceProvider).discoveredDevices;
});

final localDeviceProvider = Provider<DeviceInfo?>((ref) {
  return ref.watch(syncServiceProvider).localDevice;
});
