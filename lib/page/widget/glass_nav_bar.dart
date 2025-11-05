import 'dart:ui'; // 用于 ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'item_bar.dart'; // 导入我们刚创建的 ItemBar

///
/// 这是包含 ItemBar 的主导航栏。
/// 它实现了玻璃拟态背景和状态管理。
/// 使用 Riverpod 进行依赖注入和状态管理。
/// 集成了搜索按钮和布局切换功能
///
class GlassNavBar extends ConsumerWidget {
  final VoidCallback? onSearchPressed;

  const GlassNavBar({super.key, this.onSearchPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 provider 获取导航项数据
    final navItemsAsync = ref.watch(navItemsProvider);
    // 从 provider 获取当前激活的索引
    final activeIndex = ref.watch(activeNavIndexProvider);
    // 获取当前布局模式
    final currentLayout = ref.watch(noteLayoutProvider);

    // 获取当前主题亮度
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return navItemsAsync.when(
      data: (navItems) {
        // 如果没有导航项，返回空容器
        if (navItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主导航栏（毛玻璃效果）
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      // 根据主题调整毛玻璃颜色 - 亮色模式使用更深的背景
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05), // 改用黑色半透明
                      borderRadius: BorderRadius.circular(100.0),
                      // 添加边框以在亮色模式下提供对比度
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.08), // 使用黑色半透明边框
                        width: 1.0,
                      ),
                      // 添加微妙阴影
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.08,
                          ),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(navItems.length, (index) {
                          final item = navItems[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == navItems.length - 1 ? 0 : 6.0,
                            ),
                            child: ItemBar(
                              svgPath: item.svgPath,
                              text: item.text,
                              isActive: activeIndex == index,
                              onTap: () {
                                ref
                                        .read(activeNavIndexProvider.notifier)
                                        .state =
                                    index;
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 布局切换按钮
            _buildIconButton(
              context,
              icon: currentLayout == NoteLayout.grid
                  ? Icons.view_list
                  : Icons.view_module,
              onPressed: () {
                // 切换布局模式
                final newLayout = currentLayout == NoteLayout.grid
                    ? NoteLayout.list
                    : NoteLayout.grid;
                ref.read(noteLayoutProvider.notifier).state = newLayout;
              },
              isDark: isDark,
            ),

            const SizedBox(width: 8),

            // 搜索按钮
            _buildIconButton(
              context,
              icon: Icons.search,
              onPressed: onSearchPressed ?? () {},
              isDark: isDark,
            ),

            const SizedBox(width: 8),

            // 设置按钮
            _buildIconButton(
              context,
              icon: Icons.settings,
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              isDark: isDark,
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) {
        debugPrint('Error loading nav items: $error');
        return const SizedBox.shrink();
      },
    );
  }

  // 构建图标按钮的辅助方法
  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        // 亮色模式使用黑色半透明，暗色模式使用白色半透明
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.primary,
        iconSize: 22,
      ),
    );
  }
}
