import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
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
  static const String _tag = 'IsarCategoryRepository';
  static const _uuid = Uuid();

  IsarCategoryRepository(this._isar);

  @override
  Future<void> initDefaultCategories() async {
    final existingCount = await _isar.categorys.count();

    // 如果已有分类，不再初始化
    if (existingCount > 0) {
      PMlog.d(_tag, 'Categories already exist, skip initialization');
      return;
    }

    // 创建默认分类实体
    final defaultCategory = CategoryEntity(
      name: AppConstants.homeCategoryName,
      description: AppConstants.homeCategoryDescription,
      createdTime: DateTime.now(),
    );

    try {
      await _isar.writeTxn(() async {
        final isarCategory = defaultCategory.toModel();
        isarCategory.uuid = _uuid.v4();
        isarCategory.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _isar.categorys.put(isarCategory);
      });
      PMlog.d(_tag, 'Default categories initialized successfully');
    } catch (e) {
      PMlog.e(_tag, 'Failed to initialize default categories: $e');
      rethrow;
    }
  }

  @override
  Future<List<CategoryEntity>> getAll() async {
    try {
      final categories = await _isar.categorys
          .filter()
          .isDeletedEqualTo(false)
          .sortByCreatedTime()
          .findAll();
      return categories.toDomainList();
    } catch (e) {
      PMlog.e(_tag, 'Failed to get all categories: $e');
      return [];
    }
  }

  @override
  Future<CategoryEntity?> getById(int id) async {
    try {
      final category = await _isar.categorys.get(id);
      if (category == null || category.isDeleted) return null;
      return category.toDomain();
    } catch (e) {
      PMlog.e(_tag, 'Failed to get category by id: $e');
      return null;
    }
  }

  @override
  Future<CategoryEntity?> getByName(String name) async {
    try {
      final category = await _isar.categorys
          .filter()
          .isDeletedEqualTo(false)
          .nameEqualTo(name)
          .findFirst();
      return category?.toDomain();
    } catch (e) {
      PMlog.e(_tag, 'Failed to get category by name: $e');
      return null;
    }
  }

  @override
  Future<int> save(CategoryEntity category) async {
    try {
      int resultId = -1;

      final isarCategory = category.toModel();

      // 如果没有设置创建时间，使用当前时间
      isarCategory.createdTime ??= DateTime.now();

      // 设置同步字段
      final now = DateTime.now().millisecondsSinceEpoch;
      isarCategory.updatedAt = now;

      // 如果是新记录，生成 UUID
      if (category.id == 1 || isarCategory.uuid == null) {
        isarCategory.uuid = _uuid.v4();
      }

      await _isar.writeTxn(() async {
        resultId = await _isar.categorys.put(isarCategory);
      });

      PMlog.d(_tag, 'Category saved successfully: ${category.name}');
      return resultId;
    } catch (e) {
      PMlog.e(_tag, 'Failed to save category: $e');
      return -1;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      // 使用软删除代替物理删除
      await _isar.writeTxn(() async {
        final category = await _isar.categorys.get(id);
        if (category != null) {
          category.isDeleted = true;
          category.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.categorys.put(category);
        }
      });
      PMlog.d(_tag, 'Category soft deleted: id=$id');
    } catch (e) {
      PMlog.e(_tag, 'Failed to delete category: $e');
      rethrow;
    }
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    return _isar.categorys
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((categories) => categories.toDomainList());
  }
}
