import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketmind/page/home/home_screen.dart';
import 'package:pocketmind/page/home/desktop/desktop_home_screen.dart';
import 'package:pocketmind/page/home/note_detail_page.dart';
import 'package:pocketmind/page/home/settings_page.dart';
import 'package:pocketmind/page/home/sync_settings_page.dart';
import 'package:pocketmind/page/main_layout.dart';
import 'package:pocketmind/router/route_paths.dart';

/// 全局路由配置
final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  debugLogDiagnostics: true,
  routes: [
    // 使用 ShellRoute 实现响应式布局 (侧边栏持久化)
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        // 首页
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) {
            final isDesktop =
                Platform.isWindows || Platform.isMacOS || Platform.isLinux;
            return isDesktop ? const DesktopHomeScreen() : const HomeScreen();
          },
          routes: [
            // 笔记详情 (嵌套在首页路径下，方便返回)
            GoRoute(
              path: 'note/:nid',
              builder: (context, state) {
                final nidStr = state.pathParameters['nid'];
                final nid = int.tryParse(nidStr ?? '');

                // 参数校验
                if (nid == null) {
                  return const Scaffold(body: Center(child: Text('无效的笔记 ID')));
                }

                // 注意：这里需要 NoteDetailPage 支持通过 ID 加载
                // 暂时传递一个占位，后续重构 NoteDetailPage
                return NoteDetailPage(noteId: nid);
              },
            ),
          ],
        ),

        // 设置页
        GoRoute(
          path: RoutePaths.settings,
          builder: (context, state) => const SettingsPage(),
        ),

        // sync
        GoRoute(
          path: RoutePaths.sync,
          builder: (context, state) => const SyncSettingsPage(),
        ),
      ],
    ),
  ],

  // 错误处理
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('路由错误: ${state.error}'))),
);
