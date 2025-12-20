import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/app_config_provider.dart';
import '../providers/infrastructure_providers.dart';
import '../providers/shared_preferences_provider.dart';
import 'model/device_info.dart';
import 'util/network_utils.dart';
import 'realtime/sync_websocket_client.dart';
import 'realtime/sync_websocket_server.dart';
import 'sync_manager.dart';
import '../util/logger_service.dart';

import 'lan_sync_engine.dart';
import 'model/lan_identity.dart';
import 'model/lan_peer.dart';
import 'udp/udp_lan_discovery.dart';

/// 局域网同步状态
class LanSyncState {
  /// 服务是否正在运行
  final bool isRunning;
  /// 是否正在同步中
  final bool isSyncing;
  /// 本地设备信息
  final DeviceInfo? localDevice;
  /// 发现的对等节点列表
  final List<LanPeer> peers;
  /// 最后一次错误信息
  final String? lastError;
  /// 最后一次同步成功的时间
  final DateTime? lastSyncTime;

  const LanSyncState({
    required this.isRunning,
    required this.isSyncing,
    required this.localDevice,
    required this.peers,
    required this.lastError,
    required this.lastSyncTime,
  });

  const LanSyncState.initial()
    : isRunning = false,
      isSyncing = false,
      localDevice = null,
      peers = const [],
      lastError = null,
      lastSyncTime = null;

  // 兼容现有 UI (sync_settings_page.dart)
  bool get isServerRunning => isRunning;

  /// 获取已发现的设备列表（转换为 DeviceInfo 格式）
  List<DeviceInfo> get discoveredDevices => peers
      .map(
        (p) => DeviceInfo(
          deviceId: p.deviceId,
          deviceName: p.deviceName,
          ipAddress: p.ip,
          port: p.wsPort,
          lastSeen: p.lastSeen,
        ),
      )
      .toList();

