
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/repositories/note_repository.dart';
import 'package:pocketmind/data/repositories/isar_note_repository.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/service/note_service.dart';

import '../util/logger_service.dart';

part 'note_providers.g.dart';

/// NoteRepository Provider - 数据层
/// 提供 Isar 的具体实现
@Riverpod(keepAlive: true)
NoteRepository noteRepository(Ref ref) {
  final isar = ref.watch(isarProvider);
  return IsarNoteRepository(isar);
}

/// NoteService Provider - 业务层
/// 现在依赖抽象的 Repository 接口
@Riverpod(keepAlive: true)
NoteService noteService(Ref ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteService(repository);
}

/// 搜索查询 Provider - 用于管理当前搜索关键词
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// 搜索结果 Provider - 根据搜索查询返回结果
@riverpod
Stream<List<NoteEntity>> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  if (query == null || query.isEmpty) {
    return Stream.value([]);
  }
  final noteService = ref.watch(noteServiceProvider);
  return noteService.findNotesWithQuery(query);
}

/// 所有笔记的 Stream Provider
@riverpod
Stream<List<NoteEntity>> allNotes(Ref ref) {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.watchAllNotes();
}

/// 根据 ID 获取笔记的 Provider
@riverpod
Future<NoteEntity?> noteById(Ref ref, {required int id}) async {
  final noteService = ref.watch(noteServiceProvider);
  return noteService.getNoteById(id);
}

/// 桌面端当前选中的笔记 Provider
/// 用于桌面端详情面板显示
@riverpod
class SelectedNote extends _$SelectedNote {
  @override
  NoteEntity? build() => null;

  void set(NoteEntity? value) => state = value;
}

/// 根据分类获取笔记的 StreamNotifier
@riverpod
class NoteByCategory extends _$NoteByCategory {
  // build 方法返回 Stream，自动监听数据库变化
  @override
  Stream<List<NoteEntity>> build() async* {
    // 获取 noteService
    final noteService = ref.watch(noteServiceProvider);

    final targetCategoryId = await ref.watch(activeCategoryIdProvider.future);

    PMlog.d('activeIndex', 'targetCategoryId: $targetCategoryId');

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
