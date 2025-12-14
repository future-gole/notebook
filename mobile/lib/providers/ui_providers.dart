import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ui_providers.g.dart';

/// 是否正在添加笔记（桌面端使用）
@riverpod
class IsAddingNote extends _$IsAddingNote {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
