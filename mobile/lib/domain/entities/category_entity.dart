/// 分类领域实体 - 不依赖任何具体数据库实现
/// 
/// 这是纯净的业务对象，只包含业务逻辑需要的数据字段
class CategoryEntity {
  /// 分类ID，null 表示尚未持久化的新分类
  final int? id;

  /// 分类名称（唯一）
  final String name;

  /// 分类描述
  final String? description;

  /// 创建时间
  final DateTime? createdTime;

  const CategoryEntity({
    this.id,
    required this.name,
    this.description,
    this.createdTime,
  });

  /// 复制并修改部分字段
  CategoryEntity copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdTime,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdTime: createdTime ?? this.createdTime,
    );
  }

  @override
  String toString() {
    return 'CategoryEntity(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryEntity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdTime == createdTime;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, createdTime);
  }
}
