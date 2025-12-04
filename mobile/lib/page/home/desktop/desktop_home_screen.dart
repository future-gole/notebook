import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/page/widget/note_Item.dart';
import 'package:pocketmind/page/widget/desktop/desktop_sidebar.dart';
import 'package:pocketmind/page/widget/desktop/desktop_header.dart';
import 'package:pocketmind/page/home/note_add_sheet.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/logger_service.dart';

final String tag = "DesktopHomeScreen";

/// 桌面端主屏幕布局
/// 左侧固定侧边栏 + 右侧自适应内容区
class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 动态计算网格列数
  /// 基于内容区域宽度自适应调整
  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    if (width < 1600) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteByCategory = ref.watch(noteByCategoryProvider);
    final noteService = ref.watch(noteServiceProvider);
    final currentLayout = ref.watch(appConfigProvider).waterfallLayoutEnabled
        ? NoteLayout.grid
        : NoteLayout.list;
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // 左侧固定宽度的侧边栏
          const DesktopSidebar(),

          // 右侧内容区
          Expanded(
            child: Column(
              children: [
                // macOS 顶部预留空间 (窗口控制按钮)
                if (Platform.isMacOS) const SizedBox(height: 28),

                // 顶部导航栏
                DesktopHeader(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchSubmit: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      ref.read(searchQueryProvider.notifier).state = query;
                    }
                  },
                ),

                // 内容区域
                Expanded(
                  child: searchQuery != null
                      ? _buildSearchResults(
                          searchResults,
                          currentLayout,
                          noteService,
                        )
                      : noteByCategory.when(
                          skipLoadingOnRefresh: true,
                          data: (notes) => _buildNotesContent(
                            notes,
                            currentLayout,
                            noteService,
                          ),
                          error: (error, stack) {
                            PMlog.e(tag, "stack: $error,stack:$stack");
                            return const Center(child: Text('加载笔记失败'));
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      // FAB - 桌面端放在右下角
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNotePage(context),
        elevation: 8,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiary,
                colorScheme.tertiary.withOpacity(0.85),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  /// 显示添加笔记对话框
  void _showAddNotePage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 80,
            vertical: 40,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: NoteEditorSheet(),
            ),
          ),
        );
      },
    );
  }

  /// 构建笔记内容区域
  Widget _buildNotesContent(
    List<NoteEntity> notes,
    NoteLayout currentLayout,
    noteService,
  ) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }
    return _buildNotesList(notes, currentLayout, noteService);
  }

  /// 构建空状态占位
  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 100,
            color: colorScheme.secondary.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            '你的思绪将汇聚于此',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右下角，捕捉第一个灵感',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults(
    AsyncValue<List<NoteEntity>> searchResults,
    NoteLayout currentLayout,
    noteService,
  ) {
    return searchResults.when(
      data: (notes) {
        if (notes.isEmpty) {
          return _buildSearchEmptyState();
        }
        return _buildNotesList(notes, currentLayout, noteService);
      },
      error: (error, stack) {
        PMlog.e(tag, "搜索错误: $error, stack:$stack");
        return const Center(child: Text('搜索失败'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  /// 构建搜索结果为空状态
  Widget _buildSearchEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 100,
            color: colorScheme.secondary.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            '未找到相关笔记',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            '尝试使用其他关键词',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建笔记列表
  /// 复用 NoteItem 组件，支持网格和列表两种布局
  Widget _buildNotesList(
    List<NoteEntity> notes,
    NoteLayout currentLayout,
    noteService,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;

        if (currentLayout == NoteLayout.grid) {
          // 瀑布流布局 - 动态列数
          final crossAxisCount = _calculateCrossAxisCount(contentWidth);
          return MasonryGridView.count(
            controller: _scrollController,
            key: const PageStorageKey('desktop_masonry_grid_view'),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            cacheExtent: 500.0,
            padding: const EdgeInsets.all(24),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return RepaintBoundary(
                child: NoteItem(
                  note: note,
                  noteService: noteService,
                  isGridMode: true,
                  isDesktop: true,
                  key: ValueKey('desktop_note_${note.id}'),
                ),
              );
            },
          );
        } else {
          // 列表布局 - 限制最大宽度使其居中
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                controller: _scrollController,
                key: const PageStorageKey('desktop_list_view'),
                cacheExtent: 500.0,
                padding: const EdgeInsets.all(24),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      child: NoteItem(
                        note: note,
                        noteService: noteService,
                        isGridMode: false,
                        isDesktop: true,
                        key: ValueKey('desktop_note_${note.id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
