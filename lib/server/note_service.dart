import 'package:isar_community/isar.dart';
import 'package:notebook/model/note.dart';

class NoteService {
  final Isar isar;
  final String defaultCategory = "home";
  NoteService(this.isar);
  // 增添笔记
  Future<void> addOrUpdateNote({
    String title = "默认标题",
    String content = "默认内容",
    String? category,
    String? tag,
  }) async {
    final newNote = Note()
      ..title = title
      ..content = content
      ..category = category ?? defaultCategory
      ..time = DateTime.now()
      ..tag;
    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });
  }

  // 根据笔记id获取笔记
  Future<Note?> getNoteById(Id noteId) async {
    return await isar.notes.get(noteId);
  }

  // 获取所有笔记
  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().findAll();
  }

  // 监听并且获取所有笔记
  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().watch(fireImmediately: true);
  }

  // 删除笔记
  Future<void> deleteNote(Id noteId) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(noteId);
    });
  }

  // 根据 title 查询笔记
  Future<List<Note>> findNotesWithTitle(String query) async {
    return await isar.notes
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  // 根据 content 查询笔记
  Future<List<Note>> findNotesWithContent(String query) async {
    return await isar.notes
        .filter()
        .contentContains(query, caseSensitive: false)
        .findAll();
  }

  // 根据 category 查询笔记
  Future<List<Note>> findNotesWithCategory(String query) async {
    if(query == defaultCategory){
      return await getAllNotes();
    }
    return await isar.notes
      .filter()
      .categoryEqualTo(query, caseSensitive: false)
      .findAll();
  }

  // 根据 tag 查询笔记

  Future<List<Note>> findNotesWithTag(String query) async {
    return await isar.notes
        .filter()
        .tagContains(query,caseSensitive: false)
        .findAll();
  }
}
