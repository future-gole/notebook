// 路径: lib/pages/edit_note_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/api/note_api_service.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/server/category_service.dart';
import 'package:pocketmind/util/app_config.dart';

// 标签页枚举
enum EditTab { title, content, tags, category, AI }

class EditNotePage extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final VoidCallback onDone;
  final int id;
  final String? webUrl;

  const EditNotePage({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.onDone,
    this.webUrl,
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
  late final TextEditingController _aiController;

  final _config = AppConfig();
  bool _titleEnabled = false;

  EditTab _currentTab = EditTab.content; // 默认从内容标签开始

  String _selectedCategory = 'home';
  int _selectedCategoryId = 1;
  bool _isAddingCategory = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _categoryController = TextEditingController();
    _tagController = TextEditingController();
    _aiController = TextEditingController();
    _loadTitleSetting();
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    setState(() {
      _titleEnabled = _config.titleEnabled;
      // 根据标题启用状态选择初始标签页
      _currentTab = _titleEnabled ? EditTab.title : EditTab.content;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _titleController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  void _onDone() async {
    final noteService = ref.read(noteServiceProvider);
    await noteService.addOrUpdateNote(
      id: widget.id,
      title: _titleEnabled ? _titleController.text : null, // 根据设置决定是否保存标题
      content: _contentController.text,
      url: widget.webUrl,
      category: _selectedCategory, // 使用选中的分类名称
      categoryId: _selectedCategoryId, // 使用选中的分类ID
      tag: _tagController.text,
    );
    if(_aiController.text.isNotEmpty){
      // 直接发送不用 await
      ref.read(noteApiServiceProvider).analyzePage(
          userQuery: _aiController.text,
          webUrl: widget.webUrl,
          userEmail: "double2z2@163.com");
    }
    widget.onDone();
  }

  // 构建顶部导航栏
  Widget _buildTopNavBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.transparent, // 透明背景以显示底层 FlowingBackground
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
            tab: EditTab.category,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 40),
          _buildNavTab(
            icon: Icons.local_offer_outlined,
            label: '标签',
            tab: EditTab.tags,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 40),
          _buildNavTab(
            icon: Icons.question_answer_outlined,
            label: 'AI',
            tab: EditTab.AI,
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

  // 构建内容/标题/AI编辑页面
  Widget _buildNotesContent(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.topLeft,
      child: TextField(
        controller: _currentTab == EditTab.content
            ? _contentController :
            _currentTab == EditTab.title ? _titleController
            : _aiController,
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
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildTagsContent(ColorScheme colorScheme) {
    return Container(
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
              hintText: "添加标签...",
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
          Text(
            "暂无最近使用的标签",
            style: TextStyle(
              color: colorScheme.secondary.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String name) async {
    CategoryService service = ref.read(categoryServiceProvider);
    await service.addCategory(name: name);
  }

  void _startAddingCategory() {
    setState(() {
      _isAddingCategory = true;
    });
  }

  void _cancelAddingCategory() {
    setState(() {
      _isAddingCategory = false;
      _categoryController.clear();
    });
  }

  Future<void> _confirmAddCategory() async {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty) {
      await _addCategory(name);
      ref.invalidate(categoriesProvider);
    }
    setState(() {
      _isAddingCategory = false;
      _categoryController.clear();
    });
  }

  // 构建分类选择页面
  Widget _buildCategoryContent(ColorScheme colorScheme) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Text(
                  '暂无分类',
                  style: TextStyle(color: colorScheme.secondary),
                );
              }

              // 如果当前未选择分类，或默认分类找不到，选中第一个分类
              final fallbackCategory = categories.first;
              final matchedCategory = categories.firstWhere(
                (category) => category.name == _selectedCategory,
                orElse: () => fallbackCategory,
              );

              // 异步更新选中的分类ID
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
                children: [
                  ...categories.map((category) {
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
                  }),
                  if (_isAddingCategory) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _categoryController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: '新分类',
                                hintStyle: TextStyle(
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              onSubmitted: (_) => _confirmAddCategory(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _confirmAddCategory,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _cancelAddingCategory,
                            child: Icon(
                              Icons.close,
                              color: colorScheme.secondary.withValues(
                                alpha: 0.6,
                              ),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _startAddingCategory,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: topPadding, // 从系统状态栏下方开始
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 浮动透明导航栏
          Positioned(top: 0, left: 0, right: 0, child: _buildTopNavBar()),

          // 背景容器（从导航栏下方开始）
          Positioned(
            top: 72, // 导航栏高度
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 当前标签页内容区域
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset, top: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder:
                            (
                              Widget? currentChild,
                              List<Widget> previousChildren,
                            ) {
                              return Stack(
                                alignment: Alignment.topCenter,
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
                                  _currentTab == EditTab.title ||
                            _currentTab == EditTab.AI
                              ? _buildNotesContent(colorScheme)
                              : SingleChildScrollView(
                                  child: _currentTab == EditTab.tags
                                      ? _buildTagsContent(colorScheme)
                                      : _buildCategoryContent(colorScheme),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Done 按钮
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

                  SizedBox(height: bottomPadding > 0 ? bottomPadding : 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
