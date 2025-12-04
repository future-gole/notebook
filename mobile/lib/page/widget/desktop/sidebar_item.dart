import 'package:flutter/material.dart';

/// 侧边栏分类条目组件
/// 可复用的侧边栏导航项，支持选中态和悬停效果
class SidebarItem extends StatefulWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SidebarItem({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 背景颜色逻辑
    Color backgroundColor;
    if (widget.isActive) {
      backgroundColor = colorScheme.tertiary.withOpacity(isDark ? 0.15 : 0.12);
    } else if (_isHovered) {
      backgroundColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03);
    } else {
      backgroundColor = Colors.transparent;
    }

    // 文本颜色
    final textColor = widget.isActive
        ? colorScheme.tertiary
        : colorScheme.primary.withOpacity(0.8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 分类图标 (使用 # 符号风格)
              Text(
                '·',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              // 分类名称
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 更多选项按钮 (仅在悬停或激活且有删除回调时显示)
              if ((_isHovered || widget.isActive) && widget.onDelete != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                    tooltip: '更多选项',
                    elevation: 4,
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        height: 32,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '删除',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
