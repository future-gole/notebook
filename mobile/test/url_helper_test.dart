import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/util/url_helper.dart';

void main() {
  group('UrlHelper - URL 检测测试', () {
    test('containsHttpsUrl - 包含 https URL', () {
      expect(UrlHelper.containsHttpsUrl('访问 https://example.com 了解更多'), true);
    });

    test('containsHttpsUrl - 包含 http URL', () {
      expect(UrlHelper.containsHttpsUrl('访问 http://example.com 了解更多'), true);
    });

    test('containsHttpsUrl - 不包含 URL', () {
      expect(UrlHelper.containsHttpsUrl('这是一个普通的文本'), false);
    });

    test('containsHttpsUrl - 空字符串', () {
      expect(UrlHelper.containsHttpsUrl(''), false);
    });

    test('containsHttpsUrl - null 值', () {
      expect(UrlHelper.containsHttpsUrl(null), false);
    });

    test('containsHttpsUrl - 多个 URL', () {
      expect(
        UrlHelper.containsHttpsUrl('https://google.com 和 https://github.com'),
        true,
      );
    });

    test('containsHttpsUrl - 大小写不敏感', () {
      expect(UrlHelper.containsHttpsUrl('HTTPS://EXAMPLE.COM'), true);
      expect(UrlHelper.containsHttpsUrl('HTTP://EXAMPLE.COM'), true);
      expect(UrlHelper.containsHttpsUrl('HtTpS://example.com'), true);
    });
  });

  group('UrlHelper - URL 提取测试', () {
    test('extractHttpsUrl - 提取单个 URL', () {
      final url = UrlHelper.extractHttpsUrl('访问 https://example.com 了解更多');
      expect(url, 'https://example.com');
    });

    test('extractHttpsUrl - 提取第一个 URL（多个 URL）', () {
      final url = UrlHelper.extractHttpsUrl(
        'https://first.com 和 https://second.com',
      );
      expect(url, 'https://first.com');
    });

    test('extractHttpsUrl - 不包含 URL 返回 null', () {
      final url = UrlHelper.extractHttpsUrl('这是一个普通的文本');
      expect(url, null);
    });

    test('extractHttpsUrl - null 输入返回 null', () {
      final url = UrlHelper.extractHttpsUrl(null);
      expect(url, null);
    });

    test('extractHttpsUrl - 空字符串返回 null', () {
      final url = UrlHelper.extractHttpsUrl('');
      expect(url, null);
    });

    test('extractHttpsUrl - URL 带端口号', () {
      final url = UrlHelper.extractHttpsUrl('访问 https://example.com:8080/path');
      expect(url, contains('https://example.com'));
    });

    test('extractHttpsUrl - URL 带查询参数', () {
      final url = UrlHelper.extractHttpsUrl(
        'https://example.com?param=value&other=123',
      );
      expect(url, startsWith('https://example.com'));
    });
  });

  group('UrlHelper - 提取所有 URL 测试', () {
    test('extractAllUrls - 提取多个 URL', () {
      final urls = UrlHelper.extractAllUrls(
        'https://first.com 和 https://second.com 以及 https://third.com',
      );
      expect(urls.length, 3);
      expect(urls[0], 'https://first.com');
      expect(urls[1], 'https://second.com');
      expect(urls[2], 'https://third.com');
    });

    test('extractAllUrls - 提取单个 URL', () {
      final urls = UrlHelper.extractAllUrls('访问 https://example.com');
      expect(urls.length, 1);
      expect(urls[0], 'https://example.com');
    });

    test('extractAllUrls - 无 URL 返回空列表', () {
      final urls = UrlHelper.extractAllUrls('这是一个普通的文本');
      expect(urls, isEmpty);
    });

    test('extractAllUrls - null 输入返回空列表', () {
      final urls = UrlHelper.extractAllUrls(null);
      expect(urls, isEmpty);
    });

    test('extractAllUrls - 空字符串返回空列表', () {
      final urls = UrlHelper.extractAllUrls('');
      expect(urls, isEmpty);
    });

    test('extractAllUrls - 混合 http 和 https', () {
      final urls = UrlHelper.extractAllUrls(
        'http://example.com 和 https://secure.com',
      );
      expect(urls.length, 2);
      expect(urls[0], 'http://example.com');
      expect(urls[1], 'https://secure.com');
    });
  });

  group('UrlHelper - 移除 URL 测试', () {
    test('removeUrls - 移除单个 URL', () {
      final text = UrlHelper.removeUrls('访问 https://example.com 了解更多');
      expect(text, '访问  了解更多'); // URL 移除后会留下空格
    });

    test('removeUrls - 移除多个 URL', () {
      final text = UrlHelper.removeUrls(
        'https://first.com 和 https://second.com 的内容',
      );
      expect(text, '和  的内容'); // URL 移除后会留下空格
    });

    test('removeUrls - 无 URL', () {
      final text = UrlHelper.removeUrls('这是一个普通的文本');
      expect(text, '这是一个普通的文本');
    });

    test('removeUrls - null 输入返回空字符串', () {
      final text = UrlHelper.removeUrls(null);
      expect(text, '');
    });

    test('removeUrls - 空字符串返回空字符串', () {
      final text = UrlHelper.removeUrls('');
      expect(text, '');
    });

    test('removeUrls - 移除 file:// URI', () {
      final text = UrlHelper.removeUrls('文件 file:///path/to/file 的内容');
      expect(text, '文件  的内容'); // URI 移除后会留下空格
    });

    test('removeUrls - 移除 content:// URI', () {
      final text = UrlHelper.removeUrls('内容 content://path/to/content 的资源');
      expect(text, '内容  的资源'); // URI 移除后会留下空格
    });
  });

  group('UrlHelper - Content URI 检测测试', () {
    test('containsContentUri - 包含 content:// URI', () {
      expect(
        UrlHelper.containsContentUri(
          'content://com.android.providers.media.documents/document/image%3A123',
        ),
        true,
      );
    });

    test('containsContentUri - 不包含 content:// URI', () {
      expect(UrlHelper.containsContentUri('https://example.com'), false);
    });

    test('containsContentUri - null 返回 false', () {
      expect(UrlHelper.containsContentUri(null), false);
    });

    test('containsContentUri - 空字符串返回 false', () {
      expect(UrlHelper.containsContentUri(''), false);
    });
  });

  group('UrlHelper - 提取 Content URI 测试', () {
    test('extractContentUri - 提取 content:// URI', () {
      final uri = UrlHelper.extractContentUri(
        '分享 content://com.android.providers.documents/id/123',
      );
      expect(uri, contains('content://'));
    });

    test('extractContentUri - 不存在返回 null', () {
      final uri = UrlHelper.extractContentUri('https://example.com');
      expect(uri, null);
    });

    test('extractContentUri - null 输入返回 null', () {
      final uri = UrlHelper.extractContentUri(null);
      expect(uri, null);
    });
  });

  group('UrlHelper - 提取任意 URI 测试', () {
    test('extractAnyUri - 提取 HTTP URL', () {
      final uri = UrlHelper.extractAnyUri('访问 http://example.com');
      expect(uri, contains('http://'));
    });

    test('extractAnyUri - 提取 HTTPS URL', () {
      final uri = UrlHelper.extractAnyUri('访问 https://example.com');
      expect(uri, contains('https://'));
    });

    test('extractAnyUri - 提取 content:// URI', () {
      final uri = UrlHelper.extractAnyUri(
        '分享 content://providers/documents/id/123',
      );
      expect(uri, contains('content://'));
    });

    test('extractAnyUri - 提取 file:// URI', () {
      final uri = UrlHelper.extractAnyUri('文件 file:///path/to/file');
      expect(uri, contains('file://'));
    });

    test('extractAnyUri - 无 URI 返回 null', () {
      final uri = UrlHelper.extractAnyUri('普通文本');
      expect(uri, null);
    });
  });

  group('UrlHelper - 本地图片路径检测测试', () {
    test('isLocalImagePath - 本地图片路径', () {
      expect(UrlHelper.isLocalImagePath('pocket_images/img_123.jpg'), true);
    });

    test('isLocalImagePath - 完整路径', () {
      expect(
        UrlHelper.isLocalImagePath('pocket_images/subfolder/image.png'),
        true,
      );
    });

    test('isLocalImagePath - HTTP URL', () {
      expect(
        UrlHelper.isLocalImagePath('https://example.com/image.jpg'),
        false,
      );
    });

    test('isLocalImagePath - 相对路径（非 pocket_images）', () {
      expect(UrlHelper.isLocalImagePath('other_folder/image.jpg'), false);
    });

    test('isLocalImagePath - null 返回 false', () {
      expect(UrlHelper.isLocalImagePath(null), false);
    });

    test('isLocalImagePath - 空字符串返回 false', () {
      expect(UrlHelper.isLocalImagePath(''), false);
    });
  });

  group('UrlHelper - 图片或 URL 检测测试', () {
    test('hasImageOrUrl - 本地图片', () {
      expect(UrlHelper.hasImageOrUrl('pocket_images/photo.jpg'), true);
    });

    test('hasImageOrUrl - HTTP URL', () {
      expect(UrlHelper.hasImageOrUrl('https://example.com/image.jpg'), true);
    });

    test('hasImageOrUrl - 普通文本', () {
      expect(UrlHelper.hasImageOrUrl('这是一个普通的文本'), false);
    });

    test('hasImageOrUrl - null 返回 false', () {
      expect(UrlHelper.hasImageOrUrl(null), false);
    });

    test('hasImageOrUrl - 空字符串返回 false', () {
      expect(UrlHelper.hasImageOrUrl(''), false);
    });

    test('hasImageOrUrl - 混合内容', () {
      expect(UrlHelper.hasImageOrUrl('文本 https://example.com/img.jpg'), true);
    });
  });

  group('UrlHelper - 复杂场景测试', () {
    test('复杂分享文本处理', () {
      const text =
          'Check out this cool article https://medium.com/article and image pocket_images/screenshot.png';

      expect(UrlHelper.containsHttpsUrl(text), true);
      expect(UrlHelper.hasImageOrUrl(text), true);
      expect(UrlHelper.extractHttpsUrl(text), contains('https://'));
    });

    test('多个 URL 和图片混合', () {
      const text =
          'https://site1.com https://site2.com pocket_images/pic.png http://site3.com';

      final urls = UrlHelper.extractAllUrls(text);
      expect(urls.length, 3);
      expect(UrlHelper.hasImageOrUrl(text), true);
    });

    test('URL 包含特殊字符和编码', () {
      const url = 'https://example.com/search?q=hello%20world&lang=zh_CN';
      expect(UrlHelper.containsHttpsUrl(url), true);
      expect(UrlHelper.extractHttpsUrl(url), contains('https://'));
    });
  });
}
