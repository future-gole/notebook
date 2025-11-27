import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:isar_community/isar.dart';

import '../models/device_info.dart';
import '../models/sync_response.dart';
import '../mappers/sync_data_mapper.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';

/// 同步服务端
/// 
/// 使用 Shelf 框架实现的轻量级 HTTP 服务器
/// 监听局域网请求，响应数据同步请求
class SyncServer {
  static const String _tag = 'SyncServer';
  static const int defaultPort = 54321;

  final Isar _isar;
  final DeviceInfo _deviceInfo;
  final int _port;

  HttpServer? _server;
  bool _isRunning = false;

  SyncServer({
    required Isar isar,
    required DeviceInfo deviceInfo,
    int port = defaultPort,
  })  : _isar = isar,
        _deviceInfo = deviceInfo,
        _port = port;

  /// 服务器是否正在运行
  bool get isRunning => _isRunning;

  /// 服务器端口
  int get port => _port;

  /// 启动服务器
  Future<void> start() async {
    if (_isRunning) {
      log.w(_tag, 'Server is already running on port $_port');
      return;
    }

    try {
      final router = _createRouter();
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        _port,
      );

      _isRunning = true;
      
      // 详细日志：显示所有网络接口
      log.i(_tag, '=== Sync Server Started ===');
      log.i(_tag, 'Listening on: ${_server!.address.address}:${_server!.port}');
      log.i(_tag, 'Device ID: ${_deviceInfo.deviceId}');
      log.i(_tag, 'Device Name: ${_deviceInfo.deviceName}');
      
      // 列出所有可用的网络接口
      try {
        final interfaces = await NetworkInterface.list();
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              log.i(_tag, 'Available at: http://${addr.address}:$_port/v1/info');
            }
          }
        }
      } catch (e) {
        log.w(_tag, 'Could not list network interfaces: $e');
      }
      log.i(_tag, '===========================');
    } catch (e) {
      log.e(_tag, 'Failed to start sync server: $e');
      rethrow;
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    if (!_isRunning || _server == null) {
      return;
    }

    try {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
      log.i(_tag, 'Sync server stopped');
    } catch (e) {
      log.e(_tag, 'Failed to stop sync server: $e');
      rethrow;
    }
  }

  /// 创建路由
  Router _createRouter() {
    final router = Router();

    // 设备信息接口 - 用于握手
    router.get('/v1/info', _handleInfo);

    // 获取变更数据 - 笔记
    router.get('/v1/sync/notes', _handleSyncNotes);

    // 获取变更数据 - 分类
    router.get('/v1/sync/categories', _handleSyncCategories);

    // 获取所有变更数据
    router.get('/v1/sync/changes', _handleSyncAll);

    // 健康检查
    router.get('/v1/health', _handleHealth);

    return router;
  }

  /// 处理设备信息请求
  Response _handleInfo(Request request) {
    return Response.ok(
      jsonEncode(_deviceInfo.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 处理健康检查
  Response _handleHealth(Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'timestamp': DateTime.now().millisecondsSinceEpoch}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 处理笔记同步请求
  Future<Response> _handleSyncNotes(Request request) async {
    try {
      final sinceStr = request.url.queryParameters['since'];
      final since = sinceStr != null ? int.tryParse(sinceStr) ?? 0 : 0;

      // 查询 updatedAt 大于 since 的笔记（包括已删除的，以便同步删除操作）
      final notes = await _isar.notes
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      final changes = SyncDataMapper.notesToJsonList(notes);

      final response = SyncResponse(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        changes: changes,
        entityType: 'note',
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      log.e(_tag, 'Failed to handle sync notes: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// 处理分类同步请求
  Future<Response> _handleSyncCategories(Request request) async {
    try {
      final sinceStr = request.url.queryParameters['since'];
      final since = sinceStr != null ? int.tryParse(sinceStr) ?? 0 : 0;

      // 查询 updatedAt 大于 since 的分类（包括已删除的）
      final categories = await _isar.categorys
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      final changes = SyncDataMapper.categoriesToJsonList(categories);

      final response = SyncResponse(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        changes: changes,
        entityType: 'category',
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      log.e(_tag, 'Failed to handle sync categories: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// 处理全部数据同步请求
  Future<Response> _handleSyncAll(Request request) async {
    try {
      final sinceStr = request.url.queryParameters['since'];
      final since = sinceStr != null ? int.tryParse(sinceStr) ?? 0 : 0;

      // 获取笔记变更（使用 updatedAt 过滤，包括已删除的）
      final notes = await _isar.notes
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      // 获取分类变更
      final categories = await _isar.categorys
          .filter()
          .updatedAtGreaterThan(since)
          .findAll();

      final changes = SyncDataMapper.combineChanges(
        notes: notes,
        categories: categories,
      );

      final response = SyncResponse(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        changes: changes,
        entityType: 'all',
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      log.e(_tag, 'Failed to handle sync all: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// CORS 中间件
  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };
}
