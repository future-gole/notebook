import 'package:isar_community/isar.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/util/logger_service.dart';

final String NoteServiceTag = "NoteService";
class NoteService {
  final Isar isar;
  static const String defaultCategory = "home";
  static const String defaultTitle = "默认标题";
  static const String defaultContent = "默认内容";

  NoteService(this.isar);

  // 增添/更新笔记，返回id，-1 为插入失败
  Future<int> addOrUpdateNote({
    int? id,
    String title = defaultTitle,
    String content = defaultContent,
    String? category,
    String? tag,
  }) async {
    log.d(NoteServiceTag, 'Note added: title: $title, content: $content, category: $category ');
    final newNote = Note()
      ..title = title
      ..content = content
      ..category = category ?? defaultCategory
      ..time = DateTime.now()
      ..tag;
    if(id != null && id != -1){
      log.d(NoteServiceTag, "id:${id},进行更新操作");
      newNote.id  = id;
    }
    try {
      int resultId = -1;
      await isar.writeTxn(() async {
            // 这里需要获取id，因为用户可能点击detail进行更新
            resultId = await isar.notes.put(newNote);
          });
      return resultId;
    } catch (e) {
      log.e(NoteServiceTag,"插入/更新数据失败: $e");
      return -1;
    }
  }

  // 根据笔记id获取笔记
  Future<Note?> getNoteById(Id noteId) async {
    return await isar.notes.get(noteId);
  }

  // 获取所有笔记
  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().sortByTimeDesc().findAll();
  }

  // 监听并且获取所有笔记
  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().watch(fireImmediately: true);
  }

  // 删除笔记
  Future<void> deleteNote(Id noteId) async {
    try {
      await isar.writeTxn(() async {
            await isar.notes.delete(noteId);
          });
    } catch (e) {
      log.e(NoteServiceTag,"删除数据失败: $e");
    }
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
      .sortByTimeDesc()
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
