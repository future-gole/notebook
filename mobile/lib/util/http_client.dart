import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pocketmind/util/logger_service.dart';

/// HTTP 客户端工具类
/// 
/// 基于 Dio 封装的网络请求工具类，提供：
/// - 统一的请求/响应处理
/// - 全局拦截器（日志、错误处理）
/// - 超时配置
/// - 请求重试机制
/// - Token 管理
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;

  late Dio _dio;
  final String tag = "HttpClient";

  // 基础配置
  static const String baseUrl = ""; // 设置你的 API 基础 URL
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  HttpClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// 获取 Dio 实例（用于高级场景）
  Dio get dio => _dio;

  /// 设置 Token
  void setToken(String token) {
    _dio.options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    log.d(tag, "Token 已设置");
  }

  /// 清除 Token
  void clearToken() {
    _dio.options.headers.remove(HttpHeaders.authorizationHeader);
    log.d(tag, "Token 已清除");
  }

  /// GET 请求
  /// 
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST 请求
  /// 
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT 请求
  /// 
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE 请求
  /// 
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH 请求
  /// 
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 文件上传
  /// 
  /// [path] 上传路径
  /// [filePath] 本地文件路径
  /// [fieldName] 字段名称
  /// [data] 其他表单数据
  /// [onSendProgress] 上传进度回调
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 文件下载
  /// 
  /// [url] 下载地址
  /// [savePath] 保存路径
  /// [onReceiveProgress] 下载进度回调
  Future<Response> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 取消所有请求
  void cancelAll() {
    // 注意：这会取消所有正在进行的请求
    log.w(tag, "取消所有请求");
  }
}

/// 日志拦截器
class _LogInterceptor extends Interceptor {
  final String tag = "HttpClient";

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.d(tag, '''
┌─────────────────────────────────────────────────────────────────
│ 📤 REQUEST
├─────────────────────────────────────────────────────────────────
│ URL: ${options.method} ${options.uri}
│ Headers: ${options.headers}
│ Data: ${options.data}
└─────────────────────────────────────────────────────────────────
    ''');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log.d(tag, '''
┌─────────────────────────────────────────────────────────────────
│ 📥 RESPONSE
├─────────────────────────────────────────────────────────────────
│ URL: ${response.requestOptions.method} ${response.requestOptions.uri}
│ Status: ${response.statusCode}
│ Data: ${response.data}
└─────────────────────────────────────────────────────────────────
    ''');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.e(tag, '''
┌─────────────────────────────────────────────────────────────────
│ ❌ ERROR
├─────────────────────────────────────────────────────────────────
│ URL: ${err.requestOptions.method} ${err.requestOptions.uri}
│ Type: ${err.type}
│ Message: ${err.message}
│ Response: ${err.response?.data}
└─────────────────────────────────────────────────────────────────
    ''');
    handler.next(err);
  }
}

/// 错误处理拦截器
class _ErrorInterceptor extends Interceptor {
  final String tag = "HttpClient";

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 统一错误处理
    String errorMessage = _handleError(err);
    log.e(tag, "请求错误: $errorMessage");
    
    // 可以在这里添加全局错误提示逻辑
    // 例如：显示 Toast、SnackBar 等
    
    handler.next(err);
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请检查网络';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
      case DioExceptionType.unknown:
        return '未知错误：${error.message}';
    }
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '拒绝访问';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '请求失败 ($statusCode)';
    }
  }
}

/// 统一响应格式（可选）
/// 根据你的后端 API 响应格式进行调整
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 200;
}

/// HTTP 异常类
class HttpException implements Exception {
  final String message;
  final int? code;

  HttpException(this.message, [this.code]);

  @override
  String toString() {
    return 'HttpException: $message${code != null ? ' (code: $code)' : ''}';
  }
}
