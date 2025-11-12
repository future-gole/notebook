import 'package:isar_community/isar.dart';
import 'category.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  String? title;

  String? content;

  String? url;

  DateTime? time;
  // 没有的话都需要默认给 1 即 home 目录
  int categoryId = 1;

  // 定义到Category的关系
  // 也不会有多少浪费，这样不需要再进行转化了
  final category = IsarLink<Category>();

  String? tag;
}
