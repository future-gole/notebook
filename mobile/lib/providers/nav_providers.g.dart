// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// NavItemRepository Provider

@ProviderFor(navItemRepository)
const navItemRepositoryProvider = NavItemRepositoryProvider._();

/// NavItemRepository Provider

final class NavItemRepositoryProvider
    extends
        $FunctionalProvider<
          NavItemRepository,
          NavItemRepository,
          NavItemRepository
        >
    with $Provider<NavItemRepository> {
  /// NavItemRepository Provider
  const NavItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navItemRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<NavItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NavItemRepository create(Ref ref) {
    return navItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavItemRepository>(value),
    );
  }
}

String _$navItemRepositoryHash() => r'80230016db1da86732a5b3dc228186d9d750b62d';

/// 导航项列表 Provider (Stream)

@ProviderFor(navItems)
const navItemsProvider = NavItemsProvider._();

/// 导航项列表 Provider (Stream)

final class NavItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NavItem>>,
          List<NavItem>,
          Stream<List<NavItem>>
        >
    with $FutureModifier<List<NavItem>>, $StreamProvider<List<NavItem>> {
  /// 导航项列表 Provider (Stream)
  const NavItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<NavItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NavItem>> create(Ref ref) {
    return navItems(ref);
  }
}

String _$navItemsHash() => r'493eda65b386cff2f9cb55fdd10994f1c234f8a9';

/// 当前激活的导航项索引 Provider

@ProviderFor(ActiveNavIndex)
const activeNavIndexProvider = ActiveNavIndexProvider._();

/// 当前激活的导航项索引 Provider
final class ActiveNavIndexProvider
    extends $NotifierProvider<ActiveNavIndex, int> {
  /// 当前激活的导航项索引 Provider
  const ActiveNavIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeNavIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeNavIndexHash();

  @$internal
  @override
  ActiveNavIndex create() => ActiveNavIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeNavIndexHash() => r'cf395033e249e4474cb2056e2d747822774a8441';

/// 当前激活的导航项索引 Provider

abstract class _$ActiveNavIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 当前激活的分类 ID Provider

@ProviderFor(activeCategoryId)
const activeCategoryIdProvider = ActiveCategoryIdProvider._();

/// 当前激活的分类 ID Provider

final class ActiveCategoryIdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// 当前激活的分类 ID Provider
  const ActiveCategoryIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCategoryIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCategoryIdHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return activeCategoryId(ref);
  }
}

String _$activeCategoryIdHash() => r'e2445a4a4be2cbf8403e6fa4c9f46b7622005e90';
