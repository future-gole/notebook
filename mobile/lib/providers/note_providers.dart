import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/repositories/note_repository.dart';
import 'package:pocketmind/data/repositories/isar_note_repository.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/server/note_service.dart';

import '../util/logger_service.dart';

/// NoteRepository Provider - 数据层
/// 提供 Isar 的具体实现
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarNoteRepository(isar);
});

/// NoteService Provider - 业务层
/// 现在依赖抽象的 Repository 接口
final noteServiceProvider = Provider<NoteService>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteService(repository);
});

/// 搜索查询 Provider - 用于管理当前搜索关键词
final searchQueryProvider = StateProvider<String?>((ref) => null);

/// 搜索结果 Provider - 根据搜索查询返回结果
final searchResultsProvider = StreamProvider<List<NoteEntity>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query == null || query.isEmpty) {
    return Stream.value([]);
  }
  final noteService = ref.watch(noteServiceProvider);
  return noteService.findNotesWithQuery(query);
});

/// 所有笔记的 Stream Provider
final allNotesProvider = StreamProvider<List<NoteEntity>>((ref) {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.watchAllNotes();
});

/// 根据 ID 获取笔记的 Provider
final noteByIdProvider = FutureProvider.family<NoteEntity?, int>((
  ref,
  id,
) async {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.getNoteById(id);
});

final noteByCategoryProvider =
    StreamNotifierProvider<NoteByCategory, List<NoteEntity>>(() {
      return NoteByCategory();
    });

class NoteByCategory extends StreamNotifier<List<NoteEntity>> {
  // build 方法返回 Stream，自动监听数据库变化
  @override
  Stream<List<NoteEntity>> build() async* {
    // 获取 noteService
    final noteService = ref.watch(noteServiceProvider);

    final targetCategoryId = await ref.watch(activeCategoryId.future);

    log.d("activeIndex","targetCategoryId: $targetCategoryId");

    // 直接转发 watchCategoryNotes 的 Stream
    yield* noteService.watchCategoryNotes(targetCategoryId);
  }

  // 删除笔记方法
  Future<void> deleteNote(int noteId) async {
    try {
      // 直接删除，watchCategoryNotes() 的 Stream 会自动更新 UI
      await ref.read(noteServiceProvider).deleteNote(noteId);
    } catch (e) {
      // 可以在这里处理错误，比如显示 SnackBar
      rethrow;
    }
  }
}
