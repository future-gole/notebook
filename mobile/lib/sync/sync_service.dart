import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'models/device_info.dart';
import 'server/sync_server.dart';
import 'sync_manager.dart';
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

  final Isar _isar;
  SyncServer? _server;
  SyncManager? _manager;
  DeviceInfo? _localDevice;
  
  // 实时同步组件
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
        port: SyncServer.defaultPort,
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

  /// 启动同步服务端
  Future<bool> startServer() async {
    if (_localDevice == null) {
      await _initLocalDevice();
    }

    if (_server != null && _server!.isRunning) {
      log.w(_tag, 'Server is already running');
      return true;
    }

    try {
      // 启动 HTTP 服务器（用于数据同步）
      _server = SyncServer(
        isar: _isar,
        deviceInfo: _localDevice!,
      );
      await _server!.start();
      
      // 启动 WebSocket 服务器（用于实时通知）
      _wsServer = SyncWebSocketServer(
        isar: _isar,
        localDevice: _localDevice!,
      );
      
      // 设置回调
      _wsServer!.onDeviceConnected = (device) {
        log.i(_tag, '🔗 Device connected via WebSocket: ${device.deviceName}');
        _addDiscoveredDevice(device);
        
        // 当有新设备连接时，主动同步（确保双方数据一致）
        if (device.ipAddress != null) {
          log.i(_tag, '🔄 New device connected, triggering sync...');
          _triggerFullSync(device.ipAddress!, device.port);
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
      
      await _wsServer!.start();
      
      // 开始监听本地数据库变化
      _startLocalDataWatchers();
      
      state = state.copyWith(isServerRunning: true);
      log.i(_tag, 'Sync server started (HTTP + WebSocket)');
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
      client.stopReconnecting(); // 先停止重连
      client.dispose();
    }
    _wsClients.clear();
    
    // 停止 WebSocket 服务器
    await _wsServer?.stop();
    _wsServer = null;
    
    // 停止 HTTP 服务器
    if (_server == null || !_server!.isRunning) {
      // 即使 HTTP 服务器未运行，也要清理状态
      state = state.copyWith(isServerRunning: false, discoveredDevices: []);
      return;
    }

    try {
      await _server!.stop();
      _server = null;
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
      (d) => d.deviceId == device.deviceId || d.ipAddress == device.ipAddress
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
      (d) => d.deviceId == device.deviceId || d.ipAddress == device.ipAddress
    );
    state = state.copyWith(discoveredDevices: currentDevices);
  }

  /// 测试本机服务器是否正常运行
  Future<bool> testLocalServer() async {
    if (_server == null || !_server!.isRunning) {
      log.w(_tag, 'Server is not running');
      return false;
    }
    
    try {
      final localIp = await _getLocalIpAddress();
      if (localIp == null) {
        log.w(_tag, 'Cannot test: no local IP');
        return false;
      }
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      
      // 尝试访问本机服务
      final url = 'http://$localIp:54321/v1/info';
      log.i(_tag, 'Testing local server at: $url');
      
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        log.i(_tag, '✅ Local server is reachable! Response: ${response.data}');
        return true;
      } else {
        log.w(_tag, '❌ Server returned: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log.e(_tag, '❌ Cannot reach local server: $e');
      return false;
    }
  }
  
  /// 发现局域网设备
  Future<List<DeviceInfo>> discoverDevices() async {
    log.i(_tag, '=== Starting Device Discovery ===');
    
    // 检查本机服务状态
    log.i(_tag, 'Local server running: ${_server?.isRunning ?? false}');
    if (_server?.isRunning != true) {
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

    _manager ??= SyncManager(isar: _isar);
    final devices = await _manager!.scanNetwork(subnet);

    // 过滤掉自己
    final filteredDevices = devices
        .where((d) => d.deviceId != _localDevice?.deviceId)
        .toList();

    log.i(_tag, 'Found ${filteredDevices.length} other devices (excluded self)');
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
          log.i(_tag, '🔌 WebSocket disconnected from ${remoteDevice.deviceName}');
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
    
    // 当重连成功时，触发全量同步
    client.onReconnected = () {
      log.i(_tag, '🔄 Reconnected to ${device.deviceName}, triggering full sync');
      _triggerFullSync(ip, device.port);
    };
    
    _wsClients[ip] = client;
    await client.connect(ip);
  }
  
  /// 触发与指定设备的全量同步
  Future<void> _triggerFullSync(String ip, int port) async {
    log.i(_tag, '🔄 Full sync with $ip:$port');
    await syncWithDevice(ip, port: port);
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
      _manager ??= SyncManager(isar: _isar);
      final result = await _manager!.synchronize(
        ip,
        port: port ?? SyncServer.defaultPort,
      );

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
            port: port ?? SyncServer.defaultPort,
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
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
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
    _server?.stop();
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
