import '../../domain/entities/category_entity.dart';
import '../../model/category.dart';

/// Category 与 CategoryEntity 之间的映射器
/// 
/// 负责在数据库特定模型（Isar）和纯净领域实体之间转换
class CategoryMapper {
  /// 将 Isar Category 模型转换为领域实体
  static CategoryEntity toDomain(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      description: category.description,
      createdTime: category.createdTime,
    );
  }

  /// 将领域实体转换为 Isar Category 模型
  static Category fromDomain(CategoryEntity entity) {
    final category = Category()
      ..name = entity.name
      ..description = entity.description
      ..createdTime = entity.createdTime;

    // 如果实体有ID，说明是更新操作，设置ID
    if (entity.id != null) {
      category.id = entity.id!;
    }

    return category;
  }

  /// 批量转换为领域实体列表
  static List<CategoryEntity> toDomainList(List<Category> categories) {
    return categories.map((category) => toDomain(category)).toList();
  }

  /// 批量转换为 Isar 模型列表
  static List<Category> fromDomainList(List<CategoryEntity> entities) {
    return entities.map((entity) => fromDomain(entity)).toList();
  }
}
