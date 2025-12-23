import 'package:flutter/material.dart';
import 'package:pocketmind/page/widget/creative_toast.dart';

/// 错误处理工具类
///
/// 封装统一的错误处理逻辑，集成 CreativeToast 显示错误信息
class ErrorHandler {
  ErrorHandler._();

  /// 处理异常并显示 Toast
  ///
  /// [context] Flutter BuildContext
  /// [error] 捕获的异常对象
  /// [defaultMessage] 默认错误消息
  static void handleRepositoryError(
    BuildContext context,
    Object error, {
    String defaultMessage = '操作失败',
  }) {
    String title = '错误';
    String message = '$defaultMessage: ${error.toString()}';

    CreativeToast.error(
      context,
      title: title,
      message: message,
      direction: ToastDirection.top,
    );
  }

  /// 处理笔记操作成功并显示 Toast
  static void showNoteSuccess(BuildContext context, {required String action}) {
    CreativeToast.success(
      context,
      title: '成功',
      message: '$action成功',
      direction: ToastDirection.top,
    );
  }

  /// 处理分类操作成功并显示 Toast
  static void showCategorySuccess(
    BuildContext context, {
    required String action,
  }) {
    CreativeToast.success(
      context,
      title: '成功',
      message: '$action成功',
      direction: ToastDirection.top,
    );
  }

  /// 快捷方法：执行异步操作并自动处理错误
  ///
  /// 使用示例：
  /// ```dart
  /// await ErrorHandler.executeWithErrorHandling(
  ///   context,
  ///   action: () async {
  ///     await noteService.deleteNote(noteId);
  ///   },
  ///   successMessage: '删除笔记',
  /// );
  /// ```
  static Future<bool> executeWithErrorHandling(
    BuildContext context, {
    required Future<void> Function() action,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      await action();
      if (successMessage != null && context.mounted) {
        CreativeToast.success(
          context,
          title: '成功',
          message: successMessage,
          direction: ToastDirection.top,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        handleRepositoryError(
          context,
          e,
          defaultMessage: errorMessage ?? '操作失败',
        );
      }
      return false;
    }
  }

  /// 快捷方法：执行返回值的异步操作并自动处理错误
  ///
  /// 使用示例：
  /// ```dart
  /// final noteId = await ErrorHandler.executeWithResult<int>(
  ///   context,
  ///   action: () => noteService.addOrUpdateNote(...),
  ///   successMessage: '保存笔记',
  /// );
  /// ```
  static Future<T?> executeWithResult<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      final result = await action();
      if (successMessage != null && context.mounted) {
        CreativeToast.success(
          context,
          title: '成功',
          message: successMessage,
          direction: ToastDirection.top,
        );
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        handleRepositoryError(
          context,
          e,
          defaultMessage: errorMessage ?? '操作失败',
        );
      }
      return null;
    }
  }
}
