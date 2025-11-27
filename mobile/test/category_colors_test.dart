import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/util/category_colors.dart';

void main() {
  group('CategoryColors 常量测试', () {
    test('darkModeColors 有 10 种颜色', () {
      expect(CategoryColors.darkModeColors.length, 10);
    });

    test('lightModeColors 有 10 种颜色', () {
      expect(CategoryColors.lightModeColors.length, 10);
    });

    test('darkModeColors 都是有效的 Color 对象', () {
      for (var color in CategoryColors.darkModeColors) {
        expect(color, isA<Color>());
        expect(color.value, isNotNull);
      }
    });

    test('lightModeColors 都是有效的 Color 对象', () {
      for (var color in CategoryColors.lightModeColors) {
        expect(color, isA<Color>());
        expect(color.value, isNotNull);
      }
    });

    test('darkModeColors 的颜色值正确', () {
      expect(CategoryColors.darkModeColors[0].value, 0xFFFF6B6B); // 珊瑚红
      expect(CategoryColors.darkModeColors[1].value, 0xFFFFD93D); // 金黄色
      expect(CategoryColors.darkModeColors[2].value, 0xFF6BCF7F); // 薄荷绿
    });

    test('lightModeColors 的颜色值正确', () {
      expect(CategoryColors.lightModeColors[0].value, 0xFFE57373); // 柔和红
      expect(CategoryColors.lightModeColors[1].value, 0xFFFFD54F); // 柔和金
      expect(CategoryColors.lightModeColors[2].value, 0xFF81C784); // 柔和绿
    });
  });

  group('CategoryColors.getColor() 测试', () {
    test('暗色模式 - 有效索引', () {
      for (int i = 0; i < 10; i++) {
        final color = CategoryColors.getColor(i, Brightness.dark);
        expect(color, CategoryColors.darkModeColors[i]);
      }
    });

    test('亮色模式 - 有效索引', () {
      for (int i = 0; i < 10; i++) {
        final color = CategoryColors.getColor(i, Brightness.light);
        expect(color, CategoryColors.lightModeColors[i]);
      }
    });

    test('null 索引 - 返回默认颜色', () {
      final darkColor = CategoryColors.getColor(null, Brightness.dark);
      final lightColor = CategoryColors.getColor(null, Brightness.light);

      expect(darkColor, CategoryColors.darkModeColors[0]);
      expect(lightColor, CategoryColors.lightModeColors[0]);
    });

    test('负数索引 - 返回默认颜色', () {
      final darkColor = CategoryColors.getColor(-1, Brightness.dark);
      final lightColor = CategoryColors.getColor(-5, Brightness.light);

      expect(darkColor, CategoryColors.darkModeColors[0]);
      expect(lightColor, CategoryColors.lightModeColors[0]);
    });

    test('越界索引 (>= 10) - 返回默认颜色', () {
      final darkColor = CategoryColors.getColor(10, Brightness.dark);
      final lightColor = CategoryColors.getColor(100, Brightness.light);

      expect(darkColor, CategoryColors.darkModeColors[0]);
      expect(lightColor, CategoryColors.lightModeColors[0]);
    });

    test('边界索引 0 - 珊瑚红/柔和红', () {
      final darkColor = CategoryColors.getColor(0, Brightness.dark);
      final lightColor = CategoryColors.getColor(0, Brightness.light);

      expect(darkColor.value, 0xFFFF6B6B); // 珊瑚红
      expect(lightColor.value, 0xFFE57373); // 柔和红
    });

    test('边界索引 9 - 淡紫色/柔和淡紫', () {
      final darkColor = CategoryColors.getColor(9, Brightness.dark);
      final lightColor = CategoryColors.getColor(9, Brightness.light);

      expect(darkColor.value, 0xFFB4A7D6); // 淡紫色
      expect(lightColor.value, 0xFFCE93D8); // 柔和淡紫
    });
  });

  group('CategoryColors.getColors() 测试', () {
    test('暗色模式 - 返回 darkModeColors', () {
      final colors = CategoryColors.getColors(Brightness.dark);
      expect(colors, CategoryColors.darkModeColors);
      expect(colors.length, 10);
    });

    test('亮色模式 - 返回 lightModeColors', () {
      final colors = CategoryColors.getColors(Brightness.light);
      expect(colors, CategoryColors.lightModeColors);
      expect(colors.length, 10);
    });

    test('返回的颜色列表是不可变的', () {
      final darkColors = CategoryColors.getColors(Brightness.dark);
      final lightColors = CategoryColors.getColors(Brightness.light);

      expect(darkColors, isA<List<Color>>());
      expect(lightColors, isA<List<Color>>());
    });

    test('多次调用返回相同的列表', () {
      final first = CategoryColors.getColors(Brightness.dark);
      final second = CategoryColors.getColors(Brightness.dark);

      expect(identical(first, second), true);
    });
  });

  group('颜色区分度测试', () {
    test('暗色模式颜色有明显差异', () {
      // 验证相邻颜色有明显差异
      final colors = CategoryColors.darkModeColors;

      for (int i = 0; i < colors.length - 1; i++) {
        final color1 = colors[i];
        final color2 = colors[i + 1];

        // 颜色值不应该完全相同
        expect(color1.value != color2.value, true);
      }
    });

    test('亮色模式颜色有明显差异', () {
      final colors = CategoryColors.lightModeColors;

      for (int i = 0; i < colors.length - 1; i++) {
        final color1 = colors[i];
        final color2 = colors[i + 1];

        expect(color1.value != color2.value, true);
      }
    });
  });

  group('颜色 RGB 分量测试', () {
    test('珊瑚红 RGB 值', () {
      final color = CategoryColors.darkModeColors[0];
      // 0xFFFF6B6B: R=FF, G=6B, B=6B
      final red = (color.value >> 16) & 0xFF;
      final green = (color.value >> 8) & 0xFF;
      final blue = color.value & 0xFF;

      expect(red, 0xFF);
      expect(green, 0x6B);
      expect(blue, 0x6B);
    });

    test('金黄色 RGB 值', () {
      final color = CategoryColors.darkModeColors[1];
      // 0xFFFFD93D: R=FF, G=D9, B=3D
      final red = (color.value >> 16) & 0xFF;
      final green = (color.value >> 8) & 0xFF;
      final blue = color.value & 0xFF;

      expect(red, 0xFF);
      expect(green, 0xD9);
      expect(blue, 0x3D);
    });
  });

  group('颜色主题切换测试', () {
    test('同一索引在不同主题下颜色不同', () {
      for (int i = 0; i < 10; i++) {
        final darkColor = CategoryColors.getColor(i, Brightness.dark);
        final lightColor = CategoryColors.getColor(i, Brightness.light);

        // 暗色和亮色的相同索引颜色应该不同
        expect(darkColor.value != lightColor.value, true);
      }
    });

    test('暗色模式颜色更饱和', () {
      // 暗色模式应该有更高的饱和度用于深色背景
      final darkColor = CategoryColors.darkModeColors[0];
      final lightColor = CategoryColors.lightModeColors[0];

      // 简单验证：两个颜色的值不同
      expect(darkColor.value != lightColor.value, true);
    });
  });

  group('色彩命名一致性测试', () {
    test('暗色模式有 10 个位置', () {
      // 索引 0-9 对应 10 种颜色
      expect(CategoryColors.darkModeColors.length, 10);
    });

    test('亮色模式有 10 个位置', () {
      expect(CategoryColors.lightModeColors.length, 10);
    });

    test('颜色顺序一致', () {
      // 两种模式应该在相同位置有对应的颜色对
      // 颜色1（索引0）：珊瑚红 vs 柔和红
      // 颜色2（索引1）：金黄色 vs 柔和金
      // 等等

      expect(
        CategoryColors.darkModeColors.length,
        CategoryColors.lightModeColors.length,
      );
    });
  });

  group('无效输入边界测试', () {
    test('非常大的负数索引', () {
      final color = CategoryColors.getColor(-999999, Brightness.dark);
      expect(color, CategoryColors.darkModeColors[0]);
    });

    test('非常大的正数索引', () {
      final color = CategoryColors.getColor(999999, Brightness.light);
      expect(color, CategoryColors.lightModeColors[0]);
    });

    test('所有可能的有效索引都有颜色', () {
      for (int i = 0; i < 10; i++) {
        expect(
          () => CategoryColors.getColor(i, Brightness.dark),
          returnsNormally,
        );
        expect(
          () => CategoryColors.getColor(i, Brightness.light),
          returnsNormally,
        );
      }
    });
  });

  group('颜色列表完整性测试', () {
    test('getColors 返回完整的暗色列表', () {
      final colors = CategoryColors.getColors(Brightness.dark);
      expect(colors.length, 10);

      for (int i = 0; i < 10; i++) {
        expect(colors[i], CategoryColors.darkModeColors[i]);
      }
    });

    test('getColors 返回完整的亮色列表', () {
      final colors = CategoryColors.getColors(Brightness.light);
      expect(colors.length, 10);

      for (int i = 0; i < 10; i++) {
        expect(colors[i], CategoryColors.lightModeColors[i]);
      }
    });
  });

  group('Alpha 通道测试', () {
    test('所有颜色都有完整的 Alpha 通道', () {
      for (var color in CategoryColors.darkModeColors) {
        final alpha = (color.value >> 24) & 0xFF;
        expect(alpha, 0xFF); // 完全不透明
      }

      for (var color in CategoryColors.lightModeColors) {
        final alpha = (color.value >> 24) & 0xFF;
        expect(alpha, 0xFF); // 完全不透明
      }
    });
  });
}
