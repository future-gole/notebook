import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/lan_identity.dart';
import '../../util/logger_service.dart';

/// UDP 局域网发现服务
///
/// 通过 UDP 广播在局域网内宣告本地设备的存在，并监听其他设备的宣告。
class UdpLanDiscovery {
  static const String _tag = 'UdpLanDiscovery';

  /// 固定的 UDP 发现端口（与 WebSocket 端口分开）
  static const int discoveryPort = 54323;

  final LanIdentity Function() _localIdentityProvider;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _sub;
  Timer? _announceTimer;

  InternetAddress? _bindAddress;

  /// 当发现新设备或收到设备宣告时的回调
  void Function(LanIdentity remote, String remoteIp)? onPeerAnnouncement;

  UdpLanDiscovery({required LanIdentity Function() localIdentityProvider})
    : _localIdentityProvider = localIdentityProvider;

  bool get isRunning => _socket != null;

  /// 启动发现服务
  Future<void> start({required InternetAddress bindAddress}) async {
    if (_socket != null) return;

    // 绑定到 anyIPv4 以便在 Android 上可靠地接收广播包。
    // 我们仍然保留 bindAddress 用于计算广播目标。
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );

    socket.broadcastEnabled = true;

    _socket = socket;
    _bindAddress = bindAddress;

    _sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;

      try {
        final payload = utf8.decode(datagram.data);
        final json = jsonDecode(payload) as Map<String, dynamic>;

        if (json['type'] == 'pocketmind_lan_query') {
          _announce();
          return;
        }

        if (json['type'] != 'pocketmind_lan_announce') return;
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null) return;

        final remote = LanIdentity.tryFromJson(data);
        if (remote == null) return;

        final remoteIp = datagram.address.address;
        PMlog.d(
          _tag,
          '📥 收到来自 $remoteIp 的消息 id=${remote.deviceId} port=${remote.wsPort}',
        );
        onPeerAnnouncement?.call(remote, remoteIp);
      } catch (e) {
        // 忽略格式错误的包
      }
    });

    // 立即宣告 + 查询 + 定期宣告 (心跳)
    _announce();
    _query();
    _announceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _announce(),
    );

    PMlog.i(
      _tag,
      '✅ UDP 发现服务已启动 (绑定 0.0.0.0:$discoveryPort, 本地 ${bindAddress.address})',
    );
  }

  /// 停止发现服务
  Future<void> stop() async {
    _announceTimer?.cancel();
    _announceTimer = null;

    await _sub?.cancel();
    _sub = null;

    _socket?.close();
    _socket = null;
    _bindAddress = null;

    PMlog.i(_tag, '🛑 UDP 发现服务已停止');
  }

  /// 发送本地设备宣告
  void _announce() {
    final socket = _socket;
    if (socket == null) return;

    final local = _localIdentityProvider();

    final msg = {'type': 'pocketmind_lan_announce', 'data': local.toJson()};

    final bytes = utf8.encode(jsonEncode(msg));

    final targets = <InternetAddress>{
      InternetAddress('255.255.255.255'),
      ..._computeBroadcastTargets(),
    };

    for (final target in targets) {
      try {
        socket.send(bytes, target, discoveryPort);
      } catch (_) {
        // 忽略发送失败
      }
    }

    PMlog.d(_tag, '📤 已向 ${targets.length} 个目标发送消息');
  }

  /// 发送查询请求（新节点加入时触发）
  void _query() {
    final socket = _socket;
    if (socket == null) return;

    final msg = {'type': 'pocketmind_lan_query'};
    final bytes = utf8.encode(jsonEncode(msg));

    final targets = <InternetAddress>{
      InternetAddress('255.255.255.255'),
      ..._computeBroadcastTargets(),
    };

    for (final target in targets) {
      try {
        socket.send(bytes, target, discoveryPort);
      } catch (_) {
        // 忽略发送失败
      }
    }
    PMlog.d(_tag, '🔍 发送查询请求...');
  }

  /// 计算广播目标地址
  Iterable<InternetAddress> _computeBroadcastTargets() {
    // Dart 无法可靠地获取子网掩码；使用 /24 广播作为务实的备选方案。
    final bind = _bindAddress;
    if (bind == null) return const [];
    final parts = bind.address.split('.');
    if (parts.length != 4) return const [];
    final broadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
    return [InternetAddress(broadcast)];
  }
}
