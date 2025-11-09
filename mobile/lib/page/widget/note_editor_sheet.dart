// 路径: lib/page/widget/note_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/page/widget/categories_bar.dart' show CategoriesBar;
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/app_config.dart';

/// 统一的笔记编辑器底部模态框
/// 同时支持"新建"和"编辑"模式
class NoteEditorSheet extends ConsumerStatefulWidget {
  final NoteEntity? note; // null = 新建模式，非null = 编辑模式

  const NoteEditorSheet({super.key, this.note});

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  int? _selectedCategoryId;

  final _config = AppConfig();
  bool _titleEnabled = false;

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    // 根据模式初始化控制器
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedCategoryId = widget.note?.categoryId;
    _loadTitleSetting();
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    setState(() {
      _titleEnabled = _config.titleEnabled;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 如果未启用标题，只检查内容
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('内容不能为空'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 如果启用标题，也检查标题
    if (_titleEnabled && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('标题不能为空'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 可以选择不分类，不分类就是默认的home

    final noteService = ref.read(noteServiceProvider);

    if (_isEditMode) {
      // 编辑模式：更新现有笔记
      await noteService.addOrUpdateNote(
        id: widget.note!.id,
        title: _titleEnabled ? title : null,
        content: content,
        categoryId: _selectedCategoryId,
      );
    } else {
      // 新建模式：创建新笔记
      await noteService.addOrUpdateNote(
        title: _titleEnabled ? title : null,
        content: content,
        categoryId: _selectedCategoryId,
      );
    }

    // 刷新笔记列表
    // 注意：由于 noteByCategoryProvider 现在使用 Stream 监听数据库变化，
    // 这个 invalidate 调用实际上不再必要（Stream 会自动更新）
    // 但保留它可以确保立即刷新，不会有任何副作用
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

  /// 构建通用的文本输入框
  /// [expands] 为 true 时，输入框会尝试填满父容器高度（需要父容器有固定高度限制，如 Expanded）
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required ColorScheme colorScheme,
    int? maxLines = 1,
    bool autofocus = false,
    bool expands = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
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
        // 当 expands 为 true 时，maxLines 必须为 null，minLines 必须为 null
        maxLines: expands ? null : maxLines,
        minLines: null,
        expands: expands,
        textAlignVertical: expands
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        autofocus: autofocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // 确保键盘弹出时布局能调整
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 顶部标题栏 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      iconSize: 35,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colorScheme.secondary,
                      tooltip: '取消',
                    ),
                    // 分类选择条，使用 Expanded 避免溢出，居中显示
                    const Expanded(
                      child: CategoriesBar(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _onSave,
                      color: colorScheme.primary,
                      tooltip: '保存',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- 标题输入框 (仅在启用时显示) ---
                if (_titleEnabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTextField(
                      controller: _titleController,
                      hintText: '给你的笔记起个名字...',
                      colorScheme: colorScheme,
                      maxLines: 1,
                      autofocus: !_isEditMode, // 新建时聚焦标题
                    ),
                  ),

                // --- 内容输入框 (占据剩余空间) ---
                Expanded(
                  child: _buildTextField(
                    controller: _contentController,
                    hintText: '记录你的想法...',
                    colorScheme: colorScheme,
                    maxLines: null, // 允许无限换行
                    expands: true, // 强制填满 Expanded 提供的空间
                    autofocus: !_titleEnabled && !_isEditMode, // 如果没标题且是新建，聚焦内容
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
