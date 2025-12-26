/// 统一的 note 元数据返回结构
///
/// 整合后端和本地LinkPreview两种数据源的返回数据
/// 调用方应优先使用 previewContent，如果为空则回退到 previewDescription
class NoteMetadata {
  /// 标题
  final String? title;

  /// 描述（来自本地LinkPreview）
  final String? previewDescription;

  /// 正文内容（来自后端API）
  final String? previewContent;

  /// AI摘要（来自后端API）
  final String? aiSummary;

  /// 预览图片URL（已本地化的路径）
  final String? imageUrl;

  /// 原始URL
  final String url;

  /// 资源状态（来自后端API：PENDING, SUCCESS, FAILED）
  final String? resourceStatus;

  NoteMetadata({
    this.title,
    this.previewDescription,
    this.previewContent,
    this.aiSummary,
    this.imageUrl,
    required this.url,
    this.resourceStatus,
  });

  /// 是否有效（至少有标题或图片）
  bool get isValid =>
      (title != null && title!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  /// 获取展示用的描述（优先使用 previewContent）
  String? get displayDescription {
    if (previewContent != null && previewContent!.trim().isNotEmpty) {
      return previewContent;
    }
    return previewDescription;
  }
}
