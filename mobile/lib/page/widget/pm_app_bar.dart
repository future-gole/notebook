import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PocketMind 统一标题栏
/// 自动处理桌面端返回按钮、平台差异和样式统一
class PMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;

  const PMAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    // 统一处理返回按钮：如果当前路由可以返回，且没有手动指定 leading
    Widget? effectiveLeading = leading;
    if (leading == null && automaticallyImplyLeading && context.canPop()) {
      effectiveLeading = BackButton(onPressed: () => context.pop());
    }

    return AppBar(
      title: title,
      leading: effectiveLeading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: !isDesktop, // 桌面端标题通常靠左，移动端居中
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
