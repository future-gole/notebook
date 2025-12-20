import '../../domain/entities/note_entity.dart';
import '../../model/note.dart';

/// Note 与 NoteEntity 之间的映射扩展
///
/// 负责在数据库特定模型（Isar）和纯净领域实体之间转换

/// Note 模型的扩展方法
extension NoteX on Note {
  /// 将 Isar Note 模型转换为领域实体
  NoteEntity toDomain() {
    return NoteEntity(
      id: id,
      title: title,
      content: content,
      url: url,
      time: time,
      categoryId: categoryId,
      tag: tag,
      previewImageUrl: previewImageUrl,
      previewTitle: previewTitle,
      previewDescription: previewDescription,
    );
  }
}

/// NoteEntity 领域实体的扩展方法
extension NoteEntityX on NoteEntity {
  /// 将领域实体转换为 Isar Note 模型
  Note toModel() {
    final note = Note()
      ..title = title
      ..content = content
      ..url = url
      ..time = time
      ..categoryId = categoryId
      ..tag = tag
      ..previewImageUrl = previewImageUrl
      ..previewTitle = previewTitle
      ..previewDescription = previewDescription;

    // 如果实体有ID，说明是更新操作，设置ID
    if (id != null) {
      note.id = id!;
    }

    return note;
  }
}

/// Note 列表的扩展方法
extension NoteListX on List<Note> {
  /// 批量转换为领域实体列表
  List<NoteEntity> toDomainList() {
    return map((note) => note.toDomain()).toList();
  }
}

/// NoteEntity 列表的扩展方法
extension NoteEntityListX on List<NoteEntity> {
  /// 批量转换为 Isar 模型列表
  List<Note> toModelList() {
    return map((entity) => entity.toModel()).toList();
  }
}
