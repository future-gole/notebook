import 'package:pocketmind/domain/entities/category_entity.dart';
import 'package:pocketmind/domain/repositories/category_repository.dart';
import 'package:pocketmind/util/logger_service.dart';

final String categoryServiceTag = 'CategoryService';

/// 分类业务服务层
///
/// 现在依赖抽象的 CategoryRepository 接口，而不是具体的 Isar 实现
/// 这使得服务层与数据库实现完全解耦
class CategoryService {
  final CategoryRepository _categoryRepository;

  CategoryService(this._categoryRepository);

  /// 初始化默认分类
  Future<void> initDefaultCategories() async {
    await _categoryRepository.initDefaultCategories();
  }

  /// 获取所有分类
  Future<List<CategoryEntity>> getAllCategories() async {
    return await _categoryRepository.getAll();
  }

  /// 根据ID获取分类
  Future<CategoryEntity?> getCategoryById(int categoryId) async {
    return await _categoryRepository.getById(categoryId);
  }

  /// 根据名称获取分类
  Future<CategoryEntity?> getCategoryByName(String name) async {
    return await _categoryRepository.getByName(name);
  }

  /// 添加分类
  Future<int> addCategory({required String name, String? description}) async {
    final newCategory = CategoryEntity(
      name: name,
      description: description,
      createdTime: DateTime.now(),
    );

    final resultId = await _categoryRepository.save(newCategory);
    if (resultId != -1) {
      PMlog.d(categoryServiceTag, '分类添加成功: id: $resultId,name: $name');
    } else {
      PMlog.e(categoryServiceTag, '分类添加失败');
    }
    return resultId;
  }

  /// 删除分类
  Future<void> deleteCategory(int categoryId) async {
    await _categoryRepository.delete(categoryId);
    PMlog.d(categoryServiceTag, '分类删除成功');
  }

  /// 监听所有分类变化
  Stream<List<CategoryEntity>> watchAllCategories() {
    return _categoryRepository.watchAll();
  }
}
