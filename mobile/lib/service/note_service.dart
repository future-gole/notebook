import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/domain/repositories/note_repository.dart';
import 'package:pocketmind/util/logger_service.dart';

final String NoteServiceTag = 'NoteService';

/// 笔记业务服务层
///
/// 现在依赖抽象的 NoteRepository 接口，而不是具体的 Isar 实现
/// 这使得服务层与数据库实现完全解耦
class NoteService {
  final NoteRepository _noteRepository;
  static const String defaultCategory = 'home';
  static const String defaultTitle = '默认标题';
  static const String defaultContent = '默认内容';

  NoteService(this._noteRepository);

  // 增添/更新笔记，返回id，-1 为插入失败
  Future<int> addOrUpdateNote({
    int? id,
    String? title, // 改为可空，允许不设置标题
    String? content, // 改为可空，即用户没有设置标题
    String? url, // 直接文本插入的话就是为空
    String? category, // 分类名称（用于UI显示和查询）
    int categoryId = 1, // 分类ID（用于categories数据库关联）
    String? tag,
    String? previewImageUrl,
  }) async {
    PMlog.d(
      NoteServiceTag,
      'Note added: title: $title, content: $content, url: $url, category: $category, categoryId: $categoryId',
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

    if (id != null && id != -1) {
      PMlog.d(NoteServiceTag, 'id:$id, 进行更新操作');
    }

    // 通过仓库保存
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

  /// 删除笔记
  Future<void> deleteNote(int noteId) async {
    await _noteRepository.delete(noteId);
  }

  Future<void> deleteAllNoteByCategoryId(int categoryId) async {
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
    PMlog.d(NoteServiceTag, '预览数据已保存: noteId=$noteId');
  }
}
