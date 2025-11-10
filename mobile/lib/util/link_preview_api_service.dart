import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pocketmind/providers/http_providers.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/logger_service.dart';

import 'http_client.dart';

// 1. 定义 Provider
final linkPreviewServiceProvider = Provider<LinkPreviewApiService>((ref) {
  // 从 ref 中获取统一的 httpClient
  final httpClient = ref.watch(httpClientProvider);
  return LinkPreviewApiService(httpClient);
});

/// 使用 LinkPreview.net API 的链接预览服务
/// 这个服务不受代理限制，直接访问第三方 API
/// 但是图片的预览还是需要开启代理
final String tag = "LinkPreviewApiService";

class LinkPreviewApiService {
  static const String _baseUrl = 'https://api.linkpreview.net';

  final HttpClient _http;
  LinkPreviewApiService(this._http);

  /// 获取链接的元数据
  Future<ApiLinkMetadata> fetchMetadata(String url) async {
    try {
      // 从配置中获取 API Key
      final config = AppConfig();
      final apiKey = config.linkPreviewApiKey;

      final apiUrl = '$_baseUrl/?key=$apiKey&q=${Uri.encodeComponent(url)}';

      final response = await _http.get(apiUrl);

      final data = json.decode(response.data);

      return ApiLinkMetadata(
          title: data['title'],
          description: data['description'],
          imageUrl: data['image'],
          url: data['url'] ?? url,
          success: true,
        );
      }on DioException catch (e) {
        // 捕获 Dio 特有的异常
        // 如果有响应数据，通常在 e.response 中
        if (e.response != null) {
          log.e(tag, '❌ API 返回错误: ${e.response?.statusCode} - ${e.response?.data}');
        } else {
          log.e(tag, '❌ API 请求失败 (网络或超时): ${e.message}');
        }
        return ApiLinkMetadata(url: url, success: false);
      } catch (e) {
        // 捕获其他未知异常
        log.e(tag, '❌ 未知错误: $e');
        return ApiLinkMetadata(url: url, success: false);
      }
  }
}

/// API 链接元数据类
class ApiLinkMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;
  final bool success;

  ApiLinkMetadata({
    this.title,
    this.description,
    this.imageUrl,
    required this.url,
    required this.success,
  });

  bool get hasData =>
      (title != null && title!.isNotEmpty) ||
      (description != null && description!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}
