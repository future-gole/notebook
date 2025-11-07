import 'package:isar_community/isar.dart';
import 'package:pocketmind/model/category.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/util/logger_service.dart';

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
    String? title, // 改为可空，允许不设置标题
    String content = defaultContent,
    String? category, // 分类名称（用于UI显示和查询）
    int? categoryId, // 分类ID（用于categories数据库关联）
    String? tag,
  }) async {
    log.d(
      NoteServiceTag,
      'Note added: title: $title, content: $content, category: $category, categoryId: $categoryId',
    );
    // 确保至少都是在 home 目录下
    int resolvedCategoryId = categoryId ?? 1;

    final newNote = Note()
      ..title =
          title // 可以为 null
      ..content = content
      ..categoryId =
          resolvedCategoryId // 保存分类ID用于关联
      ..time = DateTime.now()
      ..tag = tag;
    if (id != null && id != -1) {
      log.d(NoteServiceTag, "id:${id},进行更新操作");
      newNote.id = id;
    }
    try {
      int resultId = -1;
      await isar.writeTxn(() async {
        // 建立笔记与分类的关联
        final linkedCategory = await isar.categorys.get(resolvedCategoryId);
        newNote.category.value = linkedCategory;

        // 这里需要获取id，因为用户可能点击detail进行更新
        resultId = await isar.notes.put(newNote);
        await newNote.category.save();
      });
      return resultId;
    } catch (e) {
      log.e(NoteServiceTag, "插入/更新数据失败: $e");
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
      log.e(NoteServiceTag, "删除数据失败: $e");
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

  // 根据 categoryId 查询笔记
  Future<List<Note>> findNotesWithCategory(int? categoryId) async {
    // 1 代表 home 直接返回全部
    if (categoryId == 1) {
      return await getAllNotes();
    }
    return await isar.notes
        .filter()
        .categoryIdEqualTo(categoryId)
        .sortByTimeDesc()
        .findAll();
  }

  // 根据 tag 查询笔记
  Future<List<Note>> findNotesWithTag(String query) async {
    return await isar.notes
        .filter()
        .tagContains(query, caseSensitive: false)
        .findAll();
  }
}
