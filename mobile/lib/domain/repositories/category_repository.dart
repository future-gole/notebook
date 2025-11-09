import '../entities/category_entity.dart';

/// 分类数据访问抽象接口
/// 
/// 定义所有分类相关的数据操作，不依赖任何具体数据库实现
abstract class CategoryRepository {
  /// 初始化默认分类（首次运行时）
  Future<void> initDefaultCategories();

  /// 获取所有分类（按创建时间排序）
  Future<List<CategoryEntity>> getAll();

  /// 根据ID获取分类
  Future<CategoryEntity?> getById(int id);

  /// 根据名称获取分类
  Future<CategoryEntity?> getByName(String name);

  /// 保存分类（新增或更新）
  /// 
  /// 返回保存后的分类ID，失败返回 -1
  Future<int> save(CategoryEntity category);

  /// 根据ID删除分类
  Future<void> delete(int id);

  /// 监听所有分类变化（实时订阅）
  Stream<List<CategoryEntity>> watchAll();
}
