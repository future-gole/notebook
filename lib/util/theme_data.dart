// 主题定义 - "亮色模式" (赤陶与暖沙)
import 'package:flutter/material.dart';

final ThemeData calmBeigeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF423B38), // 主文本色 - 深暖棕褐色
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9B9691), // 副文本色 - 温暖褐灰色
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFAF9F7), // 卡片背景
    onSurface: Color(0xFF423B38),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    // 自定义颜色
    tertiary: Color(0xFF3A3A3A), // Done按钮背景 - 深木炭色
    onTertiary: Color(0xFFFFFFFF), // Done按钮文本
    surfaceContainerHighest: Color(0xFFE58F6F), // 点睛色 - 赤陶色
    outline: Color(0xCCFAF9F7), // 画布遮罩 - 80%透明米白
  ),
  fontFamily: 'SF Pro',
);

// 主题定义 - "暗色模式" (静谧之夜与橄榄金)
final ThemeData quietNightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEAE5E0), // 主文本色 - 柔和米白色
    onPrimary: Color(0xFF2B2A28),
    secondary: Color(0xFFA5A19C), // 副文本色 - 哑光浅暖灰
    onSecondary: Color(0xFF2B2A28),
    surface: Color(0xFF3A3734), // 卡片背景 - 稍亮于画布
    onSurface: Color(0xFFEAE5E0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    // 自定义颜色
    tertiary: Color(0xFFEAE5E0), // Done按钮背景 - 使用主文本色
    onTertiary: Color(0xFF2B2A28), // Done按钮文本 - 使用画布色
    surfaceContainerHighest: Color(0xFFB9A389), // 点睛色 - 橄榄金
    outline: Color(0xCC2B2A28), // 画布遮罩 - 80%透明深暖灰
  ),
  fontFamily: 'SF Pro',
);