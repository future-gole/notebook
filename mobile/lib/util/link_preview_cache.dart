import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'logger_service.dart';

/// 链接预览缓存管理器
/// 缓存时间设置为1年，避免重复网络请求
final String tag = "LinkPreviewCache";
class LinkPreviewCache {
  static const String _cachePrefix = 'link_preview_cache_';
  /// 保存缓存
  static Future<void> saveCache(String url, Map<String, dynamic> metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(url);
      
      final cacheData = {
        'metadata': metadata,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
      log.d(tag,'💾 缓存已保存: $url');
    } catch (e) {
      log.e(tag,'❌ 缓存保存失败: $e');
    }
  }

  /// 获取缓存
  static Future<Map<String, dynamic>?> getCache(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(url);
      
      final cacheString = prefs.getString(cacheKey);
      if (cacheString == null) {
        return null;
      }
      
      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      final config = AppConfig();
      final metacacheTime = config.metaCacheTime;

      // 检查缓存是否过期
      if (DateTime.now().difference(cacheTime) > Duration(days: metacacheTime)) {
        log.d(tag,'💾 缓存已过期: $url');
        await clearCache(url);
        return null;
      }
      
      log.d(tag,'✅ 使用缓存: $url');
      return cacheData['metadata'] as Map<String, dynamic>;
      
    } catch (e) {
      log.e(tag,'❌ 缓存读取失败: $e');
      return null;
    }
  }

  /// 清除单个缓存
  static Future<void> clearCache(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(url);
      await prefs.remove(cacheKey);
    } catch (e) {
      log.e(tag,'❌ 缓存清除失败: $e');
    }
  }

  /// 清除所有缓存
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      log.d(tag,'🗑️ 所有缓存已清除');
    } catch (e) {
      log.e(tag,'❌ 缓存清除失败: $e');
    }
  }

  /// 生成缓存键
  static String _getCacheKey(String url) {
    return '$_cachePrefix${url.hashCode}';
  }

  /// 获取缓存统计
  static Future<Map<String, int>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int cacheCount = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          cacheCount++;
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }
      
      return {
        'count': cacheCount,
        'size': totalSize,
      };
    } catch (e) {
      log.e(tag,'❌ 获取缓存统计失败: $e');
      return {'count': 0, 'size': 0};
    }
  }
}
