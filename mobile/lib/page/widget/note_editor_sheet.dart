// 路径: lib/page/widget/note_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/providers/note_providers.dart';

/// 统一的笔记编辑器底部模态框
/// 同时支持"新建"和"编辑"模式
/// 与分享页 EditNotePage 保持一致的 UI 风格
class NoteEditorSheet extends ConsumerStatefulWidget {
  final Note? note; // null = 新建模式，非null = 编辑模式
  final String? initialContent; // 用于从分享接收内容

  const NoteEditorSheet({super.key, this.note, this.initialContent});

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    // 根据模式初始化控制器
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? widget.initialContent ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.note?.category ?? 'home',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _categoryController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      // 提示用户填写必填字段
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('标题和内容不能为空'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final noteService = ref.read(noteServiceProvider);

    if (_isEditMode) {
      // 编辑模式：更新现有笔记
      await noteService.addOrUpdateNote(
        id: widget.note!.id,
        title: title,
        content: content,
        category: category,
      );
    } else {
      // 新建模式：创建新笔记
      await noteService.addOrUpdateNote(
        title: title,
        content: content,
        category: category,
      );
    }

    // 刷新笔记列表
    ref.invalidate(noteByCategoryProvider);

    if (!context.mounted) return;

    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? '笔记已更新' : '笔记已保存'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // 关闭模态框
    Navigator.of(context).pop();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required ColorScheme colorScheme,
    int? maxLines,
    bool autofocus = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.secondary, fontSize: 16),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        maxLines: maxLines,
        autofocus: autofocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode ? '编辑笔记' : '新建笔记',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colorScheme.secondary,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 标题输入框
                _buildTextField(
                  controller: _titleController,
                  hintText: '给你的笔记起个名字...',
                  colorScheme: colorScheme,
                  maxLines: 1,
                  autofocus: !_isEditMode && widget.initialContent == null,
                ),

                // 分类输入框
                _buildTextField(
                  controller: _categoryController,
                  hintText: '选择一个分类',
                  colorScheme: colorScheme,
                  maxLines: 1,
                ),

                // 内容输入框
                _buildTextField(
                  controller: _contentController,
                  hintText: '记录你的想法...',
                  colorScheme: colorScheme,
                  maxLines: 8,
                  autofocus: widget.initialContent != null,
                ),

                const SizedBox(height: 8),

                // "Save" 药丸按钮 - 使用主题颜色
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                SizedBox(height: bottomInset > 0 ? 16 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
