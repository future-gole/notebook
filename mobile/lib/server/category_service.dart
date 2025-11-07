import 'package:isar_community/isar.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/util/logger_service.dart';

final String CategoryServiceTag = "CategoryService";

class CategoryService {
  final Isar isar;

  CategoryService(this.isar);

  /// 初始化默认分类
  Future<void> initDefaultCategories() async {
    final existingCategories = await isar.categorys.count();
    
    // 如果已有分类，不再初始化
    if (existingCategories > 0) {
      log.d(CategoryServiceTag, '分类已存在，跳过初始化');
      return;
    }

    // 创建默认分类
    final defaultCategories = [
      Category()
        ..name = 'home'
        ..description = '首页'
        ..createdTime = DateTime.now(),
    ];

    try {
      await isar.writeTxn(() async {
        await isar.categorys.putAll(defaultCategories);
      });
      log.d(CategoryServiceTag, '默认分类初始化成功');
    } catch (e) {
      log.e(CategoryServiceTag, '默认分类初始化失败: $e');
    }
  }

  /// 获取所有分类
  Future<List<Category>> getAllCategories() async {
    return await isar.categorys.where().sortByCreatedTime().findAll();
  }

  /// 根据ID获取分类
  Future<Category?> getCategoryById(Id categoryId) async {
    return await isar.categorys.get(categoryId);
  }

  /// 根据名称获取分类
  Future<Category?> getCategoryByName(String name) async {
    return await isar.categorys.filter().nameEqualTo(name).findFirst();
  }

  /// 添加分类
  Future<int> addCategory({
    required String name,
    String? description,
  }) async {
    final newCategory = Category()
      ..name = name
      ..description = description
      ..createdTime = DateTime.now();

    try {
      int resultId = -1;
      await isar.writeTxn(() async {
        resultId = await isar.categorys.put(newCategory);
      });
      log.d(CategoryServiceTag, '分类添加成功: $name');
      return resultId;
    } catch (e) {
      log.e(CategoryServiceTag, '分类添加失败: $e');
      return -1;
    }
  }

  /// 删除分类
  Future<void> deleteCategory(Id categoryId) async {
    try {
      await isar.writeTxn(() async {
        await isar.categorys.delete(categoryId);
      });
      log.d(CategoryServiceTag, '分类删除成功');
    } catch (e) {
      log.e(CategoryServiceTag, '分类删除失败: $e');
    }
  }

  /// 监听所有分类变化
  Stream<List<Category>> watchAllCategories() {
    return isar.categorys.where().watch(fireImmediately: true);
  }
}
