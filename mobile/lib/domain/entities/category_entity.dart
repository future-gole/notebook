import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_entity.freezed.dart';
part 'category_entity.g.dart';

/// 分类领域实体 - 不依赖任何具体数据库实现
///
/// 这是纯净的业务对象，只包含业务逻辑需要的数据字段
@freezed
abstract class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    @Default(1) int id,

    /// 分类名称（唯一）
    required String name,

    /// 分类描述
    String? description,

    /// 创建时间
    DateTime? createdTime,
  }) = _CategoryEntity;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) =>
      _$CategoryEntityFromJson(json);
}
