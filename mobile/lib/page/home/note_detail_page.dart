import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketmind/model/note.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/providers/app_config_provider.dart';
import 'package:pocketmind/providers/note_detail_provider.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/responsive_breakpoints.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widget/creative_toast.dart';
import '../widget/note_detail/note_detail_top_bar.dart';
import '../widget/note_detail/note_detail_sidebar.dart';
import '../widget/note_detail/note_tags_section.dart';
import '../widget/note_detail/note_ai_insight_section.dart';
import '../widget/note_detail/note_original_data_section.dart';
import '../widget/note_detail/note_category_selector.dart';
import '../../util/date_formatter.dart';

/// 笔记详情页
/// 桌面端：左右分栏布局
/// 移动端：垂直滚动布局
class NoteDetailPage extends ConsumerStatefulWidget {
  final Note? note;
  final int? noteId;

  /// 桌面端返回回调 - 用于清除选中状态
  final VoidCallback? onBack;

  const NoteDetailPage({super.key, this.note, this.noteId, this.onBack})
    : assert(
        note != null || noteId != null,
        'Either note or noteId must be provided',
      );

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  late final ScrollController _scrollController;
  TextEditingController? _titleController;
  TextEditingController? _contentController;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    if (widget.note != null) {
      _currentNote = widget.note;
      _initControllers(_currentNote!);
    }
  }

  void _initControllers(Note note) {
    _contentController = TextEditingController(text: note.content ?? '');
    _titleController = TextEditingController(text: note.title ?? '');

    // 监听输入变化并更新 Notifier (带防抖)
    _titleController!.addListener(() {
      ref
          .read(noteDetailProvider(note).notifier)
          .updateNote(title: _titleController!.text);
    });
    _contentController!.addListener(() {
      ref
          .read(noteDetailProvider(note).notifier)
          .updateNote(content: _contentController!.text);
    });

    // 初始化预览数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noteDetailProvider(note).notifier).loadLinkPreview();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contentController?.dispose();
    _titleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = ResponsiveBreakpoints.shouldShowNoteDetailSidebar(
      screenWidth,
    );

    // 确定当前显示的笔记
    Note? displayNote = _currentNote ?? widget.note;

    // 如果当前没有笔记且有 ID，则从 Provider 获取
    if (displayNote == null && widget.noteId != null) {
      final noteAsync = ref.watch(noteByIdProvider(id: widget.noteId!));
      displayNote = noteAsync.value;

      // 只有在真正加载中且没有数据时才显示加载器
      if (noteAsync.isLoading && displayNote == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (noteAsync.hasError && displayNote == null) {
        return Scaffold(body: Center(child: Text('加载失败: ${noteAsync.error}')));
      }

      if (!noteAsync.isLoading && displayNote == null) {
        return const Scaffold(body: Center(child: Text('笔记不存在')));
      }
    }

    // 如果获取到了笔记但尚未初始化控制器，则进行初始化
    if (displayNote != null && _currentNote == null) {
      // 立即赋值，避免下次 build 再次进入此逻辑
      _currentNote = displayNote;
      _initControllers(displayNote);
    }

    if (_currentNote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 监听详情状态
    final detailState = ref.watch(noteDetailProvider(_currentNote!));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏 - 已抽离为独立组件
            NoteDetailTopBar(
              onBack: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              onShare: _onSharePressed,
              onEdit: () {}, // TODO: 编辑模式切换
              onDelete: _onDeletePressed,
            ),

            // 主内容区域
            Expanded(
              child: showSidebar
                  ? _buildDesktopLayout(detailState, colorScheme, textTheme)
                  : _buildMobileLayout(detailState, colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  /// 桌面端布局 - 左右分栏
  Widget _buildDesktopLayout(
    NoteDetailState state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧内容区 (占 2/3)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 80.h),
            child: NoteOriginalDataSection(
              note: state.note,
              titleController: _titleController!,
              contentController: _contentController!,
              onCategoryPressed: _onCategoryPressed,
              categoryName: _getCategoryName(state.note.categoryId),
              formattedDate: DateFormatter.formatChinese(state.note.time),
              previewImageUrl: state.note.previewImageUrl,
              previewTitle: state.note.previewTitle,
              previewDescription: state.note.previewDescription,
              isLoadingPreview: state.isLoadingPreview,
              onSave: () => ref
                  .read(noteDetailProvider(_currentNote!).notifier)
                  .saveNote(),
              onLaunchUrl: _launchUrl,
              isDesktop: true,
              titleEnabled: ref.watch(appConfigProvider).titleEnabled,
            ),
          ),
        ),

        // 右侧元信息区 (固定宽度约 360)
        Container(
          width: 360,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: NoteDetailSidebar(
              note: state.note,
              onLaunchUrl: _launchUrl,
              tags: state.tags,
              onAddTag: _showAddTagDialog,
              onRemoveTag: (tag) => ref
                  .read(noteDetailProvider(_currentNote!).notifier)
                  .removeTag(tag),
              formattedDate: DateFormatter.formatChinese(state.note.time),
            ),
          ),
        ),
      ],
    );
  }

  /// 移动端布局 - 垂直滚动
  Widget _buildMobileLayout(
    NoteDetailState state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 原始数据区
          NoteOriginalDataSection(
            note: state.note,
            titleController: _titleController!,
            contentController: _contentController!,
            onCategoryPressed: _onCategoryPressed,
            categoryName: _getCategoryName(state.note.categoryId),
            formattedDate: DateFormatter.formatChinese(state.note.time),
            previewImageUrl: state.note.previewImageUrl,
            previewTitle: state.note.previewTitle,
            previewDescription: state.note.previewDescription,
            isLoadingPreview: state.isLoadingPreview,
            onSave: () =>
                ref.read(noteDetailProvider(_currentNote!).notifier).saveNote(),
            onLaunchUrl: _launchUrl,
            isDesktop: false,
            titleEnabled: ref.watch(appConfigProvider).titleEnabled,
          ),

          SizedBox(height: 24.h),

          // 2. AI 洞察区
          const NoteAIInsightSection(),

          SizedBox(height: 32.h),

          // 3. 元数据/标签区
          NoteTagsSection(
            tags: state.tags,
            onAddTag: _showAddTagDialog,
            onRemoveTag: (tag) => ref
                .read(noteDetailProvider(_currentNote!).notifier)
                .removeTag(tag),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  /// 分享笔记
  void _onSharePressed() {
    ref.read(noteDetailProvider(_currentNote!).notifier).shareNote(context);
  }

  /// 删除笔记
  void _onDeletePressed() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除笔记',
      message: '确定要删除这条笔记吗？此操作无法撤销',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (confirmed == true) {
      await ref.read(noteDetailProvider(_currentNote!).notifier).deleteNote();
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
        CreativeToast.success(
          context,
          title: '笔记已删除',
          message: '该笔记已被永久删除',
          direction: ToastDirection.top,
        );
      }
    }
  }

  /// 获取分类名称
  String _getCategoryName(int categoryId) {
    final categoriesAsync = ref.read(allCategoriesProvider);
    if (!categoriesAsync.hasValue) return 'HOME';
    final categories = categoriesAsync.value;
    if (categories != null) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => categories.first,
      );
      return category.name.toUpperCase();
    }
    return 'HOME';
  }

  /// 显示分类选择器
  void _onCategoryPressed(int currentCategoryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteCategorySelector(
        currentCategoryId: currentCategoryId,
        onCategorySelected: (id) {
          ref
              .read(noteDetailProvider(_currentNote!).notifier)
              .updateCategory(id);
        },
        onAddCategory: (name) async {
          final categoryId = await ref
              .read(categoryServiceProvider)
              .addCategory(name: name);
          ref
              .read(noteDetailProvider(_currentNote!).notifier)
              .updateCategory(categoryId);
          ref.invalidate(allCategoriesProvider);
        },
      ),
    );
  }

  /// 显示添加标签对话框
  void _showAddTagDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('添加标签', style: TextStyle(color: colorScheme.primary)),
          content: TextField(
            controller: textController,
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消', style: TextStyle(color: colorScheme.secondary)),
            ),
            TextButton(
              onPressed: () {
                final tag = textController.text.trim();
                if (tag.isNotEmpty) {
                  ref
                      .read(noteDetailProvider(_currentNote!).notifier)
                      .addTag(tag);
                }
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

  /// 跳转 URL
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
