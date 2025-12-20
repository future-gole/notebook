import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isar_community/isar.dart';

import '../mapper/sync_data_mapper.dart';
import '../model/device_info.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';

/// WebSocket 消息类型
class SyncMessageType {
  static const String hello = 'hello'; // 握手
  static const String deviceInfo = 'device_info'; // 设备信息
  static const String dataChanged = 'data_changed'; // 数据变化通知
  static const String syncRequest = 'sync_request'; // 请求同步
  static const String syncResponse = 'sync_response'; // 同步响应
  static const String imageRequest = 'image_request'; // 请求图片
  static const String imageData = 'image_data'; // 图片数据
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String serverShutdown = 'server_shutdown'; // 服务器即将关闭
  static const String discover = 'discover'; // 设备发现请求
  static const String discoverResponse = 'discover_response'; // 设备发现响应
}

/// 同步 WebSocket 消息
class SyncMessage {
  final String type;
  final Map<String, dynamic>? data;
  final int timestamp;

  SyncMessage({required this.type, this.data, int? timestamp})
    : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'timestamp': timestamp,
  };

  String toJsonString() => jsonEncode(toJson());
}

/// 已连接的客户端信息
class ConnectedClient {
  final WebSocket socket;
  final DeviceInfo deviceInfo;
  final DateTime connectedAt;

  ConnectedClient({
    required this.socket,
    required this.deviceInfo,
    DateTime? connectedAt,
  }) : connectedAt = connectedAt ?? DateTime.now();
}

/// WebSocket 同步服务端
///
/// 提供实时双向同步能力：
/// 1. 接收客户端连接
/// 2. 监听数据库变化并推送给所有连接的客户端
/// 3. 接收客户端的数据变化通知并同步
class SyncWebSocketServer {
  static const String _tag = 'SyncWebSocketServer';
  static const int defaultPort = 54322; // WebSocket 端口，与 HTTP 端口分开

  final Isar _isar;
  final DeviceInfo _localDevice;
  final int _port;

  HttpServer? _server;
  bool _isRunning = false;

  /// 已连接的客户端
  final Map<String, ConnectedClient> _clients = {};

  /// 数据库监听订阅
  StreamSubscription? _notesSubscription;
  StreamSubscription? _categoriesSubscription;

  /// 当有新设备连接时的回调
  void Function(String clientIp, DeviceInfo device)? onDeviceConnected;

  /// 当设备断开连接时的回调
  void Function(String clientIp, DeviceInfo device)? onDeviceDisconnected;

  /// 当收到远程数据变化时的回调
  void Function(String clientIp)? onRemoteDataChanged;

  /// 当收到同步响应时的回调（包含变更数据）
  void Function(
    String clientIp,
    List<Map<String, dynamic>> changes,
    int timestamp,
  )?
  onSyncResponseReceived;

  SyncWebSocketServer({
    required Isar isar,
    required DeviceInfo localDevice,
    int port = defaultPort,
  }) : _isar = isar,
       _localDevice = localDevice,
       _port = port;

  bool get isRunning => _isRunning;
  int get port => _port;

  /// 获取已连接的设备列表
  List<DeviceInfo> get connectedDevices =>
      _clients.values.map((c) => c.deviceInfo).toList();

