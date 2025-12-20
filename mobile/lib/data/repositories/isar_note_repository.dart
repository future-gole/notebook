import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/failures/repository_failure.dart';
import '../../model/note.dart';
import '../../model/category.dart';
import '../../util/logger_service.dart';
import '../../util/image_storage_helper.dart';

/// Isar 数据库的笔记仓库实现
///
/// 封装所有与 Isar 相关的数据访问逻辑，对外只暴露领域实体
class IsarNoteRepository implements NoteRepository {
  final Isar _isar;
  static const String _tag = 'IsarNoteRepository';
  static const _uuid = Uuid();

  IsarNoteRepository(this._isar);

  /// 将 NoteEntity 转换为 Isar Note 模型
  Note _toModel(NoteEntity entity) {
    final note = Note()
      ..title = entity.title
      ..content = entity.content
      ..url = entity.url
      ..time = entity.time
      ..categoryId = entity.categoryId
      ..tag = entity.tag
      ..previewImageUrl = entity.previewImageUrl
      ..previewTitle = entity.previewTitle
      ..previewDescription = entity.previewDescription;

    // 如果实体有ID，说明是更新操作，设置ID
    if (entity.id != null) {
      note.id = entity.id!;
    }

    return note;
  }

  /// 将 Isar Note 模型转换为 NoteEntity
  NoteEntity _toDomain(Note note) {
    return NoteEntity(
      id: note.id,
      title: note.title,
      content: note.content,
      url: note.url,
      time: note.time,
      categoryId: note.categoryId,
      tag: note.tag,
      previewImageUrl: note.previewImageUrl,
      previewTitle: note.previewTitle,
      previewDescription: note.previewDescription,
    );
  }

  /// 批量转换为领域实体列表
  List<NoteEntity> _toDomainList(List<Note> notes) {
    return notes.map(_toDomain).toList();
  }

  @override
  Future<int> save(NoteEntity note) async {
    PMlog.d(
      _tag,
      'Saving note: title: ${note.title}, categoryId: ${note.categoryId}',
    );

    try {
      // 转换为 Isar 模型
      final isarNote = _toModel(note);

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

      int resultId = 0;
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
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while saving note: $e\n$stackTrace');
      throw SaveNoteFailure(e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while saving note: $e\n$stackTrace');
      throw SaveNoteFailure(e);
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
          if (note.url != null &&
              note.url!.startsWith(AppConstants.localImagePathPrefix)) {
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
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while deleting note: $e\n$stackTrace');
      throw DeleteNoteFailure(id, e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while deleting note: $e\n$stackTrace');
      throw DeleteNoteFailure(id, e);
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
          if (note.url != null &&
              note.url!.startsWith(AppConstants.localImagePathPrefix)) {
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
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while deleting notes by category: $e\n$stackTrace');
      throw DeleteNoteFailure(categoryId, e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while deleting notes by category: $e\n$stackTrace');
      throw DeleteNoteFailure(categoryId, e);
    }
  }

  @override
  Future<NoteEntity?> getById(int id) async {
    try {
      final note = await _isar.notes.get(id);
      // 过滤已删除的记录
      if (note == null || note.isDeleted) return null;
      return _toDomain(note);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while getting note by id: $e\n$stackTrace');
      throw QueryNoteFailure('getById($id)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while getting note by id: $e\n$stackTrace');
      throw QueryNoteFailure('getById($id)', e);
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
      return _toDomainList(notes);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while getting all notes: $e\n$stackTrace');
      throw QueryNoteFailure('getAll()', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while getting all notes: $e\n$stackTrace');
      throw QueryNoteFailure('getAll()', e);
    }
  }

  @override
  Stream<List<NoteEntity>> watchAll() {
    return _isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .sortByTimeDesc() // 添加排序（最新的在前）
        .watch(fireImmediately: true)
        .map(_toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchByCategory(int category) {
    // 1. 先定义基础查询：所有未删除的笔记
    var query = _isar.notes.filter().isDeletedEqualTo(false);
    // 2. 动态判断：如果 category 不是 homeCategoryId（全部），则追加分类 ID 过滤
    if (category != AppConstants.homeCategoryId) {
      query = query.categoryIdEqualTo(category);
    }
    // 3. 统一收尾：排序、监听、转换
    return query
        .sortByTimeDesc()
        .watch(fireImmediately: true)
        .map(_toDomainList);
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
      return _toDomainList(notes);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while finding notes by title: $e\n$stackTrace');
      throw QueryNoteFailure('findByTitle($query)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while finding notes by title: $e\n$stackTrace');
      throw QueryNoteFailure('findByTitle($query)', e);
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
      return _toDomainList(notes);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while finding notes by content: $e\n$stackTrace');
      throw QueryNoteFailure('findByContent($query)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while finding notes by content: $e\n$stackTrace');
      throw QueryNoteFailure('findByContent($query)', e);
    }
  }

  @override
  Future<List<NoteEntity>> findByCategoryId(int categoryId) async {
    try {
      // categoryId = homeCategoryId 代表 home，返回所有笔记
      if (categoryId == AppConstants.homeCategoryId) {
        return await getAll();
      }

      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .categoryIdEqualTo(categoryId)
          .sortByTimeDesc()
          .findAll();
      return _toDomainList(notes);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while finding notes by category: $e\n$stackTrace');
      throw QueryNoteFailure('findByCategoryId($categoryId)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while finding notes by category: $e\n$stackTrace');
      throw QueryNoteFailure('findByCategoryId($categoryId)', e);
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
      return _toDomainList(notes);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while finding notes by tag: $e\n$stackTrace');
      throw QueryNoteFailure('findByTag($query)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while finding notes by tag: $e\n$stackTrace');
      throw QueryNoteFailure('findByTag($query)', e);
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
            .map(_toDomainList);
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
          .map(_toDomainList);
    } on IsarError catch (e, stackTrace) {
      PMlog.e(_tag, 'Isar error while finding notes by query: $e\n$stackTrace');
      throw QueryNoteFailure('findByQuery($query)', e);
    } catch (e, stackTrace) {
      PMlog.e(_tag, 'Unexpected error while finding notes by query: $e\n$stackTrace');
      throw QueryNoteFailure('findByQuery($query)', e);
    }
  }
}
