import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/nav_item.dart';
import 'package:pocketmind/repository/isar_nav_item_repository.dart';
import 'package:pocketmind/repository/nav_item_repository.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/util/app_config.dart' show AppConfig;

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

final activeCategoryId = FutureProvider<int>((ref) async {
  // 获取激活的下标
  final activeIndex = ref.watch(activeNavIndexProvider);
  // 获取最新的导航项
  final items = await ref.watch(navItemsProvider.future);
  // 获取当前分类的 categoryId
  return items[activeIndex].categoryId;
});


