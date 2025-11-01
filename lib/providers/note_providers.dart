import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/server/note_service.dart';

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

final noteByCategoryProvider = FutureProvider<List<Note>>((ref) async {
  // 获取激活的下标
  final activeIndex = ref.watch(activeNavIndexProvider);

  // 获取service
  final noteService = ref.watch(noteServiceProvider);

  // 获取最新的导航项 List<NavItem>
  final navItem = await ref.watch(navItemsProvider.future);

  // 获取 Category 下的 note
  return noteService.findNotesWithCategory(navItem[activeIndex].category);
});