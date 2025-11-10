import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/server/page_analysis_service.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/http_client.dart';

/// HttpClient Provider
///
/// 提供全局单例的 HTTP 客户端，会根据环境配置自动设置 baseUrl
final httpClientProvider = Provider<HttpClient>((ref) {
  final httpClient = HttpClient();
  // 从 AppConfig 获取当前环境的 baseUrl
  final baseUrl = AppConfig().baseUrl;
  httpClient.dio.options.baseUrl = baseUrl;
  return httpClient;
});

/// PageAnalysisService Provider
///
/// 提供页面分析服务
final pageAnalysisServiceProvider = Provider<PageAnalysisService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return PageAnalysisService(httpClient);
});
