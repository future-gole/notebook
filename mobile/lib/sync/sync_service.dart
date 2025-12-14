import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

import 'models/device_info.dart';
import 'models/sync_log.dart';
import 'sync_manager.dart';
import 'repository/sync_log_repository.dart';
import 'realtime/sync_websocket_server.dart';
import 'realtime/sync_websocket_client.dart';
import 'network_utils.dart';
import '../model/note.dart';
import '../model/category.dart';
import '../providers/infrastructure_providers.dart';
import '../util/logger_service.dart';
import '../providers/app_config_provider.dart';

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
class SyncServiceNotifier extends Notifier<SyncServiceState> {
  static const String _tag = 'SyncService';
  static const int defaultPort = SyncWebSocketServer.defaultPort;

  Isar get _isar => ref.read(isarProvider);

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

  @override
  SyncServiceState build() {
    ref.onDispose(() {
      _syncDebounceTimer?.cancel();
      _notesWatcher?.cancel();
      _categoriesWatcher?.cancel();

      for (final client in _wsClients.values) {
        client.dispose();
      }
      _wsClients.clear();

      _wsServer?.stop();
      _manager?.dispose();
    });

    _initLocalDevice().then((_) {
      // 根据设置决定是否自动启动同步服务
      _checkAndAutoStartServer();
    });
    return const SyncServiceState();
  }

  /// 检查并自动启动同步服务（根据用户设置）
  Future<void> _checkAndAutoStartServer() async {
    final config = ref.read(appConfigProvider);
    if (config.syncAutoStart) {
      PMlog.i(_tag, '🚀 自动启动同步服务器（设置中启用）...');
      try {
        await startServer();
        PMlog.i(_tag, '✅ 同步服务器自动启动成功');
      } catch (e) {
        PMlog.w(_tag, '⚠️ 自动启动同步服务器失败: $e');
      }
    } else {
      PMlog.d(_tag, '同步自动启动在设置中被禁用');
    }
  }