  LanSyncState copyWith({
    bool? isRunning,
    bool? isSyncing,
    DeviceInfo? localDevice,
    List<LanPeer>? peers,
    String? lastError,
    DateTime? lastSyncTime,
  }) {
    return LanSyncState(
      isRunning: isRunning ?? this.isRunning,
      isSyncing: isSyncing ?? this.isSyncing,
      localDevice: localDevice ?? this.localDevice,
      peers: peers ?? this.peers,
      lastError: lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// 局域网同步 Provider
final lanSyncProvider = NotifierProvider<LanSyncNotifier, LanSyncState>(
  LanSyncNotifier.new,
);

/// 局域网同步通知器
/// 
/// 负责管理 UDP 发现、WebSocket 服务端和客户端连接，以及同步流程的调度。
class LanSyncNotifier extends Notifier<LanSyncState> {
  static const String _tag = 'LanSyncNotifier';

  static const String _prefsDeviceIdKey = 'lan_sync_device_id';

  SyncWebSocketServer? _wsServer;
  UdpLanDiscovery? _discovery;
  LanSyncEngine? _engine;

  final Map<String, SyncWebSocketClient> _outboundByPeerId = {};

  // 如果指定的发起者无法连接（例如某系统拦截了入站连接），
  // 允许非发起者在延迟后尝试出站连接。
  final Map<String, Timer> _fallbackConnectTimers = {};

  // 入站映射（远程设备连接到我们的服务器）
  final Map<String, String> _peerIdByInboundIp = {};
  final Map<String, String> _inboundIpByPeerId = {};

  Timer? _peerCleanupTimer;
  bool _initialized = false;
  bool _startingOrStopping = false;

  @override
  LanSyncState build() {
    ref.onDispose(() {
      _peerCleanupTimer?.cancel();
      _peerCleanupTimer = null;

      for (final t in _fallbackConnectTimers.values) {
        t.cancel();
      }
      _fallbackConnectTimers.clear();

      unawaited(stop());
    });

    if (!_initialized) {
      _initialized = true;
      unawaited(_init());
    }

    return const LanSyncState.initial();
  }

  Future<void> _init() async {
    // If user enabled auto-start, start everything at app launch.
    final cfg = ref.read(appConfigProvider);
    if (cfg.syncAutoStart) {
      await start();
    }
  }

  Future<DeviceInfo> _buildLocalDevice() async {
    final prefs = ref.read(sharedPreferencesProvider);

    var deviceId = prefs.getString(_prefsDeviceIdKey);
    deviceId ??= const Uuid().v4();
    await prefs.setString(_prefsDeviceIdKey, deviceId);

    final ipInfo = await LanNetworkHelper.pickLanIPv4();
    final deviceName =
        prefs.getString('lan_sync_device_name') ??
        (Platform.localHostname.isNotEmpty
            ? Platform.localHostname
            : 'PocketMind-${Platform.operatingSystem}');

    return DeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      ipAddress: ipInfo?.ip,
      port: SyncWebSocketServer.defaultPort,
      platform: Platform.operatingSystem,
      lastSeen: DateTime.now(),
    );
  }

  LanIdentity _localIdentity(DeviceInfo local) {
    return LanIdentity(
      deviceId: local.deviceId,
      deviceName: local.deviceName,
      wsPort: local.port,
    );
  }

  bool _shouldInitiate({required String localId, required String remoteId}) {
    // Deterministic: exactly one side initiates.
    return localId.compareTo(remoteId) < 0;
  }

  Future<void> start() async {
    if (_startingOrStopping) return;
    _startingOrStopping = true;

    try {
      final isar = ref.read(isarProvider);
      final local = await _buildLocalDevice();

      // Start WebSocket server.
      _wsServer ??= SyncWebSocketServer(isar: isar, localDevice: local);
      if (!(_wsServer!.isRunning)) {
        try {
          await _wsServer!.start();
          PMlog.i(_tag, '✅ WS server listening on 0.0.0.0:${_wsServer!.port}');
        } catch (e) {
          state = state.copyWith(lastError: 'WS server 启动失败: $e');
          PMlog.e(_tag, '❌ WS server start failed: $e');
          rethrow;
        }
      }

      // Sync engine (reuses existing sync data mapper + apply logic).
      _engine = LanSyncEngine(isar: isar, localDevice: local);

      // Server callbacks (inbound channel).
      _wsServer!.onDeviceConnected = (clientIp, remoteDevice) {
        _peerIdByInboundIp[clientIp] = remoteDevice.deviceId;
        _inboundIpByPeerId[remoteDevice.deviceId] = clientIp;
        _upsertPeer(
          deviceId: remoteDevice.deviceId,
          deviceName: remoteDevice.deviceName,
          ip: clientIp,
          wsPort: remoteDevice.port,
          connected: true,
          outbound: false,
        );

        _cancelFallback(remoteDevice.deviceId);

        // Initial pull: ask the connected peer to send us changes.
        unawaited(_requestInboundSync(remoteDevice.deviceId));
      };

      _wsServer!.onDeviceDisconnected = (clientIp, remoteDevice) {
        final peerId = remoteDevice.deviceId;
        _peerIdByInboundIp.remove(clientIp);
        _inboundIpByPeerId.remove(peerId);
        _markDisconnected(peerId, outbound: false);

        // If we are the non-initiator, schedule a fallback dial attempt.
        _scheduleFallbackConnect(peerId);
      };

      _wsServer!.onRemoteDataChanged = (clientIp) {
        final peerId = _peerIdByInboundIp[clientIp];
        if (peerId == null) return;
        unawaited(_requestInboundSync(peerId));
      };

      _wsServer!.onSyncResponseReceived = (clientIp, changes, timestamp) {
        final peerId = _peerIdByInboundIp[clientIp];
        if (peerId == null) return;
        unawaited(_applyInboundSync(peerId, clientIp, changes, timestamp));
      };

      // Start UDP discovery.
      _discovery ??= UdpLanDiscovery(
        localIdentityProvider: () => _localIdentity(local),
      );

      _discovery!.onPeerAnnouncement = (remote, remoteIp) {
        if (remote.deviceId == local.deviceId) return;

        _upsertPeer(
          deviceId: remote.deviceId,
          deviceName: remote.deviceName,
          ip: remoteIp,
          wsPort: remote.wsPort,
          connected: _isConnected(remote.deviceId),
          outbound: _outboundByPeerId.containsKey(remote.deviceId),
        );

        unawaited(_maybeConnect(remote.deviceId));
      };

      final bindIp = local.ipAddress;
      if (bindIp == null) {
        state = state.copyWith(lastError: '无法获取局域网 IP');
      } else {
        await _discovery!.start(bindAddress: InternetAddress(bindIp));
      }

      _peerCleanupTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
        _cleanupPeers();
      });

      state = state.copyWith(
        isRunning: true,
        localDevice: local,
        lastError: null,
      );

      PMlog.i(_tag, '✅ LAN sync started');
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
      PMlog.e(_tag, '❌ start failed: $e');
    } finally {
      _startingOrStopping = false;
    }
  }

