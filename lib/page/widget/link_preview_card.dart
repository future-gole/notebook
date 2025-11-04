import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

/// 自定义链接预览卡片组件
/// 使用 AnyLinkPreview.builder 实现完全自定义的 UI
/// 支持垂直布局（瀑布流）和水平布局（列表）
class LinkPreviewCard extends StatelessWidget {
  final String url;
  final bool isVertical; // true=上下布局（瀑布流），false=左右布局（列表）
  final bool hasContent;

  const LinkPreviewCard({
    Key? key,
    required this.url,
    this.isVertical = false, // 默认水平布局
    required this.hasContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnyLinkPreview.builder(
      link: url,
      itemBuilder: (context, metadata, imageProvider, svgPicture) {
        return isVertical
            ? _buildVerticalCard(context, metadata, imageProvider)
            : _buildHorizontalCard(context, metadata, imageProvider);
      },
      placeholderWidget: _buildPlaceholder(),
      errorWidget: _buildError(),
      cache: Duration(days: 365),
    );
  }

  /// 构建垂直布局卡片（瀑布流模式：上图片下文字）
  Widget _buildVerticalCard(
    BuildContext context,
    Metadata metadata,
    ImageProvider? imageProvider,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: hasContent
              ? BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片
            _buildVerticalImageSection(imageProvider),
            // 底部文字内容
            _buildVerticalContentSection(metadata),
          ],
        ),
      ),
    );
  }

  /// 构建水平布局卡片（列表模式：左图片右文字）
  Widget _buildHorizontalCard(
    BuildContext context,
    Metadata metadata,
    ImageProvider? imageProvider,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // 左侧图片
            _buildHorizontalImageSection(imageProvider),
            // 右侧文字内容
            _buildHorizontalContentSection(metadata),
          ],
        ),
      ),
    );
  }

  /// 垂直布局：顶部图片区域
  Widget _buildVerticalImageSection(ImageProvider? imageProvider) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: imageProvider != null
          ? BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            )
          : BoxDecoration(color: Colors.grey[300]),
      child: imageProvider == null
          ? Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey[500],
              ),
            )
          : null,
    );
  }

  /// 垂直布局：底部内容区域
  Widget _buildVerticalContentSection(Metadata metadata) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            metadata.title ?? 'No Title',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // 描述
          Text(
            metadata.desc ?? 'No description available',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 来源信息
          _buildSourceInfo(metadata),
        ],
      ),
    );
  }

  /// 水平布局：左侧图片区域
  Widget _buildHorizontalImageSection(ImageProvider? imageProvider) {
    return Container(
      width: 120,
      decoration: imageProvider != null
          ? BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            )
          : BoxDecoration(color: Colors.grey[300]),
      child: imageProvider == null
          ? Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey[500],
              ),
            )
          : null,
    );
  }

  /// 水平布局：右侧内容区域
  Widget _buildHorizontalContentSection(Metadata metadata) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              metadata.title ?? 'No Title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 描述
            Expanded(
              child: Text(
                metadata.desc ?? 'No description available',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // 来源信息
            _buildSourceInfo(metadata),
          ],
        ),
      ),
    );
  }

  /// 来源信息（favicon + domain）
  Widget _buildSourceInfo(Metadata metadata) {
    return Row(
      children: [
        // Favicon
        if (metadata.image != null && metadata.image!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Image.network(
              metadata.image!,
              width: 16,
              height: 16,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.link, size: 16, color: Colors.grey[500]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Icon(Icons.link, size: 16, color: Colors.grey[500]),
          ),
        // Domain
        Flexible(
          child: Text(
            metadata.url ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 加载中占位符
  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
            SizedBox(height: 8),
            Text(
              '加载预览中...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 错误占位符
  Widget _buildError() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.grey[500]),
            SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 启动 URL
  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }
}
