import 'package:pocketmind/core/constants.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/repositories/note_repository.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/image_storage_helper.dart';

final String noteServiceTag = 'NoteService';

/// 笔记业务服务层
///
/// 现在依赖抽象的 NoteRepository 接口，而不是具体的 Isar 实现
/// 这使得服务层与数据库实现完全解耦
class NoteService {
  final NoteRepository _noteRepository;
  final ImageStorageHelper _imageHelper = ImageStorageHelper();

  NoteService(this._noteRepository);

  /// 增添/更新笔记
  ///
  /// 如果保存失败，将抛出异常
  Future<int> addOrUpdateNote({
    int? id,
    String? title,
    String? content,
    String? url,
    int categoryId = AppConstants.homeCategoryId,
    String? tag,
    String? previewImageUrl,
  }) async {
    PMlog.d(
      noteServiceTag,
      'Saving note: id: $id, title: $title, categoryId: $categoryId',
    );

    // 创建领域实体
    final noteEntity = NoteEntity(
      id: (id != null && id != -1) ? id : null,
      title: title,
      content: content,
      url: url,
      categoryId: categoryId,
      time: DateTime.now(),
      tag: tag,
      previewImageUrl: previewImageUrl,
    );

    return await _noteRepository.save(noteEntity);
  }

  /// 根据笔记id获取笔记
  Future<NoteEntity?> getNoteById(int noteId) async {
    return await _noteRepository.getById(noteId);
  }

  /// 获取所有笔记
  Future<List<NoteEntity>> getAllNotes() async {
    return await _noteRepository.getAll();
  }

  /// 监听并且获取所有笔记
  Stream<List<NoteEntity>> watchAllNotes() {
    return _noteRepository.watchAll();
  }

  /// 监听categories变化并且获取笔记
  Stream<List<NoteEntity>> watchCategoryNotes(int category) {
    return _noteRepository.watchByCategory(category);
  }

  /// 删除笔记及其关联资源（如本地图片）
  Future<void> deleteNote(int noteId) async {
    final note = await _noteRepository.getById(noteId);
    if (note != null) {
      await deleteFullNote(note);
    }
  }

  /// 删除完整笔记对象及其关联资源
  Future<void> deleteFullNote(NoteEntity note) async {
    if (note.id == null) return;

    // 1. 处理关联资源（如本地图片）
    final url = note.url;
    if (url != null && url.isNotEmpty && _isLocalImage(url)) {
      await _imageHelper.deleteImage(url);
    }

    // 2. 从数据库删除
    await _noteRepository.delete(note.id!);
    PMlog.d(noteServiceTag, 'Note deleted: ${note.id}');
  }

  bool _isLocalImage(String path) {
    // 简单的本地路径判断逻辑，可以根据实际情况完善
    return path.contains('pocket_images/');
  }

  Future<void> deleteAllNoteByCategoryId(int categoryId) async {
    // TODO: 如果需要删除分类下所有笔记，也需要循环处理图片删除
    await _noteRepository.deleteAllByCategoryId(categoryId);
  }

  /// 根据 title 查询笔记
  Future<List<NoteEntity>> findNotesWithTitle(String query) async {
    return await _noteRepository.findByTitle(query);
  }

  /// 根据 content 查询笔记
  Future<List<NoteEntity>> findNotesWithContent(String query) async {
    return await _noteRepository.findByContent(query);
  }

  /// 根据 categoryId 查询笔记
  Future<List<NoteEntity>> findNotesWithCategory(int categoryId) async {
    return await _noteRepository.findByCategoryId(categoryId);
  }

  /// 根据 tag 查询笔记
  Future<List<NoteEntity>> findNotesWithTag(String query) async {
    return await _noteRepository.findByTag(query);
  }

  /// 全部匹配查询
  Stream<List<NoteEntity>> findNotesWithQuery(String query) {
    return _noteRepository.findByQuery(query);
  }

  /// 更新笔记的预览数据（链接预览图片、标题、描述）
  Future<void> updatePreviewData({
    required int noteId,
    String? previewImageUrl,
    String? previewTitle,
    String? previewDescription,
  }) async {
    final note = await _noteRepository.getById(noteId);
    if (note == null) return;

    final updated = note.copyWith(
      previewImageUrl: previewImageUrl,
      previewTitle: previewTitle,
      previewDescription: previewDescription,
    );
    await _noteRepository.save(updated);
    PMlog.d(noteServiceTag, '预览数据已保存: noteId=$noteId');
  }
}
