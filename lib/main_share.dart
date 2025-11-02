// 路径: lib/main_share.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/page/edit_note_page.dart';
import 'package:notebook/page/share_success_page.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/services/share_background_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../util/logger_service.dart';
late Isar isar; // 这个 Isar 实例专用于分享引擎
final String tag = "main_share";
// 关键：这是一个新的、独立的入口点
@pragma('vm:entry-point')
Future<void> main_share() async {
  // 1. 初始化
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  // 2. 打开 Isar 实例,和主示例相同，要不然存的地方就不一样了
  isar = await Isar.open([NoteSchema], directory: dir.path);

  // 3. 初始化后台服务 (并把 Isar 传给它)
  ShareBackgroundService.initialize(isar);

  // 4. 运行一个 只 包含分享 UI 的应用
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const MyShareApp(),
    ),
  );
}

class MyShareApp extends StatefulWidget {
  const MyShareApp({super.key});
  @override
  State<MyShareApp> createState() => _MyShareAppState();
}

class _MyShareAppState extends State<MyShareApp> {
  static const _channel = MethodChannel('com.example.notebook/share');
  ShareData? _currentShare;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleMethodCall);
    log.d(tag,"MyShareApp 初始化完成, 等待分享...");

    // 延迟通知原生端引擎已准备好
    // 使用 addPostFrameCallback 确保第一帧渲染完成后再通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyEngineReady();
    });
  }

  // 通知原生端 Flutter 引擎已准备好
  Future<void> _notifyEngineReady() async {
    try {
      await _channel.invokeMethod('engineReady');
      log.d(tag,"已通知原生端：Flutter 引擎准备就绪");
    } catch (e) {
      log.e(tag,"通知引擎准备就绪失败: $e");
    }
  }

  // 隐藏 UI 并关闭 Activity
  void _dismissUI() {
    log.d(tag,"Dismissing UI...");

    setState(() {
      // 清楚之前的数据
      _currentShare = null;
    });

    // 关闭 ShareActivity
    SystemNavigator.pop();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    log.d(tag,"接收到方法: ${call.method}");

    switch (call.method) {
      case 'showShare':
        // 这是新的命令：显示分享 UI
        final args = call.arguments as Map;
        final title = args['title'] as String;
        final content = args['content'] as String;

        log.d(tag,"showShare: title=$title");

        try {
          // 1. 保存数据到后台
          await ShareBackgroundService.saveAndSync(
            args.cast<String, dynamic>(),
          );

          // 2. 更新 UI 状态以显示 ShareSuccessPage
          setState(() {
            _currentShare = ShareData(title: title, content: content);
          });

          log.d(tag,"分享的UI成功展示");
          return "Success";
        } catch (e) {
          log.e(tag,"展示识别: $e");
          return e.toString();
        }

      case 'saveAndSync':
        // 保留这个方法用于向后兼容（如果需要）
        final args = call.arguments as Map;
        log.d(tag,"saveAndSync (legacy): ${args['title']}");

        try {
          await ShareBackgroundService.saveAndSync(
            args.cast<String, dynamic>(),
          );

          // 也显示 UI
          final title = args['title'] as String;
          final content = args['content'] as String;
          setState(() {
            _currentShare = ShareData(title: title, content: content);
          });

          return "Success";
        } catch (e) {
          log.e(tag,"Error in saveAndSync: $e");
          return e.toString();
        }

      default:
        throw PlatformException(
          code: 'Unimplemented',
          message: 'Unknown method ${call.method}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // home 现在调用 _buildCurrentScreen
      home: _buildCurrentScreen(),

      onGenerateRoute: (settings) {
        if (settings.name == '/editNote') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final title = args['title'] as String? ?? '编辑笔记';
          final content = args['content'] as String? ?? '';

          return PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.transparent,
            pageBuilder: (context, _, __) => EditNotePage(
              initialTitle: title,
              initialContent: content,
              onDone: _dismissUI, // 把"隐藏"方法传给编辑页
            ),
          );
        }
        return null;
      },
    );
  }

  // 这个方法现在是 UI 状态机
  Widget _buildCurrentScreen() {
    if (_currentShare == null) {
      // 状态 1: 没有分享数据，显示透明
      return Container(color: Colors.transparent);
    } else {
      // 状态 2: 有分享数据，显示成功页面
      return ShareSuccessPage(
        // key: ValueKey(_currentShare.hashCode), // 确保每次新分享都重建
        title: _currentShare!.title,
        content: _currentShare!.content,
        onDismiss: _dismissUI, // 把"隐藏"方法传给成功页
      );
    }
  }
}

class ShareData {
  final String title;
  final String content;
  ShareData({required this.title, required this.content});
}
