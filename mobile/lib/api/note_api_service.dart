import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/api/api_constants.dart';
import 'package:pocketmind/api/http_client.dart';
import 'package:pocketmind/providers/http_providers.dart';

import '../util/logger_service.dart';

final noteApiServiceProvider = Provider<NoteApiService>((ref){
  // 从 ref 中获取统一的 httpClient
  final httpClient = ref.watch(httpClientProvider);
  return NoteApiService(httpClient);
});

final String tag = 'NoteApiService';

class NoteApiService{

  final HttpClient _http;
  NoteApiService(this._http);

  /// 分析网页/内容
  ///
  /// [userQuery] 用户查询/指令（例如："总结这个页面"）
  /// [webUrl] 要分析的网页 URL
  /// [userEmail] 用户邮箱
  ///
  /// 返回分析结果
  Future<void> analyzePage({
    required String userQuery,
    String? webUrl,
    required String userEmail,
  }) async {
      PMlog.d(tag, '开始分析页面: $webUrl, 用户查询: $userQuery');
      // 暂且后端没有返回
      final data = await _http.post(
        ApiConstants.analysis_service,
        data: {'userQuery': userQuery, 'url': webUrl, 'userEmail': userEmail},
      );
  }
}