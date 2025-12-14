import '../../domain/entities/note_entity.dart';
import '../../model/note.dart';

/// Note 与 NoteEntity 之间的映射器
///
/// 负责在数据库特定模型（Isar）和纯净领域实体之间转换
class NoteMapper {
  /// 将 Isar Note 模型转换为领域实体
  static NoteEntity toDomain(Note note) {
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

  /// 将领域实体转换为 Isar Note 模型
  static Note fromDomain(NoteEntity entity) {
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

  /// 批量转换为领域实体列表
  static List<NoteEntity> toDomainList(List<Note> notes) {
    return notes.map((note) => toDomain(note)).toList();
  }

  /// 批量转换为 Isar 模型列表
  static List<Note> fromDomainList(List<NoteEntity> entities) {
    return entities.map((entity) => fromDomain(entity)).toList();
  }
}
