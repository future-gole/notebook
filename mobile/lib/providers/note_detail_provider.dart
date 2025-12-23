import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'package:pocketmind/util/logger_service.dart';

part 'note_detail_provider.freezed.dart';
part 'note_detail_provider.g.dart';

@freezed
abstract class NoteDetailState with _$NoteDetailState {
  const factory NoteDetailState({
    required Note note,
    @Default(false) bool isLoadingPreview,
    @Default([]) List<String> tags,
    @Default(false) bool isSaving,
    Object? error,
  }) = _NoteDetailState;
}

@riverpod
class NoteDetail extends _$NoteDetail {
  Timer? _debounceTimer;
  static const _tag = 'NoteDetailNotifier';

  @override
  NoteDetailState build(Note initialNote) {
    // 初始化标签
    final tags = initialNote.tag != null && initialNote.tag!.isNotEmpty
        ? initialNote.tag!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    return NoteDetailState(note: initialNote, tags: tags);
  }

  /// 更新笔记内容（带防抖保存）
  void updateNote({
    String? title,
    String? content,
    int? categoryId,
    List<String>? tags,
  }) {
    final currentNote = state.note;
    final updatedNote = currentNote.copyWith(
      title: title ?? currentNote.title,
      content: content ?? currentNote.content,
      categoryId: categoryId ?? currentNote.categoryId,
      tag: tags?.join(',') ?? currentNote.tag,
    );

    state = state.copyWith(note: updatedNote, tags: tags ?? state.tags);

    _debounceSave();
  }

  /// 添加标签
  void addTag(String tag) {
    if (tag.isEmpty || state.tags.contains(tag)) return;
    final newTags = [...state.tags, tag];
    updateNote(tags: newTags);
  }

  /// 移除标签
  void removeTag(String tag) {
    final newTags = state.tags.where((t) => t != tag).toList();
    updateNote(tags: newTags);
  }

  /// 切换分类
  void updateCategory(int categoryId) {
    updateNote(categoryId: categoryId);
  }

  /// 防抖保存逻辑
  void _debounceSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      saveNote();
    });
  }

  /// 立即保存笔记
  Future<void> saveNote() async {
    if (state.isSaving) return;

    try {
      state = state.copyWith(isSaving: true);
      final noteService = ref.read(noteServiceProvider);

      final id = await noteService.addOrUpdateNote(
        id: state.note.id,
        title: state.note.title,
        content: state.note.content,
        url: state.note.url,
        categoryId: state.note.categoryId,
        tag: state.note.tag,
        previewImageUrl: state.note.previewImageUrl,
        previewTitle: state.note.previewTitle,
        previewDescription: state.note.previewDescription,
        updatedAt: state.note.updatedAt,
      );

      if (!ref.mounted) return;

      if (state.note.id == null) {
        state = state.copyWith(note: state.note.copyWith(id: id));
      }

      PMlog.d(_tag, 'Note saved successfully: $id');
    } catch (e) {
      PMlog.e(_tag, 'Failed to save note: $e');
      if (ref.mounted) {
        state = state.copyWith(error: e);
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  /// 删除笔记
  Future<void> deleteNote() async {
    try {
      final noteService = ref.read(noteServiceProvider);
      await noteService.deleteFullNote(state.note);
    } catch (e) {
      PMlog.e(_tag, 'Failed to delete note: $e');
      rethrow;
    }
  }

  /// 加载链接预览
  Future<void> loadLinkPreview() async {
    final url = state.note.url;
    if (url == null || !UrlHelper.containsHttpsUrl(url)) {
      return;
    }

    // 如果已经有预览数据，不再重复加载
    if (state.note.previewImageUrl != null || state.note.previewTitle != null) {
      return;
    }

    if (!ref.mounted) return;
    state = state.copyWith(isLoadingPreview: true);

    try {
      await ref.read(noteServiceProvider).enrichNoteWithMetadata(state.note);
    } catch (e) {
      PMlog.e(_tag, 'Failed to load link preview: $e');
      // 可以在这里设置 error state 供 UI 显示 Toast
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoadingPreview: false);
      }
    }
  }

  /// 分享笔记
  void shareNote(dynamic context) {
    // TODO: 实现分享逻辑
    PMlog.d(_tag, 'Sharing note: ${state.note.title}');
  }
}
