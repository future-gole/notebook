import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Result 类型用于表示操作的成功或失败
///
/// 使用 Result 而不是抛出异常可以：
/// 1. 明确表示操作可能失败
/// 2. 强制调用者处理错误情况
/// 3. 避免使用 try-catch 的性能开销
///
/// 示例：
/// ```dart
/// Future<Result<User>> getUser(int id) async {
///   try {
///     final user = await repository.getUser(id);
///     if (user == null) {
///       return Result.failure(UserNotFoundError());
///     }
///     return Result.success(user);
///   } catch (e) {
///     return Result.failure(e);
///   }
/// }
///
/// // 使用
/// final result = await getUser(123);
/// result.when(
///   success: (user) => print('User: ${user.name}'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
@freezed
abstract class Result<T> with _$Result<T> {
  const Result._();

  /// 成功结果
  const factory Result.success(T data) = Success<T>;

  /// 失败结果
  const factory Result.failure(Object error) = Failure<T>;

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取数据（如果成功）
  T? get dataOrNull => when(
        success: (data) => data,
        failure: (_) => null,
      );

  /// 获取错误（如果失败）
  Object? get errorOrNull => when(
        success: (_) => null,
        failure: (error) => error,
      );

  /// 获取数据或抛出异常
  T getOrThrow() => when(
        success: (data) => data,
        failure: (error) => throw error,
      );

  /// 获取数据或返回默认值
  T getOrElse(T defaultValue) => when(
        success: (data) => data,
        failure: (_) => defaultValue,
      );

  /// 转换成功值
  Result<R> map<R>(R Function(T data) transform) => when(
        success: (data) => Result.success(transform(data)),
        failure: (error) => Result.failure(error),
      );

  /// 异步转换成功值
  Future<Result<R>> mapAsync<R>(
    Future<R> Function(T data) transform,
  ) async =>
      when(
        success: (data) async {
          try {
            final result = await transform(data);
            return Result.success(result);
          } catch (e) {
            return Result.failure(e);
          }
        },
        failure: (error) => Future.value(Result.failure(error)),
      );

  /// flatMap - 链式调用多个可能失败的操作
  Result<R> flatMap<R>(Result<R> Function(T data) transform) => when(
        success: (data) => transform(data),
        failure: (error) => Result.failure(error),
      );

  /// 异步 flatMap
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async =>
      when(
        success: (data) => transform(data),
        failure: (error) => Future.value(Result.failure(error)),
      );
}

/// 便捷方法：将可能抛出异常的操作包装为 Result
Future<Result<T>> runCatching<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return Result.success(result);
  } catch (e) {
    return Result.failure(e);
  }
}

/// 同步版本的 runCatching
Result<T> runCatchingSync<T>(T Function() operation) {
  try {
    final result = operation();
    return Result.success(result);
  } catch (e) {
    return Result.failure(e);
  }
}
