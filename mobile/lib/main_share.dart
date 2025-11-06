// 路径: lib/main_share.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/page/edit_note_page.dart';
import 'package:notebook/page/share_success_page.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/providers/note_providers.dart';
import 'package:notebook/server/note_service.dart';
import 'package:notebook/util/theme_data.dart';
import 'package:path_provider/path_provider.dart';
import '../../util/logger_service.dart';

late Isar isar; // 这个 Isar 实例专用于分享引擎
final String tag = "main_share";

// UI 状态枚举
enum ShareUIState { waiting, success, editing }

// 关键：这是一个新的、独立的入口点
@pragma('vm:entry-point')
Future<void> main_share() async {
  // 1. 初始化
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  // 2. 打开 Isar 实例,和主示例相同，要不然存的地方就不一样了
  isar = await Isar.open([NoteSchema], directory: dir.path);

  // // 3. 初始化后台服务 (并把 Isar 传给它),并不需要了，先留着
  // ShareBackgroundService.initialize(isar);

  // 4. 运行一个 只 包含分享 UI 的应用
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const MyShareApp(),
    ),
  );
}

class MyShareApp extends ConsumerStatefulWidget {
  const MyShareApp({super.key});
  @override
  ConsumerState<MyShareApp> createState() => _MyShareAppState();
}

class _MyShareAppState extends ConsumerState<MyShareApp>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.notebook/share');

  // UI 状态机
  ShareUIState _currentState = ShareUIState.waiting;
  ShareData? _currentShare;
  int _noteId = -1;

  late final NoteService noteService;

  @override
  void initState() {
    super.initState();
    noteService = ref.read(noteServiceProvider);
    _channel.setMethodCallHandler(_handleMethodCall);
    log.d(tag, "MyShareApp 初始化完成, 等待分享...");

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
      log.d(tag, "已通知原生端：Flutter 引擎准备就绪");
    } catch (e) {
      log.e(tag, "通知引擎准备就绪失败: $e");
    }
  }

  // 隐藏 UI 并关闭 Activity
  void _dismissUI() {
    log.d(tag, "Dismissing UI...");

    // 重置状态机
    setState(() {
      _currentState = ShareUIState.waiting;
      _currentShare = null;
      _noteId = -1;
    });

    // 关闭 ShareActivity
    SystemNavigator.pop();
  }

  // 状态转换：从 success 到 editing
  void _onAddDetailsClicked() {
    setState(() {
      _currentState = ShareUIState.editing;
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    log.d(tag, "接收到方法: ${call.method}");

    switch (call.method) {
      case 'showShare':
        // 显示分享 UI
        final args = call.arguments as Map;
        final title = args['title'] as String;
        final content = args['content'] as String;

        log.d(tag, "showShare: title=$title");

        try {
          // 1. 保存数据到数据库
          _noteId = await noteService.addOrUpdateNote(
            title: args['title'],
            content: args['content'],
            category: args['category'],
            tag: args['tag'],
          );

          // todo 发送到后端

          // 2. 更新 UI 状态以显示 ShareSuccessPage
          setState(() {
            _currentShare = ShareData(title: title, content: content);
            _currentState = ShareUIState.success;
          });

          log.d(tag, "分享的UI成功展示");
          return "Success";
        } catch (e) {
          log.e(tag, "展示识别: $e");
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
      theme: calmBeigeTheme, // 使用 Light 主题
      darkTheme: quietNightTheme, // 使用 Dark 主题
      themeMode: ThemeMode.system, // 跟随系统
      home: Material(
        type: MaterialType.transparency,
        child: _buildStage(context),
      ),
    );
  }

  // "舞台" - 统一的背景画布
  Widget _buildStage(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Theme.of(context).colorScheme.outline, // 使用主题的画布遮罩色
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: _buildTransition,
            child: _buildCurrentView(context),
          ),
        ),
      ),
    );
  }

  // 过渡动画构建器
  Widget _buildTransition(Widget child, Animation<double> animation) {
    // 判断是进入还是退出
    final isEntering = child.key == ValueKey(_currentState);

    if (_currentState == ShareUIState.editing || (child is EditNotePage)) {
      // EditNotePage: 从底部滑入
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    } else if (_currentState == ShareUIState.success ||
        (child is ShareSuccessPage)) {
      // ShareSuccessPage: 向上飘散退出，淡入进入
      return SlideTransition(
        position:
            Tween<Offset>(
              begin: isEntering ? Offset.zero : const Offset(0, -0.2),
              end: isEntering ? Offset.zero : const Offset(0, -0.2),
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    }

    // 默认：简单淡入淡出
    return FadeTransition(opacity: animation, child: child);
  }

  // 根据状态机构建当前视图
  Widget _buildCurrentView(BuildContext context) {
    switch (_currentState) {
      case ShareUIState.waiting:
        // 等待状态：透明占位
        return SizedBox.shrink(key: const ValueKey('waiting'));

      case ShareUIState.success:
        // 成功状态：显示成功页面
        return ShareSuccessPage(
          key: const ValueKey('success'),
          title: _currentShare?.title ?? '',
          content: _currentShare?.content ?? '',
          onDismiss: _dismissUI,
          onAddDetailsClicked: _onAddDetailsClicked,
        );

      case ShareUIState.editing:
        // 编辑状态：显示编辑页面
        return EditNotePage(
          key: const ValueKey('editing'),
          id: _noteId,
          initialTitle: _currentShare?.title ?? '',
          initialContent: _currentShare?.content ?? '',
          onDone: _dismissUI,
        );
    }
  }
}

class ShareData {
  final String title;
  final String content;
  ShareData({required this.title, required this.content});
}