  /// 初始化本地设备信息
  Future<void> _initLocalDevice() async {
    try {
      final uuid = const Uuid();
      final deviceId = uuid.v4();
      final deviceName = await _getDeviceName();
      final ipAddress = await _getLocalIpAddress();

      if (ipAddress == null) {
        state = state.copyWith(lastError: '未找到 LAN IP。请连接 Wi-Fi 或启用热点。');
        PMlog.w(_tag, '本地设备初始化中止：缺少 LAN IP（需要 Wi-Fi/热点）');
        return;
      }

      _localDevice = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        ipAddress: ipAddress,
        port: defaultPort,
        platform: Platform.operatingSystem,
        lastSeen: DateTime.now(),
      );

      state = state.copyWith(localDevice: _localDevice);
      PMlog.d(_tag, '本地设备已初始化: $_localDevice');
    } catch (e) {
      PMlog.e(_tag, '初始化本地设备失败: $e');
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
      // Prefer LAN-only addresses; avoid CGNAT/public addresses (e.g., 100.x).
      final selection = await LanNetworkHelper.pickLanIPv4(logTag: _tag);
      return selection?.ip;
    } catch (e) {
      PMlog.e(_tag, '获取本地 IP 失败: $e');
    }
    return null;
  }

  /// 启动同步服务端（纯 WebSocket）
  Future<bool> startServer() async {
    if (_localDevice == null) {
      await _initLocalDevice();
    }

    if (_localDevice?.ipAddress == null) {
      state = state.copyWith(
        lastError:
            'No LAN IP found. Connect to the same Wi-Fi or enable hotspot.',
      );
      PMlog.w(_tag, '服务器启动中止：没有 LAN IP（缺少 Wi-Fi/热点）');
      return false;
    }

    if (_wsServer != null && _wsServer!.isRunning) {
      PMlog.w(_tag, '服务器已在运行');
      return true;
    }

    try {
      // 启动 WebSocket 服务器
      _wsServer = SyncWebSocketServer(isar: _isar, localDevice: _localDevice!);

      // 设置回调
      _wsServer!.onDeviceConnected = (device) {
        PMlog.i(_tag, '🔗 设备通过 WebSocket 连接: ${device.deviceName}');
        _addDiscoveredDevice(device);

        // 当有新设备连接时，通过已有连接请求同步数据（不创建新连接）
        if (device.ipAddress != null) {
          PMlog.i(_tag, '🔄 新设备连接，通过现有连接请求同步...');
          _requestSyncViaServer(device.ipAddress!);
        }
      };

      _wsServer!.onDeviceDisconnected = (device) {
        PMlog.i(_tag, '🔌 设备断开连接: ${device.deviceName}');
        _removeDiscoveredDevice(device);
      };

      _wsServer!.onRemoteDataChanged = () {
        PMlog.i(_tag, '📥 远程数据已更改，触发同步...');
        _onRemoteDataChanged();
      };

      // 当收到同步响应时，应用变更
      _wsServer!.onSyncResponseReceived = (clientIp, changes) {
        PMlog.i(_tag, '📥 从 $clientIp 收到 ${changes.length} 个更改');
        _applyChangesFromServer(clientIp, changes);
      };

      await _wsServer!.start();

      // 开始监听本地数据库变化
      _startLocalDataWatchers();

      state = state.copyWith(isServerRunning: true);
      PMlog.i(_tag, '同步服务器已启动（仅 WebSocket，端口: $defaultPort）');
      return true;
    } catch (e) {
      PMlog.e(_tag, '启动服务器失败: $e');
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
      PMlog.i(_tag, '同步服务器已停止');
    } catch (e) {
      PMlog.e(_tag, '停止服务器失败: $e');
    }
  }

  /// 开始监听本地数据库变化
  void _startLocalDataWatchers() {
    // 监听 Notes 变化
    _notesWatcher = _isar.notes.watchLazy().listen((_) {
      PMlog.d(_tag, '📤 本地笔记已更改');
      _onLocalDataChanged();
    });

    // 监听 Categories 变化
    _categoriesWatcher = _isar.categorys.watchLazy().listen((_) {
      PMlog.d(_tag, '📤 本地分类已更改');
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

    PMlog.i(_tag, '🔄 正在自动同步 ${devices.length} 个设备...');

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
      PMlog.w(_tag, '服务器未运行');
      return false;
    }

    // WebSocket 服务器运行中即为正常
    PMlog.i(_tag, '✅ WebSocket 服务器正在端口 $defaultPort 上运行');
    return true;
  }

  /// 发现局域网设备
  Future<List<DeviceInfo>> discoverDevices() async {
    PMlog.i(_tag, '=== 开始设备发现 ===');

    if (_localDevice == null) {
      await _initLocalDevice();
    }

    // 检查本机服务状态
    PMlog.i(_tag, '本地服务器运行中：${_wsServer?.isRunning ?? false}');
    if (_wsServer?.isRunning != true) {
      PMlog.w(_tag, '⚠️ WARNING: Local server is NOT running!');
      PMlog.w(_tag, 'Other devices cannot discover this device.');
      PMlog.w(_tag, 'Please start the server first.');
    }

    final ipAddress = _localDevice?.ipAddress ?? await _getLocalIpAddress();
    if (ipAddress == null) {
      PMlog.e(_tag, '❌ Cannot discover devices: no local IP address');
      PMlog.e(_tag, 'Please check WiFi connection.');
      return [];
    }

    if (_localDevice == null) {
      PMlog.e(_tag, '❌ Local device is not initialized');
      return [];
    }

    PMlog.i(_tag, 'Local IP: $ipAddress');
    final subnetMask = LanNetworkHelper.defaultSubnetMask;
    final candidates = LanNetworkHelper.hostsInSubnet(
      ipAddress,
      subnetMask: subnetMask,
    );

    PMlog.i(_tag, '在子网中发现设备（$subnetMask），主机数量：${candidates.length}');

    _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);
    final devices = await _manager!.scanNetwork(
      ipAddress,
      subnetMask: subnetMask,
    );

    // 过滤掉自己
    final filteredDevices = devices
        .where((d) => d.deviceId != _localDevice?.deviceId)
        .toList();

    PMlog.i(
      _tag,
      'Found ${filteredDevices.length} other devices (excluded self)',
    );
    PMlog.i(_tag, '=================================');

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

    PMlog.i(
      _tag,
      '🔗 Establishing WebSocket connection to ${device.deviceName}',
    );

    final client = SyncWebSocketClient(localDevice: _localDevice!);

    client.onConnectionChanged = (connected, remoteDevice) {
      if (connected && remoteDevice != null) {
        PMlog.i(_tag, '✅ WebSocket connected to ${remoteDevice.deviceName}');
        _addDiscoveredDevice(remoteDevice);
      } else if (!connected) {
        // 连接断开时，从列表中移除设备
        if (remoteDevice != null) {
          PMlog.i(
            _tag,
            '🔌 WebSocket disconnected from ${remoteDevice.deviceName}',
          );
          _removeDiscoveredDevice(remoteDevice);
        }
      }
    };

    client.onRemoteDataChanged = () {
      PMlog.i(_tag, '📥 Remote data changed from ${device.deviceName}');
      _onRemoteDataChanged();
    };

    // 当服务器主动关闭时的处理
    client.onServerShutdown = (remoteDevice) {
      if (remoteDevice != null) {
        PMlog.w(_tag, '⚠️ Server ${remoteDevice.deviceName} is shutting down');
        _removeDiscoveredDevice(remoteDevice);
      }
    };

    // 当重连成功时，请求同步（通过客户端连接）
    client.onReconnected = () {
      PMlog.i(_tag, '🔄 已重新连接到 ${device.deviceName}，请求同步');
      // 使用客户端请求同步
      _syncViaClient(client, ip);
    };

    // 当服务端请求同步时，返回本地变更数据
    client.onSyncRequestReceived = (since) async {
      PMlog.i(_tag, '📤 服务器请求自 $since 以来的同步，提供本地更改');
      _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);
      return await _manager!.getLocalChangesSince(since);
    };

    // 当收到同步响应时（客户端请求同步的结果）
    client.onSyncResponse = (changes) {
      PMlog.i(_tag, '📥 通过客户端收到 ${changes.length} 个更改');
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

    PMlog.i(_tag, '📤 通过服务器从 $clientIp 请求同步（自: $lastSyncTimestamp）');
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
      PMlog.d(_tag, 'No changes to apply from $remoteIp ($source)');
      return;
    }

    _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);

    try {
      // 尝试获取 WebSocket 客户端或服务端以支持图片同步
      SyncWebSocketClient? wsClient;
      if (source == 'client') {
        // 如果是从服务端收到的变更，使用客户端连接
        wsClient = _wsClients[remoteIp];
      }

      final result = await _manager!.applyChanges(
        changes,
        wsClient: wsClient,
        wsServer: source == 'server' ? _wsServer : null,
        clientIp: source == 'server' ? remoteIp : null,
      );

      // 更新同步日志
      final syncLogRepo = SyncLogRepository(_isar);
      await syncLogRepo.updateSyncLog(
        ip: remoteIp,
        deviceId: '$source-sync',
        deviceName: remoteIp,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: SyncStatus.success,
      );

      PMlog.i(_tag, '✅ 已应用来自 $remoteIp ($source) 的更改: $result');
      state = state.copyWith(lastSyncTime: DateTime.now());
    } catch (e) {
      PMlog.e(_tag, '应用来自 $remoteIp ($source) 的更改失败: $e');
    }
  }

  /// 通过客户端连接请求同步
  Future<void> _syncViaClient(
    SyncWebSocketClient client,
    String serverIp,
  ) async {
    final syncLogRepo = SyncLogRepository(_isar);
    final lastSyncTimestamp = await syncLogRepo.getLastSyncTimestamp(serverIp);

    PMlog.i(_tag, '📤 通过客户端从 $serverIp 请求同步（自: $lastSyncTimestamp）');
    client.requestSync(since: lastSyncTimestamp);
  }

  /// 自动发现并同步所有设备
  ///
  /// 这是一个一键操作，自动执行：
  /// 1. 扫描局域网设备
  /// 2. 与所有发现的设备逐一同步
  Future<Map<String, SyncResult>> discoverAndSyncAll() async {
    PMlog.i(_tag, '=== Auto Discover and Sync ===');

    final results = <String, SyncResult>{};

    // 1. 发现设备
    final devices = await discoverDevices();

    if (devices.isEmpty) {
      PMlog.i(_tag, '未发现设备，跳过同步');
      return results;
    }

    PMlog.i(_tag, '发现 ${devices.length} 个设备，开始同步...');

    // 2. 逐一同步
    for (final device in devices) {
      if (device.ipAddress == null) continue;

      PMlog.i(_tag, '正在与 ${device.deviceName} (${device.ipAddress}) 同步');
      final result = await syncWithDevice(device.ipAddress!, port: device.port);
      results[device.ipAddress!] = result;

      if (result.success) {
        PMlog.i(_tag, '✅ 同步成功：${result.totalChanges} 个更改');
      } else {
        PMlog.w(_tag, '❌ 同步失败：${result.error}');
      }
    }

    PMlog.i(_tag, '=== 自动同步完成 ===');
    return results;
  }

  /// 与指定设备同步
  Future<SyncResult> syncWithDevice(String ip, {int? port}) async {
    if (state.isSyncing) {
      return const SyncResult(success: false, error: '已在同步中');
    }

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      _manager ??= SyncManager(isar: _isar, localDevice: _localDevice!);

      // 子网检查：必须基于掩码判断，避免 100.x CGNAT 误判
      final localIp = _localDevice?.ipAddress;
      if (localIp != null) {
        final sameSubnet = LanNetworkHelper.isSameSubnet(
          localIp,
          ip,
          subnetMask: LanNetworkHelper.defaultSubnetMask,
        );
        PMlog.i(
          _tag,
          '子网检查 本地=$localIp, 远程=$ip, 掩码=${LanNetworkHelper.defaultSubnetMask}, 相同=$sameSubnet',
        );
        if (!sameSubnet) {
          PMlog.w(
            _tag,
            '目标 $ip 与 $localIp 不在同一子网（掩码 ${LanNetworkHelper.defaultSubnetMask}）',
          );
        }
      }

      // 检查是否已有活跃的 WebSocket 客户端连接
      final existingClient = _wsClients[ip];
      if (existingClient != null && existingClient.isConnected) {
        // 使用现有连接进行同步
        PMlog.i(
          _tag,
          '🔄 Using existing WebSocket connection for sync with $ip',
        );
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
      PMlog.e(_tag, '同步失败: $e');
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

    PMlog.d(_tag, 'Removed device with IP: $ip');
  }

  /// 与所有已发现设备同步
  Future<void> syncAll() async {
    for (final device in state.discoveredDevices) {
      if (device.ipAddress != null) {
        await syncWithDevice(device.ipAddress!, port: device.port);
      }
    }
  }


}

/// 同步服务 Provider
final syncServiceProvider =
    NotifierProvider<SyncServiceNotifier, SyncServiceState>(SyncServiceNotifier.new);
