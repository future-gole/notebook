import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';

/// 布局切换按钮组件
/// 用于切换卡片布局和列表布局
class LayoutToggleButton extends ConsumerWidget {
  const LayoutToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final isGridMode = config.waterfallLayoutEnabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayoutButton(
            icon: Icons.grid_view_rounded,
            isActive: isGridMode,
            onTap: () {
              if (!isGridMode) {
                config.setWaterFallLayout(true);
              }
            },
          ),
          const SizedBox(width: 4),
          _LayoutButton(
            icon: Icons.view_list_rounded,
            isActive: !isGridMode,
            onTap: () {
              if (isGridMode) {
                config.setWaterFallLayout(false);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 单个布局切换按钮
class _LayoutButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _LayoutButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_LayoutButton> createState() => _LayoutButtonState();
}

class _LayoutButtonState extends State<_LayoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
                : (_isHovered
                    ? (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isActive
                ? colorScheme.tertiary
                : colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

/// 主题切换按钮
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // 主题切换逻辑 - 可扩展
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 20,
            color: colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

/// 桌面端顶部导航栏
/// 包含搜索栏、主题切换和布局切换
class DesktopHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback? onSearchSubmit;

  const DesktopHeader({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    this.onSearchSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Windows 平台预留右侧窗口控制按钮空间
    // 在小窗口模式下减少右侧留白，避免溢出
    final rightPadding = Platform.isWindows
        ? (screenWidth < 600 ? 60.0 : 140.0)
        : 24.0;

    return Container(
      height: 72,
      padding: EdgeInsets.fromLTRB(32, 0, rightPadding, 0),
      child: Row(
        children: [
          // 搜索栏 - 居中对齐，限制最大宽度
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _DesktopSearchBar(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onSubmitted: onSearchSubmit,
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // 右侧功能按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemeToggleButton(),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: colorScheme.outlineVariant,
              ),
              const SizedBox(width: 8),
              const LayoutToggleButton(),
            ],
          ),
        ],
      ),
    );
  }
}

/// 桌面端搜索栏组件
class _DesktopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSubmitted;

  const _DesktopSearchBar({
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(Icons.search, size: 18, color: colorScheme.secondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: '搜索收藏...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintStyle: TextStyle(
                  color: colorScheme.secondary.withOpacity(0.6),
                  fontSize: 14,
                ),
                isDense: true,
              ),
              style: TextStyle(color: colorScheme.primary, fontSize: 14),
              onSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox(width: 14);
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    controller.clear();
                    focusNode.requestFocus();
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.secondary.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
