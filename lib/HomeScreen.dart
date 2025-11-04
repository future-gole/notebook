import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notebook/page/widget/glass_nav_bar.dart';
import 'package:notebook/page/widget/note_Item.dart';
import 'package:notebook/page/widget/note_editor_sheet.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/providers/note_providers.dart';
import 'package:notebook/util/logger_service.dart';

final String tag = "HomeScreen";

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 对应 Category 下的 note
    final noteByCategory = ref.watch(noteByCategoryProvider);
    final noteService = ref.watch(noteServiceProvider);
    // 获取当前布局模式
    final currentLayout = ref.watch(noteLayoutProvider);

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

            // GlassNavBar（包含搜索和布局切换）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlassNavBar(
                onSearchPressed: () {
                  // TODO: 实现搜索功能
                },
              ),
            ),

            const SizedBox(height: 12),

            // 笔记列表（根据布局模式切换）
            Expanded(
              child: noteByCategory.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '你的思绪将汇聚于此',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右下角，捕捉第一个灵感',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  // 根据布局模式返回不同的列表
                  if (currentLayout == NoteLayout.grid) {
                    // 瀑布流布局
                    return MasonryGridView.count(
                      crossAxisCount: 2,
                      // 外边距由noteItem自己来决定
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return noteItem(note, noteService);
                      },
                    );
                  } else {
                    // 列表布局
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return noteItem(note, noteService);
                      },
                    );
                  }
                },
                error: (error, stack) {
                  log.e(tag, "stack: $error,stack:$stack");
                  return const Center(child: Text('加载笔记失败'));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),

      // FAB - 使用主题样式（药丸形状）
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddNoteModal(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建笔记'),
      ),
    );
  }

  // 显示添加笔记模态框（底部弹窗）
  void _showAddNoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NoteEditorSheet(),
    );
  }
}
