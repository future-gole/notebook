// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CategoryRepository Provider - 数据层
/// 提供 Isar 的具体实现

@ProviderFor(categoryRepository)
const categoryRepositoryProvider = CategoryRepositoryProvider._();

/// CategoryRepository Provider - 数据层
/// 提供 Isar 的具体实现

final class CategoryRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryRepository,
          CategoryRepository,
          CategoryRepository
        >
    with $Provider<CategoryRepository> {
  /// CategoryRepository Provider - 数据层
  /// 提供 Isar 的具体实现
  const CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryRepository>(value),
    );
  }
}

String _$categoryRepositoryHash() =>
    r'5831ed6868e116f0eac78c1481f79036207e9273';

/// CategoryService Provider - 业务层
/// 现在依赖抽象的 Repository 接口

@ProviderFor(categoryService)
const categoryServiceProvider = CategoryServiceProvider._();

/// CategoryService Provider - 业务层
/// 现在依赖抽象的 Repository 接口

final class CategoryServiceProvider
    extends
        $FunctionalProvider<CategoryService, CategoryService, CategoryService>
    with $Provider<CategoryService> {
  /// CategoryService Provider - 业务层
  /// 现在依赖抽象的 Repository 接口
  const CategoryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryServiceHash();

  @$internal
  @override
  $ProviderElement<CategoryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryService create(Ref ref) {
    return categoryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryService>(value),
    );
  }
}

String _$categoryServiceHash() => r'b47d95ad06288b5e265d860a918ad9ed30ad6c5e';

/// 所有分类 Stream Provider - 自动监听数据库变化

@ProviderFor(allCategories)
const allCategoriesProvider = AllCategoriesProvider._();

/// 所有分类 Stream Provider - 自动监听数据库变化

final class AllCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryEntity>>,
          List<CategoryEntity>,
          Stream<List<CategoryEntity>>
        >
    with
        $FutureModifier<List<CategoryEntity>>,
        $StreamProvider<List<CategoryEntity>> {
  /// 所有分类 Stream Provider - 自动监听数据库变化
  const AllCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<CategoryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CategoryEntity>> create(Ref ref) {
    return allCategories(ref);
  }
}

String _$allCategoriesHash() => r'9e4dc7f22e7936f613a5a822529e4b3aed752202';
