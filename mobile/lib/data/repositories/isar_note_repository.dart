import 'package:isar_community/isar.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../mappers/note_mapper.dart';
import '../../util/logger_service.dart';

/// Isar 数据库的笔记仓库实现
/// 
/// 封装所有与 Isar 相关的数据访问逻辑，对外只暴露领域实体
class IsarNoteRepository implements NoteRepository {
  final Isar _isar;
  static const String _tag = "IsarNoteRepository";

  IsarNoteRepository(this._isar);

  @override
  Future<int> save(NoteEntity note) async {
    log.d(
      _tag,
      'Saving note: title: ${note.title}, categoryId: ${note.categoryId}',
    );

    try {
      int resultId = -1;
      
      // 转换为 Isar 模型
      final isarNote = NoteMapper.fromDomain(note);
      
      // 确保至少有默认分类（categoryId = 1）
      final resolvedCategoryId = note.categoryId ?? 1;
      isarNote.categoryId = resolvedCategoryId;
      
      // 如果没有设置时间，使用当前时间
      if (isarNote.time == null) {
        isarNote.time = DateTime.now();
      }

      await _isar.writeTxn(() async {
        // 建立笔记与分类的关联（保持 IsarLink 用于数据库关系）
        final linkedCategory = await _isar.categorys.get(resolvedCategoryId);
        isarNote.category.value = linkedCategory;

        // 保存笔记
        resultId = await _isar.notes.put(isarNote);
        await isarNote.category.save();
      });

      log.d(_tag, 'Note saved successfully with id: $resultId');
      return resultId;
    } catch (e) {
      log.e(_tag, "Failed to save note: $e");
      return -1;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.notes.delete(id);
      });
      log.d(_tag, 'Note deleted: id=$id');
    } catch (e) {
      log.e(_tag, "Failed to delete note: $e");
      rethrow;
    }
  }

  @override
  Future<NoteEntity?> getById(int id) async {
    try {
      final note = await _isar.notes.get(id);
      return note != null ? NoteMapper.toDomain(note) : null;
    } catch (e) {
      log.e(_tag, "Failed to get note by id: $e");
      return null;
    }
  }

  @override
  Future<List<NoteEntity>> getAll() async {
    try {
      final notes = await _isar.notes.where().sortByTimeDesc().findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      log.e(_tag, "Failed to get all notes: $e");
      return [];
    }
  }

  @override
  Stream<List<NoteEntity>> watchAll() {
    return _isar.notes
        .where()
        .sortByTimeDesc()  // 添加排序（最新的在前）
        .watch(fireImmediately: true)
        .map((notes) => NoteMapper.toDomainList(notes));
  }

  @override
  Stream<List<NoteEntity>> watchByCategory(int category) {
    return _isar.notes
        .filter()
        .categoryIdEqualTo(category)
        .sortByTimeDesc()  // 添加排序（最新的在前）
        .watch(fireImmediately: true)
        .map((notes) => NoteMapper.toDomainList(notes));
  }

  @override
  Future<List<NoteEntity>> findByTitle(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .titleContains(query, caseSensitive: false)
          .sortByTimeDesc()  // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      log.e(_tag, "Failed to find notes by title: $e");
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByContent(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .contentContains(query, caseSensitive: false)
          .sortByTimeDesc()  // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      log.e(_tag, "Failed to find notes by content: $e");
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByCategoryId(int? categoryId) async {
    try {
      // categoryId = 1 代表 home，返回所有笔记
      if (categoryId == 1) {
        return await getAll();
      }

      final notes = await _isar.notes
          .filter()
          .categoryIdEqualTo(categoryId)
          .sortByTimeDesc()
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      log.e(_tag, "Failed to find notes by category: $e");
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByTag(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .tagContains(query, caseSensitive: false)
          .sortByTimeDesc()  // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      log.e(_tag, "Failed to find notes by tag: $e");
      return [];
    }
  }

}