  // ---- Compatibility methods for existing UI ----
  Future<bool> startServer() async {
    await start();
    return state.isRunning;
  }

  Future<void> stopServer() => stop();

  Future<bool> testServerReachability() async {
    // Best-effort: if we're running, peers can try to connect.
    return state.isRunning && state.localDevice?.ipAddress != null;
  }

  Future<bool> testLocalServer() => testServerReachability();

  Future<Map<String, SyncResult>> discoverAndSyncAll() async {
    await start();
    final local = state.localDevice;
    final engine = _engine;
    if (local == null || engine == null) return {};

    // Deduplicate by peer deviceId.
    final byId = <String, LanPeer>{};
    for (final p in state.peers) {
      byId[p.deviceId] = p;
    }

    final results = <String, SyncResult>{};
    for (final entry in byId.entries) {
      final peerId = entry.key;
      final peer = entry.value;
      if (peer.ip == 'unknown') continue;

      // Use a short-lived outbound client so this works even when the
      // long-lived channel is inbound-only.
      final tempClient = SyncWebSocketClient(localDevice: local);
      tempClient.onSyncRequestReceived = (since) async {
        return engine.handleRemoteSyncRequest(since);
      };

      try {
        final ok = await _connectWithRetry(
          tempClient,
          peer.ip,
          port: peer.wsPort,
        );
        if (!ok) {
          results[peerId] = const SyncResult(success: false, error: '连接失败');
          continue;
        }
        final r = await engine.pullFromClient(peerId, tempClient);
        results[peerId] = r;
      } catch (e) {
        results[peerId] = SyncResult(success: false, error: e.toString());
      } finally {
        tempClient.stopReconnecting();
        await tempClient.disconnect();
        tempClient.dispose();
      }
    }

    return results;
  }

  Future<SyncResult> syncWithDevice(
    String ip, {
    int port = SyncWebSocketServer.defaultPort,
  }) async {
    await start();
    final isar = ref.read(isarProvider);
    final local = state.localDevice;
    final engine = _engine;

    final peer = state.peers.where((p) => p.ip == ip).toList();
    final peerId = peer.isNotEmpty ? peer.first.deviceId : ip;

    if (local != null && engine != null) {
      final tempClient = SyncWebSocketClient(localDevice: local);
      tempClient.onSyncRequestReceived = (since) async {
        return engine.handleRemoteSyncRequest(since);
      };
      try {
        final ok = await _connectWithRetry(tempClient, ip, port: port);
        if (!ok) return const SyncResult(success: false, error: '连接失败');
        return await engine.pullFromClient(peerId, tempClient);
      } finally {
        tempClient.stopReconnecting();
        await tempClient.disconnect();
        tempClient.dispose();
      }
    }

    // Fallback (should rarely happen): use legacy SyncManager direct IP sync.
    final mgr = SyncManager(
      isar: isar,
      localDevice: local ?? await _buildLocalDevice(),
    );
    return mgr.synchronize(ip, port: port);
  }

