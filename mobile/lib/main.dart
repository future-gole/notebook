import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:pocketmind/HomeScreen.dart';
import 'package:pocketmind/page/settings_page.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/services/share_background_service.dart';
import 'package:pocketmind/util/proxy_config.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/theme_data.dart';
import 'package:path_provider/path_provider.dart';
import 'model/note.dart';

// 这会强制构建系统将 main_share.dart 编译到应用中
// 防止另一个入口没有被引用
import 'package:pocketmind/main_share.dart' as share_entrypoint;

late Isar isar;

Future<void> main() async {
  // 确保 flutter 绑定初始化了
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用配置
  final config = AppConfig();
  await config.init();

  // 根据配置设置代理
  if (config.proxyEnabled) {
    HttpOverrides.global = GlobalHttpOverrides(
      "${config.proxyHost}:${config.proxyPort}",
      allowBadCertificates: true,
    );
  }

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
      debugShowCheckedModeBanner: false,

      title: 'PocketMind',

      // 应用"赤陶与暖沙"主题（亮色模式）
      theme: calmBeigeTheme,

      // 应用"静谧之夜"主题（暗色模式）
      darkTheme: quietNightTheme,

      // 跟随系统主题设置
      themeMode: ThemeMode.system,

      home: HomeScreen(),

      // 配置路由
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
