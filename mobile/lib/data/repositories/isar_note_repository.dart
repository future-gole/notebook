import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';
import '../mappers/note_mapper.dart';
import '../../util/image_storage_helper.dart';

/// Isar 数据库的笔记仓库实现
///
/// 封装所有与 Isar 相关的数据访问逻辑，对外只暴露领域实体
class IsarNoteRepository implements NoteRepository {
  final Isar _isar;
  static const String _tag = 'IsarNoteRepository';
  static const _uuid = Uuid();

  IsarNoteRepository(this._isar);

  @override
  Future<int> save(NoteEntity note) async {
    PMlog.d(
      _tag,
      'Saving note: title: ${note.title}, categoryId: ${note.categoryId}',
    );

    try {
      int resultId = -1;

      // 转换为 Isar 模型
      final isarNote = NoteMapper.fromDomain(note);

      // 如果没有设置时间，使用当前时间
      isarNote.time ??= DateTime.now();

      // 设置同步字段
      final now = DateTime.now().millisecondsSinceEpoch;
      isarNote.updatedAt = now;

      // 如果是更新操作，保留现有的 uuid
      if (note.id != null) {
        final existingNote = await _isar.notes.get(note.id!);
        if (existingNote != null && existingNote.uuid != null) {
          isarNote.uuid = existingNote.uuid;
        }
      }

      // 如果是新记录或者没有 uuid，生成新的 UUID
      if (isarNote.uuid == null || isarNote.uuid!.isEmpty) {
        isarNote.uuid = _uuid.v4();
      }

      await _isar.writeTxn(() async {
        // 建立笔记与分类的关联（保持 IsarLink 用于数据库关系）
        final linkedCategory = await _isar.categorys.get(note.categoryId);
        isarNote.category.value = linkedCategory;

        // 保存笔记
        resultId = await _isar.notes.put(isarNote);
        await isarNote.category.save();
      });

      PMlog.d(_tag, 'Note saved successfully with id: $resultId');
      return resultId;
    } catch (e) {
      PMlog.e(_tag, 'Failed to save note: $e');
      return -1;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      // 使用软删除代替物理删除
      await _isar.writeTxn(() async {
        final note = await _isar.notes.get(id);
        if (note != null) {
          // 删除对应的图片文件（如果有）
          if (note.url != null && note.url!.startsWith('pocket_images/')) {
            try {
              await ImageStorageHelper().deleteImage(note.url!);
              PMlog.d(_tag, 'Deleted image: ${note.url}');
            } catch (e) {
              PMlog.w(_tag, 'Failed to delete image ${note.url}: $e');
            }
          }
          
          note.isDeleted = true;
          note.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.notes.put(note);
        }
      });
      PMlog.d(_tag, 'Note soft deleted: id=$id');
    } catch (e) {
      PMlog.e(_tag, 'Failed to delete note: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllByCategoryId(int categoryId) async {
    try {
      await _isar.writeTxn(() async {
        final notes = await _isar.notes
            .filter()
            .categoryIdEqualTo(categoryId)
            .findAll();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final note in notes) {
          // 删除对应的图片文件（如果有）
          if (note.url != null && note.url!.startsWith('pocket_images/')) {
            try {
              await ImageStorageHelper().deleteImage(note.url!);
            } catch (e) {
              PMlog.w(_tag, 'Failed to delete image ${note.url}: $e');
            }
          }
          
          note.isDeleted = true;
          note.updatedAt = now;
        }
        await _isar.notes.putAll(notes);
        PMlog.d(_tag, '成功软删除了 ${notes.length} 条 categoryId为 $categoryId 的笔记');
      });
    } catch (e) {
      PMlog.e(_tag, '笔记删除失败: $e');
      rethrow;
    }
  }

  @override
  Future<NoteEntity?> getById(int id) async {
    try {
      final note = await _isar.notes.get(id);
      // 过滤已删除的记录
      if (note == null || note.isDeleted) return null;
      return NoteMapper.toDomain(note);
    } catch (e) {
      PMlog.e(_tag, 'Failed to get note by id: $e');
      return null;
    }
  }

  @override
  Future<List<NoteEntity>> getAll() async {
    try {
      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .sortByTimeDesc()
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      PMlog.e(_tag, 'Failed to get all notes: $e');
      return [];
    }
  }

  @override
  Stream<List<NoteEntity>> watchAll() {
    return _isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .sortByTimeDesc() // 添加排序（最新的在前）
        .watch(fireImmediately: true)
        .map((notes) => NoteMapper.toDomainList(notes));
  }

  @override
  Stream<List<NoteEntity>> watchByCategory(int category) {
    // 1. 先定义基础查询：所有未删除的笔记
    var query = _isar.notes.filter().isDeletedEqualTo(false);
    // 2. 动态判断：如果 category 不是 1（全部），则追加分类 ID 过滤
    if (category != 1) {
      query = query.categoryIdEqualTo(category);
    }
    // 3. 统一收尾：排序、监听、转换
    return query
        .sortByTimeDesc()
        .watch(fireImmediately: true)
        .map((notes) => NoteMapper.toDomainList(notes));
  }

  @override
  Future<List<NoteEntity>> findByTitle(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .titleContains(query, caseSensitive: false)
          .sortByTimeDesc() // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      PMlog.e(_tag, 'Failed to find notes by title: $e');
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByContent(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .contentContains(query, caseSensitive: false)
          .sortByTimeDesc() // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      PMlog.e(_tag, 'Failed to find notes by content: $e');
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByCategoryId(int categoryId) async {
    try {
      // categoryId = 1 代表 home，返回所有笔记
      if (categoryId == 1) {
        return await getAll();
      }

      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .categoryIdEqualTo(categoryId)
          .sortByTimeDesc()
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      PMlog.e(_tag, 'Failed to find notes by category: $e');
      return [];
    }
  }

  @override
  Future<List<NoteEntity>> findByTag(String query) async {
    try {
      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .tagContains(query, caseSensitive: false)
          .sortByTimeDesc() // 添加排序（最新的在前）
          .findAll();
      return NoteMapper.toDomainList(notes);
    } catch (e) {
      PMlog.e(_tag, 'Failed to find notes by tag: $e');
      return [];
    }
  }

  @override
  Stream<List<NoteEntity>> findByQuery(String query) {
    try {
      if (query.trim().isEmpty) {
        return _isar.notes
            .filter()
            .isDeletedEqualTo(false)
            .sortByTimeDesc()
            .watch(fireImmediately: true)
            .map((notes) => NoteMapper.toDomainList(notes));
      }
      return _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group(
            (q) => q
                .titleContains(query, caseSensitive: false)
                .or()
                .contentContains(query, caseSensitive: false),
          )
          .sortByTimeDesc()
          .watch(fireImmediately: true)
          .map((notes) => NoteMapper.toDomainList(notes));
    } catch (e) {
      PMlog.e(_tag, 'Failed to find notes by query: $e');
      return Stream.value([]);
    }
  }
}
