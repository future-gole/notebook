import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notebook/server/LogService.dart';
import 'package:share_handler/share_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 获取插件单例
  final handler = ShareHandler.instance;
  SharedMedia? _sharedMedia; // 用于存储分享过来的媒体对象
  String? sharedContent;
  @override
  void initState() {
    super.initState();
    _initShareHandler();
  }

  Future<void> _initShareHandler() async {
    // 监听：当App在后台/前台运行时，接收到新的分享
    handler.sharedMediaStream.listen((SharedMedia media) {
      log.d('Received shared media while running');
      _handleSharedData(media);
    });

    // 获取：当App是关闭状态，通过分享第一次启动
    final media = await handler.getInitialSharedMedia();
    if (media != null) {
      log.d('Received shared media on launch');
      _handleSharedData(media);
    }
  }

  // 统一的处理入口
  void _handleSharedData(SharedMedia media) {
    setState(() {
      _sharedMedia = media;
    });

    // 我们只关心第一个附件中的内容（B站等分享过来的是URL）
    sharedContent = media.content;
    if (sharedContent == null) return;

    // 提取分享的内容，通常是URL或文本
    log.d("Detected shared content: $sharedContent");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Handler Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('最近分享的内容:', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 10),
              // 显示分享过来的内容
              if (sharedContent != null)
                Text(
                  sharedContent!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                )
              else
                Text("暂未接收到分享内容", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}