import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/server/note_service.dart';

/// NoteService Provider
final noteServiceProvider = Provider<NoteService>((ref) {
  final isar = ref.watch(isarProvider);
  return NoteService(isar);
});

/// 所有笔记的 Stream Provider
final allNotesProvider = StreamProvider<List<Note>>((ref) {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.watchAllNotes();
});

/// 根据 ID 获取笔记的 Provider
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.getNoteById(id);
});

final noteByCategoryProvider = AsyncNotifierProvider<NoteByCategory, List<Note>>(() {
  return NoteByCategory();
});

class NoteByCategory extends AsyncNotifier<List<Note>> {

  // 1. build 方法负责异步获取数据（和你旧的 FutureProvider 逻辑一样）
  @override
  Future<List<Note>> build() async {
    // 获取激活的下标
    final activeIndex = ref.watch(activeNavIndexProvider);
    // 获取service
    final noteService = ref.watch(noteServiceProvider);
    // 获取最新的导航项 List<NavItem>
    final navItem = await ref.watch(navItemsProvider.future);

    // 检查 navItem 是否为空或索引超出范围
    if (navItem.isEmpty || activeIndex >= navItem.length) {
      // 返回默认分类的笔记
      return noteService.findNotesWithCategory(NoteService.defaultCategory);
    }

    // 获取 Category 下的 note
    return noteService.findNotesWithCategory(navItem[activeIndex].category);
  }

  // 2. 关键：一个同步修改状态的方法
  Future<void> deleteNote(int noteId) async {
    // A. 保存旧状态，用于失败时回滚
    final previousState = state;

    // B. (关键!) 立即、同步地更新 UI 状态
    // 我们从当前的状态(.value)中过滤掉被删除的笔记
    // 这就是“Optimistic UI”：我们乐观地假设删除会成功
    state = AsyncValue.data(
      state.valueOrNull?.where((note) => note.id != noteId).toList() ?? [],
    );

    // C. 在后台异步执行真正的数据库删除
    try {
      await ref.read(noteServiceProvider).deleteNote(noteId);
      // 成功了！UI 已经是正确的，什么都不用做。
    } catch (e) {
      // D. (回滚) 数据库删除失败！把 UI 恢复到旧状态
      state = previousState;
    }
  }
}