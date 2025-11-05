import 'dart:convert';
import 'package:http/http.dart' as http;

/// 使用 LinkPreview.net API 的链接预览服务
/// 这个服务不受代理限制，直接访问第三方 API
class LinkPreviewApiService {
  static const String _apiKey = 'a7550aee7664cdd0a16233f8c1150c47';
  static const String _baseUrl = 'https://api.linkpreview.net';

  /// 获取链接的元数据
  static Future<ApiLinkMetadata> fetchMetadata(String url) async {
    try {
      print('🌐 使用 LinkPreview API 获取: $url');
      
      final apiUrl = '$_baseUrl/?key=$_apiKey&q=${Uri.encodeComponent(url)}';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('✅ API 返回成功: title=${data['title']}');
        
        return ApiLinkMetadata(
          title: data['title'],
          description: data['description'],
          imageUrl: data['image'],
          url: data['url'] ?? url,
        );
      } else {
        print('❌ API 返回错误: ${response.statusCode} - ${response.body}');
        return ApiLinkMetadata(url: url);
      }
    } catch (e) {
      print('❌ API 请求失败: $e');
      return ApiLinkMetadata(url: url);
    }
  }
}

/// API 链接元数据类
class ApiLinkMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  ApiLinkMetadata({
    this.title,
    this.description,
    this.imageUrl,
    required this.url,
  });

  bool get hasData =>
      (title != null && title!.isNotEmpty) ||
      (description != null && description!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}
