import 'dart:convert';
import 'package:dio/dio.dart';

import '../models/device_info.dart';
import '../models/sync_response.dart';
import '../../api/http_client.dart';
import '../../util/logger_service.dart';

/// 同步客户端
/// 
/// 使用 Dio 发起 HTTP 请求，从远程设备拉取同步数据
class SyncClient {
  static const String _tag = 'SyncClient';
  static const int defaultPort = 54321;

  final Dio _dio;

  /// 使用项目的 HttpClient 单例，或传入自定义 Dio 实例
  SyncClient({Dio? dio}) : _dio = dio ?? HttpClient().dio;

  /// 构建基础 URL
  String _baseUrl(String ip, {int port = defaultPort}) {
    return 'http://$ip:$port';
  }

  /// 获取远程设备信息（握手）
  Future<DeviceInfo?> getDeviceInfo(String ip, {int port = defaultPort}) async {
    try {
      final url = '${_baseUrl(ip, port: port)}/v1/info';
      log.d(_tag, 'Fetching device info from $url');

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final deviceInfo = DeviceInfo.fromJson(data);
        log.d(_tag, 'Got device info: $deviceInfo');
        return deviceInfo;
      }

      log.w(_tag, 'Failed to get device info: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      log.e(_tag, 'Dio error getting device info: ${e.message}');
      return null;
    } catch (e) {
      log.e(_tag, 'Error getting device info: $e');
      return null;
    }
  }

  /// 健康检查
  Future<bool> healthCheck(String ip, {int port = defaultPort}) async {
    try {
      final url = '${_baseUrl(ip, port: port)}/v1/health';
      final response = await _dio.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 拉取笔记变更
  Future<SyncResponse?> fetchNoteChanges(
    String ip, {
    int since = 0,
    int port = defaultPort,
  }) async {
    try {
      final url = '${_baseUrl(ip, port: port)}/v1/sync/notes';
      log.d(_tag, 'Fetching note changes from $url since $since');

      final response = await _dio.get(
        url,
        queryParameters: {'since': since.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final syncResponse = SyncResponse.fromJson(data);
        log.d(_tag, 'Got ${syncResponse.changeCount} note changes');
        return syncResponse;
      }

      log.w(_tag, 'Failed to fetch note changes: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      log.e(_tag, 'Dio error fetching note changes: ${e.message}');
      return null;
    } catch (e) {
      log.e(_tag, 'Error fetching note changes: $e');
      return null;
    }
  }

  /// 拉取分类变更
  Future<SyncResponse?> fetchCategoryChanges(
    String ip, {
    int since = 0,
    int port = defaultPort,
  }) async {
    try {
      final url = '${_baseUrl(ip, port: port)}/v1/sync/categories';
      log.d(_tag, 'Fetching category changes from $url since $since');

      final response = await _dio.get(
        url,
        queryParameters: {'since': since.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final syncResponse = SyncResponse.fromJson(data);
        log.d(_tag, 'Got ${syncResponse.changeCount} category changes');
        return syncResponse;
      }

      log.w(_tag, 'Failed to fetch category changes: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      log.e(_tag, 'Dio error fetching category changes: ${e.message}');
      return null;
    } catch (e) {
      log.e(_tag, 'Error fetching category changes: $e');
      return null;
    }
  }

  /// 拉取所有变更
  Future<SyncResponse?> fetchAllChanges(
    String ip, {
    int since = 0,
    int port = defaultPort,
  }) async {
    try {
      final url = '${_baseUrl(ip, port: port)}/v1/sync/changes';
      log.d(_tag, 'Fetching all changes from $url since $since');

      final response = await _dio.get(
        url,
        queryParameters: {'since': since.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final syncResponse = SyncResponse.fromJson(data);
        log.d(_tag, 'Got ${syncResponse.changeCount} total changes');
        return syncResponse;
      }

      log.w(_tag, 'Failed to fetch all changes: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      log.e(_tag, 'Dio error fetching all changes: ${e.message}');
      return null;
    } catch (e) {
      log.e(_tag, 'Error fetching all changes: $e');
      return null;
    }
  }

  /// 扫描局域网中的设备
  /// 
  /// 扫描指定子网中的所有 IP，尝试获取设备信息
  Future<List<DeviceInfo>> scanNetwork(
    String subnet, {
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 2),  // 增加超时时间
  }) async {
    log.i(_tag, '=== Network Scan Started ===');
    log.i(_tag, 'Subnet: $subnet.*');
    log.i(_tag, 'Port: $port');
    log.i(_tag, 'Timeout: ${timeout.inMilliseconds}ms');
    
    final devices = <DeviceInfo>[];
    final futures = <Future<DeviceInfo?>>[];
    int successCount = 0;

    // 创建临时 Dio 实例，使用更短的超时时间用于扫描
    final scanDio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
    ));

    // 扫描 1-254
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_scanHost(scanDio, ip, port).then((device) {
        if (device != null) {
          successCount++;
          log.i(_tag, '✅ Found device at $ip: ${device.deviceName}');
        }
        return device;
      }));
    }

    // 并发执行扫描
    log.i(_tag, 'Scanning 254 hosts concurrently...');
    final results = await Future.wait(futures);
    
    for (final device in results) {
      if (device != null) {
        devices.add(device);
      }
    }

    log.i(_tag, '=== Network Scan Completed ===');
    log.i(_tag, 'Found: ${devices.length} devices');
    log.i(_tag, 'Success responses: $successCount');
    log.i(_tag, '==============================');
    
    return devices;
  }

  /// 扫描单个主机
  Future<DeviceInfo?> _scanHost(Dio dio, String ip, int port) async {
    try {
      final url = 'http://$ip:$port/v1/info';
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        log.d(_tag, 'Got response from $ip: $data');
        return DeviceInfo.fromJson({
          ...data,
          'ipAddress': ip,
        });
      }
    } on DioException catch (e) {
      // 只记录非超时错误（超时是正常的，表示该IP没有服务）
      if (e.type != DioExceptionType.connectionTimeout && 
          e.type != DioExceptionType.receiveTimeout &&
          e.type != DioExceptionType.connectionError) {
        log.d(_tag, 'Unexpected error scanning $ip: ${e.type} - ${e.message}');
      }
    } catch (e) {
      log.d(_tag, 'Error scanning $ip: $e');
    }
    return null;
  }

  /// 关闭客户端
  void close() {
    _dio.close();
  }
}
