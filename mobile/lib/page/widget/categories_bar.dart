import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/nav_providers.dart';

import 'item_bar.dart';

class CategoriesBar extends ConsumerWidget {

  const CategoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 provider 获取导航项数据
    final navItemsAsync = ref.watch(navItemsProvider);
    // 从 provider 获取当前激活的索引
    final activeIndex = ref.watch(activeNavIndexProvider);

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
                                ref.read(activeNavIndexProvider.notifier)
                                    .state = index;
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
}