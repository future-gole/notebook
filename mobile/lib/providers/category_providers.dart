import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/data/repositories/isar_category_repository.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/service/category_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'category_providers.g.dart';

/// CategoryRepository Provider - 数据层
/// 提供 Isar 的具体实现
@Riverpod(keepAlive: true)
IsarCategoryRepository categoryRepository(Ref ref) {
  final isar = ref.watch(isarProvider);
  return IsarCategoryRepository(isar);
}

/// CategoryService Provider - 业务层
@Riverpod(keepAlive: true)
CategoryService categoryService(Ref ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryService(repository);
}

/// 所有分类 Stream Provider - 自动监听数据库变化
@riverpod
Stream<List<Category>> allCategories(Ref ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
}
