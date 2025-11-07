import 'package:isar_community/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name; // 分类名称，唯一索引

  String? description; // 分类描述

  DateTime? createdTime; // 创建时间
}
