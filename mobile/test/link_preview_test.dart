import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketmind/api/link_preview_api_service.dart';
import 'package:pocketmind/api/http_client.dart';
import 'package:dio/dio.dart';

// Mock HttpClient
class MockHttpClient extends Mock implements HttpClient {}

void main() {
  group('ApiLinkMetadata 模型测试', () {
    test('ApiLinkMetadata - 完整初始化', () {
      final metadata = ApiLinkMetadata(
        title: '测试标题',
        description: '测试描述',
        imageUrl: 'https://example.com/image.png',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.title, '测试标题');
      expect(metadata.description, '测试描述');
      expect(metadata.imageUrl, 'https://example.com/image.png');
      expect(metadata.url, 'https://example.com');
      expect(metadata.success, true);
    });

    test('ApiLinkMetadata - 最小初始化', () {
      final metadata = ApiLinkMetadata(
        url: 'https://example.com',
        success: false,
      );

      expect(metadata.title, null);
      expect(metadata.description, null);
      expect(metadata.imageUrl, null);
      expect(metadata.url, 'https://example.com');
      expect(metadata.success, false);
    });

    test('ApiLinkMetadata.hasData - 有完整数据', () {
      final metadata = ApiLinkMetadata(
        title: '标题',
        description: '描述',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.hasData, true);
    });

    test('ApiLinkMetadata.hasData - 只有标题', () {
      final metadata = ApiLinkMetadata(
        title: '标题',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.hasData, true);
    });

    test('ApiLinkMetadata.hasData - 只有描述', () {
      final metadata = ApiLinkMetadata(
        description: '描述信息',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.hasData, true);
    });

    test('ApiLinkMetadata.hasData - 只有图片', () {
      final metadata = ApiLinkMetadata(
        imageUrl: 'https://example.com/img.png',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.hasData, true);
    });

    test('ApiLinkMetadata.hasData - 无数据', () {
      final metadata = ApiLinkMetadata(
        url: 'https://example.com',
        success: false,
      );

      expect(metadata.hasData, false);
    });

    test('ApiLinkMetadata.hasData - 空字符串不算有数据', () {
      final metadata = ApiLinkMetadata(
        title: '',
        description: '',
        imageUrl: '',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.hasData, false);
    });

    test('ApiLinkMetadata - 空白字符串处理', () {
      final metadata = ApiLinkMetadata(
        title: '   ',
        description: '\n',
        url: 'https://example.com',
        success: true,
      );

      // 假设框架不去掉空白
      expect(metadata.title, '   ');
      expect(metadata.description, '\n');
    });
  });

  group('LinkPreviewApiService 初始化测试', () {
    test('LinkPreviewApiService 创建实例', () {
      final mockHttpClient = MockHttpClient();
      final service = LinkPreviewApiService(mockHttpClient);

      expect(service, isNotNull);
    });
  });

  group('ApiLinkMetadata URL 处理测试', () {
    test('URL 包含查询参数', () {
      final metadata = ApiLinkMetadata(
        title: '搜索结果',
        url: 'https://google.com/search?q=flutter&lang=zh',
        success: true,
      );

      expect(metadata.url, contains('?q='));
      expect(metadata.url, contains('&lang='));
    });

    test('URL 包含端口号', () {
      final metadata = ApiLinkMetadata(
        title: '本地服务',
        url: 'http://localhost:8080/api/data',
        success: true,
      );

      expect(metadata.url, contains(':8080'));
    });

    test('URL 包含 fragment', () {
      final metadata = ApiLinkMetadata(
        title: '锚点链接',
        url: 'https://example.com/page#section',
        success: true,
      );

      expect(metadata.url, contains('#section'));
    });

    test('HTTPS 和 HTTP 支持', () {
      final https = ApiLinkMetadata(
        url: 'https://secure.example.com',
        success: true,
      );

      final http = ApiLinkMetadata(url: 'http://example.com', success: true);

      expect(https.url, startsWith('https://'));
      expect(http.url, startsWith('http://'));
    });
  });

  group('ApiLinkMetadata 成功和失败状态', () {
    test('success = true 表示获取成功', () {
      final metadata = ApiLinkMetadata(
        title: '标题',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.success, true);
      expect(metadata.hasData, true);
    });

    test('success = false 表示获取失败', () {
      final metadata = ApiLinkMetadata(
        url: 'https://example.com',
        success: false,
      );

      expect(metadata.success, false);
    });

    test('失败状态可以仍有 URL', () {
      final metadata = ApiLinkMetadata(
        url: 'https://failed-fetch.com',
        success: false,
      );

      expect(metadata.url, 'https://failed-fetch.com');
      expect(metadata.success, false);
      expect(metadata.hasData, false);
    });
  });

  group('ApiLinkMetadata 内容长度测试', () {
    test('长标题处理', () {
      final longTitle = 'A' * 500;
      final metadata = ApiLinkMetadata(
        title: longTitle,
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.title?.length, 500);
    });

    test('长描述处理', () {
      final longDescription = '这是一个很长的描述。' * 100;
      final metadata = ApiLinkMetadata(
        description: longDescription,
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.description?.length, greaterThan(1000));
    });

    test('图片 URL 长度', () {
      final longImageUrl =
          'https://example.com/image/very/long/path/to/image_' +
          ('x' * 200) +
          '.jpg';
      final metadata = ApiLinkMetadata(
        imageUrl: longImageUrl,
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.imageUrl?.length, greaterThan(200));
    });
  });

  group('ApiLinkMetadata 特殊字符处理', () {
    test('标题包含特殊字符', () {
      final metadata = ApiLinkMetadata(
        title: '标题 & 描述 | 内容 "quoted"',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.title, contains('&'));
      expect(metadata.title, contains('|'));
      expect(metadata.title, contains('"'));
    });

    test('描述包含 HTML 实体', () {
      final metadata = ApiLinkMetadata(
        description: 'Price &pound; 99.99 &copy; 2024',
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.description, contains('&pound;'));
      expect(metadata.description, contains('&copy;'));
    });

    test('URL 包含编码字符', () {
      final metadata = ApiLinkMetadata(
        url: 'https://example.com/search?q=%E6%B5%8B%E8%AF%95',
        success: true,
      );

      expect(metadata.url, contains('%'));
    });

    test('多行内容', () {
      final multilineTitle = '''
        标题第一行
        标题第二行
        标题第三行
      ''';
      final metadata = ApiLinkMetadata(
        title: multilineTitle,
        url: 'https://example.com',
        success: true,
      );

      expect(metadata.title, contains('\n'));
    });
  });

  group('ApiLinkMetadata 边界值测试', () {
    test('null 值处理', () {
      final metadata = ApiLinkMetadata(
        title: null,
        description: null,
        imageUrl: null,
        url: 'https://example.com',
        success: false,
      );

      expect(metadata.title, null);
      expect(metadata.description, null);
      expect(metadata.imageUrl, null);
      expect(metadata.hasData, false);
    });

    test('空字符串 URL', () {
      final metadata = ApiLinkMetadata(url: '', success: false);

      expect(metadata.url, isEmpty);
    });

    test('空字符串标题时 hasData 检查', () {
      final metadata = ApiLinkMetadata(
        title: '',
        description: '',
        imageUrl: '',
        url: 'https://example.com',
        success: true,
      );

      // 由于都是空字符串，hasData 应该返回 false
      expect(metadata.hasData, false);
    });
  });

  group('LinkPreviewApiService 依赖注入测试', () {
    test('服务依赖 HttpClient', () {
      final mockHttpClient = MockHttpClient();
      final service = LinkPreviewApiService(mockHttpClient);

      expect(service, isNotNull);
      // 验证服务能正常创建
    });
  });

  group('ApiLinkMetadata 实际数据示例', () {
    test('真实网站预览数据示例', () {
      final metadata = ApiLinkMetadata(
        title: 'Flutter - Beautiful native apps in a fraction of the time',
        description:
            'Flutter transforms the entire app development process. Build, test, and deploy beautiful mobile, web, desktop, and embedded apps from a single codebase.',
        imageUrl: 'https://flutter.dev/assets/homepage/carousel/slide_1.jpg',
        url: 'https://flutter.dev',
        success: true,
      );

      expect(metadata.success, true);
      expect(metadata.hasData, true);
      expect(metadata.title, isNotEmpty);
      expect(metadata.description, isNotEmpty);
      expect(metadata.imageUrl, isNotEmpty);
    });

    test('新闻文章预览示例', () {
      final metadata = ApiLinkMetadata(
        title: '今日科技新闻：AI 发展新突破',
        description: '最新的人工智能技术进展和市场分析...',
        imageUrl: 'https://news.example.com/images/ai-breakthrough.jpg',
        url: 'https://news.example.com/article/12345',
        success: true,
      );

      expect(metadata.hasData, true);
    });

    test('无法获取预览信息示例', () {
      final metadata = ApiLinkMetadata(
        url: 'https://example.com/private-resource',
        success: false,
      );

      expect(metadata.success, false);
      expect(metadata.hasData, false);
      // 虽然获取失败，但 URL 仍然保留
      expect(metadata.url, isNotEmpty);
    });
  });
}
