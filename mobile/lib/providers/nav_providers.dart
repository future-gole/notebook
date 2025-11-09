import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/nav_item.dart';
import 'package:pocketmind/repository/isar_nav_item_repository.dart';
import 'package:pocketmind/repository/nav_item_repository.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';

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

/// 笔记布局模式枚举
enum NoteLayout { list, grid }

/// 笔记布局模式 Provider（默认使用瀑布流）
final noteLayoutProvider = StateProvider<NoteLayout>((ref) => NoteLayout.grid);
