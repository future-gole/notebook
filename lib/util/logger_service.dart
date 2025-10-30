import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:logger/logger.dart'; // 导入 developer 库

class DeveloperLogOutput extends LogOutput {

  static const MethodChannel _androidLogChannel = MethodChannel('com.example.notebook/logger');

  @override
  void output(OutputEvent event) {
    dynamic message = event.lines.join('\n'); // 默认消息是行列表
    String tag = 'noteBook'; // 默认 tag

    // 从 LogEvent 中解析出原始的 Map 消息
    if (event.origin.message is Map) {
      final msgMap = event.origin.message as Map;
      if (msgMap.containsKey('tag') && msgMap.containsKey('msg')) {
        tag = msgMap['tag'] as String;
        message = msgMap['msg'];
      }
    }

    // 将 logger 的 Level 转换为 developer.log 的 level (int)
    int level = 0;
    switch (event.level) {
      case Level.debug:
        level = 500; // Debug
        break;
      case Level.info:
        level = 800; // Info
        break;
      case Level.warning:
        level = 900; // Warning
        break;
      case Level.error:
        level = 1000; // Error
        break;
      case Level.fatal:
        level = 1200; // Fatal / Alert
        break;
      default:
        level = 500;
    }

    // 调试阶段，非 Android 仍通过 developer.log 方便 IDE 查看。
    if (!Platform.isAndroid) {
      developer.log(
        message.toString(),
        name: tag,
        level: level,
        error: event.origin.error,
        stackTrace: event.origin.stackTrace,
        time: event.origin.time,
      );
    }

    final error = event.origin.error;
    final stack = event.origin.stackTrace;
    final levelLabel = _levelLabel(event.level);

    if (Platform.isAndroid) {
      _sendToAndroidLog(
        tag: tag,
        level: levelLabel,
        message: message.toString(),
        error: error,
        stackTrace: stack,
      );
      return;
    }

    // 非 Android (或 Android 通道不可用) 时退回到 debugPrint，至少保证能看到日志。
    final lines = message.toString().split('\n');
    for (final line in lines) {
      debugPrint('[${tag}] [$levelLabel] ${line.trim()}');
    }
    if (error != null) {
      debugPrint('[${tag}] [$levelLabel] error: ${error.toString()}');
    }
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }

  String _levelLabel(Level level) {
    switch (level) {
      case Level.verbose:
        return 'VERBOSE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'DEBUG';
    }
  }

  void _sendToAndroidLog({
    required String tag,
    required String level,
    required String message,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final payload = <String, dynamic>{
      'tag': tag,
      'level': level,
      'message': message,
    };

    if (error != null) {
      payload['error'] = error.toString();
    }
    if (stackTrace != null) {
      payload['stackTrace'] = stackTrace.toString();
    }

    _androidLogChannel.invokeMethod<void>('log', payload).catchError((e, _) {
      final fallbackLines = message.split('\n');
      for (final line in fallbackLines) {
        debugPrint('[${tag}] [$level] ${line.trim()}');
      }
      if (error != null) {
        debugPrint('[${tag}] [$level] error: ${error.toString()}');
      }
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
      debugPrint('Logger Android channel error: ${e.toString()}');
    });
  }
}

// 2. LogService 类 (配置变化)
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

  late Logger _logger;

  LogService._internal() {
    _logger = Logger(
      // 1. 设置过滤级别
      level: kReleaseMode ? Level.info : Level.verbose,

      printer: SimplePrinter(
        colors: true,
      ),

      output: DeveloperLogOutput(),
    );

    // 打印一条启动日志
    i("LogService", "Logger Service initialized. Mode: ${kReleaseMode ? 'Release' : 'Debug'}");
  }

  // 4. 封装的日志方法
  void v(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.v({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }

  void d(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }

  void i(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }

  void w(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }

  void e(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }

  void wtf(String tag, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f({"tag": tag, "msg": message}, error: error, stackTrace: stackTrace);
  }
}

// 5. 全局访问实例 (不变)
final log = LogService();