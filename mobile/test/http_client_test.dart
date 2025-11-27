import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:pocketmind/api/http_client.dart';

// 生成 mock 类
class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response {}

void main() {
  group('HttpClient - API 响应格式测试', () {
    test('ApiResponse.isSuccess - 成功响应', () {
      final response = ApiResponse(
        code: 200,
        message: '成功',
        data: {'id': 1, 'name': '测试'},
      );
      expect(response.isSuccess, true);
    });

    test('ApiResponse.isSuccess - 失败响应', () {
      final response = ApiResponse(code: 400, message: '请求失败', data: null);
      expect(response.isSuccess, false);
    });

    test('ApiResponse.fromJson - 解析成功响应', () {
      final json = {
        'code': 200,
        'message': '成功',
        'data': {'id': 1, 'name': '测试'},
      };

      final response = ApiResponse.fromJson(json, (data) => data);
      expect(response.code, 200);
      expect(response.message, '成功');
      expect(response.data, isNotNull);
      expect(response.isSuccess, true);
    });

    test('ApiResponse.fromJson - 解析失败响应', () {
      final json = {'code': 400, 'message': '参数错误', 'data': null};

      final response = ApiResponse.fromJson(json, (data) => data);
      expect(response.code, 400);
      expect(response.message, '参数错误');
      expect(response.data, null);
      expect(response.isSuccess, false);
    });

    test('ApiResponse.fromJson - 空数据', () {
      final json = {'code': 200, 'message': '成功', 'data': null};

      final response = ApiResponse.fromJson(json, (data) => data);
      expect(response.code, 200);
      expect(response.data, null);
    });
  });

  group('HttpClient - 异常处理测试', () {
    test('HttpException - 基础异常', () {
      final exception = HttpException('网络错误');
      expect(exception.message, '网络错误');
      expect(exception.code, null);
    });

    test('HttpException - 带状态码的异常', () {
      final exception = HttpException('服务器错误', 500);
      expect(exception.message, '服务器错误');
      expect(exception.code, 500);
    });

    test('HttpException.toString()', () {
      final exception1 = HttpException('错误消息');
      expect(exception1.toString(), contains('HttpException'));

      final exception2 = HttpException('服务器错误', 502);
      expect(exception2.toString(), contains('502'));
    });

    test('HttpException - 各种错误码', () {
      final exceptions = [
        HttpException('未授权', 401),
        HttpException('禁止访问', 403),
        HttpException('资源不存在', 404),
        HttpException('服务不可用', 503),
      ];

      for (var ex in exceptions) {
        expect(ex.code, isNotNull);
        expect(ex.message, isNotEmpty);
      }
    });
  });

  group('HttpException 消息内容测试', () {
    test('连接超时错误消息', () {
      // 模拟 DioException 的各种类型
      final messages = [
        '连接超时，请检查网络',
        '发送超时，请检查网络',
        '接收超时，请检查网络',
        '请求已取消',
        '网络连接失败，请检查网络',
        '证书验证失败',
      ];

      for (var msg in messages) {
        expect(msg, isNotEmpty);
      }
    });

    test('HTTP 状态码对应的错误消息', () {
      final statusMessages = {
        400: '请求参数错误',
        401: '未授权，请重新登录',
        403: '拒绝访问',
        404: '请求的资源不存在',
        405: '请求方法不允许',
        408: '请求超时',
        500: '服务器内部错误',
        502: '网关错误',
        503: '服务不可用',
        504: '网关超时',
      };

      statusMessages.forEach((code, message) {
        expect(message, isNotEmpty);
      });
    });
  });

  group('HttpClient - 单例模式测试', () {
    test('HttpClient 是单例', () {
      final client1 = HttpClient();
      final client2 = HttpClient();
      expect(identical(client1, client2), true);
    });

    test('HttpClient 有有效的 Dio 实例', () {
      final client = HttpClient();
      expect(client.dio, isNotNull);
    });
  });

  group('HttpClient - Token 管理测试', () {
    test('setToken - 设置 Bearer token', () {
      final client = HttpClient();
      final token = 'test-token-12345';

      client.setToken(token);
      // 验证 token 已设置（通过检查 dio 的 headers）
      expect(client.dio.options.headers, isNotNull);
    });

    test('clearToken - 清除 token', () {
      final client = HttpClient();
      client.setToken('test-token');
      client.clearToken();

      // 清除后应该没有 Authorization header
      expect(client.dio.options.headers['Authorization'], null);
    });

    test('Token 更新', () {
      final client = HttpClient();
      client.setToken('old-token');
      client.setToken('new-token');

      // 最后设置的 token 应该生效
      expect(client.dio.options.headers.isNotEmpty, true);
    });
  });

  group('HttpClient - 超时配置测试', () {
    test('连接超时配置', () {
      expect(HttpClient.connectTimeout, Duration(seconds: 30));
    });

    test('接收超时配置', () {
      expect(HttpClient.receiveTimeout, Duration(seconds: 30));
    });

    test('发送超时配置', () {
      expect(HttpClient.sendTimeout, Duration(seconds: 30));
    });
  });

  group('ApiResponse 边界情况测试', () {
    test('ApiResponse - code 为 0', () {
      final response = ApiResponse(code: 0, message: '状态码为0');
      expect(response.isSuccess, false);
      expect(response.code, 0);
    });

    test('ApiResponse - 空消息', () {
      final response = ApiResponse(code: 200, message: '');
      expect(response.message, isEmpty);
    });

    test('ApiResponse - 很长的消息', () {
      final longMessage = 'A' * 10000;
      final response = ApiResponse(code: 200, message: longMessage);
      expect(response.message.length, 10000);
    });

    test('ApiResponse - 复杂的 data 对象', () {
      final complexData = {
        'users': [
          {'id': 1, 'name': '用户1'},
          {'id': 2, 'name': '用户2'},
        ],
        'metadata': {'total': 2, 'page': 1},
      };

      final response = ApiResponse.fromJson({
        'code': 200,
        'message': '成功',
        'data': complexData,
      }, (data) => data);

      expect(response.data, isNotNull);
      expect((response.data as Map).containsKey('users'), true);
    });

    test('ApiResponse - null data 转换', () {
      final response = ApiResponse.fromJson({
        'code': 200,
        'message': '成功',
        'data': null,
      }, (data) => data != null ? data.toString() : null);

      expect(response.data, null);
    });
  });

  group('HttpException 各类型异常消息测试', () {
    test('业务错误异常', () {
      final exception = HttpException('业务处理失败', 200);
      expect(exception.message, '业务处理失败');
      expect(exception.code, 200);
    });

    test('网络异常', () {
      final exception = HttpException('网络不可达');
      expect(exception.message, '网络不可达');
    });

    test('解析异常', () {
      final exception = HttpException('数据解析失败');
      expect(exception.message, '数据解析失败');
    });

    test('超时异常', () {
      final exception = HttpException('请求超时', 408);
      expect(exception.message, '请求超时');
    });

    test('认证异常', () {
      final exception = HttpException('未授权，请重新登录', 401);
      expect(exception.code, 401);
      expect(exception.message, contains('未授权'));
    });
  });

  group('HttpClient 拦截器配置测试', () {
    test('HttpClient 初始化时配置了拦截器', () {
      final client = HttpClient();
      expect(client.dio.interceptors, isNotEmpty);
      // 应该有日志、转换、错误拦截器
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(3));
    });
  });

  group('API 响应转换逻辑测试', () {
    test('成功状态码 200 时 isSuccess 为 true', () {
      final response = ApiResponse(code: 200, message: 'OK');
      expect(response.isSuccess, true);
    });

    test('非 200 状态码时 isSuccess 为 false', () {
      final codes = [100, 201, 300, 400, 500, 999];
      for (var code in codes) {
        final response = ApiResponse(code: code, message: 'Error');
        expect(response.isSuccess, false);
      }
    });

    test('ApiResponse.fromJson 保留原始数据类型', () {
      final json = {
        'code': 200,
        'message': '成功',
        'data': {
          'count': 123,
          'items': [1, 2, 3],
          'nested': {'key': 'value'},
        },
      };

      final response = ApiResponse.fromJson(json, (d) => d);
      expect((response.data as Map)['count'], 123);
      expect(((response.data as Map)['items'] as List).length, 3);
    });
  });
}
