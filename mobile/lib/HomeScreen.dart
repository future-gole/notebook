import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/page/widget/glass_nav_bar.dart';
import 'package:pocketmind/page/widget/note_Item.dart';
import 'package:pocketmind/page/home/note_add_sheet.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/logger_service.dart';

final String tag = "HomeScreen";

class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // 滚动控制器，用于保持滚动位置
  final ScrollController _scrollController = ScrollController();

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  late AnimationController _searchAnimationController;
  late Animation<Offset> _navBarSlideAnimation;
  late Animation<Offset> _searchBarSlideAnimation;

  // 防抖计时器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // NavBar 向左滑出的动画
    _navBarSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
          CurvedAnimation(
            parent: _searchAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // 搜索框从右滑入的动画
    _searchBarSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _searchAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // 监听输入变化，实现实时搜索
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 监听搜索输入变化（实时搜索 + 防抖）
  void _onSearchChanged() {
    // 取消之前的计时器
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();

    // 如果输入为空，立即清空搜索结果
    if (query.isEmpty) {
      ref.read(searchQueryProvider.notifier).state = null;
      return;
    }

    // 设置新的防抖计时器，500ms 后执行搜索
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  // 切换搜索模式
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchAnimationController.forward();
        // 延迟一点让动画先执行，然后再聚焦
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
        _debounceTimer?.cancel();
        // 清空搜索，返回到分类视图
        ref.read(searchQueryProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 对应 Category 下的 note
    final noteByCategory = ref.watch(noteByCategoryProvider);
    final noteService = ref.watch(noteServiceProvider);
    // 获取当前布局模式
    final currentLayout = ref.watch(appConfigProvider).waterfallLayoutEnabled ? NoteLayout.grid : NoteLayout.list;
    // 获取搜索查询
    final searchQuery = ref.watch(searchQueryProvider);
    // 获取搜索结果
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      // 使用主题背景色
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 移除 AppBar
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部间距
            const SizedBox(height: 8),

            // 导航栏 / 搜索栏 切换区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 56, // 固定高度，防止切换时跳动
                child: Stack(
                  children: [
                    // GlassNavBar - 向左滑出
                    SlideTransition(
                      position: _navBarSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8), // 添加右侧间距
                        child: GlassNavBar(onSearchPressed: _toggleSearchMode),
                      ),
                    ),
                    // 搜索栏 - 从右滑入
                    SlideTransition(
                      position: _searchBarSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8), // 添加左侧间距
                        child: _buildSearchBar(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 笔记列表（根据布局模式切换 或 搜索结果）
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // 淡入淡出 + 轻微缩放效果，掩盖瀑布流的重排
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(
                    searchQuery != null
                        ? 'search_${searchQuery}_${searchResults.value?.length ?? 0}'
                        : 'notes_count_${noteByCategory.value?.length ?? 0}',
                  ),
                  child: searchQuery != null
                      ? _buildSearchResults(
                          searchResults,
                          currentLayout,
                          noteService,
                        )
                      : noteByCategory.when(
                          skipLoadingOnRefresh: true,
                          data: (notes) {
                            if (notes.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.note_add_outlined,
                                      size: 80,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '你的思绪将汇聚于此',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '点击右下角，捕捉第一个灵感',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            }

                            // 使用共用的列表构建方法
                            return _buildNotesList(
                              notes,
                              currentLayout,
                              noteService,
                            );
                          },
                          error: (error, stack) {
                            PMlog.e(tag, "stack: $error,stack:$stack");
                            return const Center(child: Text('加载笔记失败'));
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                ), // KeyedSubtree
              ), // AnimatedSwitcher
            ), // Expanded
          ],
        ),
      ),

      // FAB - 使用主题样式（药丸形状）
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddNotePage(context);
          },
          elevation: 12,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.85),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              size: 28,
            ),
          ),
        )
    );
  }

  // 显示添加笔记模态框（底部弹窗）
  void _showAddNotePage(BuildContext context) {
    showModalBottomSheet(
      context: context,

      // 允许模态框占据全屏高度，并且能响应键盘
      isScrollControlled: true,

      // 将 BottomSheet 的背景设为透明
      // 这样 NoteEditorSheet 内部 Container 的圆角和颜色才能正常显示
      backgroundColor: Colors.transparent,

      useSafeArea: true,

      builder: (context) {
        return Padding(
            padding: EdgeInsets.only(top:MediaQuery.of(context).size.height * 0.10),
            child: NoteEditorSheet());
      },
    );
  }

  // 构建搜索栏
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _toggleSearchMode,
            color: colorScheme.primary,
          ),

          // 搜索输入框
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '搜索笔记...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
              // 实时搜索，不需要提交动作
            ),
          ),

          // 清空按钮（当有输入时显示）
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox(width: 48); // 占位，保持布局稳定
              }
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.requestFocus();
                },
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                iconSize: 20,
              );
            },
          ),
        ],
      ),
    );
  }

  // 构建搜索结果列表
  Widget _buildSearchResults(
    AsyncValue<List<NoteEntity>> searchResults,
    NoteLayout currentLayout,
    noteService,
  ) {
    return searchResults.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  '未找到相关笔记',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('尝试使用其他关键词', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        // 使用与主列表相同的布局逻辑
        return _buildNotesList(notes, currentLayout, noteService);
      },
      error: (error, stack) {
        PMlog.e(tag, "搜索错误: $error, stack:$stack");
        return const Center(child: Text('搜索失败'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  // 构建笔记列表
  Widget _buildNotesList(
    List<NoteEntity> notes,
    NoteLayout currentLayout,
    noteService,
  ) {
    if (currentLayout == NoteLayout.grid) {
      // 瀑布流布局
      return MasonryGridView.count(
        controller: _scrollController,
        key: const PageStorageKey('masonry_grid_view'),
        crossAxisCount: 2,
        cacheExtent: 500.0,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return RepaintBoundary(
            child: NoteItem(
              note: note,
              noteService: noteService,
              isGridMode: true,
              key: ValueKey('note_${note.id}'),
            ),
          );
        },
      );
    } else {
      // 列表布局
      return ListView.builder(
        controller: _scrollController,
        key: const PageStorageKey('list_view'),
        cacheExtent: 500.0,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return RepaintBoundary(
            child: NoteItem(
              note: note,
              noteService: noteService,
              isGridMode: false,
              key: ValueKey('note_${note.id}'),
            ),
          );
        },
      );
    }
  }
}
