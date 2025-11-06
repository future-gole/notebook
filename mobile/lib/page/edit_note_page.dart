// 路径: lib/pages/edit_note_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/note_providers.dart';

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

  EditTab _currentTab = EditTab.title;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _categoryController = TextEditingController();
    _tagController = TextEditingController();
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
      title: _titleController.text,
      content: _contentController.text,
      category: _categoryController.text,
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
          _buildNavTab(
            icon: Icons.title_outlined,
            label: '标题',
            tab: EditTab.title,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 40),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
        maxLines: null,
        minLines: 8,
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
              hintText: "标签",
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

  // 构建 Spaces 页面内容
  Widget _buildSpacesContent(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _categoryController,
        decoration: InputDecoration(
          hintText: "分类",
          hintStyle: TextStyle(color: colorScheme.secondary, fontSize: 16),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部导航栏
            _buildTopNavBar(),

            const SizedBox(height: 8),

            // 当前标签页内容
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_currentTab),
                child:
                    _currentTab == EditTab.content || _currentTab == EditTab.title
                    ? _buildNotesContent(colorScheme)
                    : _currentTab == EditTab.tags
                    ? _buildTagsContent(colorScheme)
                    : _buildSpacesContent(colorScheme),
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
