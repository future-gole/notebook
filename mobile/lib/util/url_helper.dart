/// URL 检测和提取工具类
class UrlHelper {
  /// 检测文本中是否包含 URL
  static bool containsHttpsUrl(String? text) {
    if (text == null || text.isEmpty) return false;
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  /// 从文本中提取第一个 URL
  static String? extractHttpsUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final match = urlPattern.firstMatch(text);
    return match?.group(0);
  }

  /// 从文本中提取所有 URL
  static List<String> extractAllUrls(String? text) {
    if (text == null || text.isEmpty) return [];
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return urlPattern.allMatches(text).map((match) => match.group(0)!).toList();
  }

  /// 移除文本中的 URL，保留其他内容
  static String removeUrls(String? text) {
    if (text == null || text.isEmpty) return '';
    final urlPattern = RegExp(
      r'(https?|content|file)://[^\s]+',
      caseSensitive: false,
    );
    return text.replaceAll(urlPattern, '').trim();
  }

  // Content/File URI 部分
  /// 检测文本是否包含 content:// URI (常见于 Android 系统分享)
  static bool containsContentUri(String? text) {
    if (text == null || text.isEmpty) return false;
    // 匹配 content:// 开头，直到遇到空白字符
    final uriPattern = RegExp(r'content://[^\s]+', caseSensitive: false);
    return uriPattern.hasMatch(text);
  }

  /// 从文本中提取第一个 content:// URI
  static String? extractContentUri(String? text) {
    if (text == null || text.isEmpty) return null;
    final uriPattern = RegExp(r'content://[^\s]+', caseSensitive: false);
    final match = uriPattern.firstMatch(text);
    return match?.group(0);
  }

  /// 提取第一个任意类型的 URI (HTTP, HTTPS, Content, File)
  /// 如果你不确定分享过来的是链接还是文件路径，用这个最保险
  static String? extractAnyUri(String? text) {
    if (text == null || text.isEmpty) return null;
    // 匹配 http, https, content, file 四种常见协议
    final uriPattern = RegExp(
      r'(https?|content|file)://[^\s]+',
      caseSensitive: false,
    );
    final match = uriPattern.firstMatch(text);
    return match?.group(0);
  }

  /// 检测是否为本地图片路径（pocket_images目录下的相对路径）
  static bool isLocalImagePath(String? text) {
    if (text == null || text.isEmpty) return false;
    // 检测是否以 pocket_images/ 开头
    return text.startsWith('pocket_images/');
  }

  /// 检测是否为本地图片或HTTP链接
  static bool hasImageOrUrl(String? text) {
    return isLocalImagePath(text) || containsHttpsUrl(text);
  }
}
