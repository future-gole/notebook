import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketmind/domain/entities/category_entity.dart';
import 'package:pocketmind/domain/repositories/category_repository.dart';
import 'package:pocketmind/data/repositories/isar_category_repository.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/service/category_service.dart';

part 'category_providers.g.dart';

/// CategoryRepository Provider - 数据层
/// 提供 Isar 的具体实现
@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) {
  final isar = ref.watch(isarProvider);
  return IsarCategoryRepository(isar);
}

/// CategoryService Provider - 业务层
/// 现在依赖抽象的 Repository 接口
@Riverpod(keepAlive: true)
CategoryService categoryService(Ref ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryService(repository);
}

/// 所有分类 Stream Provider - 自动监听数据库变化
@riverpod
Stream<List<CategoryEntity>> allCategories(Ref ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
}
