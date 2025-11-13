import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 环境枚举
enum Environment {
  /// 开发环境（本地）
  development,

  /// 预发布环境
  staging,

  /// 生产环境
  production,
}

/// 应用配置管理类
class AppConfig extends ChangeNotifier{
  //todo 其他的地方可以换的都用ref换掉
  static const String _keyProxyEnabled = 'proxy_enabled';
  static const String _keyProxyHost = 'proxy_host';
  static const String _keyProxyPort = 'proxy_port';
  static const String _keyLinkPreviewApiKey = 'linkpreview_api_key';
  static const String _metaCacheTime = 'meta_cache_time';
  static const String _keyTitleEnabled = 'title_enabled';
  static const String _keyEnvironment = 'app_environment';
  static const String _isWaterfallLayout = 'waterfall_layout';

  // 单例模式
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  SharedPreferences? _prefs;

  /// 初始化配置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  /// 代理配置
  bool get proxyEnabled => _prefs?.getBool(_keyProxyEnabled) ?? false;
  String get proxyHost => _prefs?.getString(_keyProxyHost) ?? '127.0.0.1';
  int get proxyPort => _prefs?.getInt(_keyProxyPort) ?? 7890;
  int get metaCacheTime => _prefs?.getInt(_metaCacheTime) ?? 10;

  /// Title 显示配置
  bool get titleEnabled => _prefs?.getBool(_keyTitleEnabled) ?? false; // 默认不开启

  /// waterfall
  bool get waterfallLayoutEnabled => _prefs?.getBool(_isWaterfallLayout) ?? true; // 默认开启

  Future<void> setProxyEnabled(bool enabled) async {
    await _prefs?.setBool(_keyProxyEnabled, enabled);
    notifyListeners();
  }

  Future<void> setWaterFallLayout(bool enabled) async {
    await _prefs?.setBool(_isWaterfallLayout, enabled);
    notifyListeners();
  }

  Future<void> setProxyHost(String host) async {
    await _prefs?.setString(_keyProxyHost, host);
    notifyListeners();
  }

  Future<void> setProxyPort(int port) async {
    await _prefs?.setInt(_keyProxyPort, port);
    notifyListeners();
  }

  /// LinkPreview API 配置
  String get linkPreviewApiKey =>
      _prefs?.getString(_keyLinkPreviewApiKey) ?? ''; // 默认值

  Future<void> setLinkPreviewApiKey(String apiKey) async {
    await _prefs?.setString(_keyLinkPreviewApiKey, apiKey);
    notifyListeners();
  }

  Future<void> setMetaCacheTime(int day) async {
    await _prefs?.setInt(_metaCacheTime, day);
    notifyListeners();
  }

  Future<void> setTitleEnabled(bool enabled) async {
    await _prefs?.setBool(_keyTitleEnabled, enabled);
    notifyListeners();
  }

  /// 清除所有配置
  Future<void> clearAll() async {
    await _prefs?.clear();
    notifyListeners();
  }

  // ==================== 环境配置 ====================

  /// 获取当前环境
  Environment get environment {
    final envString = _prefs?.getString(_keyEnvironment);
    switch (envString) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }

  /// 设置环境
  Future<void> setEnvironment(Environment env) async {
    final envString = env.toString().split('.').last;
    await _prefs?.setString(_keyEnvironment, envString);
  }

  /// 获取 API 基础 URL
  String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return ''; // 预发布环境，可按需修改
      case Environment.production:
        return ''; // 生产环境，可按需修改
    }
  }

  /// 是否为开发环境
  bool get isDevelopment => environment == Environment.development;

  /// 是否为生产环境
  bool get isProduction => environment == Environment.production;
}
