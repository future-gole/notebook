import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/util/link_preview_config.dart';
import 'package:pocketmind/api/link_preview_api_service.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/util/theme_data.dart';

import '../../util/logger_service.dart';
import 'source_info.dart';

/// 智能链接预览卡片组件
/// - 优先使用 Note 中的预览数据
/// - 如果没有，请求网络并保存到 Note
final String tag = "LinkPreviewCard";

class LinkPreviewCard extends StatefulWidget {
  final NoteEntity note;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const LinkPreviewCard({
    Key? key,
    required this.note,
    this.isVertical = false,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  String get url => note.url ?? '';

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  @override
  Widget build(BuildContext context) {
    // 智能选择：国外网站用API，国内网站用any_link_preview
    final useApi = LinkPreviewConfig.shouldUseApiService(widget.url);

    // 优先使用 Note 中已缓存的预览数据
    final hasCache =
        widget.note.previewImageUrl != null || widget.note.previewTitle != null;

    if (hasCache) {
      // 已有缓存，直接显示
      return _CachedLinkPreview(
        note: widget.note,
        isVertical: widget.isVertical,
        hasContent: widget.hasContent,
        onTap: widget.onTap,
        isDesktop: widget.isDesktop,
        publishDate: widget.publishDate,
        isHovered: widget.isHovered,
      );
    } else if (useApi) {
      // 国外网站：使用 API 方案
      return _ApiLinkPreview(
        note: widget.note,
        isVertical: widget.isVertical,
        hasContent: widget.hasContent,
        onTap: widget.onTap,
        isDesktop: widget.isDesktop,
        publishDate: widget.publishDate,
        isHovered: widget.isHovered,
      );
    } else {
      // 国内网站：直接使用 any_link_preview
      return _NativeLinkPreview(
        note: widget.note,
        isVertical: widget.isVertical,
        hasContent: widget.hasContent,
        onTap: widget.onTap,
        isDesktop: widget.isDesktop,
        publishDate: widget.publishDate,
        isHovered: widget.isHovered,
      );
    }
  }
}

// 已缓存的预览组件（从 Note 读取）
class _CachedLinkPreview extends StatelessWidget {
  final NoteEntity note;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const _CachedLinkPreview({
    Key? key,
    required this.note,
    required this.isVertical,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metadata = Metadata();
    metadata.title = note.previewTitle ?? 'No Title';
    metadata.desc = note.previewDescription ?? '';
    metadata.image = note.previewImageUrl;
    metadata.url = note.url;

    final imageUrl = note.previewImageUrl;

    return isVertical
        ? _VerticalPreviewCard(
            url: note.url ?? '',
            metadata: metadata,
            imageProvider: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            hasContent: hasContent,
            onTap: onTap,
            isDesktop: isDesktop,
            publishDate: publishDate,
            isHovered: isHovered,
          )
        : _HorizontalPreviewCard(
            url: note.url ?? '',
            metadata: metadata,
            imageProvider: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            onTap: onTap,
            publishDate: publishDate,
          );
  }
}

// 国内网站预览组件（使用 any_link_preview）
class _NativeLinkPreview extends ConsumerStatefulWidget {
  final NoteEntity note;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const _NativeLinkPreview({
    Key? key,
    required this.note,
    required this.isVertical,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  @override
  ConsumerState<_NativeLinkPreview> createState() => _NativeLinkPreviewState();
}

class _NativeLinkPreviewState extends ConsumerState<_NativeLinkPreview> {
  @override
  Widget build(BuildContext context) {
    return AnyLinkPreview.builder(
      link: widget.note.url ?? '',
      itemBuilder: (context, metadata, imageProvider, svgPicture) {
        // 获取到预览数据后保存到 Note
        _savePreviewToNote(metadata);

        return widget.isVertical
            ? _VerticalPreviewCard(
                url: widget.note.url ?? '',
                metadata: metadata,
                imageProvider: imageProvider,
                hasContent: widget.hasContent,
                onTap: widget.onTap,
                isDesktop: widget.isDesktop,
                publishDate: widget.publishDate,
                isHovered: widget.isHovered,
              )
            : _HorizontalPreviewCard(
                url: widget.note.url ?? '',
                metadata: metadata,
                imageProvider: imageProvider,
                onTap: widget.onTap,
                publishDate: widget.publishDate,
              );
      },
      placeholderWidget: widget.isVertical
          ? _VerticalSkeletonCard(hasContent: widget.hasContent)
          : const _HorizontalSkeletonCard(),
      errorWidget: widget.isVertical
          ? _VerticalErrorCard(
              url: widget.note.url ?? '',
              hasContent: widget.hasContent,
            )
          : _HorizontalErrorCard(url: widget.note.url ?? ''),
      cache: const Duration(hours: 24),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );
  }

  /// 保存预览数据到 Note（Isar 数据库）
  void _savePreviewToNote(Metadata metadata) {
    final noteId = widget.note.id;
    if (noteId == null) return;

    // 只保存一次
    if (widget.note.previewImageUrl != null ||
        widget.note.previewTitle != null) {
      return;
    }

    // 异步保存，不阻塞 UI
    Future.microtask(() async {
      try {
        final noteService = ref.read(noteServiceProvider);
        await noteService.updatePreviewData(
          noteId: noteId,
          previewImageUrl: metadata.image,
          previewTitle: metadata.title,
          previewDescription: metadata.desc,
        );
        PMlog.d(tag, '预览数据已保存到 Note: ${metadata.title}');
      } catch (e) {
        PMlog.e(tag, '保存预览数据失败: $e');
      }
    });
  }
}

// =============================================================================
// API 预览组件（用于国外网站）
// =============================================================================

class _ApiLinkPreview extends ConsumerStatefulWidget {
  final NoteEntity note;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const _ApiLinkPreview({
    Key? key,
    required this.note,
    required this.isVertical,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  @override
  ConsumerState<_ApiLinkPreview> createState() => _ApiLinkPreviewState();
}

class _ApiLinkPreviewState extends ConsumerState<_ApiLinkPreview> {
  Map<String, dynamic>? _metadata;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    final url = widget.note.url;
    if (url == null || url.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      // 从 API 获取
      final apiMetadata = await ref
          .read(linkPreviewServiceProvider)
          .fetchMetadata(url);

      Map<String, dynamic> metadata;
      if (apiMetadata.success) {
        metadata = {
          'title': apiMetadata.title ?? 'No title',
          'description': apiMetadata.description ?? 'No description available',
          'imageUrl': apiMetadata.imageUrl,
          'url': apiMetadata.url,
        };

        // 保存到 Note（Isar 数据库）
        _savePreviewToNote(metadata);
      } else {
        metadata = {
          'title': "预览错误",
          'description': "请检查网络或者api是否正确",
          'imageUrl': "",
          'url': url,
        };
      }

      if (mounted) {
        setState(() {
          _metadata = metadata;
          _isLoading = false;
        });
      }
    } catch (e) {
      PMlog.d(tag, '❌ API 获取失败: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// 保存预览数据到 Note
  void _savePreviewToNote(Map<String, dynamic> metadata) {
    final noteId = widget.note.id;
    if (noteId == null) return;

    Future.microtask(() async {
      try {
        final noteService = ref.read(noteServiceProvider);
        await noteService.updatePreviewData(
          noteId: noteId,
          previewImageUrl: metadata['imageUrl'],
          previewTitle: metadata['title'],
          previewDescription: metadata['description'],
        );
        PMlog.d(tag, '预览数据已保存到 Note: ${metadata['title']}');
      } catch (e) {
        PMlog.e(tag, '保存预览数据失败: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.note.url ?? '';

    if (_isLoading) {
      return widget.isVertical
          ? _VerticalSkeletonCard(hasContent: widget.hasContent)
          : const _HorizontalSkeletonCard();
    }

    if (_hasError || _metadata == null) {
      return widget.isVertical
          ? _VerticalErrorCard(url: url, hasContent: widget.hasContent)
          : _HorizontalErrorCard(url: url);
    }

    // 创建 Metadata 对象用于显示
    final metadata = Metadata();
    metadata.title = _metadata!['title'];
    metadata.desc = _metadata!['description'];
    metadata.image = _metadata!['imageUrl'];
    metadata.url = _metadata!['url'];

    final imageUrl = _metadata!['imageUrl'] as String?;

    return widget.isVertical
        ? _VerticalPreviewCard(
            url: url,
            metadata: metadata,
            imageProvider: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            hasContent: widget.hasContent,
            onTap: widget.onTap,
            isDesktop: widget.isDesktop,
            publishDate: widget.publishDate,
            isHovered: widget.isHovered,
          )
        : _HorizontalPreviewCard(
            url: url,
            metadata: metadata,
            imageProvider: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            onTap: widget.onTap,
          );
  }
}

// 常量定义 (用于保证高度一致性)

// 垂直布局下，图片区域的固定高度
final double _kVerticalImageHeight = 100.w;
// 垂直布局下，骨架屏和错误卡片"内容区域"的固定高度。
final double _kVerticalPlaceholderContentHeight = 105.w;

// 基础组件
class _BaseCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isVertical;
  final bool hasContent;
  final double? height;
  final bool isDesktop;

  const _BaseCardContainer({
    Key? key,
    required this.child,
    this.onTap,
    required this.isVertical,
    this.hasContent = true,
    this.height,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = (isVertical && hasContent)
        ? BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )
        : BorderRadius.circular(16);

    // 统一使用主题色，移除移动端的独立阴影（由外层 NoteItem 统一控制）
    final decoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: borderRadius,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// 成功状态组件
class _VerticalPreviewCard extends StatelessWidget {
  final String url;
  final Metadata metadata;
  final ImageProvider? imageProvider;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const _VerticalPreviewCard({
    Key? key,
    required this.url,
    required this.metadata,
    this.imageProvider,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 判断是否为空内容（真正的空数据，而不是默认的 "No Title"）
    // 只有当 metadata 完全没有有效信息时才认为是空内容
    final bool isEmptyContent =
        (metadata.title == null ||
            metadata.title!.isEmpty ||
            metadata.title == 'No Title') &&
        (metadata.desc == null ||
            metadata.desc!.isEmpty ||
            metadata.desc == 'No description available') &&
        (metadata.image == null || metadata.image!.isEmpty);

    return _BaseCardContainer(
      isVertical: true,
      hasContent: hasContent,
      isDesktop: isDesktop,
      // 只有空内容时才固定高度,正常内容自适应
      height: isEmptyContent
          ? (_kVerticalImageHeight + _kVerticalPlaceholderContentHeight)
          : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardImageSection(
            imageProvider: imageProvider,
            isVertical: true,
            isDesktop: isDesktop,
          ),
          _VerticalContentSection(
            metadata: metadata,
            fixedHeight: isEmptyContent,
            isDesktop: isDesktop,
            publishDate: publishDate,
            isHovered: isHovered,
          ),
        ],
      ),
    );
  }
}

class _HorizontalPreviewCard extends StatelessWidget {
  final String url;
  final Metadata metadata;
  final ImageProvider? imageProvider;
  final VoidCallback onTap;
  final String? publishDate;

  const _HorizontalPreviewCard({
    Key? key,
    required this.url,
    required this.metadata,
    this.imageProvider,
    required this.onTap,
    this.publishDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseCardContainer(
      isVertical: false,
      height: 120,
      onTap: onTap,
      child: Row(
        children: [
          _CardImageSection(imageProvider: imageProvider, isVertical: false),
          _HorizontalContentSection(
            metadata: metadata,
            publishData: publishDate,
          ),
        ],
      ),
    );
  }
}

// 骨架屏组件 (Loading States)
class _VerticalSkeletonCard extends StatelessWidget {
  final bool hasContent;

  const _VerticalSkeletonCard({Key? key, required this.hasContent})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return _BaseCardContainer(
      isVertical: true,
      hasContent: hasContent,
      height:
          _kVerticalImageHeight + _kVerticalPlaceholderContentHeight, // 明确指定总高度
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片区域
          Container(
            height: _kVerticalImageHeight,
            width: double.infinity,
            color: appColors.skeletonBase,
          ),
          // 内容区域 - 强制高度
          Container(
            height: _kVerticalPlaceholderContentHeight, // 固定高度
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.max, // 确保 Column 填满整个容器高度
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 15.w,
                  width: double.infinity,
                  color: appColors.skeletonBase,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 15.w,
                  width: 150.w,
                  color: appColors.skeletonBase,
                ),
                // 使用 Spacer 或者 Expanded 来自动填充剩余空间,或者保持固定间距
                // 这里为了精确控制骨架形状,保持原样即可,因为外层 Container 已经固定了总高度
                const SizedBox(height: 14),
                Container(
                  height: 13.w,
                  width: double.infinity,
                  color: appColors.skeletonHighlight,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 13.w,
                  width: 100.w,
                  color: appColors.skeletonHighlight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalSkeletonCard extends StatelessWidget {
  const _HorizontalSkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return _BaseCardContainer(
      isVertical: false,
      height: 120,
      child: Row(
        children: [
          Container(
            width: 120.w,
            height: double.infinity,
            color: appColors.skeletonBase,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.w,
                    width: 180.w,
                    color: appColors.skeletonBase,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 13.w,
                    width: double.infinity,
                    color: appColors.skeletonHighlight,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 13.w,
                    width: 120.w,
                    color: appColors.skeletonHighlight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 错误状态组件 (Error States)
class _VerticalErrorCard extends StatelessWidget {
  final String url;
  final bool hasContent;

  const _VerticalErrorCard({
    Key? key,
    required this.url,
    required this.hasContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return _BaseCardContainer(
      isVertical: true,
      hasContent: hasContent,
      height:
          _kVerticalImageHeight + _kVerticalPlaceholderContentHeight, // 明确指定总高度
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _kVerticalImageHeight,
            width: double.infinity,
            color: appColors.errorBackground,
            child: Icon(
              Icons.broken_image_outlined,
              color: appColors.errorIcon,
              size: 40.w,
            ),
          ),
          // 内容区域 - 强制高度,确保与骨架屏一致
          Container(
            height: _kVerticalPlaceholderContentHeight, // 固定高度
            padding: const EdgeInsets.all(12.0),
            // 使用 Stack 或 Column + Spacer 可以让错误信息居中或顶部对齐,看你喜好。
            // 这里保持顶部对齐,与骨架屏视觉重心一致。
            child: Column(
              mainAxisSize: MainAxisSize.max, // 确保 Column 填满整个容器高度
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '加载失败',
                  style: TextStyle(
                    color: appColors.errorText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: appColors.errorIcon, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalErrorCard extends StatelessWidget {
  final String url;

  const _HorizontalErrorCard({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    return _BaseCardContainer(
      isVertical: false,
      height: 120,
      child: Row(
        children: [
          Container(
            width: 120.w,
            height: double.infinity,
            color: appColors.errorBackground,
            child: Icon(
              Icons.broken_image_outlined,
              color: appColors.errorIcon,
              size: 30.w,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '加载失败',
                    style: TextStyle(
                      color: appColors.errorText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appColors.errorIcon,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 通用子组件
class _CardImageSection extends StatelessWidget {
  final ImageProvider? imageProvider;
  final bool isVertical;
  final bool isDesktop;

  const _CardImageSection({
    Key? key,
    required this.imageProvider,
    required this.isVertical,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 桌面端图片高度增加
    final height = isDesktop ? 180.w : _kVerticalImageHeight;
    final color = Theme.of(context).colorScheme;
    return Container(
      width: isVertical ? double.infinity : 120.w,
      height: isVertical ? height : double.infinity,
      decoration: imageProvider != null
          ? BoxDecoration(
              image: DecorationImage(image: imageProvider!, fit: BoxFit.cover),
            )
          : BoxDecoration(color: color.surfaceContainerLow),
      child: imageProvider == null
          ? Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: isVertical ? 50.w : 40.w,
                color: color.primary,
              ),
            )
          : null,
    );
  }
}

class _VerticalContentSection extends StatelessWidget {
  final Metadata metadata;
  final bool fixedHeight;
  final bool isDesktop;
  final String? publishDate;
  final bool isHovered;

  const _VerticalContentSection({
    Key? key,
    required this.metadata,
    this.fixedHeight = false,
    this.isDesktop = false,
    this.publishDate,
    this.isHovered = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 标题样式 - 杂志感：衬线字体、紧凑行高、hover高亮
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontSize: isDesktop ? 20.sp : 17.sp,
      color: isHovered ? colorScheme.tertiary : null,
    );

    // 描述样式
    final descStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.secondary,
      fontSize: isDesktop ? 14.sp : 13.sp,
    );

    final padding = isDesktop ? 16.0 : 12.0;

    if (fixedHeight) {
      return Container(
        height: _kVerticalPlaceholderContentHeight,
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata.title ?? 'No Title',
              style: titleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              metadata.desc ?? 'No description available',
              style: descStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SourceInfo(metadata: metadata, publishDate: publishDate),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.title ?? 'No Title',
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isDesktop ? 10.w : 8.w),
          Text(
            metadata.desc ?? 'No description available',
            style: descStyle,
            maxLines: isDesktop ? 4 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isDesktop ? 14.w : 12.w),
          SourceInfo(metadata: metadata, publishDate: publishDate),
        ],
      ),
    );
  }
}

class _HorizontalContentSection extends StatelessWidget {
  final Metadata metadata;
  final String? publishData;

  const _HorizontalContentSection({
    Key? key,
    required this.metadata,
    this.publishData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata.title ?? 'No Title',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                metadata.desc ?? 'No description available',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            SourceInfo(metadata: metadata, publishDate: publishData),
          ],
        ),
      ),
    );
  }
}
