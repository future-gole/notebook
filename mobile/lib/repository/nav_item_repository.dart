import 'package:pocketmind/model/nav_item.dart';

/// 导航项仓库接口
abstract class NavItemRepository {

  /// 监听并获取导航项
  Stream<List<NavItem>> watchNavItems();
}
