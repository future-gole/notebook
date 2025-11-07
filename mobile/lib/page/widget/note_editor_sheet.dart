// 路径: lib/page/widget/note_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/app_config.dart';

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
      text: widget.note?.content ?? widget.initialContent ?? '',
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

    // 确保选择了分类
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择一个分类'),
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
        title: _titleEnabled ? title : null, // 根据设置决定是否保存标题
        content: content,
        categoryId: _selectedCategoryId,
      );
    } else {
      // 新建模式：创建新笔记
      await noteService.addOrUpdateNote(
        title: _titleEnabled ? title : null, // 根据设置决定是否保存标题
        content: content,
        categoryId: _selectedCategoryId,
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

  Widget _buildCategorySection(ColorScheme colorScheme) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Text(
              '暂无分类，请先创建分类后再添加笔记',
              style: TextStyle(color: colorScheme.secondary),
            );
          }

          if (_selectedCategoryId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedCategoryId = categories.first.id;
              });
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.map((category) {
                  final isSelected = category.id == _selectedCategoryId;
                  final label = category.description?.isNotEmpty == true
                      ? category.description!
                      : category.name;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                    selectedColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    backgroundColor: colorScheme.surface,
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text(
          '加载分类失败: $error',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
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

                // 标题输入框 - 只在启用时显示
                if (_titleEnabled)
                  _buildTextField(
                    controller: _titleController,
                    hintText: '给你的笔记起个名字...',
                    colorScheme: colorScheme,
                    maxLines: 1,
                    autofocus: !_isEditMode && widget.initialContent == null,
                  ),

                _buildCategorySection(colorScheme),

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
