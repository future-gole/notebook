import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 是否正在添加笔记（桌面端使用）
final isAddingNoteProvider = StateProvider<bool>((ref) => false);
