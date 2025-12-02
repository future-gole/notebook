import 'package:dio/dio.dart';
import 'package:pocketmind/api/http_client.dart';
import 'package:pocketmind/util/logger_service.dart';

final String tag = "PageAnalysisService";

/// 页面分析服务
///
/// 负责调用后端 API 进行网页内容分析
class PageAnalysisService {
  final HttpClient _httpClient;

  PageAnalysisService(this._httpClient);

  /// 分析网页
  ///
  /// [userQuery] 用户查询/指令（例如："总结这个页面"）
  /// [url] 要分析的网页 URL
  /// [userEmail] 用户邮箱
  ///
  /// 返回分析结果
  Future<PageAnalysisResult> analyzePage({
    required String userQuery,
    required String url,
    required String userEmail,
  }) async {
    try {
      PMlog.d(tag, "开始分析页面: $url");
      PMlog.d(tag, "用户查询: $userQuery");

      final response = await _httpClient.post(
        '/api/mydemo/analyze',
        data: {'userQuery': userQuery, 'url': url, 'userEmail': userEmail},
      );

      if (response.statusCode == 200) {
        PMlog.d(tag, "页面分析成功");
        return PageAnalysisResult.fromJson(response.data);
      }

      throw HttpException('页面分析失败', response.statusCode);
    } on DioException catch (e) {
      PMlog.e(tag, "页面分析请求失败: ${e.message}");
      throw _handleDioError(e);
    } catch (e) {
      PMlog.e(tag, "页面分析发生未知错误: $e");
      rethrow;
    }
  }

  /// 处理 Dio 错误
  HttpException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HttpException('网络超时，请检查网络连接');
      case DioExceptionType.connectionError:
        return HttpException('网络连接失败，请检查网络');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return HttpException('未授权，请先登录');
        } else if (statusCode == 404) {
          return HttpException('API 接口不存在');
        } else if (statusCode == 500) {
          return HttpException('服务器内部错误');
        }
        return HttpException('请求失败 ($statusCode)');
      case DioExceptionType.cancel:
        return HttpException('请求已取消');
      default:
        return HttpException('未知错误');
    }
  }
}

/// 页面分析结果
///
/// 根据你的后端 API 响应格式进行调整
class PageAnalysisResult {
  /// 分析结果摘要
  final String summary;

  /// 详细分析内容（可选）
  final String? details;

  /// 关键词（可选）
  final List<String>? keywords;

  /// 分析时间戳
  final DateTime timestamp;

  /// 是否成功
  final bool success;

  /// 错误信息（如果有）
  final String? errorMessage;

  PageAnalysisResult({
    required this.summary,
    this.details,
    this.keywords,
    required this.timestamp,
    this.success = true,
    this.errorMessage,
  });

  /// 从 JSON 创建
  factory PageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PageAnalysisResult(
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String?,
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'] as List)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'details': details,
      'keywords': keywords,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}
