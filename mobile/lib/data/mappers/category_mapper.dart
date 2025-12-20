import '../../domain/entities/category_entity.dart';
import '../../model/category.dart';

/// Category 与 CategoryEntity 之间的映射扩展
///
/// 负责在数据库特定模型（Isar）和纯净领域实体之间转换

/// Category 模型的扩展方法
extension CategoryX on Category {
  /// 将 Isar Category 模型转换为领域实体
  CategoryEntity toDomain() {
    return CategoryEntity(
      id: id,
      name: name,
      description: description,
      createdTime: createdTime,
    );
  }
}

/// CategoryEntity 领域实体的扩展方法
extension CategoryEntityX on CategoryEntity {
  /// 将领域实体转换为 Isar Category 模型
  Category toModel() {
    final category = Category()
      ..name = name
      ..description = description
      ..createdTime = createdTime;

    return category;
  }
}

/// Category 列表的扩展方法
extension CategoryListX on List<Category> {
  /// 批量转换为领域实体列表
  List<CategoryEntity> toDomainList() {
    return map((category) => category.toDomain()).toList();
  }
}

/// CategoryEntity 列表的扩展方法
extension CategoryEntityListX on List<CategoryEntity> {
  /// 批量转换为 Isar 模型列表
  List<Category> toModelList() {
    return map((entity) => entity.toModel()).toList();
  }
}
