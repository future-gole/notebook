import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/failures/repository_failure.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';

/// Isar 数据库的分类仓库实现
///
/// 封装所有与 Isar 相关的数据访问逻辑，对外只暴露领域实体
class IsarCategoryRepository implements CategoryRepository {
  final Isar _isar;
  static const String _tag = 'IsarCategoryRepository';
  static const _uuid = Uuid();

  IsarCategoryRepository(this._isar);

  /// 将 CategoryEntity 转换为 Isar Category 模型
  Category _toModel(CategoryEntity entity) {
    final category = Category()
      ..name = entity.name
      ..description = entity.description
      ..createdTime = entity.createdTime;

    return category;
  }

  /// 将 Isar Category 模型转换为 CategoryEntity
  CategoryEntity _toDomain(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      description: category.description,
      createdTime: category.createdTime,
    );
  }

  /// 批量转换为领域实体列表
  List<CategoryEntity> _toDomainList(List<Category> categories) {
    return categories.map(_toDomain).toList();
  }

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
        final isarCategory = _toModel(defaultCategory);
        isarCategory.uuid = _uuid.v4();
        isarCategory.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _isar.categorys.put(isarCategory);
      });
      PMlog.d(_tag, 'Default categories initialized successfully');
    } on IsarError catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Isar error while initializing categories: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('initDefaultCategories', e);
    } catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Unexpected error while initializing categories: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('initDefaultCategories', e);
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
      return _toDomainList(categories);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while getting all categories: $e\n$stackTrace');
      throw CategoryOperationFailure('getAll', e);
    } catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Unexpected error while getting all categories: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('getAll', e);
    }
  }

  @override
  Future<CategoryEntity?> getById(int id) async {
    try {
      final category = await _isar.categorys.get(id);
      if (category == null || category.isDeleted) return null;
      return _toDomain(category);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while getting category by id: $e\n$stackTrace');
      throw CategoryOperationFailure('getById($id)', e);
    } catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Unexpected error while getting category by id: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('getById($id)', e);
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
      return category != null ? _toDomain(category) : null;
    } on IsarError catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Isar error while getting category by name: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('getByName($name)', e);
    } catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Unexpected error while getting category by name: $e\n$stackTrace',
      );
      throw CategoryOperationFailure('getByName($name)', e);
    }
  }

  @override
  Future<int> save(CategoryEntity category) async {
    try {
      final isarCategory = _toModel(category);

      // 如果没有设置创建时间，使用当前时间
      isarCategory.createdTime ??= DateTime.now();

      // 设置同步字段
      final now = DateTime.now().millisecondsSinceEpoch;
      isarCategory.updatedAt = now;

      // 如果是新记录，生成 UUID
      if (category.id == 1 || isarCategory.uuid == null) {
        isarCategory.uuid = _uuid.v4();
      }

      int resultId = 0;
      await _isar.writeTxn(() async {
        resultId = await _isar.categorys.put(isarCategory);
      });

      PMlog.d(_tag, 'Category saved successfully: ${category.name}');
      return resultId;
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while saving category: $e\n$stackTrace');
      throw SaveCategoryFailure(e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while saving category: $e\n$stackTrace');
      throw SaveCategoryFailure(e);
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
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while deleting category: $e\n$stackTrace');
      throw DeleteCategoryFailure(id, e);
    } catch (e, stackTrace) {
      PMlog.e(
        _tag,
        'Unexpected error while deleting category: $e\n$stackTrace',
      );
      throw DeleteCategoryFailure(id, e);
    }
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    return _isar.categorys
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map(_toDomainList);
  }
}
