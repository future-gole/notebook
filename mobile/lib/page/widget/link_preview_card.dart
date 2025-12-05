import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/util/link_preview_config.dart';
import 'package:pocketmind/api/link_preview_api_service.dart';
import 'package:pocketmind/util/link_preview_cache.dart';

import '../../util/logger_service.dart';
import 'source_info.dart';

/// 智能链接预览卡片组件
/// - 国内网站：使用 any_link_preview + 本地缓存
/// - 国外网站（X/Twitter/YouTube）：使用 LinkPreview.net API + 本地缓存
/// - 本地缓存：不开代理也能查看文本内容
final String tag = "LinkPreviewCard";

class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;

  const LinkPreviewCard({
    Key? key,
    required this.url,
    this.isVertical = false,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
  }) : super(key: key);

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  @override
  Widget build(BuildContext context) {
    // 智能选择：国外网站用API，国内网站用any_link_preview
    final useApi = LinkPreviewConfig.shouldUseApiService(widget.url);

    if (useApi) {
      // 国外网站：使用 API 方案（带本地缓存）
      return _ApiLinkPreview(
        url: widget.url,
        isVertical: widget.isVertical,
        hasContent: widget.hasContent,
        onTap: widget.onTap,
        isDesktop: widget.isDesktop,
        publishDate: widget.publishDate,
      );
    } else {
      // 国内网站：直接使用 any_link_preview
      return AnyLinkPreview.builder(
        link: widget.url,
        itemBuilder: (context, metadata, imageProvider, svgPicture) {
          return widget.isVertical
              ? _VerticalPreviewCard(
                  url: widget.url,
                  metadata: metadata,
                  imageProvider: imageProvider,
                  hasContent: widget.hasContent,
                  onTap: widget.onTap,
                  isDesktop: widget.isDesktop,
                  publishDate: widget.publishDate,
                )
              : _HorizontalPreviewCard(
                  url: widget.url,
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
            ? _VerticalErrorCard(url: widget.url, hasContent: widget.hasContent)
            : _HorizontalErrorCard(url: widget.url),
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
  }
}

// =============================================================================
// API 预览组件（用于国外网站，带本地缓存）
// =============================================================================

class _ApiLinkPreview extends ConsumerStatefulWidget {
  final String url;
  final bool isVertical;
  final bool hasContent;
  final VoidCallback onTap;
  final bool isDesktop;
  final String? publishDate;

  const _ApiLinkPreview({
    Key? key,
    required this.url,
    required this.isVertical,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
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
    try {
      // 1. 先检查本地缓存
      final cached = await LinkPreviewCache.getCache(widget.url);
      if (cached != null) {
        if (mounted) {
          setState(() {
            _metadata = cached;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. 从 API 获取
      final apiMetadata = await ref
          .read(linkPreviewServiceProvider)
          .fetchMetadata(widget.url);
      final metadata;
      // 3.1 存在数据才进行保存
      // 3.1.1 成功
      if (apiMetadata.success) {
        // 3.2 转换并保存到本地缓存
        // 3.1 如果没有拉取到正确的值，就不需要保存到本地缓存，否则会导致下次不会发起拉取请求
        // log.d(tag, "title: ${apiMetadata.title}，description：${apiMetadata.description},imageUrl:${apiMetadata.imageUrl}");
        metadata = {
          'title': apiMetadata.title ?? 'No title',
          'description': apiMetadata.description ?? 'No description available',
          'imageUrl': apiMetadata.imageUrl,
          'url': apiMetadata.url,
        };
        await LinkPreviewCache.saveCache(widget.url, metadata);
      } else {
        // 3.1.1 没成功
        metadata = {
          'title': "预览错误",
          'description': "请检查网络或者api是否正确",
          'imageUrl': "",
          'url': apiMetadata.url,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.isVertical
          ? _VerticalSkeletonCard(hasContent: widget.hasContent)
          : const _HorizontalSkeletonCard();
    }

    if (_hasError || _metadata == null) {
      return widget.isVertical
          ? _VerticalErrorCard(url: widget.url, hasContent: widget.hasContent)
          : _HorizontalErrorCard(url: widget.url);
    }

    // 创建 Metadata 对象用于显示
    final metadata = Metadata();
    PMlog.d(
      tag,
      "title: ${_metadata!['title']}，description：${_metadata!['description']},imageUrl:${_metadata!['imageUrl']}",
    );
    metadata.title = _metadata!['title'];
    metadata.desc = _metadata!['description'];
    metadata.image = _metadata!['imageUrl'];
    metadata.url = _metadata!['url'];

    final imageUrl = _metadata!['imageUrl'] as String?;

    return widget.isVertical
        ? _VerticalPreviewCard(
            url: widget.url,
            metadata: metadata,
            imageProvider: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            hasContent: widget.hasContent,
            onTap: widget.onTap,
            isDesktop: widget.isDesktop,
            publishDate: widget.publishDate,
          )
        : _HorizontalPreviewCard(
            url: widget.url,
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

  const _VerticalPreviewCard({
    Key? key,
    required this.url,
    required this.metadata,
    this.imageProvider,
    required this.hasContent,
    required this.onTap,
    this.isDesktop = false,
    this.publishDate,
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
            color: Colors.grey[200],
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
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 6),
                Container(height: 15.w, width: 150.w, color: Colors.grey[200]),
                // 使用 Spacer 或者 Expanded 来自动填充剩余空间,或者保持固定间距
                // 这里为了精确控制骨架形状,保持原样即可,因为外层 Container 已经固定了总高度
                const SizedBox(height: 14),
                Container(
                  height: 13.w,
                  width: double.infinity,
                  color: Colors.grey[100],
                ),
                const SizedBox(height: 4),
                Container(height: 13.w, width: 100.w, color: Colors.grey[100]),
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
    return _BaseCardContainer(
      isVertical: false,
      height: 120,
      child: Row(
        children: [
          Container(
            width: 120.w,
            height: double.infinity,
            color: Colors.grey[200],
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
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 13.w,
                    width: double.infinity,
                    color: Colors.grey[100],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 13.w,
                    width: 120.w,
                    color: Colors.grey[100],
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
            color: Colors.grey[100],
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[300],
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
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
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
    return _BaseCardContainer(
      isVertical: false,
      height: 120,
      child: Row(
        children: [
          Container(
            width: 120.w,
            height: double.infinity,
            color: Colors.grey[100],
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[300],
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
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 12.sp),
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

    return Container(
      width: isVertical ? double.infinity : 120.w,
      height: isVertical ? height : double.infinity,
      decoration: imageProvider != null
          ? BoxDecoration(
              image: DecorationImage(image: imageProvider!, fit: BoxFit.cover),
            )
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
      child: imageProvider == null
          ? Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: isVertical ? 50.w : 40.w,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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

  const _VerticalContentSection({
    Key? key,
    required this.metadata,
    this.fixedHeight = false, // 默认不固定高度
    this.isDesktop = false,
    this.publishDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 根据 fixedHeight 参数决定是否使用固定高度
    if (fixedHeight) {
      return Container(
        height: _kVerticalPlaceholderContentHeight, // 固定高度
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata.title ?? 'No Title',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              metadata.desc ?? 'No description available',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SourceInfo(metadata: metadata, publishDate: publishDate),
          ],
        ),
      );
    } else {
      // 正常内容,自适应高度
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata.title ?? 'No Title',
              style: textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              metadata.desc ?? 'No description available',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
                fontSize: isDesktop ? 17.sp : 15.sp,
              ),
              maxLines: isDesktop ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SourceInfo(metadata: metadata, publishDate: publishDate),
          ],
        ),
      );
    }
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


