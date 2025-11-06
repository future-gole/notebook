import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/logger_service.dart';
/// 使用 LinkPreview.net API 的链接预览服务
/// 这个服务不受代理限制，直接访问第三方 API
/// 但是图片的预览还是需要开启代理
final String tag = "LinkPreviewApiService";
class LinkPreviewApiService {
  static const String _baseUrl = 'https://api.linkpreview.net';

  /// 获取链接的元数据
  static Future<ApiLinkMetadata> fetchMetadata(String url) async {
    try {
      // 从配置中获取 API Key
      final config = AppConfig();
      final apiKey = config.linkPreviewApiKey;
      
      final apiUrl = '$_baseUrl/?key=$apiKey&q=${Uri.encodeComponent(url)}';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return ApiLinkMetadata(
          title: data['title'],
          description: data['description'],
          imageUrl: data['image'],
          url: data['url'] ?? url,
          success: true,
        );
      } else {
        log.e(tag,'❌ API 返回错误: ${response.statusCode} - ${response.body}');
        return ApiLinkMetadata(url: url, success: false);
      }
    } catch (e) {
      log.e(tag,'❌ API 请求失败: $e');
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
