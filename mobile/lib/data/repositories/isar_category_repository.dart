import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';

/// Isar 数据库的分类仓库实现
class IsarCategoryRepository {
  final Isar _isar;
  static const String _tag = 'IsarCategoryRepository';
  static const _uuid = Uuid();

  IsarCategoryRepository(this._isar);

  Future<void> initDefaultCategories() async {
    final existingCount = await _isar.categorys.count();

    // 如果已有分类，不再初始化
    if (existingCount > 0) {
      PMlog.d(_tag, 'Categories already exist, skip initialization');
      return;
    }

    // 创建默认分类
    final defaultCategory = Category()
      ..name = AppConstants.homeCategoryName
      ..description = AppConstants.homeCategoryDescription
      ..createdTime = DateTime.now()
      ..uuid = _uuid.v4()
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;

    try {
      await _isar.writeTxn(() async {
        await _isar.categorys.put(defaultCategory);
      });
      PMlog.d(_tag, 'Default categories initialized successfully');
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while initializing categories: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Category>> getAll() async {
    try {
      return await _isar.categorys
          .filter()
          .isDeletedEqualTo(false)
          .sortByCreatedTime()
          .findAll();
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while getting all categories: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<Category?> getById(int id) async {
    try {
      final category = await _isar.categorys.get(id);
      if (category == null || category.isDeleted) return null;
      return category;
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while getting category by id: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<Category?> getByName(String name) async {
    try {
      return await _isar.categorys
          .filter()
          .isDeletedEqualTo(false)
          .nameEqualTo(name)
          .findFirst();
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while getting category by name: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<int> save(Category category) async {
    try {
      // 如果没有设置创建时间，使用当前时间
      category.createdTime ??= DateTime.now();

      // 设置同步字段
      final now = DateTime.now().millisecondsSinceEpoch;
      category.updatedAt = now;

      // 如果是新记录，生成 UUID
      category.uuid ??= _uuid.v4();

      int resultId = 0;
      await _isar.writeTxn(() async {
        resultId = await _isar.categorys.put(category);
      });

      PMlog.d(_tag, 'Category saved successfully: ${category.name}');
      return resultId;
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while saving category: $e\n$stackTrace');
      rethrow;
    }
  }

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
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Error while deleting category: $e\n$stackTrace');
      rethrow;
    }
  }

  Stream<List<Category>> watchAll() {
    return _isar.categorys
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }
}
