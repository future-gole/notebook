import 'package:any_link_preview/any_link_preview.dart';
import 'package:pocketmind/api/link_preview_api_service.dart';
import 'package:pocketmind/util/image_storage_helper.dart';
import 'package:pocketmind/util/link_preview_config.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/url_helper.dart';

/// 元数据管理服务
///
/// 负责处理链接预览数据的获取、加工和本地化。
/// 不直接操作数据库，只返回处理好的数据对象。
class MetadataManager {
  static const String _tag = 'MetadataManager';
  final ImageStorageHelper _imageHelper = ImageStorageHelper();
  final LinkPreviewApiService? _apiService;

  MetadataManager({LinkPreviewApiService? apiService})
    : _apiService = apiService;

  /// 获取并处理链接元数据
  ///
  /// [url] : 目标链接
  /// 返回 : 处理好的元数据对象（包含本地化后的图片路径），如果获取失败返回 null
  Future<Metadata?> fetchAndProcessMetadata(String url) async {
    if (!UrlHelper.containsHttpsUrl(url)) {
      return null;
    }

    try {
      Metadata? metadata;

      // 1. 策略路由：根据 URL 特征选择获取方式
      if (LinkPreviewConfig.shouldUseApiService(url) && _apiService != null) {
        // 使用后端 API 获取元数据 (针对 X/Twitter/YouTube 等)
        metadata = await _fetchFromBackend(url);
      }

      // 如果 API 获取失败或不需要使用 API，回退到本地解析
      if (metadata == null) {
        metadata = await _fetchFromLocalParser(url);
      }

      if (metadata == null) {
        PMlog.w(_tag, '无法获取元数据: $url');
        return null;
      }

      // 2. 数据完整性校验与补全
      _sanitizeMetadata(metadata, url);

      if (!_isValidMetadata(metadata)) {
        PMlog.w(_tag, '元数据不完整，跳过处理: $url');
        return null;
      }

      // 3. 资源本地化 (图片下载)
      final processedMetadata = await _localizeResources(metadata);

      return processedMetadata;
    } catch (e) {
      PMlog.e(_tag, '元数据处理失败: $url, error: $e');
      return null;
    }
  }

  /// 使用后端 API 获取元数据
  Future<Metadata?> _fetchFromBackend(String url) async {
    if (_apiService == null) return null;

    try {
      final apiData = await _apiService!.fetchMetadata(url);
      if (apiData.success && apiData.hasData) {
        final metadata = Metadata();
        metadata.title = apiData.title;
        metadata.desc = apiData.description;
        metadata.image = apiData.imageUrl;
        metadata.url = apiData.url;
        PMlog.d(_tag, '从 API 成功获取元数据: ${metadata.title}');
        return metadata;
      }
    } catch (e) {
      PMlog.w(_tag, 'API 获取失败，准备回退到本地解析: $e');
    }
    return null;
  }

  /// 清洗和补全元数据
  void _sanitizeMetadata(Metadata data, String url) {
    // 移除标题和描述中的多余空白
    data.title = data.title?.trim();
    data.desc = data.desc?.trim();

    // 如果标题为空，保持为 null，不要使用域名兜底
    // UI 层会根据 title == null 显示“预览失败”
    if (data.title != null && data.title!.isEmpty) {
      data.title = null;
    }
  }

  /// 使用本地解析库获取元数据
  Future<Metadata?> _fetchFromLocalParser(String url) async {
    try {
      // 针对不同平台使用特定的 User-Agent
      String userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      if (url.contains('x.com') || url.contains('twitter.com')) {
        userAgent = 'Twitterbot/1.0';
      } else if (url.contains('xhslink.com') ||
          url.contains('xiaohongshu.com')) {
        // 小红书使用移动端 User-Agent 效果更好
        userAgent =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1';
      }

      // AnyLinkPreview.getMetadata 内部已经处理了部分解析逻辑
      final metadata = await AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(hours: 24),
        proxyUrl: null, // 不使用公共代理，避免被封
        headers: {
          'User-Agent': userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Cache-Control': 'no-cache',
        },
      );
      return metadata;
    } catch (e) {
      PMlog.w(_tag, '本地解析失败: $e');
      return null;
    }
  }

  /// 资源本地化：下载图片并替换为本地路径
  Future<Metadata> _localizeResources(Metadata original) async {
    final imageUrl = original.image;

    // 如果没有图片或已经是本地路径，直接返回
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        UrlHelper.isLocalImagePath(imageUrl)) {
      return original;
    }

    // 尝试下载图片
    final localPath = await _imageHelper.downloadAndSaveImage(imageUrl);

    if (localPath != null) {
      // 下载成功，替换为本地路径
      original.image = localPath;
      PMlog.d(_tag, '图片已本地化: $localPath');
    } else {
      // 下载失败，将图片字段设为 null，避免保存网络 URL
      // 这样符合“失败静默”原则，不保存无法本地化的资源
      original.image = null;
      PMlog.w(_tag, '图片本地化失败，已清除图片字段: $imageUrl');
    }

    return original;
  }

  /// 校验元数据有效性
  bool _isValidMetadata(Metadata data) {
    final hasTitle = data.title != null && data.title!.isNotEmpty;
    final hasImage = data.image != null && data.image!.isNotEmpty;
    // 至少要有标题或图片
    return hasTitle || hasImage;
  }
}
