/// 路由路径常量定义
class RoutePaths {
  /// 首页 (笔记列表)
  static const String home = '/';

  /// 笔记详情页
  /// 参数: nid (笔记 ID)
  static const String noteDetail = '/note/:nid';

  /// 设置页
  static const String settings = '/settings';
  /// 设置页
  static const String sync = '/settings/sync';

  /// 辅助方法：生成笔记详情路径
  static String noteDetailWithId(int id) => '/note/$id';
}
