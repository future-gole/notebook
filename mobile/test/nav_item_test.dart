import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/model/nav_item.dart';

void main() {
  group('NavItem 模型测试', () {
    test('NavItem 基础初始化', () {
      final navItem = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );

      expect(navItem.svgPath, 'assets/home.svg');
      expect(navItem.text, 'Home');
      expect(navItem.category, 'home');
      expect(navItem.categoryId, 1); // 默认值
    });

    test('NavItem 带自定义 categoryId', () {
      final navItem = NavItem(
        svgPath: 'assets/work.svg',
        text: 'Work',
        category: 'work',
        categoryId: 2,
      );

      expect(navItem.categoryId, 2);
      expect(navItem.text, 'Work');
    });

    test('NavItem 所有字段都必需（除了 categoryId）', () {
      expect(
        () =>
            NavItem(svgPath: 'assets/icon.svg', text: 'Test', category: 'test'),
        returnsNormally,
      );
    });

    test('NavItem 相等性比较 - 相同内容', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
        categoryId: 1,
      );
      final item2 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
        categoryId: 1,
      );

      expect(item1, item2);
    });

    test('NavItem 相等性比较 - 不同 svgPath', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );
      final item2 = NavItem(
        svgPath: 'assets/home2.svg',
        text: 'Home',
        category: 'home',
      );

      expect(item1 != item2, true);
    });

    test('NavItem 相等性比较 - 不同 categoryId', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
        categoryId: 1,
      );
      final item2 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
        categoryId: 2,
      );

      expect(item1 != item2, true);
    });

    test('NavItem hashCode 一致性', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );
      final item2 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );

      expect(item1.hashCode, item2.hashCode);
    });

    test('NavItem 在 Set 中的去重', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );
      final item2 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );
      final item3 = NavItem(
        svgPath: 'assets/work.svg',
        text: 'Work',
        category: 'work',
      );

      final set = {item1, item2, item3};
      expect(set.length, 2); // item1 和 item2 相同，应该合并
    });

    test('NavItem 在 Map 中作为 key', () {
      final item1 = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );
      final item2 = NavItem(
        svgPath: 'assets/work.svg',
        text: 'Work',
        category: 'work',
      );

      final map = {item1: 'Home', item2: 'Work'};
      expect(map.length, 2);
      expect(map[item1], 'Home');
    });

    test('NavItem 字段完整性', () {
      final item = NavItem(
        svgPath: 'assets/study.svg',
        text: 'Study',
        category: 'study',
        categoryId: 3,
      );

      expect(item.svgPath, isNotEmpty);
      expect(item.text, isNotEmpty);
      expect(item.category, isNotEmpty);
      expect(item.categoryId, greaterThan(0));
    });

    test('NavItem const 构造函数', () {
      const item = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Home',
        category: 'home',
      );

      expect(item.text, 'Home');
    });

    test('NavItem 路径格式验证', () {
      final item = NavItem(
        svgPath: 'assets/icons/home.svg',
        text: 'Home',
        category: 'home',
      );

      expect(item.svgPath, contains('assets'));
      expect(item.svgPath, endsWith('.svg'));
    });

    test('NavItem 特殊字符支持', () {
      final item = NavItem(
        svgPath: 'assets/home_icon.svg',
        text: '工作 & 生活',
        category: 'work_life',
      );

      expect(item.text, contains('&'));
      expect(item.category, contains('_'));
    });

    test('NavItem categoryId 边界值', () {
      final min = NavItem(
        svgPath: 'assets/home.svg',
        text: 'Min',
        category: 'min',
        categoryId: 1,
      );

      final max = NavItem(
        svgPath: 'assets/max.svg',
        text: 'Max',
        category: 'max',
        categoryId: 999999,
      );

      expect(min.categoryId, 1);
      expect(max.categoryId, 999999);
    });
  });

  group('NavItem 列表操作测试', () {
    test('创建导航项列表', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
        NavItem(svgPath: 'assets/study.svg', text: 'Study', category: 'study'),
      ];

      expect(navItems.length, 3);
    });

    test('通过索引访问导航项', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
      ];

      expect(navItems[0].text, 'Home');
      expect(navItems[1].text, 'Work');
    });

    test('查找导航项', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(
          svgPath: 'assets/work.svg',
          text: 'Work',
          category: 'work',
          categoryId: 2,
        ),
        NavItem(
          svgPath: 'assets/study.svg',
          text: 'Study',
          category: 'study',
          categoryId: 3,
        ),
      ];

      final found = navItems.firstWhere(
        (item) => item.categoryId == 2,
        orElse: () => NavItem(svgPath: '', text: '', category: ''),
      );

      expect(found.text, 'Work');
    });

    test('过滤导航项', () {
      final navItems = [
        NavItem(
          svgPath: 'assets/home.svg',
          text: 'Home',
          category: 'home',
          categoryId: 1,
        ),
        NavItem(
          svgPath: 'assets/work.svg',
          text: 'Work',
          category: 'work',
          categoryId: 2,
        ),
        NavItem(
          svgPath: 'assets/study.svg',
          text: 'Study',
          category: 'study',
          categoryId: 3,
        ),
      ];

      final filtered = navItems.where((item) => item.categoryId > 1).toList();

      expect(filtered.length, 2);
      expect(filtered.every((item) => item.categoryId > 1), true);
    });

    test('映射导航项属性', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
      ];

      final texts = navItems.map((item) => item.text).toList();

      expect(texts, ['Home', 'Work']);
    });

    test('排序导航项', () {
      final navItems = [
        NavItem(
          svgPath: 'assets/c.svg',
          text: 'C',
          category: 'c',
          categoryId: 3,
        ),
        NavItem(
          svgPath: 'assets/a.svg',
          text: 'A',
          category: 'a',
          categoryId: 1,
        ),
        NavItem(
          svgPath: 'assets/b.svg',
          text: 'B',
          category: 'b',
          categoryId: 2,
        ),
      ];

      navItems.sort((a, b) => a.categoryId.compareTo(b.categoryId));

      expect(navItems[0].categoryId, 1);
      expect(navItems[1].categoryId, 2);
      expect(navItems[2].categoryId, 3);
    });

    test('反转导航项顺序', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
        NavItem(svgPath: 'assets/study.svg', text: 'Study', category: 'study'),
      ];

      final reversed = navItems.reversed.toList();

      expect(reversed[0].text, 'Study');
      expect(reversed[2].text, 'Home');
    });

    test('获取导航项子集', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
        NavItem(svgPath: 'assets/study.svg', text: 'Study', category: 'study'),
        NavItem(svgPath: 'assets/life.svg', text: 'Life', category: 'life'),
      ];

      final subset = navItems.sublist(1, 3);

      expect(subset.length, 2);
      expect(subset[0].text, 'Work');
      expect(subset[1].text, 'Study');
    });

    test('添加导航项', () {
      final navItems = <NavItem>[
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
      ];

      navItems.add(
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
      );

      expect(navItems.length, 2);
      expect(navItems.last.text, 'Work');
    });

    test('删除导航项', () {
      final navItems = [
        NavItem(
          svgPath: 'assets/home.svg',
          text: 'Home',
          category: 'home',
          categoryId: 1,
        ),
        NavItem(
          svgPath: 'assets/work.svg',
          text: 'Work',
          category: 'work',
          categoryId: 2,
        ),
      ];

      navItems.removeWhere((item) => item.categoryId == 2);

      expect(navItems.length, 1);
      expect(navItems[0].text, 'Home');
    });

    test('检查导航项存在性', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
      ];

      expect(navItems.any((item) => item.text == 'Home'), true);
      expect(navItems.any((item) => item.text == 'Study'), false);
    });

    test('验证所有导航项都有效', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
        NavItem(svgPath: 'assets/study.svg', text: 'Study', category: 'study'),
      ];

      final allValid = navItems.every(
        (item) =>
            item.svgPath.isNotEmpty &&
            item.text.isNotEmpty &&
            item.category.isNotEmpty,
      );

      expect(allValid, true);
    });

    test('获取导航项总数', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
        NavItem(svgPath: 'assets/study.svg', text: 'Study', category: 'study'),
        NavItem(svgPath: 'assets/life.svg', text: 'Life', category: 'life'),
        NavItem(
          svgPath: 'assets/travel.svg',
          text: 'Travel',
          category: 'travel',
        ),
      ];

      expect(navItems.length, 5);
    });
  });

  group('NavItem 文本匹配测试', () {
    test('精确匹配导航项', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(svgPath: 'assets/work.svg', text: 'Work', category: 'work'),
      ];

      final home = navItems.firstWhere(
        (item) => item.text == 'Home',
        orElse: () => NavItem(svgPath: '', text: '', category: ''),
      );

      expect(home.text, 'Home');
    });

    test('不区分大小写搜索', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
      ];

      final found = navItems.firstWhere(
        (item) => item.text.toLowerCase() == 'home',
        orElse: () => NavItem(svgPath: '', text: '', category: ''),
      );

      expect(found.text, 'Home');
    });

    test('搜索包含特定关键词', () {
      final navItems = [
        NavItem(svgPath: 'assets/home.svg', text: 'Home', category: 'home'),
        NavItem(
          svgPath: 'assets/work_travel.svg',
          text: 'Work & Travel',
          category: 'work',
        ),
      ];

      final found = navItems
          .where((item) => item.text.contains('Travel'))
          .toList();

      expect(found.length, 1);
      expect(found[0].text, 'Work & Travel');
    });
  });
}
