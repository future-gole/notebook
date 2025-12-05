// 主题定义 - 统一的亮色/暗色主题
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 流动背景颜色 - 亮色模式
class LightFlowingBackgroundColors {
  static const Color blob1 = Color(0xFFE58F6F); // 赤陶橙
  static const Color blob2 = Color(0xFFF4A261); // 温暖杏色
  static const Color blob3 = Color(0xFFE76F51); // 珊瑚橙
  static const Color blob4 = Color(0xFF2A9D8F); // 青绿色
}

// 流动背景颜色 - 暗色模式
class DarkFlowingBackgroundColors {
  static const Color blob1 = Color(0xFFFF6B35); // 明亮橙红
  static const Color blob2 = Color(0xFF8B5CF6); // 紫色
  static const Color blob3 = Color(0xFF3B82F6); // 蓝色
  static const Color blob4 = Color(0xFFF59E0B); // 金色
}

class SharePageThemeColors extends ThemeExtension<SharePageThemeColors> {
  const SharePageThemeColors({required this.primary, required this.secondary});

  final Color? primary;
  final Color? secondary;

  @override
  SharePageThemeColors copyWith({Color? primary, Color? secondary}) {
    return SharePageThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
    );
  }

  @override
  SharePageThemeColors lerp(
    ThemeExtension<SharePageThemeColors>? other,
    double t,
  ) {
    if (other is! SharePageThemeColors) {
      return this;
    }
    return SharePageThemeColors(
      primary: Color.lerp(primary, other.primary, t),
      secondary: Color.lerp(secondary, other.secondary, t),
    );
  }

  static SharePageThemeColors? of(BuildContext context) {
    return Theme.of(context).extension<SharePageThemeColors>();
  }
}

const lightShareColors = SharePageThemeColors(
  primary: Color(0xFFFFFFFF),
  secondary: Color(0xFFEAE5E0),
);

const darkShareColors = SharePageThemeColors(
  primary: Color(0xFFFFFFFF),
  secondary: Color(0xFFEAE5E0),
);

// 暗色模式
final ThemeData calmBeigeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3A3A35), // 主文本色
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9B9691), // 副文本色
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF), // 卡片背景
    onSurface: Color(0xFF3A3A35),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    // 强调色 - 赤陶色
    tertiary: Color(0xFFD97757),
    onTertiary: Color(0xFFFFFFFF),
    // 侧边栏/次级背景色
    surfaceContainerLow: Color(0xFFF2F0ED),
    // 点睛色
    surfaceContainerHighest: Color(0xFFD97757),
    outline: Color(0xFFE0DDD9), // 分割线颜色
    onSurfaceVariant: Color(0xFF9B9691),
    outlineVariant: Color(0xFFD6D2CE),
  ),
  switchTheme: SwitchThemeData(
    // 1. 定义滑块颜色 (Thumb)
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFD97757); // 【打开】状态：橙色
      }
      // 【关闭】状态：显式指定为灰色/白色，不要返回 null
      return const Color(0xFF79747E);
    }),

    // 2. 定义轨道颜色 (Track)
    trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFD97757).withOpacity(0.5); // 【打开】状态：淡橙色
      }
      // 【关闭】状态：显式指定为浅灰色
      return const Color(0xFFE7E0EC);
    }),

    // 3. 定义轨道边框
    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent; // 打开时不要边框
      }
      return const Color(0xFF79747E); // 关闭时显示深灰边框
    }),
  ),
  scaffoldBackgroundColor: const Color(0xFFF2F0ED), // Scaffold 背景
  canvasColor: const Color(0xFFF2F0ED),
  cardColor: const Color(0xFFFFFFFF), // 卡片背景
  shadowColor: Colors.black.withOpacity(0.05),
  fontFamily: 'SF Pro',
  textTheme: TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'Merriweather',
      fontFamilyFallback: const ['LXGWWenKaiLite'],
      fontSize: 24.sp,
      fontWeight: FontWeight.w900,
      // 杂志感大标题稍微收紧字母间距
      letterSpacing: -0.5,
      // 标题行高要小，避免松散
      height: 1.2,
      color: const Color(0xFF3A3A35),
    ),

    titleMedium: TextStyle(
      fontFamily: 'Merriweather',
      fontFamilyFallback: const ['LXGWWenKaiLite'],
      fontSize: 18.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
      color: const Color(0xFF3A3A35),
    ),
    bodyLarge: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      // 杂志感正文行高 1.6 倍
      height: 1.6,
      color: const Color(0xFF3A3A35),
    ),

    bodyMedium: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: const Color(0xFF3A3A35),
    ),

    bodySmall: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: const Color(0xFF3A3A35),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFF3A3A35),
    titleTextStyle: TextStyle(
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: Color(0xFF3A3A35),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFD97757), // 强调色
    foregroundColor: Color(0xFFFFFFFF),
    shape: StadiumBorder(),
    elevation: 4,
  ),
  extensions: const <ThemeExtension<dynamic>>[lightShareColors],
);

