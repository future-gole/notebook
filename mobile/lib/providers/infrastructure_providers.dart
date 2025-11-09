import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

/// Isar 实例 Provider（基础设施层）
/// 当 DatabaseConfig.useIsar 为 true 时使用
/// 需要在 main.dart 中通过 overrideWithValue 提供实际的 Isar 实例
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main()');
});
