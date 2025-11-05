import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置管理类
class AppConfig {
  static const String _keyProxyEnabled = 'proxy_enabled';
  static const String _keyProxyHost = 'proxy_host';
  static const String _keyProxyPort = 'proxy_port';
  static const String _keyLinkPreviewApiKey = 'linkpreview_api_key';

  // 单例模式
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  SharedPreferences? _prefs;

  /// 初始化配置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 代理配置
  bool get proxyEnabled => _prefs?.getBool(_keyProxyEnabled) ?? false;
  String get proxyHost => _prefs?.getString(_keyProxyHost) ?? '127.0.0.1';
  int get proxyPort => _prefs?.getInt(_keyProxyPort) ?? 7890;

  Future<void> setProxyEnabled(bool enabled) async {
    await _prefs?.setBool(_keyProxyEnabled, enabled);
  }

  Future<void> setProxyHost(String host) async {
    await _prefs?.setString(_keyProxyHost, host);
  }

  Future<void> setProxyPort(int port) async {
    await _prefs?.setInt(_keyProxyPort, port);
  }

  /// LinkPreview API 配置
  String get linkPreviewApiKey =>
      _prefs?.getString(_keyLinkPreviewApiKey) ??
      ''; // 默认值

  Future<void> setLinkPreviewApiKey(String apiKey) async {
    await _prefs?.setString(_keyLinkPreviewApiKey, apiKey);
  }

  /// 清除所有配置
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
