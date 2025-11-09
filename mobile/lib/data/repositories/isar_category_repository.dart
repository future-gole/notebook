import 'package:isar_community/isar.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../model/category.dart';
import '../mappers/category_mapper.dart';
import '../../util/logger_service.dart';

/// Isar 数据库的分类仓库实现
/// 
/// 封装所有与 Isar 相关的数据访问逻辑，对外只暴露领域实体
class IsarCategoryRepository implements CategoryRepository {
  final Isar _isar;
  static const String _tag = "IsarCategoryRepository";

  IsarCategoryRepository(this._isar);

  @override
  Future<void> initDefaultCategories() async {
    final existingCount = await _isar.categorys.count();

    // 如果已有分类，不再初始化
    if (existingCount > 0) {
      log.d(_tag, 'Categories already exist, skip initialization');
      return;
    }

    // 创建默认分类实体
    final defaultCategory = CategoryEntity(
      name: 'home',
      description: '首页',
      createdTime: DateTime.now(),
    );

    try {
      await _isar.writeTxn(() async {
        final isarCategory = CategoryMapper.fromDomain(defaultCategory);
        await _isar.categorys.put(isarCategory);
      });
      log.d(_tag, 'Default categories initialized successfully');
    } catch (e) {
      log.e(_tag, 'Failed to initialize default categories: $e');
      rethrow;
    }
  }

  @override
  Future<List<CategoryEntity>> getAll() async {
    try {
      final categories = await _isar.categorys.where().sortByCreatedTime().findAll();
      return CategoryMapper.toDomainList(categories);
    } catch (e) {
      log.e(_tag, "Failed to get all categories: $e");
      return [];
    }
  }

  @override
  Future<CategoryEntity?> getById(int id) async {
    try {
      final category = await _isar.categorys.get(id);
      return category != null ? CategoryMapper.toDomain(category) : null;
    } catch (e) {
      log.e(_tag, "Failed to get category by id: $e");
      return null;
    }
  }

  @override
  Future<CategoryEntity?> getByName(String name) async {
    try {
      final category = await _isar.categorys.filter().nameEqualTo(name).findFirst();
      return category != null ? CategoryMapper.toDomain(category) : null;
    } catch (e) {
      log.e(_tag, "Failed to get category by name: $e");
      return null;
    }
  }

  @override
  Future<int> save(CategoryEntity category) async {
    try {
      int resultId = -1;
      
      final isarCategory = CategoryMapper.fromDomain(category);
      
      // 如果没有设置创建时间，使用当前时间
      if (isarCategory.createdTime == null) {
        isarCategory.createdTime = DateTime.now();
      }

      await _isar.writeTxn(() async {
        resultId = await _isar.categorys.put(isarCategory);
      });

      log.d(_tag, 'Category saved successfully: ${category.name}');
      return resultId;
    } catch (e) {
      log.e(_tag, 'Failed to save category: $e');
      return -1;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.categorys.delete(id);
      });
      log.d(_tag, 'Category deleted: id=$id');
    } catch (e) {
      log.e(_tag, 'Failed to delete category: $e');
      rethrow;
    }
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    return _isar.categorys
        .where()
        .watch(fireImmediately: true)
        .map((categories) => CategoryMapper.toDomainList(categories));
  }
}
