import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/image_storage_helper.dart'
    show ImageStorageHelper;
import 'package:pocketmind/util/logger_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketmind/util/url_helper.dart';

import '../../util/link_preview_cache.dart';
import '../widget/load_image_widget.dart';

const String _tag = "NoteDetailPage";

/// 笔记详情页
/// 采用垂直单列、内容优先的暗色模式设计
class NoteDetailPage extends ConsumerStatefulWidget {
  final NoteEntity note;

  const NoteDetailPage({super.key, required this.note});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _notesController;
  late final TextEditingController _newTagController;
  late final TextEditingController _addCategoryController;
  late final FocusNode _addCategoryFocusNode;

  late AnimationController _addCategoryAnimationController;
  late Animation<Offset> _categoryBarSlideAnimation;
  late Animation<Offset> _addCategoryBarSlideAnimation;

  bool _isAddCategoryMode = false;

  // 标签列表（从note.tag解析，逗号分隔）
  List<String> _tags = [];

  // AppConfig
  final _config = AppConfig();
  bool _titleEnabled = false;

  // 当前选中的分类ID
  late int _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _contentController = TextEditingController(text: widget.note.content ?? '');
    _titleController = TextEditingController(text: widget.note.title ?? '');
    _notesController = TextEditingController();
    _newTagController = TextEditingController();
    _addCategoryController = TextEditingController();
    _addCategoryFocusNode = FocusNode();


    _selectedCategoryId = widget.note.categoryId;

