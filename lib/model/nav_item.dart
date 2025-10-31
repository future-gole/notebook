/// 导航项模型
class NavItem {
  final String svgPath;
  final String text;
  final String category;

  const NavItem({
    required this.svgPath,
    required this.text,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavItem &&
          runtimeType == other.runtimeType &&
          svgPath == other.svgPath &&
          text == other.text &&
          category == other.category;

  @override
  int get hashCode => svgPath.hashCode ^ text.hashCode ^ category.hashCode;
}
