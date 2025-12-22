import 'package:pocketmind/core/constants.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/repositories/note_repository.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/image_storage_helper.dart';
import 'package:pocketmind/service/metadata_manager.dart';

final String noteServiceTag = 'NoteService';

/// 笔记业务服务层
///
/// 现在依赖抽象的 NoteRepository 接口，而不是具体的 Isar 实现
/// 这使得服务层与数据库实现完全解耦
class NoteService {
  final NoteRepository _noteRepository;
  final MetadataManager _metadataManager;
  final ImageStorageHelper _imageHelper = ImageStorageHelper();

  NoteService(this._noteRepository, this._metadataManager);

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

    final savedId = await _noteRepository.save(noteEntity);

    // 如果是新笔记且包含 URL，触发异步元数据抓取
    if (id == null || id == -1) {
      if (url != null && url.isNotEmpty) {
        // 异步执行，不阻塞保存操作
        Future.microtask(() async {
          try {
            final savedNote = await _noteRepository.getById(savedId);
            if (savedNote != null) {
              await enrichNoteWithMetadata(savedNote);
            }
          } catch (e) {
            PMlog.e(noteServiceTag, 'Background enrichment failed: $e');
          }
        });
      }
    }

    return savedId;
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

    final previewUrl = note.previewImageUrl;
    if (previewUrl != null &&
        previewUrl.isNotEmpty &&
        _isLocalImage(previewUrl)) {
      await _imageHelper.deleteImage(previewUrl);
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

  /// 丰富笔记元数据（链接预览）
  ///
  /// 自动抓取链接预览信息，本地化图片，并更新数据库
  /// 如果抓取失败或数据不完整，不会更新数据库
  Future<void> enrichNoteWithMetadata(NoteEntity note) async {
    final url = note.url;
    // 1. 基础校验：必须有 URL，且未处理过（或者强制刷新）
    // 这里简单判断：如果已经有预览图或标题，就不再处理，避免重复流量
    if (url == null ||
        url.isEmpty ||
        (note.previewImageUrl != null && note.previewImageUrl!.isNotEmpty) ||
        (note.previewTitle != null && note.previewTitle!.isNotEmpty)) {
      return;
    }

    PMlog.d(noteServiceTag, '开始获取链接元数据: $url');

    try {
      // 2. 调用 MetadataManager 获取并处理数据
      final metadata = await _metadataManager.fetchAndProcessMetadata(url);

      if (metadata != null) {
        // 3. 更新数据库
        // previewImageUrl 存储的是本地化后的路径
        final updatedNote = note.copyWith(
          previewImageUrl: metadata.image,
          previewTitle: metadata.title,
          previewDescription: metadata.desc,
        );

        await _noteRepository.save(updatedNote);
        PMlog.d(noteServiceTag, '元数据已更新: ${note.id}');
      }
    } catch (e) {
      PMlog.e(noteServiceTag, '丰富笔记元数据失败: $e');
      // 这里可以选择抛出异常供 UI 层展示 Toast
      rethrow;
    }
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
