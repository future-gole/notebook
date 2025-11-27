import '../../model/note.dart';
import '../../model/category.dart';

/// 同步数据映射器
/// 
/// 集中管理 Note 和 Category 与 JSON 之间的转换
/// 用于网络传输和同步功能
/// 
/// 注意：这里直接使用 Isar 模型是因为同步层需要访问数据库特定字段
/// (uuid, updatedAt, isDeleted)，这些字段不在领域实体中
class SyncDataMapper {
  // ==================== Note 转换 ====================

  /// 将 Note 转换为同步 JSON
  static Map<String, dynamic> noteToJson(Note note) {
    return {
      'uuid': note.uuid,
      'title': note.title,
      'content': note.content,
      'url': note.url,
      'time': note.time?.millisecondsSinceEpoch,
      'updatedAt': note.updatedAt,
      'isDeleted': note.isDeleted,
      'categoryId': note.categoryId,
      'tag': note.tag,
    };
  }

  /// 将 Note 转换为带类型标记的同步 JSON
  static Map<String, dynamic> noteToJsonWithType(Note note) {
    return {
      ...noteToJson(note),
      '_entityType': 'note',
    };
  }

  /// 从同步 JSON 创建 Note
  static Note noteFromJson(Map<String, dynamic> json) {
    final note = Note()
      ..uuid = json['uuid'] as String?
      ..title = json['title'] as String?
      ..content = json['content'] as String?
      ..url = json['url'] as String?
      ..categoryId = json['categoryId'] as int? ?? 1
      ..tag = json['tag'] as String?
      ..updatedAt = json['updatedAt'] as int? ?? 0
      ..isDeleted = json['isDeleted'] as bool? ?? false;

    if (json['time'] != null) {
      note.time = DateTime.fromMillisecondsSinceEpoch(json['time'] as int);
    }

    return note;
  }

  /// 批量转换 Note 列表为 JSON
  static List<Map<String, dynamic>> notesToJsonList(List<Note> notes) {
    return notes.map(noteToJson).toList();
  }

  /// 批量转换 Note 列表为带类型标记的 JSON
  static List<Map<String, dynamic>> notesToJsonListWithType(List<Note> notes) {
    return notes.map(noteToJsonWithType).toList();
  }

  // ==================== Category 转换 ====================

  /// 将 Category 转换为同步 JSON
  static Map<String, dynamic> categoryToJson(Category category) {
    return {
      'uuid': category.uuid,
      'name': category.name,
      'description': category.description,
      'createdTime': category.createdTime?.millisecondsSinceEpoch,
      'updatedAt': category.updatedAt,
      'isDeleted': category.isDeleted,
    };
  }

  /// 将 Category 转换为带类型标记的同步 JSON
  static Map<String, dynamic> categoryToJsonWithType(Category category) {
    return {
      ...categoryToJson(category),
      '_entityType': 'category',
    };
  }

  /// 从同步 JSON 创建 Category
  static Category categoryFromJson(Map<String, dynamic> json) {
    final category = Category()
      ..uuid = json['uuid'] as String?
      ..name = json['name'] as String
      ..description = json['description'] as String?
      ..updatedAt = json['updatedAt'] as int? ?? 0
      ..isDeleted = json['isDeleted'] as bool? ?? false;

    if (json['createdTime'] != null) {
      category.createdTime = DateTime.fromMillisecondsSinceEpoch(json['createdTime'] as int);
    }

    return category;
  }

  /// 批量转换 Category 列表为 JSON
  static List<Map<String, dynamic>> categoriesToJsonList(List<Category> categories) {
    return categories.map(categoryToJson).toList();
  }

  /// 批量转换 Category 列表为带类型标记的 JSON
  static List<Map<String, dynamic>> categoriesToJsonListWithType(List<Category> categories) {
    return categories.map(categoryToJsonWithType).toList();
  }

  // ==================== 混合数据转换 ====================

  /// 将 Notes 和 Categories 合并为带类型标记的 JSON 列表
  static List<Map<String, dynamic>> combineChanges({
    required List<Note> notes,
    required List<Category> categories,
  }) {
    return [
      ...notesToJsonListWithType(notes),
      ...categoriesToJsonListWithType(categories),
    ];
  }
}
