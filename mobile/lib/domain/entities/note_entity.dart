/// 笔记领域实体 - 不依赖任何具体数据库实现
/// 
/// 这是纯净的业务对象，只包含业务逻辑需要的数据字段
class NoteEntity {
  /// 笔记ID，null 表示尚未持久化的新笔记
  final int? id;

  /// 笔记标题，可为空
  final String? title;

  /// 笔记内容
  final String? content;

  /// url
  final String? url;

  /// 创建/修改时间
  final DateTime? time;

  /// 分类ID，用于关联到 CategoryEntity
  final int categoryId;

  /// 标签
  final String? tag;

  const NoteEntity({
    this.id,
    this.title,
    this.content,
    this.url,
    this.time,
    this.categoryId = 1,
    this.tag,
  });

  /// 复制并修改部分字段
  NoteEntity copyWith({
    int? id,
    String? title,
    String? content,
    String? url,
    DateTime? time,
    int? categoryId,
    String? tag,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.content,
      time: time ?? this.time,
      categoryId: categoryId ?? this.categoryId,
      tag: tag ?? this.tag,
    );
  }

  @override
  String toString() {
    return 'NoteEntity(id: $id, title: $title, categoryId: $categoryId, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NoteEntity &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.url == url &&
        other.time == time &&
        other.categoryId == categoryId &&
        other.tag == tag;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, url, time, categoryId, tag);
  }
}
