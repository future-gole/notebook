import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/domain/entities/category_entity.dart';
import 'package:pocketmind/providers/category_providers.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/providers/nav_providers.dart';
import 'package:pocketmind/page/widget/creative_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class NoteEditorRoute extends PageRouteBuilder {
  NoteEditorRoute()
    : super(
        opaque: false, // 允许看到下面的 route
        barrierColor: Colors.transparent, // 不要额外蒙一层黑
        transitionDuration: Duration.zero, // 不用默认的 page 动画
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const NoteEditorSheet(),
      );
}

/// 笔记编辑器
class NoteEditorSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const NoteEditorSheet({super.key, this.onClose});

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet>
    with SingleTickerProviderStateMixin {
  // 控制器
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagInputController;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _bodySlideAnimation;
  late Animation<double> _bgFadeAnimation;

  // 状态
  int _selectedCategoryId = 1; // 默认分类ID
  final List<String> _tags = [];
  bool _isTagInputVisible = false;

  // 图片相关
  String? _localImagePath;
  String? _uploadedImageUrl; // 模拟上传后的URL
  bool _isImageInputVisible = false;

  // 焦点
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _tagInputController = TextEditingController();

    // 动画初始化
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 背景淡入动画
    _bgFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0,
          0.7, // 🔥 0~40% 动画时间内完成淡入
          curve: Curves.easeOut,
        ),
      ),
    );

    // 头部从右向左滑入
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 内容从下向上滑入
    _bodySlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // 启动动画
    _animationController.forward();

    // 初始化分类
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeId = ref.read(activeCategoryId).value;
      if (activeId != null) {
        setState(() {
          _selectedCategoryId = activeId;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    _tagFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- 逻辑处理方法 ---

  void _handleAddTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
        _isTagInputVisible = false;
      });
    } else if (text.isEmpty) {
      setState(() {
        _isTagInputVisible = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _localImagePath = image.path;
        _isImageInputVisible = true;
      });

      // TODO: 调用实际的上传API
    }
  }

  Future<void> _handleClose() async {
    // 反向播放动画
    await _animationController.reverse();

    if (!mounted) return;

    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      CreativeToast.error(
        context,
        title: '空笔记',
        message: '请至少输入标题或内容',
        direction: ToastDirection.top,
      );
      return;
    }

    final noteService = ref.read(noteServiceProvider);

    try {
      await noteService.addOrUpdateNote(
        title: title.isNotEmpty ? title : null,
        content: content,
        categoryId: _selectedCategoryId,
        tag: _tags.isNotEmpty ? _tags.join(',') : null,
        // 如果有上传后的URL则使用，否则如果只是本地预览则暂不保存(或根据需求保存本地路径)
        // 这里假设需要上传后才能保存，暂时留空或使用本地路径作为占位
        previewImageUrl: _uploadedImageUrl ?? _localImagePath,
      );

      if (!mounted) return;

      CreativeToast.success(
        context,
        title: '已保存',
        message: '笔记已成功保存',
        direction: ToastDirection.top,
      );
      await _handleClose();
    } catch (e) {
      if (!mounted) return;
      CreativeToast.error(
        context,
        title: '保存失败',
        message: e.toString(),
        direction: ToastDirection.top,
      );
    }
  }

  // --- UI 构建方法 ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = colorScheme.surface;

    final media = MediaQuery.of(context);
    final double headerHeight = 60.h; // 和 _buildHeader 里的高度保持一致
    final double keyboard = media.viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 用 padding 处理键盘，关掉默认的挤压行为
      resizeToAvoidBottomInset: false,
      body: AnimatedPadding(
        // 键盘出来时，整体内容往上抬，底部空出 keyboard 高度
        padding: EdgeInsets.only(bottom: keyboard),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: SafeArea(
          child: Stack(
            children: [
              // 顶部栏：固定在顶部，高度 headerHeight
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: headerHeight,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: _buildHeader(context),
                ),
              ),

              // 底部编辑区：从 headerHeight 到底（受 AnimatedPadding 影响）
              Positioned(
                left: 0,
                right: 0,
                top: headerHeight,
                bottom: 0, // 键盘出现时，这个 bottom 实际就是“键盘上沿”
                child: SlideTransition(
                  position: _bodySlideAnimation, // (0,1) -> (0,0)
                  child: Container(
                    color: bg, // 整块编辑区域有背景色，哪里滑到哪里就被覆盖
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataBar(context),
                          SizedBox(height: 24.h),
                          _buildImagePreview(context),
                          _buildMainInputs(context),
                          SizedBox(
                            height: media.viewInsets.bottom > 0 ? 300.h : 100.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. 顶部工具栏
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        color: colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 关闭按钮
          IconButton(
            onPressed: _handleClose,
            icon: Icon(Icons.close, size: 24.sp),
            color: colorScheme.onSurfaceVariant,
            tooltip: '关闭',
          ),

          // 标题
          Text(
            'NEW ENTRY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),

          // 保存按钮
          ElevatedButton.icon(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            icon: Icon(Icons.check, size: 16.sp),
            label: Text(
              'Save',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. 元数据栏 (分类、标签、工具按钮)
  Widget _buildMetadataBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outline.withValues(alpha: 0.2);
    final iconColor = colorScheme.onSurfaceVariant;

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 分类选择器
        _buildCategorySelector(context),

        // 添加标签按钮 / 输入框
        if (_isTagInputVisible)
          Container(
            width: 120.w,
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _tagInputController,
              focusNode: _tagFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '输入标签...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 12.sp, color: colorScheme.onSurface),
              onSubmitted: (_) => _handleAddTag(),
              onEditingComplete: _handleAddTag, // 失去焦点或完成时提交
            ),
          )
        else
          InkWell(
            onTap: () {
              setState(() {
                _isTagInputVisible = true;
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 14.sp,
                    color: iconColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Add Tag',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 已添加的标签展示
        ..._tags.map(
          (tag) => Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4.w),
                InkWell(
                  onTap: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                  child: Icon(
                    Icons.close,
                    size: 12.sp,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 分割线
        Container(
          width: 1,
          height: 24.h,
          color: borderColor,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
        ),

        // todo
        // // 图片上传按钮
        // IconButton(
        //   onPressed: _pickImage,
        //   icon: Icon(Icons.image_outlined, size: 20.sp),
        //   color: (_isImageInputVisible || _localImagePath != null)
        //       ? colorScheme.primary
        //       : iconColor,
        //   tooltip: '上传图片',
        //   style: IconButton.styleFrom(
        //     backgroundColor: (_isImageInputVisible || _localImagePath != null)
        //         ? colorScheme.primary.withValues(alpha: 0.1)
        //         : null,
        //   ),
        // ),
      ],
    );
  }

  // 分类选择器组件
  Widget _buildCategorySelector(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return categoriesAsync.when(
      data: (categories) {
        // 确保 selectedCategoryId 有效
        if (!categories.any((c) => c.id == _selectedCategoryId) &&
            categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }

        final selectedCategory = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => CategoryEntity(id: 0, name: 'Uncategorized'),
        );

        return PopupMenuButton<int>(
          initialValue: _selectedCategoryId,
          onSelected: (id) {
            setState(() {
              _selectedCategoryId = id;
            });
          },
          itemBuilder: (context) {
            return categories
                .map((c) => PopupMenuItem(value: c.id, child: Text(c.name)))
                .toList();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedCategory.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Text('Error'),
    );
  }

  // 3. 图片预览区域
  Widget _buildImagePreview(BuildContext context) {
    if (!_isImageInputVisible || _localImagePath == null)
      return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Stack(
        children: [
          Container(
            height: 200.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: colorScheme.outlineVariant),
              image: DecorationImage(
                image: FileImage(File(_localImagePath!)),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _localImagePath = null;
                  _isImageInputVisible = false;
                });
              },
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. 主要输入区域 (标题、内容)
  Widget _buildMainInputs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题输入
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Untitled',
            border: InputBorder.none,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          style: textTheme.bodyLarge,
          maxLines: null,
        ),

        SizedBox(height: 16.h),

        // 内容输入
        TextField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: 'Tell your story...',
            border: InputBorder.none,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontFamily: 'Merriweather',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          style: textTheme.bodyLarge?.copyWith(
            height: 1.6,
            fontFamily: 'Merriweather',
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          maxLines: null, // 自动高度
          minLines: 10, // 最小高度
        ),
      ],
    );
  }
}
