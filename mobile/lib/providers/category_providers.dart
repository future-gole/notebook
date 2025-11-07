import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/server/category_service.dart';

// CategoryService Provider - 用于依赖注入
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final isar = ref.watch(isarProvider);
  return CategoryService(isar);
});

// 所有分类 Stream Provider - 自动监听数据库变化
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
});

// 所有分类 Future Provider - 一次性获取
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categoryService = ref.watch(categoryServiceProvider);
  return await categoryService.getAllCategories();
});
