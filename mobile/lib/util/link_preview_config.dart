/// 链接预览配置
class LinkPreviewConfig {
  /// 智能判断是否使用 API 服务
  /// 
  /// **X/Twitter/YouTube 使用 API**（稳定可靠，支持复杂网站）
  /// **国内网站使用 any_link_preview**（效果好，有图片）
  static bool shouldUseApiService(String url) {
    final lowerUrl = url.toLowerCase();
    
    // X/Twitter 使用 API
    if (lowerUrl.contains('x.com') || 
        lowerUrl.contains('twitter.com') ||
        lowerUrl.contains('t.co')) {
      return true;
    }
    
    // YouTube 使用 API（效果更好）
    if (lowerUrl.contains('youtube.com') || 
        lowerUrl.contains('youtu.be')) {
      return true;
    }
    
    // 国内网站和其他网站使用 any_link_preview
    return false;
  }
  
  /// 缓存时间：1年
  static const Duration cacheDuration = Duration(days: 365);
  
  /// LinkPreview.net API 配额说明：
  /// - 免费账户：120 次/小时，240 次/天
  /// - 仅用于 X/Twitter 和 YouTube
  
  /// 调试模式：打印详细日志
  static const bool debugMode = true;
}
