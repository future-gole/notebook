import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/api/http_client.dart';

import 'infrastructure_providers.dart';

/// HttpClient Provider
///
/// 提供全局单例的 HTTP 客户端，会根据环境配置自动设置 baseUrl
final httpClientProvider = Provider<HttpClient>((ref) {
  final httpClient = HttpClient();
  // 从 AppConfig 获取当前环境的 baseUrl
  final config = ref.read(appConfigProvider);
  httpClient.dio.options.baseUrl = config.baseUrl;
  return httpClient;
});
