// 路径: lib/pages/edit_note_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/util/app_config.dart';

// 标签页枚举
enum EditTab { title, content, tags, spaces }

class EditNotePage extends ConsumerStatefulWidget {
  final String initialTitle;
  final String initialContent;
  final VoidCallback onDone;
  final int id;

  const EditNotePage({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.onDone,
    required this.id,
  });

  @override
  ConsumerState<EditNotePage> createState() => EditNotePageState();
}

class EditNotePageState extends ConsumerState<EditNotePage> {
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagController;
  late final TextEditingController _titleController;

  final _config = AppConfig();
  bool _titleEnabled = false;

  EditTab _currentTab = EditTab.content; // 默认从内容标签开始
  
  String _selectedCategory = 'home';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _categoryController = TextEditingController();
    _tagController = TextEditingController();
    _loadTitleSetting();
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    setState(() {
      _titleEnabled = _config.titleEnabled;
      if (!_titleEnabled) {
        _currentTab = EditTab.content; // 如果标题禁用，从内容开始
      } else {
        _currentTab = EditTab.title; // 如果标题启用，从标题开始
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onDone() async {
    final noteService = ref.read(noteServiceProvider);
    await noteService.addOrUpdateNote(
      id: widget.id,
      title: _titleEnabled ? _titleController.text : null, // 根据设置决定是否保存标题
      content: _contentController.text,
      category: _selectedCategory, // 使用选中的分类名称
      categoryId: _selectedCategoryId, // 使用选中的分类ID
      tag: _tagController.text,
    );

    // todo 发送至后端

    widget.onDone();
  }

  // 构建顶部导航栏
  Widget _buildTopNavBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 只在启用标题时显示标题标签
          if (_titleEnabled) ...[
            _buildNavTab(
              icon: Icons.title_outlined,
              label: '标题',
              tab: EditTab.title,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 40),
          ],
          _buildNavTab(
            icon: Icons.note_outlined,
            label: '正文',
            tab: EditTab.content,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 40),
          _buildNavTab(
            icon: Icons.circle_outlined,
            label: '分类',
            tab: EditTab.spaces,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 40),
          _buildNavTab(
            icon: Icons.local_offer_outlined,
            label: '标签',
            tab: EditTab.tags,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  // 构建单个导航标签
  Widget _buildNavTab({
    required IconData icon,
    required String label,
    required EditTab tab,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _currentTab == tab;
    final color = isSelected ? colorScheme.primary : colorScheme.secondary;

    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 构建 Notes 页面内容
  Widget _buildNotesContent(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        // 强制对齐到顶部
        alignment: Alignment.topLeft,
        child: TextField(
          controller: _currentTab == EditTab.content
              ? _contentController
              : _titleController,
          decoration: InputDecoration(
            hintText: "Start typing here...",
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
          maxLines: null, // 允许无限行
          expands: true, // 关键：让TextField扩展填充可用空间
          textAlignVertical: TextAlignVertical.top, // 文本从顶部开始
          textAlign: TextAlign.left, // 文本左对齐
        ),
      ),
    );
  }

  // 构建 Tags 页面内容
  Widget _buildTagsContent(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagController,
            decoration: InputDecoration(
              hintStyle: TextStyle(color: colorScheme.secondary, fontSize: 16),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          Text(
            "RECENT TAGS",
            style: TextStyle(
              color: colorScheme.secondary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // todo 这里添加标签列表
        ],
      ),
    );
  }

  // 构建 Category 页面内容
  Widget _buildCategoryContent(ColorScheme colorScheme) {
    // 使用 AsyncValue 处理异步分类数据
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 根据异步状态显示内容
          categoriesAsync.when(
            data: (categories) {
              // 数据加载成功，显示分类列表
              if (categories.isEmpty) {
                return Text(
                  '暂无分类',
                  style: TextStyle(color: colorScheme.secondary),
                );
              }

              // 如果当前未选择分类，或默认分类名称找不到，选中第一个分类
              final fallbackCategory = categories.first;
              final matchedCategory = categories.firstWhere(
                (category) => category.name == _selectedCategory,
                orElse: () => fallbackCategory,
              );

              if (_selectedCategoryId != matchedCategory.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _selectedCategoryId = matchedCategory.id;
                    _selectedCategory = matchedCategory.name;
                  });
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: categories.map((category) {
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    value: category.name,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _selectedCategoryId = category.id;
                      });
                    },
                    activeColor: colorScheme.primary,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              '加载分类失败: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: screenHeight * 0.85, // 占屏幕85%高度
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部导航栏
            _buildTopNavBar(),

            const SizedBox(height: 8),

            // 当前标签页内容
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter, // 靠上对齐
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: Container(
                  key: ValueKey(_currentTab),
                  child:
                      _currentTab == EditTab.content ||
                          _currentTab == EditTab.title
                      ? _buildNotesContent(colorScheme)
                      : SingleChildScrollView(
                          child: _currentTab == EditTab.tags
                          ? _buildTagsContent(colorScheme)
                          : _buildCategoryContent(colorScheme),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // "Done" 药丸按钮 - 使用主题颜色
            ElevatedButton(
              onPressed: _onDone,
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
                "Done",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            SizedBox(height: bottomInset > 0 ? 16 : 40),
          ],
        ),
      ),
    );
  }
}
