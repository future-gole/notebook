import 'package:isar_community/isar.dart';
import 'package:pocketmind/model/nav_item.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/repository/nav_item_repository.dart';

/// 基于 Isar Category 的导航项仓库实现
class IsarNavItemRepository implements NavItemRepository {
  final Isar isar;

  IsarNavItemRepository(this.isar);

  @override
  Future<List<NavItem>> getNavItems() async {
    // 从 Isar 获取所有分类
    final categories = await isar.categorys.where().findAll();

    // 将 Category 转换为 NavItem
    return categories.map((category) {
      return NavItem(
        svgPath: _getIconForCategory(category.name),
        text: category.name,
        category: category.name,
        categoryId: category.id,
      );
    }).toList();
  }

  @override
  Stream<List<NavItem>> watchNavItems() {
    // 监听 categories 变化
    return isar.categorys.where().watch(fireImmediately: true).map((categories) {
      return categories.map((category) {
        return NavItem(
          svgPath: _getIconForCategory(category.name),
          text: category.name,
          category: category.name,
          categoryId: category.id,
        );
      }).toList();
    });
  }

  /// 根据 category 返回对应的图标路径
  /// TODO: 根据实际需求配置不同分类的图标
  String _getIconForCategory(String category) {
    // 这里可以根据不同的 category 返回不同的图标
    // 目前先返回默认图标
    const iconMap = {
      '工作': 'assets/icons/work.svg',
      '学习': 'assets/icons/study.svg',
      '生活': 'assets/icons/life.svg',
      '娱乐': 'assets/icons/entertainment.svg',
      'b站': 'assets/icons/bilibili.svg',
    };

    return iconMap[category] ?? 'assets/icons/bilibili.svg';
  }
}