// 暗色模式
final ThemeData quietNightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA1A1AA), // 主文本色 - 柔和灰白
    onPrimary: Color(0xFF09090B),
    secondary: Color(0xFF71717A), // 副文本色
    onSecondary: Color(0xFF09090B),
    surface: Color(0xFF202022), // 卡片背景
    onSurface: Color(0xFFA1A1AA),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    // 强调色 - 暖橙
    tertiary: Color(0xFFE58F6F),
    onTertiary: Color(0xFF09090B),
    // 侧边栏/次级背景色 - 纯黑
    surfaceContainerLow: Color(0xFF151515),
    // 点睛色
    surfaceContainerHighest: Color(0xFFE58F6F),
    outline: Color(0xBB838282), // 分割线颜色
    onSurfaceVariant: Color(0xFFC6C1C1),
    outlineVariant: Color(0xFF3F3F46),
  ),
  switchTheme: SwitchThemeData(
    // 1. 定义滑块颜色 (Thumb)
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFD97757); // 【打开】状态：橙色
      }
      // 【关闭】状态：显式指定为灰色/白色，不要返回 null
      return const Color(0xFF79747E);
    }),

    // 2. 定义轨道颜色 (Track)
    trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFD97757).withOpacity(0.5); // 【打开】状态：淡橙色
      }
      // 【关闭】状态：显式指定为浅灰色
      return const Color(0xFFE7E0EC);
    }),

    // 3. 定义轨道边框 (可选，让关闭状态更清晰)
    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent; // 打开时不要边框
      }
      return const Color(0xFF79747E); // 关闭时显示深灰边框
    }),
  ),
  scaffoldBackgroundColor: const Color(0xFF09090B), // Scaffold 背景
  canvasColor: const Color(0xFF09090B),
  cardColor: const Color(0xFF18181B), // 卡片背景 - 提亮
  shadowColor: Colors.black.withOpacity(0.3),
  fontFamily: 'SF Pro',
  textTheme: TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'Merriweather',
      fontFamilyFallback: const ['LXGWWenKaiLite'],
      fontSize: 32.sp,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      // 标题行高要小，避免松散
      height: 1.2,
      color: const Color(0xFFE4E4E6),
    ),

    titleMedium: TextStyle(
      fontFamily: 'Merriweather',
      fontFamilyFallback: const ['LXGWWenKaiLite'],
      fontSize: 18.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.25,
      color: const Color(0xFFE4E4E6),
    ),

    bodyLarge: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: const Color(0xFFA1A1AA),
    ),

    bodyMedium: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      height: 1.6,
      color: const Color(0xFFA1A1AA),
    ),

    bodySmall: TextStyle(
      fontFamily: 'LXGWWenKaiLite',
      fontFamilyFallback: const ['Merriweather'],
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: const Color(0xFF71717A),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFFA1A1AA),
    titleTextStyle: TextStyle(
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: Color(0xFFA1A1AA),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFE58F6F), // 强调色
    foregroundColor: Color(0xFFFFFFFF),
    shape: StadiumBorder(),
    elevation: 4,
  ),
  extensions: const <ThemeExtension<dynamic>>[darkShareColors],
);
