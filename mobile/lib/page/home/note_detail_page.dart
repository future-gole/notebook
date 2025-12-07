import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/util/image_storage_helper.dart'
    show ImageStorageHelper;
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/responsive_breakpoints.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../widget/creative_toast.dart';
import '../widget/hero_gallery.dart';

const String _tag = "NoteDetailPage";

/// 中文日期格式化
String _formatDateChinese(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays == 0) {
    return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } else if (diff.inDays == 1) {
    return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}天前';
  } else {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 笔记详情页
/// 桌面端：左右分栏布局
/// 移动端：垂直滚动布局
class NoteDetailPage extends ConsumerStatefulWidget {
  final NoteEntity note;

  /// 桌面端返回回调 - 用于清除选中状态
  final VoidCallback? onBack;

  const NoteDetailPage({super.key, required this.note, this.onBack});

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

  // 链接预览数据（优先从 note 读取，没有则请求网络）
  String? _previewImageUrl;
  String? _previewTitle;
  String? _previewDescription;
  bool _isLoadingPreview = false;

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

    // 初始化预览数据（优先从数据库读取）
    _previewImageUrl = widget.note.previewImageUrl;
    _previewTitle = widget.note.previewTitle;
    _previewDescription = widget.note.previewDescription;

    // 加载标题设置
    _loadTitleSetting();

    // 如果没有缓存的预览数据，才请求网络
    if (_previewImageUrl == null && _previewTitle == null) {
      _loadLinkPreview();
    }

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

  /// 加载链接预览数据并保存到数据库
  Future<void> _loadLinkPreview() async {
    final url = widget.note.url;
    final noteId = widget.note.id;

    // 只有网络链接才需要加载预览
    if (url == null ||
        noteId == null ||
        !UrlHelper.containsHttpsUrl(url) ||
        UrlHelper.isLocalImagePath(url)) {
      return;
    }

    setState(() => _isLoadingPreview = true);

    try {
      // 使用 AnyLinkPreview 获取元数据（复用现有逻辑）
      final metadata = await AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(hours: 24),
      );

      if (mounted && metadata != null) {
        setState(() {
          _previewImageUrl = metadata.image;
          _previewTitle = metadata.title;
          _previewDescription = metadata.desc;
          _isLoadingPreview = false;
        });

        // 保存到数据库，下次不再请求
        final noteService = ref.read(noteServiceProvider);
        await noteService.updatePreviewData(
          noteId: noteId,
          previewImageUrl: metadata.image,
          previewTitle: metadata.title,
          previewDescription: metadata.desc,
        );
      }
    } catch (e) {
      PMlog.e(_tag, '预览加载失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = ResponsiveBreakpoints.shouldShowNoteDetailSidebar(
      screenWidth,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(colorScheme),

            // 主内容区域
            Expanded(
              child: showSidebar
                  ? _buildDesktopLayout(colorScheme, textTheme)
                  : _buildMobileLayout(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  /// 桌面端布局 - 左右分栏
  Widget _buildDesktopLayout(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧内容区 (占 2/3)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 80.h),
            child: _buildMainContent(colorScheme, textTheme),
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
            padding: EdgeInsets.all(24),
            child: _buildSidebarContent(colorScheme, textTheme),
          ),
        ),
      ],
    );
  }

  /// 移动端布局 - 垂直滚动
  Widget _buildMobileLayout(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 原始数据区
          _buildOriginalDataSection(colorScheme, textTheme),

          SizedBox(height: 24.h),

          // 2. AI 洞察区
          _buildAIInsightSection(colorScheme, textTheme),

          SizedBox(height: 32.h),

          // 3. 元数据/标签区
          _buildTagsSection(colorScheme, textTheme),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  /// 桌面端左侧主内容
  Widget _buildMainContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 原始数据区
        _buildOriginalDataSection(colorScheme, textTheme),

        SizedBox(height: 32.h),
      ],
    );
  }

  /// 桌面端右侧边栏内容
  Widget _buildSidebarContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 洞察区
        _buildAIInsightSection(colorScheme, textTheme),

        SizedBox(height: 32.h),

        // 来源信息
        _buildSourceSection(colorScheme, textTheme),

        SizedBox(height: 24.h),

        // 标签区
        _buildTagsSection(colorScheme, textTheme),

        SizedBox(height: 24.h),

        // 最后编辑时间
        _buildLastEditedInfo(colorScheme),
      ],
    );
  }

  /// 来源信息区
  Widget _buildSourceSection(ColorScheme colorScheme, TextTheme textTheme) {
    final isHttpsUrl = UrlHelper.containsHttpsUrl(widget.note.url);
    if (!isHttpsUrl) return const SizedBox.shrink();

    final domain = UrlHelper.extractDomain(widget.note.url ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOURCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            final url = widget.note.url;
            if (url != null && url.isNotEmpty) {
              _launchUrl(url);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    domain,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 最后编辑时间信息
  Widget _buildLastEditedInfo(ColorScheme colorScheme) {
    final formattedDate = _formatDateChinese(widget.note.time);

    return Text(
      'Last edited on $formattedDate',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: colorScheme.secondary.withValues(alpha: 0.7),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar(ColorScheme colorScheme) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮 - 带文字提示
          _buildNavButton(
            icon: Icons.arrow_back_rounded,
            label: '返回',
            onPressed: () {
              // 如果有 onBack 回调（桌面端），调用它；否则使用 Navigator.pop
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
            colorScheme: colorScheme,
          ),

          const Spacer(),

          // 右侧操作按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavButton(
                icon: Icons.share_outlined,
                label: '分享',
                onPressed: _onSharePressed,
                colorScheme: colorScheme,
              ),
              _buildNavButton(
                icon: Icons.edit_outlined,
                label: '编辑',
                onPressed: () {}, // TODO: 编辑模式切换
                colorScheme: colorScheme,
              ),
              Container(
                width: 1,
                height: 20.h,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
              _buildNavButton(
                icon: Icons.delete_outline,
                label: '删除',
                onPressed: _onDeletePressed,
                colorScheme: colorScheme,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 导航栏按钮
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? colorScheme.error.withOpacity(0.8)
        : colorScheme.secondary;
    final hoverColor = isDestructive
        ? colorScheme.error.withOpacity(0.1)
        : colorScheme.surfaceContainerHighest.withOpacity(0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        hoverColor: hoverColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. 主内容区域 - 杂志式排版
  Widget _buildOriginalDataSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isLocalImage = UrlHelper.isLocalImagePath(widget.note.url);
    final isHttpsUrl = UrlHelper.containsHttpsUrl(widget.note.url);
    final hasTitle =
        _titleEnabled &&
        widget.note.title != null &&
        widget.note.title!.isNotEmpty;
    final formattedDate = _formatDateChinese(widget.note.time);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.shouldShowNoteDetailSidebar(
      screenWidth,
    );

    // 收集可显示的图片
    List<String> displayImages = [];
    bool isNetworkImage = false;

    if (isLocalImage && widget.note.url != null) {
      final fullPath = ImageStorageHelper()
          .getFileByRelativePath(widget.note.url!)
          .path;
      displayImages.add(fullPath);
    }

    // 如果是网络链接且预览图已加载，使用预览图
    if (isHttpsUrl && !isLocalImage) {
      isNetworkImage = true;
      if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) {
        displayImages.add(_previewImageUrl!);
      }
    }

    final hasImages = displayImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片/画廊区域
        if (hasImages) ...[
          HeroGallery(
            images: displayImages,
            title: hasTitle ? widget.note.title! : "",
            isDesktop: isDesktop,
            showGradientFade: true,
            categoryLabel: _getCategoryName(),
            dateLabel: formattedDate,
            overlayTitle: _previewTitle ?? "",
          ),
        ] else if (isNetworkImage && _isLoadingPreview) ...[
          // 加载中显示占位
          Container(
            height: isDesktop ? 0.35.sh : 0.25.sh,
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],

        // 内容容器
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 无图时显示分类和日期
              if (!hasImages && !_isLoadingPreview) ...[
                SizedBox(height: 24.h),
                // 分类标签和日期
                Row(
                  children: [
                    // 分类胶囊 - 可点击切换分类
                    GestureDetector(
                      onTap: _onCategoryPressed,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getCategoryName(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 14.sp,
                              color: colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 日期
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12.sp,
                          color: colorScheme.secondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // 标题
                if (hasTitle) ...[
                  TextField(
                    controller: _titleController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                    onChanged: (_) => _saveNote(),
                  ),
                  SizedBox(height: 16.h),
                  // 装饰线
                  Container(
                    width: 60.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ],

              // 网络链接时显示链接标题和正文
              if (isHttpsUrl) ...[
                _buildLinkContentSection(colorScheme, textTheme),
              ],

              // 用户笔记区（个人笔记）
              if (!isHttpsUrl) ...[
                // 非链接类型时，content 就是用户内容
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: '记录你的想法...',
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 16.sp,
                    height: 1.8,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurface,
                  ),
                  onChanged: (_) => _saveNote(),
                ),
              ],

              SizedBox(height: 24.h),

              // 来源链接卡片
              if (isHttpsUrl && !isDesktop && widget.note.url != null) ...[
                _buildSourceLinkCard(colorScheme, isHttpsUrl),
                SizedBox(height: 16.h),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 链接内容区域
  Widget _buildLinkContentSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final linkDescription = _previewDescription;
    final hasDescription =
        linkDescription != null && linkDescription.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 链接正文/描述
        if (hasDescription) ...[
          Text(
            linkDescription,
            style: textTheme.bodyMedium,
          ),
          SizedBox(height: 24.h),
          // 分隔线
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 16.sp,
                color: colorScheme.tertiary,
              ),
              SizedBox(width: 8.w),
              Text(
                '个人笔记',
                style: textTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.5,
                  color: colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],

        // 用户笔记编辑框
        TextField(
          controller: _contentController,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '添加你的想法和注释...',
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.secondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            height: 1.8,
            letterSpacing: 0.2,
          ),
          onChanged: (_) => _saveNote(),
        ),
      ],
    );
  }

  /// 获取分类名称
  String _getCategoryName() {
    final categories = ref.read(allCategoriesProvider).valueOrNull;
    if (categories != null) {
      final category = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => categories.first,
      );
      return category.name.toUpperCase();
    }
    return 'HOME';
  }

  /// URL 来源卡片
  Widget _buildSourceLinkCard(ColorScheme colorScheme, bool isHttpsUrl) {
    final url = widget.note.url!;
    final domain = Uri.tryParse(url)?.host ?? url;

    return GestureDetector(
      onTap: isHttpsUrl ? () => _launchUrl(url) : null,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.language_rounded,
                size: 20.sp,
                color: colorScheme.secondary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '来源',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: colorScheme.secondary.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          domain,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHttpsUrl) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 14.sp,
                          color: colorScheme.secondary.withOpacity(0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. AI 洞察区
  Widget _buildAIInsightSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        children: [
          // 渐变背景光晕
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.tertiary.withOpacity(0.15),
                    Colors.orange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // 主卡片
          Container(
            margin: EdgeInsets.all(1),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16.sp,
                      color: colorScheme.tertiary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'AI 洞察',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // 占位内容
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Column(
                    children: [
                      Text(
                        '让 AI 为你提炼核心洞察',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: colorScheme.secondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      // 生成按钮
                      ElevatedButton(
                        onPressed: () {
                          CreativeToast.info(
                            context,
                            title: '即将上线',
                            message: 'AI 洞察功能正在开发中',
                            direction: ToastDirection.top,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.onSurface,
                          foregroundColor: colorScheme.surface,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '生成洞察',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(
                '标签',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.secondary,
                ),
              ),
              const Spacer(),
              // 添加标签按钮
              TextButton.icon(
                onPressed: _showAddTagDialog,
                icon: Icon(
                  Icons.add_rounded,
                  size: 16.sp,
                  color: colorScheme.tertiary,
                ),
                label: Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.tertiary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 标签列表
          if (_tags.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  '点击添加标签',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.secondary.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close_rounded,
              size: 12.sp,
              color: colorScheme.secondary,
            ),
          ),
        ],
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

    PMlog.d(_tag, "Note saved");
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
      CreativeToast.warning(
        context,
        title: '标签已存在',
        message: '该标签已经添加过了',
        direction: ToastDirection.top,
      );
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
      constraints: BoxConstraints(maxHeight: 0.6.sh),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                      padding: EdgeInsets.all(20.r),
                      child: Row(
                        children: [
                          Text(
                            '选择分类',
                            style: TextStyle(
                              fontSize: 18.sp,
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
                    padding: EdgeInsets.symmetric(vertical: 8.h),
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
                          size: 12.sp,
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
      padding: EdgeInsets.all(20.r),
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
          SizedBox(width: 8.w),
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
    PMlog.d(_tag, "Share pressed");
    CreativeToast.info(
      context,
      title: '即将上线',
      message: '分享功能正在开发中',
      direction: ToastDirection.top,
    );
  }

  /// Delete 按钮
  void _onDeletePressed() async {
    bool? confirm = await showConfirmDialog(
      context,
      title: "删除笔记",
      message: "确定要删除这条笔记吗？此操作无法撤销",
      cancelText: "取消",
      confirmText: "确认",
    );
    if (confirm == true) {
      _deleteNote();
    }
  }

  /// 删除笔记
  Future<void> _deleteNote() async {
    final noteId = widget.note.id;
    if (noteId == null) return;

    // 删除图片，如果有的话
    final imagePaths = widget.note.url;
    if (imagePaths != null && imagePaths.isNotEmpty) {
      await ImageStorageHelper().deleteImage(imagePaths);
    }

    final noteService = ref.read(noteServiceProvider);
    await noteService.deleteNote(noteId);

    if (mounted) {
      Navigator.of(context).pop(); // 返回上一页
      CreativeToast.success(
        context,
        title: '笔记已删除',
        message: '该笔记已被永久删除',
        direction: ToastDirection.top,
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      PMlog.e(_tag, '❌ URL 跳转失败: $e');
      CreativeToast.error(context, title: "出错咯~", message: "URL 跳转失败", direction: ToastDirection.top);
    }
  }
}
