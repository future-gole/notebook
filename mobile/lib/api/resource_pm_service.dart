import 'package:pocketmind/api/api_constants.dart';
import 'package:pocketmind/api/http_client.dart';
import 'package:pocketmind/api/models/resource_models.dart';
import 'package:pocketmind/util/logger_service.dart';

final String _tag = 'ResourcePmService';

class ResourcePmService {
  final HttpClient _http;

  ResourcePmService(this._http);

  /// 提交资源抓取请求（分享页只做 submit）
  Future<bool> submit({required String url}) async {
    try {
      final req = ResourceSubmitRequest(url: url);
      await _http.post(ApiConstants.resourceSubmit, data: req.toJson());
      return true;
    } catch (e) {
      PMlog.e(_tag, 'submit failed: $e');
      return false;
    }
  }

  /// 批量查询资源状态（按 url）
  Future<List<ResourceStatusItem>> statusByUrls(List<String> urls) async {
    try {
      final req = ResourceStatusRequest(urls: urls);
      final list = await _http.post<List<dynamic>>(
        ApiConstants.resourceStatus,
        data: req.toJson(),
      );
      return list
          .whereType<Map<String, dynamic>>()
          .map(ResourceStatusItem.fromJson)
          .toList();
    } catch (e) {
      PMlog.e(_tag, 'statusByUrls failed: $e');
      return [];
    }
  }
}
