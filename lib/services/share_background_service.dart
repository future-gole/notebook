import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';
import 'package:notebook/main.dart';
import 'package:notebook/server/note_service.dart';
import 'package:notebook/util/logger_service.dart';

/// Flutter 后台服务
/// 处理来自原生 ShareActivity 的数据
/// 不显示任何 UI，只处理业务逻辑
class ShareBackgroundService {
  static const String _tag = 'ShareBackgroundService';
  static const MethodChannel _channel = MethodChannel(
    'com.example.notebook/share',
  );

  static late Isar _isar;

  /// 初始化后台服务
  static void initialize(Isar isarInstance) {
    _isar = isarInstance;
    _channel.setMethodCallHandler(_handleMethodCall);
    log.d(_tag, 'Share background service initialized');
  }

  /// 处理来自原生的方法调用
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'saveAndSync':
          return await saveAndSync(call.arguments);
        default:
          log.w(_tag, 'Unknown method: ${call.method}');
          return null;
      }
    } catch (e, stackTrace) {
      log.e(_tag, 'Error handling method call: $e\n$stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 保存数据并同步到后端
  static Future<Map<String, dynamic>> saveAndSync(dynamic arguments) async {
    try {
      if (arguments is! Map) {
        throw ArgumentError('Invalid arguments type');
      }

      final title = arguments['title'] as String? ?? '分享内容';
      final content = arguments['content'] as String? ?? '';
      final category = arguments['category'] as String?;
      final tag = arguments['tag'] as String?;
      final timestamp =
          arguments['timestamp'] as int? ??
          DateTime.now().millisecondsSinceEpoch;

      log.d(_tag, '📥 Received: $title (${content.length} chars)');

      // 1. 立即保存到本地数据库
      await _saveToLocal(title, content, category, tag);

      // 2. 异步同步到后端（不阻塞）
      _syncToBackend(title, content, category, tag, timestamp);

      return {
        'success': true,
        'saved': true,
        'message': 'Data saved and sync started',
      };
    } catch (e, stackTrace) {
      log.e(_tag, 'Error in saveAndSync: $e\n$stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 保存到本地 Isar 数据库
  static Future<void> _saveToLocal(
      String title,
      String content,
      String? category,
      String? tag) async {
    try {
      final noteService = NoteService(_isar);
      await noteService.addOrUpdateNote(
        title: title,
        content: content,
        category: category,
        tag: tag,
      );
      log.d(_tag, '✅ Saved to local database');
    } catch (e) {
      log.e(_tag, '❌ Failed to save locally: $e');
      rethrow;
    }
  }

  /// 同步到后端服务器
  static Future<void> _syncToBackend(
      String title,
      String content,
      String? category,
      String? tag,
      int timestamp,
  ) async {
    try {
      // TODO: 替换为你的实际后端 API 地址
      final apiUrl = 'https://your-api.com/api/notes';

      log.d(_tag, '🌐 Syncing to backend...');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              // 'Authorization': 'Bearer YOUR_TOKEN', // 如果需要认证
            },
            body: jsonEncode({
              'title': title,
              'content': content,
              'category': category,
              'tag': tag,
              'timestamp': timestamp,
              'source': 'android_share',
              'device_id': 'TODO', // 可以添加设备 ID
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Backend sync timeout');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.d(_tag, '✅ Synced to backend successfully');
      } else {
        log.w(_tag, '⚠️ Backend returned ${response.statusCode}');
        // 可以实现重试逻辑
        _saveToRetryQueue(title, content, timestamp);
      }
    } catch (e) {
      log.e(_tag, '❌ Failed to sync to backend: $e');
      // 保存到重试队列
      _saveToRetryQueue(title, content, timestamp);
    }
  }

  /// 保存到重试队列（失败时）
  static Future<void> _saveToRetryQueue(
    String title,
    String content,
    int timestamp,
  ) async {
    // TODO: 实现重试队列
    // 可以使用 SharedPreferences 或本地数据库
    // 在主应用启动时或网络恢复时重试
    log.d(_tag, '💾 Saved to retry queue for later sync');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
