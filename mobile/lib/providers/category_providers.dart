import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/domain/entities/category_entity.dart';
import 'package:pocketmind/domain/repositories/category_repository.dart';
import 'package:pocketmind/data/repositories/isar_category_repository.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/server/category_service.dart';

/// CategoryRepository Provider - 数据层
/// 提供 Isar 的具体实现
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarCategoryRepository(isar);
});

/// CategoryService Provider - 业务层
/// 现在依赖抽象的 Repository 接口
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryService(repository);
});

/// 所有分类 Stream Provider - 自动监听数据库变化
final allCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
});

/// 所有分类 Future Provider - 一次性获取
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final categoryService = ref.watch(categoryServiceProvider);
  return await categoryService.getAllCategories();
});
