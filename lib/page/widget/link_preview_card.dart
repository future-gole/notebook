import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

/// 自定义链接预览卡片组件
/// 使用 AnyLinkPreview.builder 实现完全自定义的 UI
class LinkPreviewCard extends StatelessWidget {
  final String url;

  const LinkPreviewCard({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnyLinkPreview.builder(
      link: url,
      itemBuilder: (context, metadata, imageProvider, svgPicture) {
        return _buildCustomCard(context, metadata, imageProvider);
      },
      placeholderWidget: _buildPlaceholder(),
      errorWidget: _buildError(),
      cache: Duration(hours: 1),
    );
  }

  /// 构建自定义卡片
  Widget _buildCustomCard(
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
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // 左侧图片
            _buildImageSection(imageProvider),
            // 右侧文字内容
            _buildContentSection(metadata),
          ],
        ),
      ),
    );
  }

  /// 左侧图片区域
  Widget _buildImageSection(ImageProvider? imageProvider) {
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

  /// 右侧内容区域
  Widget _buildContentSection(Metadata metadata) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              metadata.title ?? 'No Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
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
            SizedBox(height: 8),
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
        Expanded(
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
