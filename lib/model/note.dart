import 'package:isar_community/isar.dart';

part 'note.g.dart';
@collection
class Note{
  Id id = Isar.autoIncrement;

  String? title;

  String? content;

  DateTime? time;
}