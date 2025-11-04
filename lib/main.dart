import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notebook/HomeScreen.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/services/share_background_service.dart';
import 'package:notebook/util/theme_data.dart';
import 'package:path_provider/path_provider.dart';
import 'model/note.dart';

// 这会强制构建系统将 main_share.dart 编译到应用中
// 我们给它一个 "as" 别名，以防万一有命名冲突
import 'package:notebook/main_share.dart' as share_entrypoint;

late Isar isar;

Future<void> main() async {
  // 确保 flutter 绑定初始化了
  WidgetsFlutterBinding.ensureInitialized();

  // 获取一个可写目录
  final dir = await getApplicationDocumentsDirectory();

  // 打开 Isar 实例
  isar = await Isar.open(
    [NoteSchema], // 传入您所有模型的 Schema
    directory: dir.path,
  );

  runApp(
    // 使用 ProviderScope 包裹应用，并 override isarProvider
    // 后续都使用状态管理里面的isar
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteBook',

      // 应用"赤陶与暖沙"主题（亮色模式）
      theme: calmBeigeTheme,

      // 应用"静谧之夜"主题（暗色模式）
      darkTheme: quietNightTheme,

      // 跟随系统主题设置
      themeMode: ThemeMode.system,

      home: HomeScreen(),
    );
  }
}
