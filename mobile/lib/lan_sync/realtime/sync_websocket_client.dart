import 'dart:async';
import 'dart:io';

import '../model/device_info.dart';
import '../model/sync_response.dart';
import '../model/sync_message.dart';
import '../protocol/sync_protocol_handler.dart';
import '../mapper/sync_data_mapper.dart';
import '../../util/logger_service.dart';
import 'sync_websocket_server.dart';

/// WebSocket 同步客户端
///
/// 连接到远程设备的 WebSocket 服务器，实现：
/// 1. 接收远程数据变化通知
/// 2. 发送本地数据变化通知
/// 3. 请求同步数据
/// 4. 保持长连接
class SyncWebSocketClient {
  static const String _tag = 'SyncWebSocketClient';

  final DeviceInfo _localDevice;
  final SyncProtocolHandler _protocolHandler = SyncProtocolHandler();

  WebSocket? _socket;
  String? _remoteIp;
  int? _remotePort;
  DeviceInfo? _remoteDevice;
  bool _isConnected = false;
  bool _isDisposed = false; // 标记是否已被销毁，防止销毁后继续重连
  bool _shouldReconnect = true; // 是否应该自动重连

  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _wasConnected = false; // 记录是否曾经连接过，用于重连时触发同步

  // 同步请求的 Completer，用于等待响应
  Completer<SyncResponse?>? _syncCompleter;

  /// 当收到远程数据变化时的回调
  void Function()? onRemoteDataChanged;

  /// 当连接状态变化时的回调
  void Function(bool connected, DeviceInfo? remoteDevice)? onConnectionChanged;

  /// 当服务器主动关闭时的回调
  void Function(DeviceInfo? remoteDevice)? onServerShutdown;

  /// 当重新连接成功时的回调（用于触发全量同步）
  void Function()? onReconnected;

  /// 当收到同步请求时的回调（服务端向客户端请求数据）
  /// 返回本地变更数据
  Future<List<Map<String, dynamic>>> Function(int since)? onSyncRequestReceived;

  /// 当收到同步响应时的回调（服务端返回数据）
  void Function(List<Map<String, dynamic>> changes)? onSyncResponse;

  SyncWebSocketClient({required DeviceInfo localDevice})
    : _localDevice = localDevice {
    _registerHandlers();
  }

  bool get isConnected => _isConnected;
  DeviceInfo? get remoteDevice => _remoteDevice;

  void _registerHandlers() {
    _protocolHandler.registerHandler(
      SyncMessageType.hello,
      (msg, _) => _handleHello(msg),
    );
    _protocolHandler.registerHandler(SyncMessageType.dataChanged, (msg, _) {
      PMlog.i(_tag, '📥 远程数据已更改！');
      onRemoteDataChanged?.call();
    });
    _protocolHandler.registerHandler(
      SyncMessageType.pong,
      (msg, _) {},
    ); // No-op
    _protocolHandler.registerHandler(
      SyncMessageType.syncRequest,
      (msg, _) => _handleSyncRequest(msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.syncResponse,
      (msg, _) => _handleSyncResponse(msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.imageRequest,
      (msg, _) => _handleImageRequest(msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.imageData,
      (msg, _) => _handleImageData(msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.serverShutdown,
      (msg, _) => _handleServerShutdown(msg),
    );
  }

  /// 连接到远程设备
  Future<bool> connect(
    String ip, {
    int port = SyncWebSocketServer.defaultPort,
  }) async {
    // 如果已被销毁，不允许连接
    if (_isDisposed) {
      PMlog.w(_tag, '客户端已销毁，无法连接');
      return false;
    }

    if (_isConnected && _remoteIp == ip) {
      PMlog.d(_tag, '已连接到 $ip');
      return true;
    }

    // 先断开现有连接（但保留重连能力）
    await _disconnectInternal(keepReconnect: true);

    _remoteIp = ip;
    _remotePort = port;

    try {
      PMlog.i(_tag, '连接到 ws://$ip:$port');

      _socket = await WebSocket.connect(
        'ws://$ip:$port',
        headers: {'X-Device-Id': _localDevice.deviceId},
      ).timeout(const Duration(seconds: 5));

      _isConnected = true;

      // 发送握手消息
      SyncProtocolHandler.send(
        _socket!,
        SyncMessage(
          type: SyncMessageType.hello,
          data: {
            ..._localDevice.toJson(),
            'protocolVersion': SyncWebSocketServer.protocolVersion,
            'schemaVersion': SyncWebSocketServer.schemaVersion,
          },
        ),
      );

      // 监听消息
      _socket!.listen(
        (data) => _protocolHandler.handleMessage(_socket!, data),
        onDone: _handleDisconnect,
        onError: (e) {
          PMlog.e(_tag, 'WebSocket 错误: $e');
          _handleDisconnect();
        },
      );

      // 启动心跳（60秒一次，避免UI频繁跳动）
      _startPingTimer();

      PMlog.i(_tag, '✅ 已连接到 $ip:$port');

      // 检测是否是重连
      if (_wasConnected) {
        PMlog.i(_tag, '🔄 已重新连接！触发全量同步...');
        onReconnected?.call();
      }
      _wasConnected = true;

      return true;
    } catch (e) {
      PMlog.e(_tag, '❌ 连接到 $ip:$port 失败: $e');
      _isConnected = false;
      // 只有在允许重连的情况下才尝试重连
      if (_shouldReconnect && !_isDisposed) {
        _scheduleReconnect();
      }
      return false;
    }
  }

  /// 断开连接（外部调用，停止重连）
  Future<void> disconnect() async {
    await _disconnectInternal(keepReconnect: false);
  }

  /// 内部断开连接方法
  Future<void> _disconnectInternal({bool keepReconnect = false}) async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    if (!keepReconnect) {
      _shouldReconnect = false;
    }

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    final remoteDeviceSnapshot = _remoteDevice;
    _isConnected = false;
    _remoteDevice = null;

    onConnectionChanged?.call(false, remoteDeviceSnapshot);
  }

  /// 停止自动重连
  void stopReconnecting() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    PMlog.d(_tag, '已停止自动重连');
  }

  /// 通知远程设备数据已变化
  void notifyDataChanged() {
    if (!_isConnected || _socket == null) return;

    SyncProtocolHandler.send(
      _socket!,
      SyncMessage(
        type: SyncMessageType.dataChanged,
        data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      ),
    );

    PMlog.d(_tag, '📤 已发送数据更改通知');
  }

  /// 请求同步数据（异步等待响应）
  Future<SyncResponse?> requestSyncAndWait({
    int since = 0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isConnected || _socket == null) return null;

    // 创建 Completer 等待响应
    _syncCompleter = Completer<SyncResponse?>();

    // 发送同步请求
    SyncProtocolHandler.send(
      _socket!,
      SyncMessage(type: SyncMessageType.syncRequest, data: {'since': since}),
    );

    try {
      // 等待响应或超时
      return await _syncCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          PMlog.w(_tag, '同步请求超时');
          return null;
        },
      );
    } finally {
      _syncCompleter = null;
    }
  }

