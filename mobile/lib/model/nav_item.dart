/// 导航项模型
class NavItem {
  final String svgPath;
  final String text;
  final String category; // 用于显示，
  final int? categoryId; // 用于查询

  const NavItem({
    required this.svgPath,
    required this.text,
    required this.category,
    this.categoryId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavItem &&
          runtimeType == other.runtimeType &&
          svgPath == other.svgPath &&
          text == other.text &&
          category == other.category &&
          categoryId == other.categoryId;

  @override
  int get hashCode =>
      svgPath.hashCode ^
      text.hashCode ^
      category.hashCode ^
      categoryId.hashCode;
}
