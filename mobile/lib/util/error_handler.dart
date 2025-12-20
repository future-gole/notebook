import 'package:flutter/material.dart';
import 'package:pocketmind/domain/failures/repository_failure.dart';
import 'package:pocketmind/page/widget/creative_toast.dart';

/// 错误处理工具类
///
/// 封装统一的错误处理逻辑，集成 CreativeToast 显示错误信息
class ErrorHandler {
  ErrorHandler._();

  /// 处理 Repository 异常并显示 Toast
  ///
  /// [context] Flutter BuildContext
  /// [error] 捕获的异常对象
  /// [defaultMessage] 默认错误消息（当异常不是 RepositoryFailure 时使用）
  static void handleRepositoryError(
    BuildContext context,
    Object error, {
    String defaultMessage = '操作失败',
  }) {
    String title = '错误';
    String message = defaultMessage;

    if (error is RepositoryFailure) {
      // Domain 层异常，提取友好消息
      title = _getFailureTitle(error);
      message = error.message;
    } else {
      // 其他未知异常
      message = '$defaultMessage: ${error.toString()}';
    }

    CreativeToast.error(
      context,
      title: title,
      message: message,
      direction: ToastDirection.top,
    );
  }

  /// 处理笔记操作成功并显示 Toast
  static void showNoteSuccess(
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

  /// 根据 Failure 类型返回友好的标题
  static String _getFailureTitle(RepositoryFailure failure) {
    if (failure is SaveNoteFailure) {
      return '保存失败';
    } else if (failure is DeleteNoteFailure) {
      return '删除失败';
    } else if (failure is NoteNotFoundFailure) {
      return '笔记不存在';
    } else if (failure is QueryNoteFailure) {
      return '查询失败';
    } else if (failure is SaveCategoryFailure) {
      return '保存分类失败';
    } else if (failure is DeleteCategoryFailure) {
      return '删除分类失败';
    } else if (failure is CategoryNotFoundFailure) {
      return '分类不存在';
    } else if (failure is CategoryOperationFailure) {
      return '分类操作失败';
    } else {
      return '操作失败';
    }
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