  Future<bool> _connectWithRetry(
    SyncWebSocketClient client,
    String ip, {
    required int port,
  }) async {
    // Keep this minimal: handle transient refusal during remote startup.
    const delays = [
      Duration(milliseconds: 0),
      Duration(milliseconds: 250),
      Duration(milliseconds: 800),
    ];

    for (final d in delays) {
      if (d.inMilliseconds > 0) {
        await Future.delayed(d);
      }

      final ok = await client.connect(ip, port: port);
      if (ok) return true;
    }
    return false;
  }

  Future<void> stop() async {
    if (_startingOrStopping) return;
    _startingOrStopping = true;

    try {
      await _discovery?.stop();
      _discovery = null;

      for (final t in _fallbackConnectTimers.values) {
        t.cancel();
      }
      _fallbackConnectTimers.clear();

      for (final client in _outboundByPeerId.values) {
        client.stopReconnecting();
        await client.disconnect();
        client.dispose();
      }
      _outboundByPeerId.clear();

      _peerIdByInboundIp.clear();
      _inboundIpByPeerId.clear();

      await _wsServer?.stop();
      _wsServer = null;

      state = const LanSyncState.initial();
      PMlog.i(_tag, '🛑 LAN sync stopped');
    } finally {
      _startingOrStopping = false;
    }
  }

  Future<void> _maybeConnect(String peerId) async {
    final local = state.localDevice;
    if (local == null) return;

    // If we already have inbound connection from this peer, do not create outbound.
    if (_inboundIpByPeerId.containsKey(peerId)) return;

    final shouldInitiate = _shouldInitiate(
      localId: local.deviceId,
      remoteId: peerId,
    );
    if (!shouldInitiate) {
      // Normally we don't initiate, but schedule a fallback dial if the initiator
      // can't connect (common on some Android ROMs / network policies).
      _scheduleFallbackConnect(peerId);
      return;
    }

    await _connectOutbound(peerId, force: false);
  }

  void _scheduleFallbackConnect(String peerId) {
    if (_fallbackConnectTimers.containsKey(peerId)) return;

    _fallbackConnectTimers[peerId] = Timer(const Duration(seconds: 4), () {
      _fallbackConnectTimers.remove(peerId);

      if (_isConnected(peerId)) return;

      final local = state.localDevice;
      if (local == null) return;

      PMlog.w(
        _tag,
        '⚠️ No connection yet, trying outbound fallback to $peerId',
      );
      unawaited(_connectOutbound(peerId, force: true));
    });
  }

  void _cancelFallback(String peerId) {
    final t = _fallbackConnectTimers.remove(peerId);
    t?.cancel();
  }

  Future<void> _connectOutbound(String peerId, {required bool force}) async {
    final local = state.localDevice;
    if (local == null) return;

    // If we already have inbound connection from this peer, do not create outbound.
    if (_inboundIpByPeerId.containsKey(peerId)) return;

    final peer = state.peers.firstWhere(
      (p) => p.deviceId == peerId,
      orElse: () => LanPeer(
        deviceId: peerId,
        deviceName: peerId,
        ip: 'unknown',
        wsPort: SyncWebSocketServer.defaultPort,
        lastSeen: DateTime.now(),
        connected: false,
        outbound: true,
      ),
    );

    if (peer.ip == 'unknown') return;

    if (!force) {
      final shouldInitiate = _shouldInitiate(
        localId: local.deviceId,
        remoteId: peerId,
      );
      if (!shouldInitiate) return;
    }

    // Connect outbound.
    final existing = _outboundByPeerId[peerId];
    if (existing != null && existing.isConnected) return;

    final client = existing ?? SyncWebSocketClient(localDevice: local);
    _outboundByPeerId[peerId] = client;

    client.onSyncRequestReceived = (since) async {
      final engine = _engine;
      if (engine == null) return [];
      return engine.handleRemoteSyncRequest(since);
    };

    client.onRemoteDataChanged = () {
      unawaited(_pullOutbound(peerId));
    };

    client.onConnectionChanged = (connected, remoteDevice) {
      _upsertPeer(
        deviceId: peerId,
        deviceName: remoteDevice?.deviceName ?? peer.deviceName,
        ip: peer.ip,
        wsPort: peer.wsPort,
        connected: connected,
        outbound: true,
      );

      if (connected) {
        _cancelFallback(peerId);
        unawaited(_pullOutbound(peerId));
      } else {
        // If we drop outbound and we are the non-initiator, schedule fallback again.
        _scheduleFallbackConnect(peerId);
      }
    };

    client.onReconnected = () {
      unawaited(_pullOutbound(peerId));
    };

    final ok = await client.connect(peer.ip, port: peer.wsPort);
    if (!ok) {
      // Keep it; client may auto-reconnect. Also allow fallback timer to kick in.
      _markDisconnected(peerId, outbound: true);
      _scheduleFallbackConnect(peerId);
    }
  }

