import 'package:flutter/services.dart';
import 'package:notebook/util/logger_service.dart';

/// 处理来自原生 Android ShareActivity 的分享数据
class ShareHandlerNative {
  static const String _tag = 'ShareHandlerNative';
  static const MethodChannel _channel = MethodChannel(
    'com.example.notebook/share',
  );

  static Function(String title, String content)? _onSharedContentReceived;
  static Function(String title, String content)? _onShowShareOverlay;

  /// 初始化并监听来自原生的分享数据
  static void initialize({
    required Function(String title, String content) onSharedContentReceived,
    Function(String title, String content)? onShowShareOverlay,
  }) {
    _onSharedContentReceived = onSharedContentReceived;
    _onShowShareOverlay = onShowShareOverlay;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'saveSharedContent') {
        await _handleSaveSharedContent(call.arguments);
      } else if (call.method == 'showShareOverlay') {
        await _handleShowShareOverlay(call.arguments);
      }
    });

    log.d(_tag, 'ShareHandlerNative initialized');
  }

  /// 处理显示分享覆盖层的请求
  static Future<void> _handleShowShareOverlay(dynamic arguments) async {
    try {
      if (arguments is Map) {
        final title = arguments['title'] as String? ?? '分享内容';
        final content = arguments['content'] as String? ?? '';

        log.d(
          _tag,
          'Show share overlay - Title: $title, Content length: ${content.length}',
        );

        if (content.isNotEmpty) {
          // 先保存内容
          if (_onSharedContentReceived != null) {
            await _onSharedContentReceived!(title, content);
            log.d(_tag, 'Content saved to database');
          }

          // 再显示覆盖层 UI
          if (_onShowShareOverlay != null) {
            _onShowShareOverlay!(title, content);
            log.d(_tag, 'Share overlay displayed');
          }
        } else {
          log.w(_tag, 'Content is empty');
        }
      } else {
        log.e(_tag, 'Invalid arguments type: ${arguments.runtimeType}');
      }
    } catch (e, stackTrace) {
      log.e(_tag, 'Error showing share overlay: $e\n$stackTrace');
    }
  }

  /// 处理保存分享内容的请求（保留向后兼容）
  static Future<void> _handleSaveSharedContent(dynamic arguments) async {
    try {
      if (arguments is Map) {
        final title = arguments['title'] as String? ?? '分享内容';
        final content = arguments['content'] as String? ?? '';

        log.d(
          _tag,
          'Received shared content - Title: $title, Content length: ${content.length}',
        );

        if (content.isNotEmpty && _onSharedContentReceived != null) {
          _onSharedContentReceived!(title, content);
          log.d(_tag, 'Shared content saved successfully');
        } else {
          log.w(_tag, 'Content is empty or handler is not set');
        }
      } else {
        log.e(_tag, 'Invalid arguments type: ${arguments.runtimeType}');
      }
    } catch (e, stackTrace) {
      log.e(_tag, 'Error handling shared content: $e\n$stackTrace');
    }
  }
}
