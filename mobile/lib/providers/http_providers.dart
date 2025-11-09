import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/util/http_client.dart';

/// HttpClient Provider
/// 
/// 提供全局单例的 HTTP 客户端
final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient();
});
