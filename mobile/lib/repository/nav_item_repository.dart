import 'package:pocketmind/model/nav_item.dart';

/// 导航项仓库接口
abstract class NavItemRepository {
  /// 获取所有导航项
  Future<List<NavItem>> getNavItems();

  /// 监听导航项变化
  Stream<List<NavItem>> watchNavItems();
}
