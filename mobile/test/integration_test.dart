import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'package:pocketmind/util/category_colors.dart';
import 'package:pocketmind/api/link_preview_api_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('笔记创建完整流程测试', () {
    test('创建包含 URL 的笔记', () {
      final note = Note()
        ..title = '有趣的文章'
        ..content = '检查这篇文章：https://example.com/article'
        ..categoryId = 1;

      // 验证笔记基本信息
      expect(note.title, '有趣的文章');
      expect(note.categoryId, 1);

      // 验证 URL 提取
      final extractedUrl = UrlHelper.extractHttpsUrl(note.content);
      expect(extractedUrl, 'https://example.com/article');
    });

    test('创建带分类的笔记', () {
      final category = Category()..name = '工作';
      final note = Note()
        ..title = '会议记录'
        ..content = '团队会议内容'
        ..categoryId = 1;

      expect(note.title, '会议记录');
      expect(category.name, '工作');
    });

    test('笔记与分类关联', () {
      final note = Note()
        ..title = '学习笔记'
        ..categoryId = 2;

      // 验证关联
      expect(note.categoryId, 2);
    });

    test('笔记包含多个 URL', () {
      const content = '''
        参考资源：
        https://flutter.dev
        https://pub.dev
        https://github.com
      ''';

      final urls = UrlHelper.extractAllUrls(content);
      expect(urls.length, 3);
      expect(urls[0], 'https://flutter.dev');
    });

    test('笔记包含本地图片', () {
      const content = '我的截图：pocket_images/screenshot_2024.png';

      expect(
        UrlHelper.isLocalImagePath('pocket_images/screenshot_2024.png'),
        true,
      );
      expect(UrlHelper.hasImageOrUrl(content), true);
    });
  });

  group('笔记搜索和过滤测试', () {
    test('按标题搜索笔记', () {
      final note1 = Note()
        ..title = 'Flutter 学习笔记'
        ..content = '学习 Flutter 框架';

      final note2 = Note()
        ..title = 'Dart 基础'
        ..content = 'Dart 编程语言';

      expect(note1.title?.contains('Flutter'), true);
      expect(note2.title?.contains('Dart'), true);
      expect(note1.title?.contains('Dart'), false);
    });

    test('按分类过滤笔记', () {
      final notes = [
        Note()..categoryId = 1,
        Note()..categoryId = 2,
        Note()..categoryId = 1,
        Note()..categoryId = 3,
      ];

      final category1Notes = notes.where((n) => n.categoryId == 1);
      expect(category1Notes.length, 2);
    });

    test('按内容搜索', () {
      const searchContent = 'Flutter';
      const noteContent = '这是关于 Flutter 框架的笔记';

      expect(noteContent.contains(searchContent), true);
    });

    test('多条件搜索', () {
      final notes = [
        Note()
          ..title = 'Flutter'
          ..categoryId = 1
          ..tag = 'framework',
        Note()
          ..title = 'Dart'
          ..categoryId = 1
          ..tag = 'language',
        Note()
          ..title = 'Flutter Animation'
          ..categoryId = 2
          ..tag = 'framework',
      ];

      // 搜索分类为1且tag为'framework'的笔记
      final results = notes.where(
        (n) => n.categoryId == 1 && n.tag == 'framework',
      );

      expect(results.length, 1);
      expect(results.first.title, 'Flutter');
    });
  });

  group('URL 处理集成测试', () {
    test('从分享文本提取内容', () {
      const shareText = '''
        看我找到的这个：https://medium.com/article
        很有意思的内容！
      ''';

      final url = UrlHelper.extractHttpsUrl(shareText);
      expect(url, 'https://medium.com/article');

      final cleanText = UrlHelper.removeUrls(shareText);
      expect(cleanText.contains('https://'), false);
      expect(cleanText.contains('很有意思的内容'), true);
    });

    test('处理包含图片和链接的内容', () {
      const content = '''
        图片：pocket_images/photo.jpg
        来源：https://example.com
      ''';

      expect(UrlHelper.hasImageOrUrl(content), true);
      expect(UrlHelper.isLocalImagePath('pocket_images/photo.jpg'), true);

      final urls = UrlHelper.extractAllUrls(content);
      expect(urls.length, 1);
      expect(urls[0], 'https://example.com');
    });

    test('处理多个 URL', () {
      const content = '''
        https://site1.com
        http://site2.com
        https://site3.com/path?query=1
      ''';

      final urls = UrlHelper.extractAllUrls(content);
      expect(urls.length, 3);
      expect(urls[0], contains('site1'));
      expect(urls[1], contains('site2'));
      expect(urls[2], contains('site3'));
    });

    test('提取 URL 后创建笔记', () {
      const shareText = 'Check this: https://example.com/article';

      final url = UrlHelper.extractHttpsUrl(shareText);
      final note = Note()
        ..title = '分享的文章'
        ..url = url
        ..content = shareText;

      expect(note.url, 'https://example.com/article');
      expect(note.content, shareText);
    });
  });

  group('分类和颜色映射测试', () {
    test('为分类分配颜色', () {
      final categories = [
        Category()..name = '工作',
        Category()..name = '学习',
        Category()..name = '生活',
      ];

      final darkColors = CategoryColors.getColors(Brightness.dark);
      expect(darkColors.length, 10);

      // 为每个分类分配颜色（循环）
      for (int i = 0; i < categories.length; i++) {
        final color = darkColors[i % darkColors.length];
        expect(color, isNotNull);
      }
    });

    test('不同主题下的颜色切换', () {
      const colorIndex = 2;

      final darkColor = CategoryColors.getColor(colorIndex, Brightness.dark);
      final lightColor = CategoryColors.getColor(colorIndex, Brightness.light);

      // 颜色应该不同
      expect(darkColor.toARGB32() != lightColor.toARGB32(), true);
    });

    test('无效索引使用默认颜色', () {
      final defaultDark = CategoryColors.getColor(-1, Brightness.dark);
      final defaultLight = CategoryColors.getColor(100, Brightness.light);

      expect(defaultDark, CategoryColors.darkModeColors[0]);
      expect(defaultLight, CategoryColors.lightModeColors[0]);
    });

    test('颜色数量与分类数量匹配', () {
      final colors = CategoryColors.getColors(Brightness.dark);
      expect(colors.length, greaterThanOrEqualTo(10));
    });
  });

  group('链接预览数据模型测试', () {
    test('完整的链接预览信息', () {
      final preview = ApiLinkMetadata(
        title: '文章标题',
        description: '文章描述和摘要内容',
        imageUrl: 'https://example.com/image.jpg',
        url: 'https://example.com/article',
        success: true,
      );

      expect(preview.success, true);
      expect(preview.hasData, true);
      expect(preview.title, isNotEmpty);
    });

    test('预览获取失败处理', () {
      final failedPreview = ApiLinkMetadata(
        url: 'https://unreachable.example.com',
        success: false,
      );

      expect(failedPreview.success, false);
      expect(failedPreview.hasData, false);
      // 但 URL 保留用于回退处理
      expect(failedPreview.url, 'https://unreachable.example.com');
    });

    test('部分预览信息', () {
      final partialPreview = ApiLinkMetadata(
        title: '只有标题',
        url: 'https://example.com',
        success: true,
      );

      expect(partialPreview.hasData, true);
      expect(partialPreview.description, null);
      expect(partialPreview.imageUrl, null);
    });
  });

  group('笔记编辑流程测试', () {
    test('更新笔记内容', () {
      final note = Note()
        ..id = 1
        ..title = '原标题'
        ..content = '原内容'
        ..categoryId = 1;

      // 模拟更新
      note.title = '新标题';
      note.content = '新内容';

      expect(note.title, '新标题');
      expect(note.content, '新内容');
      expect(note.id, 1); // ID 不变
    });

    test('移动笔记到其他分类', () {
      final note = Note()
        ..title = '笔记'
        ..categoryId = 1;

      final newCategoryId = 3;
      note.categoryId = newCategoryId;

      expect(note.categoryId, 3);
    });

    test('添加标签到笔记', () {
      final note = Note()
        ..title = '笔记'
        ..tag = 'important';

      expect(note.tag, 'important');

      note.tag = 'work';
      expect(note.tag, 'work');
    });

    test('更新笔记的 URL', () {
      final note = Note()
        ..title = '笔记'
        ..url = 'https://old-url.com';

      const newUrl = 'https://new-url.com';
      note.url = newUrl;

      expect(note.url, 'https://new-url.com');
    });
  });

  group('分类管理测试', () {
    test('创建多个分类', () {
      final categories = [
        Category()..name = '工作',
        Category()..name = '学习',
        Category()..name = '生活',
        Category()..name = '项目',
      ];

      expect(categories.length, 4);
      expect(categories[0].name, '工作');
      expect(categories[3].name, '项目');
    });

    test('分类名称验证', () {
      final category = Category()
        ..name = '有效的分类名称'
        ..description = '这是分类的描述';

      expect(category.name, isNotEmpty);
      expect(category.name.length, lessThan(100));
    });

    test('分类排序', () {
      final categories = [
        Category()..name = 'C',
        Category()..name = 'A',
        Category()..name = 'B',
      ];

      categories.sort((a, b) => a.name.compareTo(b.name));

      expect(categories[0].name, 'A');
      expect(categories[1].name, 'B');
      expect(categories[2].name, 'C');
    });

    test('分类去重', () {
      final categoryNames = ['工作', '学习', '工作', '生活', '学习'];
      final uniqueNames = categoryNames.toSet().toList();

      expect(uniqueNames.length, 3);
      expect(uniqueNames.contains('工作'), true);
      expect(uniqueNames.contains('学习'), true);
      expect(uniqueNames.contains('生活'), true);
    });
  });

  group('笔记时间戳测试', () {
    test('笔记创建时间', () {
      final now = DateTime.now();
      final note = Note()
        ..title = '新笔记'
        ..time = now;

      expect(note.time, now);
    });

    test('笔记时间排序', () {
      final notes = [
        Note()..time = DateTime(2024, 1, 3),
        Note()..time = DateTime(2024, 1, 1),
        Note()..time = DateTime(2024, 1, 2),
      ];

      notes.sort((a, b) => b.time!.compareTo(a.time!)); // 最新的在前

      expect(notes[0].time, DateTime(2024, 1, 3));
      expect(notes[1].time, DateTime(2024, 1, 2));
      expect(notes[2].time, DateTime(2024, 1, 1));
    });

    test('笔记时间间隔计算', () {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      final note1 = Note()..time = now;
      final note2 = Note()..time = yesterday;

      final difference = note1.time!.difference(note2.time!).inDays;
      expect(difference, 1);
    });
  });

  group('端对端内容流测试', () {
    test('从分享到保存的完整流程', () {
      // 1. 接收分享内容
      const shareText = '''
        看到这篇很有意思的文章：https://example.com/article
        需要好好研究一下
      ''';

      // 2. 提取 URL
      final url = UrlHelper.extractHttpsUrl(shareText);
      expect(url, 'https://example.com/article');

      // 3. 清理内容
      final cleanedContent = UrlHelper.removeUrls(shareText);
      expect(cleanedContent.contains('https://'), false);

      // 4. 创建笔记
      final note = Note()
        ..title = '有趣的文章'
        ..content = cleanedContent
        ..url = url
        ..categoryId = 1;

      expect(note.title, '有趣的文章');
      expect(note.url, 'https://example.com/article');

      // 5. 分配分类和颜色
      final color = CategoryColors.getColor(1, Brightness.dark);
      expect(color, isNotNull);
    });

    test('笔记的完整生命周期', () {
      // 创建
      final note = Note()
        ..title = '日记'
        ..content = '今天发生的事'
        ..categoryId = 1
        ..time = DateTime.now();

      expect(note.title, '日记');

      // 编辑
      note.content = '更新后的日记内容';
      expect(note.content, '更新后的日记内容');

      // 重新分类
      note.categoryId = 2;
      expect(note.categoryId, 2);

      // 添加标签
      note.tag = 'personal';
      expect(note.tag, 'personal');
    });
  });
}
