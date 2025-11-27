import 'package:isar_community/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  /// 全局唯一标识符 (UUID v4)，用于跨设备同步
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  late String name; // 分类名称，唯一索引

  String? description; // 分类描述

  DateTime? createdTime; // 创建时间

  /// 最后更新时间戳（毫秒），用于增量同步和冲突解决
  @Index()
  int updatedAt = 0;

  /// 软删除标记，true 表示已删除
  bool isDeleted = false;
}
