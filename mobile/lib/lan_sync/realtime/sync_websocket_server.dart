import 'dart:async';
import 'dart:io';

import '../repository/i_sync_data_repository.dart';
import '../mapper/sync_data_mapper.dart';
import '../model/device_info.dart';
import '../model/sync_message.dart';
import '../protocol/sync_protocol_handler.dart';
import '../../util/logger_service.dart';

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

  static const int protocolVersion = 1;
  static const int schemaVersion = 20231224;

  final ISyncDataRepository _repository;
  final DeviceInfo _localDevice;
  final int _port;
  final SyncProtocolHandler _protocolHandler = SyncProtocolHandler();

  HttpServer? _server;
  bool _isRunning = false;

  /// 已连接的客户端
  final Map<String, ConnectedClient> _clients = {};
  final Map<WebSocket, String> _socketIps = {};

  /// 数据库监听订阅
  StreamSubscription? _notesSubscription;
  StreamSubscription? _categoriesSubscription;

  /// 当有新设备连接时的回调
  void Function(String clientIp, DeviceInfo device)? onDeviceConnected;

  /// 当设备断开连接时的回调
  void Function(String clientIp, DeviceInfo device)? onDeviceDisconnected;

  /// 当收到远程数据变化时的回调
  void Function(String clientIp, String deviceId)? onRemoteDataChanged;

  /// 当收到同步响应时的回调（包含变更数据）
  void Function(
    String clientIp,
    String deviceId,
    List<Map<String, dynamic>> changes,
    int timestamp,
  )?
  onSyncResponseReceived;

  SyncWebSocketServer({
    required ISyncDataRepository repository,
    required DeviceInfo localDevice,
    int port = defaultPort,
  }) : _repository = repository,
       _localDevice = localDevice,
       _port = port {
    _registerHandlers();
  }

  bool get isRunning => _isRunning;
  int get port => _port;

  /// 获取已连接的设备列表
  List<DeviceInfo> get connectedDevices =>
      _clients.values.map((c) => c.deviceInfo).toList();

  void _registerHandlers() {
    _protocolHandler.registerHandler(
      SyncMessageType.hello,
      (msg, socket) => _handleHello(socket, _getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.deviceInfo,
      (msg, socket) => _handleDeviceInfo(socket, _getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.discover,
      (msg, socket) => _handleDiscover(socket, _getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.dataChanged,
      (msg, socket) => _handleDataChanged(_getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.ping,
      (msg, socket) => SyncProtocolHandler.send(
        socket,
        const SyncMessage(type: SyncMessageType.pong),
      ),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.syncRequest,
      (msg, socket) => _handleSyncRequest(socket, msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.syncResponse,
      (msg, socket) => _handleSyncResponse(_getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.imageRequest,
      (msg, socket) => _handleImageRequest(socket, _getIp(socket), msg),
    );
    _protocolHandler.registerHandler(
      SyncMessageType.imageData,
      (msg, socket) => _handleImageData(_getIp(socket), msg),
    );
  }

  String _getIp(WebSocket socket) {
    return _socketIps[socket] ?? 'unknown';
  }

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
        SyncProtocolHandler.send(client.socket, shutdownMessage);
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
      _socketIps[socket] = clientIp;

      PMlog.i(_tag, '来自 $clientIp 的新 WebSocket 连接');

      // 发送欢迎消息（包含本机设备信息和版本）
      SyncProtocolHandler.send(
        socket,
        SyncMessage(
          type: SyncMessageType.hello,
          data: {
            ..._localDevice.toJson(),
            'protocolVersion': protocolVersion,
            'schemaVersion': schemaVersion,
          },
        ),
      );

      // 监听客户端消息
      socket.listen(
        (data) =>
            _protocolHandler.handleMessage(socket, data, sourceInfo: clientIp),
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
    SyncProtocolHandler.send(
      socket,
      SyncMessage(
        type: SyncMessageType.discoverResponse,
        data: _localDevice.toJson(),
      ),
    );
  }

  /// 处理 Hello 握手消息
  void _handleHello(WebSocket socket, String clientIp, SyncMessage message) {
    if (message.data == null) return;

    final remoteProtocol = message.data!['protocolVersion'] as int? ?? 0;
    final remoteSchema = message.data!['schemaVersion'] as int? ?? 0;

    if (remoteProtocol != protocolVersion) {
      PMlog.w(_tag, '协议版本不兼容: $remoteProtocol != $protocolVersion');
      socket.close(4000, 'Protocol version mismatch');
      return;
    }

    if (remoteSchema != schemaVersion) {
      PMlog.w(_tag, 'Schema 版本不兼容: $remoteSchema != $schemaVersion');
      socket.close(4001, 'Schema version mismatch');
      return;
    }

    // 握手成功，注册设备
    _handleDeviceInfo(socket, clientIp, message);
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

    final client = _clients[clientIp];
    if (client != null) {
      // 通知上层进行同步
      onRemoteDataChanged?.call(clientIp, client.deviceInfo.deviceId);
    }
  }

  /// 处理同步请求
  Future<void> _handleSyncRequest(WebSocket socket, SyncMessage message) async {
    final since = message.data?['since'] as int? ?? 0;

    PMlog.d(_tag, '处理自 $since 以来的同步请求');

    try {
      // 获取变更数据
      final notes = await _repository.getNoteChanges(since);
      final categories = await _repository.getCategoryChanges(since);

      final changes = SyncDataMapper.combineChanges(
        notes: notes,
        categories: categories,
      );

      SyncProtocolHandler.send(
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
    _socketIps.removeWhere((k, v) => v == clientIp);
    final client = _clients.remove(clientIp);
    if (client != null) {
      PMlog.i(_tag, '❌ 设备断开连接: ${client.deviceInfo.deviceName}');
      onDeviceDisconnected?.call(clientIp, client.deviceInfo);
    }
  }

  /// 处理同步响应（当服务端作为请求方时）
  void _handleSyncResponse(String clientIp, SyncMessage message) {
    PMlog.d(_tag, 'Received sync response from $clientIp');

    final client = _clients[clientIp];
    if (client == null) {
      PMlog.w(_tag, 'Received sync response from unknown client: $clientIp');
      return;
    }

    final changes = message.data?['changes'] as List<dynamic>? ?? [];
    final typedChanges = changes.cast<Map<String, dynamic>>();

    final timestamp =
        (message.data?['timestamp'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;

    onSyncResponseReceived?.call(
      clientIp,
      client.deviceInfo.deviceId,
      typedChanges,
      timestamp,
    );
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
      SyncProtocolHandler.send(
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

    SyncProtocolHandler.send(
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
    SyncProtocolHandler.send(
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
    _notesSubscription = _repository.watchNotes().listen((_) {
      PMlog.d(_tag, '📤 Notes changed, notifying clients');
      _broadcastDataChanged();
    });

    // 监听 Categories 变化
    _categoriesSubscription = _repository.watchCategories().listen((_) {
      PMlog.d(_tag, '📤 Categories changed, notifying clients');
      _broadcastDataChanged();
    });
  }

  /// 广播数据变化通知给所有客户端
  void broadcastDataChanged() {
    _broadcastDataChanged();
  }

  /// 广播数据变化通知给所有客户端
  void _broadcastDataChanged() {
    final message = SyncMessage(
      type: SyncMessageType.dataChanged,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );

    for (final client in _clients.values) {
      SyncProtocolHandler.send(client.socket, message);
    }

    PMlog.d(_tag, 'Broadcast data_changed to ${_clients.length} clients');
  }
}
