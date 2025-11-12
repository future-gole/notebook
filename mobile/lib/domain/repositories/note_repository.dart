import '../entities/note_entity.dart';

/// 笔记数据访问抽象接口
/// 定义所有笔记相关的数据操作，不依赖任何具体数据库实现
abstract class NoteRepository {
  /// 保存笔记（新增或更新）
  /// 返回保存后的笔记ID，失败返回 -1
  Future<int> save(NoteEntity note);

  /// 根据ID删除笔记
  Future<void> delete(int id);

  /// 根据ID获取笔记
  Future<NoteEntity?> getById(int id);

  /// 获取所有笔记（按时间倒序）
  Future<List<NoteEntity>> getAll();

  /// 监听所有笔记变化（实时订阅）
  Stream<List<NoteEntity>> watchAll();

  /// 监听对应category的笔记变化（实时订阅）
  Stream<List<NoteEntity>> watchByCategory(int category);

  /// 根据标题搜索笔记（模糊匹配，不区分大小写）
  Future<List<NoteEntity>> findByTitle(String query);

  /// 根据内容搜索笔记（模糊匹配，不区分大小写）
  Future<List<NoteEntity>> findByContent(String query);

  /// 搜索笔记（模糊匹配，不区分大小写）
  Future<List<NoteEntity>> findByQuery(String query);

  /// 根据分类ID获取笔记（按时间倒序）
  /// categoryId 为 1 时返回所有笔记
  Future<List<NoteEntity>> findByCategoryId(int categoryId);

  /// 根据标签搜索笔记（模糊匹配，不区分大小写）
  Future<List<NoteEntity>> findByTag(String query);
}