  /// 请求同步数据（仅发送请求，不等待）
  void requestSync({int since = 0}) {
    if (!_isConnected || _socket == null) return;

    SyncProtocolHandler.send(
      _socket!,
      SyncMessage(type: SyncMessageType.syncRequest, data: {'since': since}),
    );
  }

  /// 处理欢迎消息
  void _handleHello(SyncMessage message) {
    if (message.data != null) {
      _remoteDevice = DeviceInfo.fromJson(message.data!);
      PMlog.i(_tag, '🤝 已连接到: ${_remoteDevice!.deviceName}');
      onConnectionChanged?.call(true, _remoteDevice);
    }
  }

  /// 处理同步请求（服务端向客户端请求数据）
  Future<void> _handleSyncRequest(SyncMessage message) async {
    final since = message.data?['since'] as int? ?? 0;
    PMlog.i(_tag, '📥 收到自 $since 以来的同步请求');

    if (onSyncRequestReceived != null) {
      try {
        // 获取本地变更数据
        final changes = await onSyncRequestReceived!(since);

        // 发送同步响应
        if (_socket != null) {
          SyncProtocolHandler.send(
            _socket!,
            SyncMessage(
              type: SyncMessageType.syncResponse,
              data: {
                'changes': changes,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            ),
          );
        }
        PMlog.i(_tag, '📤 已发送包含 ${changes.length} 个更改的同步响应');
      } catch (e) {
        PMlog.e(_tag, '处理同步请求失败: $e');
      }
    } else {
      PMlog.w(_tag, '未注册同步请求处理器，发送空响应');
      if (_socket != null) {
        SyncProtocolHandler.send(
          _socket!,
          SyncMessage(
            type: SyncMessageType.syncResponse,
            data: {
              'changes': <Map<String, dynamic>>[],
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          ),
        );
      }
    }
  }

  /// 处理同步响应
  void _handleSyncResponse(SyncMessage message) {
    PMlog.d(_tag, '收到同步响应');

    // 如果有等待中的 Completer（来自 requestSyncAndWait），优先完成它
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      try {
        final response = SyncResponse.fromJson(message.data ?? {});
        _syncCompleter!.complete(response);
      } catch (e) {
        PMlog.e(_tag, '解析同步响应失败: $e');
        _syncCompleter!.complete(null);
      }
    } else {
      // 否则通过回调通知（来自 requestSync 非阻塞请求）
      final changes = message.data?['changes'] as List<dynamic>? ?? [];
      final typedChanges = changes.cast<Map<String, dynamic>>();
      onSyncResponse?.call(typedChanges);
    }
  }

  /// 处理图片请求
  void _handleImageRequest(SyncMessage message) async {
    final relativePath = message.data?['path'] as String?;
    if (relativePath == null) {
      PMlog.w(_tag, '图片请求没有路径');
      return;
    }

    PMlog.d(_tag, '📷 Image request: $relativePath');

    try {
      // 读取图片并转换为 Base64
      final base64Data = await SyncDataMapper.imageToBase64(relativePath);

      if (base64Data == null) {
        PMlog.w(_tag, '未找到图片: $relativePath');
        return;
      }

      // 发送图片数据
      if (_socket != null) {
        SyncProtocolHandler.send(
          _socket!,
          SyncMessage(
            type: SyncMessageType.imageData,
            data: SyncDataMapper.buildImageDataMessage(
              relativePath: relativePath,
              base64Data: base64Data,
            ),
          ),
        );
      }

      PMlog.d(_tag, '✅ 已发送图片: $relativePath');
    } catch (e) {
      PMlog.e(_tag, '发送图片 $relativePath 失败: $e');
    }
  }

  /// 处理接收到的图片数据
  void _handleImageData(SyncMessage message) async {
    final relativePath = message.data?['path'] as String?;
    final base64Data = message.data?['data'] as String?;

    if (relativePath == null || base64Data == null) {
      PMlog.w(_tag, 'Invalid image data');
      return;
    }

    PMlog.d(_tag, '📷 收到图片: $relativePath');
    PMlog.d(_tag, 'Base64 数据长度: ${base64Data.length} 字符');

    try {
      final savedPath = await SyncDataMapper.saveImageFromBase64(
        base64Data: base64Data,
        relativePath: relativePath,
      );
      if (savedPath != null) {
        PMlog.d(_tag, '✅ 已保存图片: $relativePath (返回: $savedPath)');
      } else {
        PMlog.e(_tag, '❌ 保存图片失败: $relativePath (返回 null)');
      }
    } catch (e, stackTrace) {
      PMlog.e(_tag, '保存图片 $relativePath 失败: $e');
      PMlog.e(_tag, '堆栈跟踪: $stackTrace');
    }
  }

  /// 请求图片数据
  void requestImage(String relativePath) {
    if (!isConnected || _socket == null) {
      PMlog.w(_tag, 'Cannot request image: not connected');
      return;
    }

    PMlog.i(_tag, '📤 请求图片: $relativePath');
    SyncProtocolHandler.send(
      _socket!,
      SyncMessage(
        type: SyncMessageType.imageRequest,
        data: {'path': relativePath},
      ),
    );
  }

  /// 处理服务器主动关闭通知
  void _handleServerShutdown(SyncMessage message) {
    PMlog.w(_tag, '⚠️ Remote server is shutting down');

    // 取消重连定时器
    _reconnectTimer?.cancel();

    // 通知上层
    onServerShutdown?.call(_remoteDevice);

    // 断开当前连接
    _isConnected = false;
    _socket = null;

    onConnectionChanged?.call(false, _remoteDevice);

    // 远程服务器主动关闭，延迟重连（等服务器重启）
    // 但只有在 _shouldReconnect 为 true 时才重连
    if (_shouldReconnect && !_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// 处理断开连接
  void _handleDisconnect() {
    PMlog.w(_tag, 'WebSocket disconnected');
    _isConnected = false;
    _socket = null;

    onConnectionChanged?.call(false, _remoteDevice);

    // 只有在允许重连的情况下才尝试重连
    if (_shouldReconnect && !_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// 启动心跳定时器 (60秒一次，避免UI频繁跳动)
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isConnected && _socket != null) {
        SyncProtocolHandler.send(
          _socket!,
          const SyncMessage(type: SyncMessageType.ping),
        );
      }
    });
  }

  /// 计划重连 (10秒后尝试，避免频繁重连)
  void _scheduleReconnect() {
    if (_remoteIp == null || _isDisposed || !_shouldReconnect) {
      PMlog.d(
        _tag,
        'Reconnect skipped: remoteIp=$_remoteIp, disposed=$_isDisposed, shouldReconnect=$_shouldReconnect',
      );
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (!_isConnected &&
          _remoteIp != null &&
          !_isDisposed &&
          _shouldReconnect) {
        PMlog.i(_tag, 'Attempting to reconnect...');
        connect(
          _remoteIp!,
          port: _remotePort ?? SyncWebSocketServer.defaultPort,
        );
      }
    });
  }

  /// 关闭客户端（完全销毁，不再重连）
  void dispose() {
    _isDisposed = true;
    _shouldReconnect = false;
    disconnect();
    PMlog.d(_tag, 'Client disposed');
  }
}
