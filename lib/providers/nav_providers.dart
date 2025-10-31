import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notebook/model/nav_item.dart';
import 'package:notebook/repository/isar_nav_item_repository.dart';
import 'package:notebook/repository/nav_item_repository.dart';

/// Isar 实例 Provider
/// 需要在 main 中通过 overrideWithValue 提供实际的 Isar 实例
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main()');
});

/// NavItemRepository Provider
final navItemRepositoryProvider = Provider<NavItemRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarNavItemRepository(isar);
});

/// 导航项列表 Provider (Stream)
final navItemsProvider = StreamProvider<List<NavItem>>((ref) {
  final repository = ref.watch(navItemRepositoryProvider);
  return repository.watchNavItems();
});

/// 当前激活的导航项索引 Provider
final activeNavIndexProvider = StateProvider<int>((ref) => 0);
