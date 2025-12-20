/// Domain 层异常基类
///
/// 所有 Repository 抛出的异常必须继承此类，确保上层（Service/UI）
/// 不依赖任何基础设施实现（如 Isar、SQLite 等）
///
/// 这是 Clean Architecture 依赖倒置原则的体现：
/// - Data 层可以知道 Isar 异常
/// - Domain/Service/UI 层只知道这些抽象异常
abstract class RepositoryFailure implements Exception {
  /// 用户友好的错误消息
  final String message;

  /// 原始异常（用于调试和日志记录）
  /// 使用 Object? 而不是 Exception? 来兼容 IsarError 等非 Exception 类型
  final Object? originalException;

  const RepositoryFailure(this.message, [this.originalException]);

  @override
  String toString() =>
      'RepositoryFailure: $message'
      '${originalException != null ? ' (原因: $originalException)' : ''}';
}

// ==================== 笔记相关异常 ====================

/// 保存笔记失败
class SaveNoteFailure extends RepositoryFailure {
  const SaveNoteFailure([Object? cause]) : super('保存笔记失败', cause);
}

/// 删除笔记失败
class DeleteNoteFailure extends RepositoryFailure {
  final int noteId;

  const DeleteNoteFailure(this.noteId, [Object? cause])
    : super('删除笔记失败', cause);

  @override
  String toString() =>
      'DeleteNoteFailure: 删除笔记 $noteId 失败'
      '${originalException != null ? ' (原因: $originalException)' : ''}';
}

/// 笔记不存在
class NoteNotFoundFailure extends RepositoryFailure {
  final int noteId;

  const NoteNotFoundFailure(this.noteId) : super('笔记不存在');

  @override
  String toString() => 'NoteNotFoundFailure: 笔记 $noteId 不存在';
}

/// 查询笔记失败
class QueryNoteFailure extends RepositoryFailure {
  const QueryNoteFailure(String operation, [Object? cause])
    : super('查询笔记失败', cause);
}

// ==================== 分类相关异常 ====================

/// 分类操作失败
class CategoryOperationFailure extends RepositoryFailure {
  final String operation;

  const CategoryOperationFailure(this.operation, [Object? cause])
    : super('分类操作失败', cause);

  @override
  String toString() =>
      'CategoryOperationFailure: $operation 失败'
      '${originalException != null ? ' (原因: $originalException)' : ''}';
}

/// 保存分类失败
class SaveCategoryFailure extends RepositoryFailure {
  const SaveCategoryFailure([Object? cause]) : super('保存分类失败', cause);
}

/// 删除分类失败
class DeleteCategoryFailure extends RepositoryFailure {
  final int categoryId;

  const DeleteCategoryFailure(this.categoryId, [Object? cause])
    : super('删除分类失败', cause);

  @override
  String toString() =>
      'DeleteCategoryFailure: 删除分类 $categoryId 失败'
      '${originalException != null ? ' (原因: $originalException)' : ''}';
}

/// 分类不存在
class CategoryNotFoundFailure extends RepositoryFailure {
  final int categoryId;

  const CategoryNotFoundFailure(this.categoryId) : super('分类不存在');

  @override
  String toString() => 'CategoryNotFoundFailure: 分类 $categoryId 不存在';
}

// ==================== 数据库通用异常 ====================

/// 数据库连接失败
class DatabaseConnectionFailure extends RepositoryFailure {
  const DatabaseConnectionFailure([Object? cause]) : super('数据库连接失败', cause);
}

/// 数据库事务失败
class DatabaseTransactionFailure extends RepositoryFailure {
  const DatabaseTransactionFailure(String operation, [Object? cause])
    : super('数据库事务失败', cause);
}
