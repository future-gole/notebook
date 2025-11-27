import 'package:flutter/material.dart';
import 'package:pocketmind/util/link_preview_config.dart';

/// 链接预览路由测试工具
void main() {
  runApp(const LinkPreviewRouteTest());
}

class LinkPreviewRouteTest extends StatelessWidget {
  const LinkPreviewRouteTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('链接路由测试')),
        body: const TestList(),
      ),
    );
  }
}

class TestList extends StatelessWidget {
  const TestList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final testUrls = [
      // 国内网站
      'https://weixin.qq.com/article/123',
      'https://www.zhihu.com/question/123',
      'https://www.bilibili.com/video/BV123',
      'https://www.xiaohongshu.com/explore/123',
      'https://www.douyin.com/video/123',

      // 国外网站（应该用 API）
      'https://x.com/user/status/123',
      'https://twitter.com/user/status/123',
      'https://www.youtube.com/watch?v=123',
      'https://youtu.be/123',

      // 其他国外网站（应该用 any_link_preview）
      'https://www.reddit.com/r/test',
      'https://github.com/user/repo',
      'https://stackoverflow.com/questions/123',
    ];

    return ListView.builder(
      itemCount: testUrls.length,
      itemBuilder: (context, index) {
        final url = testUrls[index];
        final useApi = LinkPreviewConfig.shouldUseApiService(url);

        return ListTile(
          title: Text(url),
          subtitle: Text(useApi ? '✅ 使用 API' : '🔧 使用 any_link_preview'),
          trailing: Icon(
            useApi ? Icons.cloud : Icons.home,
            color: useApi ? Colors.blue : Colors.green,
          ),
        );
      },
    );
  }
}
