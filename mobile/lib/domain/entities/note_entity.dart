import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketmind/core/constants.dart';

part 'note_entity.freezed.dart';

/// 笔记领域实体 - 不依赖任何具体数据库实现
///
/// 这是纯净的业务对象，只包含业务逻辑需要的数据字段
@freezed
abstract class NoteEntity with _$NoteEntity {
  const factory NoteEntity({
    /// 笔记ID，null 表示尚未持久化的新笔记
    int? id,

    /// 笔记标题，可为空
    String? title,

    /// 笔记内容
    String? content,

    /// 保存网页链接的 url
    String? url,

    /// 创建/修改时间
    DateTime? time,

    /// 分类ID，用于关联到 CategoryEntity
    @Default(AppConstants.homeCategoryId) int categoryId,

    /// 标签
    String? tag,

    /// 链接预览图片URL（网络链接笔记用）
    String? previewImageUrl,

    /// 链接预览标题（网络链接笔记用）
    String? previewTitle,

    /// 链接预览描述（网络链接笔记用）
    String? previewDescription,
  }) = _NoteEntity;
}
