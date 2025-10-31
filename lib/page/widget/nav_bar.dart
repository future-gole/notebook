import 'dart:ui'; // 用于 ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'item_bar.dart'; // 导入我们刚创建的 ItemBar

///
/// 这是包含 ItemBar 的主导航栏。
/// 它实现了玻璃拟态背景和状态管理。
/// 使用 Riverpod 进行依赖注入和状态管理。
///
class GlassNavBar extends ConsumerWidget {
  const GlassNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 provider 获取导航项数据
    final navItemsAsync = ref.watch(navItemsProvider);
    // 从 provider 获取当前激活的索引
    final activeIndex = ref.watch(activeNavIndexProvider);

    return navItemsAsync.when(
      data: (navItems) {
        // 如果没有导航项，返回空容器
        if (navItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(100.0), // 匹配 'rounded-full'
          child: BackdropFilter(
            // 匹配 'backdrop-blur-lg'
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              // 匹配 'p-2'
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                // 匹配 'bg-white/10'
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // 使 Row 包裹内容
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  return Padding(
                    // 模拟 'gap-1.5' (6px)。
                    padding: EdgeInsets.only(
                      // 最后一个 item 右侧没有间距
                      right: index == navItems.length - 1 ? 0 : 6.0,
                    ),
                    child: ItemBar(
                      svgPath: item.svgPath,
                      text: item.text,
                      // 检查当前 index 是否为激活 index
                      isActive: activeIndex == index,
                      onTap: () {
                        // 点击时，更新 provider 中的状态
                        ref.read(activeNavIndexProvider.notifier).state = index;
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) {
        // 发生错误时显示错误信息或返回默认 UI
        debugPrint('Error loading nav items: $error');
        return const SizedBox.shrink();
      },
    );
  }
}