  Future<void> _pullOutbound(String peerId) async {
    final engine = _engine;
    final client = _outboundByPeerId[peerId];
    if (engine == null || client == null || !client.isConnected) return;

    state = state.copyWith(isSyncing: true);
    try {
      final r = await engine.pullFromClient(peerId, client);
      if (r.success) {
        state = state.copyWith(lastSyncTime: DateTime.now());
      }
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _requestInboundSync(String peerId) async {
    final server = _wsServer;
    final engine = _engine;
    final ip = _inboundIpByPeerId[peerId];
    if (server == null || engine == null || ip == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      // Ask remote to send changes since our stored timestamp.
      final since = await engine.getLastSync(peerId);
      server.requestSyncFromClient(ip, since: since);
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _applyInboundSync(
    String peerId,
    String clientIp,
    List<Map<String, dynamic>> changes,
    int timestamp,
  ) async {
    final engine = _engine;
    final server = _wsServer;
    if (engine == null || server == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      await engine.applyInboundSyncResponse(
        peerDeviceId: peerId,
        changes: changes,
        timestamp: timestamp,
        wsServer: server,
        clientIp: clientIp,
      );
      state = state.copyWith(lastSyncTime: DateTime.now());
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  void _cleanupPeers() {
    final now = DateTime.now();
    final updated = <LanPeer>[];

    for (final p in state.peers) {
      final age = now.difference(p.lastSeen);
      if (age > const Duration(seconds: 30) && !p.connected) {
        continue;
      }
      updated.add(p);
    }

    if (updated.length != state.peers.length) {
      state = state.copyWith(peers: updated);
    }
  }

  bool _isConnected(String peerId) {
    final peer = state.peers.where((p) => p.deviceId == peerId).toList();
    if (peer.isEmpty) return false;
    return peer.any((p) => p.connected);
  }

  void _markDisconnected(String peerId, {required bool outbound}) {
    final updated = state.peers
        .map(
          (p) => p.deviceId == peerId && p.outbound == outbound
              ? p.copyWith(connected: false)
              : p,
        )
        .toList();
    state = state.copyWith(peers: updated);
  }

  void _upsertPeer({
    required String deviceId,
    required String deviceName,
    required String ip,
    required int wsPort,
    required bool connected,
    required bool outbound,
  }) {
    final now = DateTime.now();
    final peers = [...state.peers];
    final idx = peers.indexWhere(
      (p) => p.deviceId == deviceId && p.outbound == outbound,
    );

    final next = LanPeer(
      deviceId: deviceId,
      deviceName: deviceName,
      ip: ip,
      wsPort: wsPort,
      lastSeen: now,
      connected: connected,
      outbound: outbound,
    );

    if (idx >= 0) {
      peers[idx] = next;
    } else {
      peers.add(next);
    }

    state = state.copyWith(peers: peers);
  }
}