    // 初始化标签列表
    if (widget.note.tag != null && widget.note.tag!.isNotEmpty) {
      _tags = widget.note.tag!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // 加载标题设置
    _loadTitleSetting();

    // 初始化动画控制器
    _addCategoryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _categoryBarSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
          CurvedAnimation(
            parent: _addCategoryAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _addCategoryBarSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _addCategoryAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    if (mounted) {
      setState(() {
        _titleEnabled = _config.titleEnabled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    _newTagController.dispose();
    _addCategoryController.dispose();
    _addCategoryFocusNode.dispose();
    _addCategoryAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(colorScheme),

            // 可滚动内容区域
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80), // 留出底部操作栏空间
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 原始数据区（可编辑）
                    _buildOriginalDataSection(colorScheme, textTheme),

                    const SizedBox(height: 24),

                    // 2. AI 洞察区
                    _buildAIInsightSection(colorScheme, textTheme),

                    const SizedBox(height: 32),

                    // 3. 元数据/标签区
                    _buildTagsSection(colorScheme, textTheme),

                    const SizedBox(height: 32),

                    // // 4. 用户注解区 mymind有，但是感觉暂且没用
                    // _buildUserNotesSection(colorScheme, textTheme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 固定操作栏
            _buildActionBar(colorScheme),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: colorScheme.primary,
          ),

          // 标题（如果启用且有标题）
          if (_titleEnabled &&
              widget.note.title != null &&
              widget.note.title!.isNotEmpty)
            Expanded(
              child: Center(
                child: TextField(
                  controller: _titleController,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                  onChanged: (_) => _saveNote(), // 自动保存
                ),
                // child: Text(
                //   widget.note.title!,
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.w600,
                //     color: colorScheme.primary,
                //   ),
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ),
            )
          else
            const Spacer(),

          // 占位（保持对称）
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// 1. 原始数据区（可编辑）
  Widget _buildOriginalDataSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isLocalImage = UrlHelper.isLocalImagePath(widget.note.url);
    final isHttpsUrl = UrlHelper.containsHttpsUrl(widget.note.url);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 本地图片显示（如果是本地图片）
          if (isLocalImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LocalImageWidget(relativePath: widget.note.url!),
            ),
            const SizedBox(height: 16),
          ],

          // 内容编辑框
          TextField(
            controller: _contentController,
            maxLines: null,
            decoration: InputDecoration(
              hintText: '记录你的想法...',
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
            ),
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.6,
              color: colorScheme.onSurface,
            ),
            onChanged: (_) => _saveNote(), // 自动保存
          ),

          // URL链接（如果有且不是本地图片）
          if (widget.note.url != null &&
              widget.note.url!.isNotEmpty &&
              !isLocalImage) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: isHttpsUrl
                          ? () => _launchUrl(widget.note.url!)
                          : null,
                      child: Text(
                        widget.note.url!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.surfaceContainerHighest,
                          decoration: isHttpsUrl
                              ? TextDecoration.underline
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. AI 洞察区
  Widget _buildAIInsightSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 洞察',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TODO: AI 内容占位符
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-generated summary will appear here...',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Row(
                //   children: [
                //     Icon(
                //       Icons.info_outline,
                //       size: 14,
                //       color: colorScheme.secondary,
                //     ),
                //     const SizedBox(width: 6),
                //     Expanded(
                //       child: Text(
                //         'TODO: 接入后端 AI 服务',
                //         style: textTheme.bodySmall?.copyWith(
                //           color: colorScheme.secondary,
                //           fontSize: 11,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 元数据/标签区
  Widget _buildTagsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(
                '思维标签',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              // 添加标签按钮
              TextButton.icon(
                onPressed: _showAddTagDialog,
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: colorScheme.surfaceContainerHighest,
                ),
                label: Text(
                  '添加标签',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 标签列表
          if (_tags.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '还没有标签。点击"添加标签"创建一个。',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => _buildTagChip(tag, colorScheme))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// 标签芯片
  Widget _buildTagChip(String tag, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(Icons.close, size: 14, color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  /// 4. 用户注解区
  Widget _buildUserNotesSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '思维笔记',
            style: textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 12),

          // 多行输入框
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Type here to add a note...',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 固定操作栏
  Widget _buildActionBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Category 按钮
          _buildActionButton(
            icon: Icons.circle_outlined,
            label: '分类',
            onPressed: _onCategoryPressed,
            colorScheme: colorScheme,
          ),

          // Share 按钮
          _buildActionButton(
            icon: Icons.share_outlined,
            label: '分享',
            onPressed: _onSharePressed,
            colorScheme: colorScheme,
          ),

          // Delete 按钮
          _buildActionButton(
            icon: Icons.delete_outline,
            label: '删除',
            onPressed: _onDeletePressed,
            colorScheme: colorScheme,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存笔记
  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    final title = _titleController.text.trim();
    final tagsString = _tags.join(',');

    final noteService = ref.read(noteServiceProvider);
    await noteService.addOrUpdateNote(
      id: widget.note.id,
      title: title,
      content: content,
      url: widget.note.url,
      categoryId: _selectedCategoryId,
      tag: tagsString,
    );

    log.d(_tag, "Note saved");
  }

  /// 显示添加标签对话框
  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('添加标签', style: TextStyle(color: colorScheme.primary)),
          content: TextField(
            controller: _newTagController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '输入标签名称',
              hintStyle: TextStyle(color: colorScheme.secondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            style: TextStyle(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newTagController.clear();
                Navigator.of(context).pop();
              },
              child: Text('取消', style: TextStyle(color: colorScheme.secondary)),
            ),
            TextButton(
              onPressed: () {
                _addTag(_newTagController.text.trim());
                _newTagController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                '添加',
                style: TextStyle(color: colorScheme.surfaceContainerHighest),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 添加标签
  void _addTag(String tag) {
    if (tag.isEmpty) return;
    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标签已存在')));
      return;
    }

    setState(() {
      _tags.add(tag);
    });

    _saveNote();
  }

  /// 移除标签
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });

    _saveNote();
  }

  /// Category 按钮 - 显示分类选择对话框
  void _onCategoryPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategorySelector(),
    );
  }

  /// 构建分类选择器
  Widget _buildCategorySelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            ClipRect(
              child: Stack(
                children: [
                  // 普通标题栏
                  SlideTransition(
                    position: _categoryBarSlideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            '选择分类',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _toggleAddCategoryMode,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 添加分类输入栏
                  SlideTransition(
                    position: _addCategoryBarSlideAnimation,
                    child: _buildAddCategoryBar(colorScheme),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 分类列表
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == _selectedCategoryId;

                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: isSelected
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.secondary,
                          size: 12,
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: colorScheme.surfaceContainerHighest,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                          _saveNote();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('加载失败: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建添加分类输入栏
  Widget _buildAddCategoryBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addCategoryController,
              focusNode: _addCategoryFocusNode,
              decoration: InputDecoration(
                hintText: '输入新分类名称',
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                hintStyle: TextStyle(color: colorScheme.secondary),
              ),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.surfaceContainerHighest),
            onPressed: () async {
              final categoryName = _addCategoryController.text.trim();
              if (categoryName.isNotEmpty) {
                await _addNewCategory(categoryName);
                _toggleAddCategoryMode();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.secondary),
            onPressed: _toggleAddCategoryMode,
          ),
        ],
      ),
    );
  }

  /// 切换添加分类模式
  void _toggleAddCategoryMode() {
    setState(() {
      _isAddCategoryMode = !_isAddCategoryMode;
      if (_isAddCategoryMode) {
        _addCategoryAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          _addCategoryFocusNode.requestFocus();
        });
      } else {
        _addCategoryAnimationController.reverse();
        _addCategoryController.clear();
        _addCategoryFocusNode.unfocus();
      }
    });
  }

  /// 添加新分类
  Future<void> _addNewCategory(String name) async {
    final categoryService = ref.read(categoryServiceProvider);
    await categoryService.addCategory(name: name);

    // 获取最新的分类列表
    ref.invalidate(allCategoriesProvider);
    final categories = await ref.read(allCategoriesProvider.future);
    if (categories.isNotEmpty) {
      // 选中最新添加的分类
      final newCategory = categories.last;
      setState(() {
        _selectedCategoryId = newCategory.id;
      });
      await _saveNote();
    }
  }

  /// Share 按钮
  void _onSharePressed() {
    // TODO: 实现分享功能
    log.d(_tag, "Share pressed");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享功能即将上线')));
  }

  /// Delete 按钮
  void _onDeletePressed() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('删除笔记', style: TextStyle(color: colorScheme.primary)),
          content: Text(
            '确定要删除这条笔记吗？此操作无法撤销。',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消', style: TextStyle(color: colorScheme.secondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNote();
              },
              child: Text('删除', style: TextStyle(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  /// 删除笔记
  Future<void> _deleteNote() async {
    final noteId = widget.note.id;
    if (noteId == null) return;

    if (widget.note.url != null) {
      // 删除对应的链接缓存
      await LinkPreviewCache.clearCache(widget.note.url!);
    }
    // 删除图片，如果有的话
    final imagePaths = widget.note.url;
    if (imagePaths != null && imagePaths.isNotEmpty) {
      await ImageStorageHelper().deleteImage(imagePaths);
    }

    final noteService = ref.read(noteServiceProvider);
    await noteService.deleteNote(noteId);

    if (mounted) {
      Navigator.of(context).pop(); // 返回上一页
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('笔记已删除')));
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      log.e(tag, '❌ URL 跳转失败: $e');
    }
  }
}
