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
    tertiary: Color(0xFF3A3A3A), // Done/FAB按钮背景 - 深木炭色
    onTertiary: Color(0xFFFFFFFF), // Done/FAB按钮文本
    surfaceContainerHighest: Color(0xFFE58F6F), // 点睛色 - 赤陶色
    outline: Color(0xCCFAF9F7), // 画布遮罩 - 80%透明米白
    onSurfaceVariant: Color(0xFF9B9691), // 辅助文字（副文本）
    outlineVariant: Color(0xFFD6D2CE), //分割线/描边颜色
  ),
  scaffoldBackgroundColor: const Color(0xFFFAF9F7), // 画布背景
  canvasColor: const Color(0xFFFAF9F7), // 画布背景
  cardColor: Colors.white, // 卡片在画布上"浮"起来
  shadowColor: Colors.black.withOpacity(0.05), // 柔和的阴影
  fontFamily: 'SF Pro',
  textTheme: const TextTheme(
    // 标题样式
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF423B38),
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF423B38),
    ),
    // 正文样式
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF423B38), height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF423B38), height: 1.5),
    // 辅助文字（时间、提示等）
    bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9B9691)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFF423B38),
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF423B38),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF3A3A3A), // 与Done按钮一致
    foregroundColor: Color(0xFFFFFFFF),
    shape: StadiumBorder(),
    elevation: 4,
  ),
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
    tertiary: Color(0xFFEAE5E0), // Done/FAB按钮背景 - 使用主文本色（反转设计）
    onTertiary: Color(0xFF2B2A28), // Done/FAB按钮文本 - 使用画布色
    surfaceContainerHighest: Color(0xFFB9A389), // 点睛色 - 橄榄金
    outline: Color(0xCC2B2A28), // 画布遮罩 - 80%透明深暖灰
    onSurfaceVariant: Color(0xFFA5A19C), // 辅助文字（副文本）
    outlineVariant: Color(0xFF4A4744), //分割线/描边颜色
  ),
  scaffoldBackgroundColor: const Color(0xFF2B2A28), // 画布背景
  canvasColor: const Color(0xFF2B2A28), // 画布背景
  cardColor: const Color(0xFF3A3734), // 卡片稍亮于画布
  shadowColor: Colors.black.withOpacity(0.3), // 暗色模式的阴影稍深
  fontFamily: 'SF Pro',
  textTheme: const TextTheme(
    // 标题样式
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFEAE5E0),
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFFEAE5E0),
    ),
    // 正文样式
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFEAE5E0), height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFEAE5E0), height: 1.5),
    // 辅助文字（时间、提示等）
    bodySmall: TextStyle(fontSize: 12, color: Color(0xFFA5A19C)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFFEAE5E0),
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFEAE5E0),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFEAE5E0), // 反转设计 - 浅色背景
    foregroundColor: Color(0xFF2B2A28), // 深色文字
    shape: StadiumBorder(),
    elevation: 4,
  ),
);
