/// URL 检测和提取工具类
class UrlHelper {
  // 检测文本中是否包含 URL
  static bool containsUrl(String? text) {
    if (text == null || text.isEmpty) return false;
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  // 从文本中提取第一个 URL
  static String? extractUrl(String? text) {
    if (text == null || text.isEmpty) return null;
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final match = urlPattern.firstMatch(text);
    return match?.group(0);
  }

  // 从文本中提取所有 URL
  static List<String> extractAllUrls(String? text) {
    if (text == null || text.isEmpty) return [];
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return urlPattern.allMatches(text).map((match) => match.group(0)!).toList();
  }

  // 移除文本中的 URL，保留其他内容
  static String removeUrls(String? text) {
    if (text == null || text.isEmpty) return '';
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return text.replaceAll(urlPattern, '').trim();
  }
}
