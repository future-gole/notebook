import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemBar extends StatelessWidget {
  // 假设这些是来自 'assets/' 的路径
  final String svgPath;
  final String text;
  final bool isActive;
  final VoidCallback onTap;


  const ItemBar({
    super.key,
    required this.svgPath,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 根据 'isActive' 状态定义样式
    // 匹配 Variant 1 的 'bg-white/30' (激活)
    final Color bgColor =
    isActive ? Color(0xE22583DF) : Colors.transparent;

    // 匹配 'text-white' (激活) vs 'text-white/80' (非激活)
    final Color textColor =
    isActive ? Colors.white : Colors.white.withValues(alpha: 0.8);

    // 匹配 'font-semibold' (激活) vs 'font-medium' (非激活)
    final FontWeight fontWeight =
    isActive ? FontWeight.w600 : FontWeight.w500;

    // 匹配 'shadow-xl' (激活)
    final List<BoxShadow>? boxShadow = isActive
        ? [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ]
        : null;

    // 2. 模拟激活项的 '悬浮微光' (before:animate-pulse-slow)
    // 这是一个静态的从左上到右下的渐变，模仿 '微光'
    final Gradient? activeGradient = isActive
        ? LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.5),
        Colors.white.withValues(alpha:0.0),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : null;

    // 3. 使用 GestureDetector 监听点击
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // 匹配 'px-4 py-2.5'
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bgColor,
          gradient: activeGradient,
          // 匹配 'rounded-full'
          borderRadius: BorderRadius.circular(100.0),
          boxShadow: boxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              // 匹配 'nav-icon' 尺寸和 'text-white' 颜色
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              width: 20,
              height: 20,
            ),
            // 匹配 'gap-2'
            const SizedBox(width: 8.0),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                // 匹配 'text-sm'
                fontSize: 14,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
