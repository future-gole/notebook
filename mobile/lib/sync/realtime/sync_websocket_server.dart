import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isar_community/isar.dart';

import '../mappers/sync_data_mapper.dart';
import '../models/device_info.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';

/// WebSocket 消息类型
class SyncMessageType {
  static const String hello = 'hello';           // 握手
  static const String deviceInfo = 'device_info'; // 设备信息
  static const String dataChanged = 'data_changed'; // 数据变化通知
  static const String syncRequest = 'sync_request'; // 请求同步
  static const String syncResponse = 'sync_response'; // 同步响应
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String serverShutdown = 'server_shutdown'; // 服务器即将关闭
}

/// 同步 WebSocket 消息
class SyncMessage {
  final String type;
  final Map<String, dynamic>? data;
  final int timestamp;

  SyncMessage({
    required this.type,
    this.data,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

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
  void Function(DeviceInfo device)? onDeviceConnected;
  
  /// 当设备断开连接时的回调
  void Function(DeviceInfo device)? onDeviceDisconnected;
  
  /// 当收到远程数据变化时的回调
  void Function()? onRemoteDataChanged;

  SyncWebSocketServer({
    required Isar isar,
    required DeviceInfo localDevice,
    int port = defaultPort,
  })  : _isar = isar,
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
      log.w(_tag, 'WebSocket server already running');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;
      
      log.i(_tag, '=== WebSocket Server Started ===');
      log.i(_tag, 'Listening on port: $_port');
      
      // 监听连接
      _server!.listen(_handleConnection);
      
      // 开始监听数据库变化
      _startDatabaseWatchers();
      
      log.i(_tag, '================================');
    } catch (e) {
      log.e(_tag, 'Failed to start WebSocket server: $e');
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
        log.w(_tag, 'Failed to send shutdown notification: $e');
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
    
    log.i(_tag, 'WebSocket server stopped');
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
      final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
      
      log.i(_tag, 'New WebSocket connection from: $clientIp');
      
      // 发送欢迎消息（包含本机设备信息）
      _sendMessage(socket, SyncMessage(
        type: SyncMessageType.hello,
        data: _localDevice.toJson(),
      ));
      
      // 监听客户端消息
      socket.listen(
        (data) => _handleMessage(socket, clientIp, data),
        onDone: () => _handleDisconnect(clientIp),
        onError: (e) {
          log.e(_tag, 'WebSocket error from $clientIp: $e');
          _handleDisconnect(clientIp);
        },
      );
    } catch (e) {
      log.e(_tag, 'Failed to upgrade WebSocket: $e');
    }
  }

  /// 处理客户端消息
  void _handleMessage(WebSocket socket, String clientIp, dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = SyncMessage.fromJson(json);
      
      log.d(_tag, 'Received message from $clientIp: ${message.type}');
      
      switch (message.type) {
        case SyncMessageType.deviceInfo:
          _handleDeviceInfo(socket, clientIp, message);
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
      }
    } catch (e) {
      log.e(_tag, 'Failed to handle message: $e');
    }
  }

  /// 处理设备信息
  void _handleDeviceInfo(WebSocket socket, String clientIp, SyncMessage message) {
    if (message.data == null) return;
    
    final deviceInfo = DeviceInfo.fromJson(message.data!);
    
    // 保存客户端信息
    _clients[clientIp] = ConnectedClient(
      socket: socket,
      deviceInfo: deviceInfo,
    );
    
    log.i(_tag, '✅ Device registered: ${deviceInfo.deviceName} ($clientIp)');
    
    // 通知回调
    onDeviceConnected?.call(deviceInfo);
  }

  /// 处理数据变化通知
  void _handleDataChanged(String clientIp, SyncMessage message) {
    log.i(_tag, '📥 Data changed notification from $clientIp');
    
    // 通知上层进行同步
    onRemoteDataChanged?.call();
  }

  /// 处理同步请求
  Future<void> _handleSyncRequest(WebSocket socket, SyncMessage message) async {
    final since = message.data?['since'] as int? ?? 0;
    
    log.d(_tag, 'Handling sync request since: $since');
    
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
      
      _sendMessage(socket, SyncMessage(
        type: SyncMessageType.syncResponse,
        data: {
          'changes': changes,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ));
    } catch (e) {
      log.e(_tag, 'Failed to handle sync request: $e');
    }
  }

  /// 处理断开连接
  void _handleDisconnect(String clientIp) {
    final client = _clients.remove(clientIp);
    if (client != null) {
      log.i(_tag, '❌ Device disconnected: ${client.deviceInfo.deviceName}');
      onDeviceDisconnected?.call(client.deviceInfo);
    }
  }

  /// 开始监听数据库变化
  void _startDatabaseWatchers() {
    // 监听 Notes 变化
    _notesSubscription = _isar.notes.watchLazy().listen((_) {
      log.d(_tag, '📤 Notes changed, notifying clients');
      _broadcastDataChanged();
    });
    
    // 监听 Categories 变化
    _categoriesSubscription = _isar.categorys.watchLazy().listen((_) {
      log.d(_tag, '📤 Categories changed, notifying clients');
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
    
    log.d(_tag, 'Broadcast data_changed to ${_clients.length} clients');
  }

  /// 发送消息
  void _sendMessage(WebSocket socket, SyncMessage message) {
    try {
      socket.add(message.toJsonString());
    } catch (e) {
      log.e(_tag, 'Failed to send message: $e');
    }
  }
}
