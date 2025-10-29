
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart'; // 用于 kReleaseMode

class LogService {
  // 使用单例模式，确保App中只有一个 Logger 实例
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

  late Logger _logger;

  LogService._internal() {
    _logger = Logger(
      // 1. 设置日志级别
      level: kReleaseMode ? Level.debug : Level.info,

      // 2. 设置打印格式
      printer: PrettyPrinter(
        methodCount: 1, // 只显示 1 层堆栈信息
        errorMethodCount: 8, // 错误时显示 8 层堆栈
        lineLength: 120, // 每行宽度
        colors: true, // 开启颜色
        printEmojis: true, // 开启 Emoji
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 打印时间戳
      ),

      // 3. (可选) 设置日志输出
      // 默认是 ConsoleOutput，你也可以自定义 Output，比如输出到文件
      // output: FileOutput(file: File('app.log')),
    );

    // 可以在这里打印一条启动日志
    i("Logger Service initialized. Mode: ${kReleaseMode ? 'Release' : 'Debug'}");
  }

  // 定义日志方法
  void v(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
final log = LogService();