  /// 启动 WebSocket 服务器
  Future<void> start() async {
    if (_isRunning) {
      PMlog.w(_tag, 'WebSocket 服务器已在运行');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;

      PMlog.i(_tag, '=== WebSocket 服务器已启动 ===');
      PMlog.i(_tag, '监听端口: $_port');

      // 监听连接
      _server!.listen(_handleConnection);

      // 开始监听数据库变化
      _startDatabaseWatchers();

      PMlog.i(_tag, '================================');
    } catch (e) {
      PMlog.e(_tag, '启动 WebSocket 服务器失败: $e');
      rethrow;
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    if (!_isRunning) return;

    // 停止数据库监听
    await _notesSubscription?.cancel();
    await _categoriesSubscription?.cancel();

    // 广播服务器关闭通知给所有客户端
    final shutdownMessage = SyncMessage(
      type: SyncMessageType.serverShutdown,
      data: {
        'deviceId': _localDevice.deviceId,
        'deviceName': _localDevice.deviceName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    for (final client in _clients.values) {
      try {
        _sendMessage(client.socket, shutdownMessage);
      } catch (e) {
        PMlog.w(_tag, '发送关闭通知失败: $e');
      }
    }

    // 短暂等待消息发送
    await Future.delayed(const Duration(milliseconds: 100));

    // 关闭所有客户端连接
    for (final client in _clients.values) {
      await client.socket.close();
    }
    _clients.clear();

    // 关闭服务器
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;

    PMlog.i(_tag, 'WebSocket 服务器已停止');
  }

  /// 处理新连接
  void _handleConnection(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      final clientIp =
          request.connectionInfo?.remoteAddress.address ?? 'unknown';

      PMlog.i(_tag, '来自 $clientIp 的新 WebSocket 连接');

      // 发送欢迎消息（包含本机设备信息）
      _sendMessage(
        socket,
        SyncMessage(type: SyncMessageType.hello, data: _localDevice.toJson()),
      );

      // 监听客户端消息
      socket.listen(
        (data) => _handleMessage(socket, clientIp, data),
        onDone: () => _handleDisconnect(clientIp),
        onError: (e) {
          PMlog.e(_tag, '来自 $clientIp 的 WebSocket 错误: $e');
          _handleDisconnect(clientIp);
        },
      );
    } catch (e) {
      PMlog.e(_tag, '升级 WebSocket 失败: $e');
    }
  }

  /// 处理客户端消息
  void _handleMessage(WebSocket socket, String clientIp, dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = SyncMessage.fromJson(json);

      PMlog.d(_tag, '从 $clientIp 收到消息: ${message.type}');

      switch (message.type) {
        case SyncMessageType.deviceInfo:
          _handleDeviceInfo(socket, clientIp, message);
          break;
        case SyncMessageType.discover:
          _handleDiscover(socket, clientIp, message);
          break;
        case SyncMessageType.dataChanged:
          _handleDataChanged(clientIp, message);
          break;
        case SyncMessageType.ping:
          _sendMessage(socket, SyncMessage(type: SyncMessageType.pong));
          break;
        case SyncMessageType.syncRequest:
          _handleSyncRequest(socket, message);
          break;
        case SyncMessageType.syncResponse:
          _handleSyncResponse(clientIp, message);
          break;
        case SyncMessageType.imageRequest:
          _handleImageRequest(socket, clientIp, message);
          break;
        case SyncMessageType.imageData:
          _handleImageData(clientIp, message);
          break;
      }
    } catch (e) {
      PMlog.e(_tag, '处理消息失败: $e');
    }
  }

  /// 处理设备发现请求（不注册设备，仅返回本机信息）
  void _handleDiscover(WebSocket socket, String clientIp, SyncMessage message) {
    PMlog.d(_tag, '🔍 来自 $clientIp 的发现请求');

    // 记录请求数据
    if (message.data != null) {
      try {
        final deviceInfo = DeviceInfo.fromJson(message.data!);
        PMlog.d(
          _tag,
          '发现来自: ${deviceInfo.deviceName} (${deviceInfo.deviceId})',
        );
      } catch (e) {
        PMlog.w(_tag, '解析发现中的设备信息失败: $e');
      }
    }

    // 直接返回本机设备信息，不注册客户端
    PMlog.d(_tag, '向 $clientIp 发送发现响应: ${_localDevice.deviceName}');
    _sendMessage(
      socket,
      SyncMessage(
        type: SyncMessageType.discoverResponse,
        data: _localDevice.toJson(),
      ),
    );
  }

  /// 处理设备信息
  void _handleDeviceInfo(
    WebSocket socket,
    String clientIp,
    SyncMessage message,
  ) {
    if (message.data == null) return;

    final deviceInfo = DeviceInfo.fromJson(message.data!);

    // 保存客户端信息
    _clients[clientIp] = ConnectedClient(
      socket: socket,
      deviceInfo: deviceInfo,
    );

    PMlog.i(_tag, '✅ 设备已注册: ${deviceInfo.deviceName} ($clientIp)');

    // 延迟通知回调，确保客户端已完全准备好
    Future.delayed(const Duration(milliseconds: 100), () {
      // 确认客户端仍然连接
      if (_clients.containsKey(clientIp)) {
        onDeviceConnected?.call(clientIp, deviceInfo);
      }
    });
  }

  /// 处理数据变化通知
  void _handleDataChanged(String clientIp, SyncMessage message) {
    PMlog.i(_tag, '📥 来自 $clientIp 的数据更改通知');

    // 通知上层进行同步
    onRemoteDataChanged?.call(clientIp);
  }

  /// 处理同步请求
  Future<void> _handleSyncRequest(WebSocket socket, SyncMessage message) async {
    final since = message.data?['since'] as int? ?? 0;

    PMlog.d(_tag, '处理自 $since 以来的同步请求');

    try {
      // 获取变更数据
      final notes = await _isar.notes
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      final categories = await _isar.categorys
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      final changes = SyncDataMapper.combineChanges(
        notes: notes,
        categories: categories,
      );

      _sendMessage(
        socket,
        SyncMessage(
          type: SyncMessageType.syncResponse,
          data: {
            'changes': changes,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        ),
      );
    } catch (e) {
      PMlog.e(_tag, '处理同步请求失败: $e');
    }
  }

  /// 处理断开连接
  void _handleDisconnect(String clientIp) {
    final client = _clients.remove(clientIp);
    if (client != null) {
      PMlog.i(_tag, '❌ 设备断开连接: ${client.deviceInfo.deviceName}');
      onDeviceDisconnected?.call(clientIp, client.deviceInfo);
    }
  }

  /// 处理同步响应（当服务端作为请求方时）
  void _handleSyncResponse(String clientIp, SyncMessage message) {
    PMlog.d(_tag, 'Received sync response from $clientIp');

    final changes = message.data?['changes'] as List<dynamic>? ?? [];
    final typedChanges = changes.cast<Map<String, dynamic>>();

    final timestamp =
        (message.data?['timestamp'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;

    onSyncResponseReceived?.call(clientIp, typedChanges, timestamp);
  }

  /// 处理图片请求
  void _handleImageRequest(
    WebSocket socket,
    String clientIp,
    SyncMessage message,
  ) async {
    final relativePath = message.data?['path'] as String?;
    if (relativePath == null) {
      PMlog.w(_tag, 'Image request without path from $clientIp');
      return;
    }

    PMlog.d(_tag, '📷 Image request from $clientIp: $relativePath');

    try {
      // 读取图片并转换为 Base64
      final base64Data = await SyncDataMapper.imageToBase64(relativePath);

      if (base64Data == null) {
        PMlog.w(_tag, 'Image not found: $relativePath');
        return;
      }

      // 发送图片数据
      _sendMessage(
        socket,
        SyncMessage(
          type: SyncMessageType.imageData,
          data: SyncDataMapper.buildImageDataMessage(
            relativePath: relativePath,
            base64Data: base64Data,
          ),
        ),
      );

      PMlog.d(_tag, '✅ 已发送图片: $relativePath');
    } catch (e) {
      PMlog.e(_tag, '发送图片 $relativePath 失败: $e');
    }
  }

  /// 处理接收到的图片数据
  void _handleImageData(String clientIp, SyncMessage message) async {
    final relativePath = message.data?['path'] as String?;
    final base64Data = message.data?['data'] as String?;

    if (relativePath == null || base64Data == null) {
      PMlog.w(_tag, 'Invalid image data from $clientIp');
      return;
    }

    PMlog.d(_tag, '📷 Received image from $clientIp: $relativePath');
    PMlog.d(_tag, 'Base64 data length: ${base64Data.length} chars');

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

  /// 向指定客户端请求同步数据
  ///
  /// 服务端主动向已连接的客户端请求同步，用于：
  /// 1. 新设备连接时，获取对方数据
  /// 2. 收到 dataChanged 通知时，拉取变更
  void requestSyncFromClient(String clientIp, {int since = 0}) {
    final client = _clients[clientIp];
    if (client == null) {
      PMlog.w(_tag, 'Cannot request sync: client $clientIp not found');
      return;
    }

    PMlog.i(_tag, '📤 Requesting sync from $clientIp since $since');

    _sendMessage(
      client.socket,
      SyncMessage(type: SyncMessageType.syncRequest, data: {'since': since}),
    );
  }

  /// 向所有已连接客户端请求同步数据
  void requestSyncFromAllClients({int since = 0}) {
    for (final ip in _clients.keys) {
      requestSyncFromClient(ip, since: since);
    }
  }

  /// 向指定客户端请求图片
  void requestImage(String clientIp, String relativePath) {
    final client = _clients[clientIp];
    if (client == null) {
      PMlog.w(_tag, 'Cannot request image: client $clientIp not found');
      return;
    }

    PMlog.i(_tag, '📷 Requesting image from $clientIp: $relativePath');
    _sendMessage(
      client.socket,
      SyncMessage(
        type: SyncMessageType.imageRequest,
        data: {'path': relativePath},
      ),
    );
  }

  /// 开始监听数据库变化
  void _startDatabaseWatchers() {
    // 监听 Notes 变化
    _notesSubscription = _isar.notes.watchLazy().listen((_) {
      PMlog.d(_tag, '📤 Notes changed, notifying clients');
      _broadcastDataChanged();
    });

    // 监听 Categories 变化
    _categoriesSubscription = _isar.categorys.watchLazy().listen((_) {
      PMlog.d(_tag, '📤 Categories changed, notifying clients');
      _broadcastDataChanged();
    });
  }

  /// 广播数据变化通知给所有客户端
  void _broadcastDataChanged() {
    final message = SyncMessage(
      type: SyncMessageType.dataChanged,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );

    for (final client in _clients.values) {
      _sendMessage(client.socket, message);
    }

    PMlog.d(_tag, 'Broadcast data_changed to ${_clients.length} clients');
  }

  /// 发送消息
  void _sendMessage(WebSocket socket, SyncMessage message) {
    try {
      socket.add(message.toJsonString());
    } catch (e) {
      PMlog.e(_tag, '发送消息失败: $e');
    }
  }
}
