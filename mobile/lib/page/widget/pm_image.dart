import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pocketmind/util/image_storage_helper.dart';
import 'package:pocketmind/util/url_helper.dart';

/// 统一图片渲染组件
///
/// 自动识别并加载不同类型的图片路径：
/// 1. 网络图片 (http/https)
/// 2. 本地相对路径 (pocket_images/...)
/// 3. 本地绝对路径 (Windows 盘符或 Android /data/...)
/// 4. Asset 资源
class PMImage extends StatelessWidget {
  final String pathOrUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PMImage({
    super.key,
    required this.pathOrUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (pathOrUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    // 1. 网络图片
    if (UrlHelper.containsHttpsUrl(pathOrUrl)) {
      return CachedNetworkImage(
        imageUrl: pathOrUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      );
    }

    // 2. 本地相对路径 (pocket_images/...)
    if (UrlHelper.isLocalImagePath(pathOrUrl)) {
      final file = ImageStorageHelper().getFileByRelativePath(pathOrUrl);
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context),
      );
    }

    // 3. 本地绝对路径 (兼容 Windows 和 Android)
    // Windows: 包含盘符 (C:\...) 或正斜杠 (C:/...)
    // Android/Linux: 以 / 开头
    if (pathOrUrl.contains(':\\') ||
        pathOrUrl.contains(':/') ||
        pathOrUrl.startsWith('/')) {
      return Image.file(
        File(pathOrUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context),
      );
    }

    // 4. 默认为 Asset 资源
    return Image.asset(
      pathOrUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
