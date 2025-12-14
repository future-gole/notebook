import 'package:flutter/foundation.dart';

/// 环境枚举
enum Environment {
  /// 开发环境（本地）
  development,

  /// 预发布环境
  staging,

  /// 生产环境
  production,
}

/// AppConfig 状态类
@immutable
class AppConfigState {
  final bool proxyEnabled;
  final String proxyHost;
  final int proxyPort;
  final int metaCacheTime;
  final bool titleEnabled;
  final bool waterfallLayoutEnabled;
  final bool syncAutoStart;
  final List<Map<String, String>> reminderShortcuts;
  final bool highPrecisionNotification;
  final int notificationIntensity;
  final String linkPreviewApiKey;
  final Environment environment;

  const AppConfigState({
    this.proxyEnabled = false,
    this.proxyHost = '127.0.0.1',
    this.proxyPort = 7890,
    this.metaCacheTime = 10,
    this.titleEnabled = false,
    this.waterfallLayoutEnabled = true,
    this.syncAutoStart = false,
    this.reminderShortcuts = const [],
    this.highPrecisionNotification = false,
    this.notificationIntensity = 2,
    this.linkPreviewApiKey = '',
    this.environment = Environment.development,
  });

  AppConfigState copyWith({
    bool? proxyEnabled,
    String? proxyHost,
    int? proxyPort,
    int? metaCacheTime,
    bool? titleEnabled,
    bool? waterfallLayoutEnabled,
    bool? syncAutoStart,
    List<Map<String, String>>? reminderShortcuts,
    bool? highPrecisionNotification,
    int? notificationIntensity,
    String? linkPreviewApiKey,
    Environment? environment,
  }) {
    return AppConfigState(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      metaCacheTime: metaCacheTime ?? this.metaCacheTime,
      titleEnabled: titleEnabled ?? this.titleEnabled,
      waterfallLayoutEnabled: waterfallLayoutEnabled ?? this.waterfallLayoutEnabled,
      syncAutoStart: syncAutoStart ?? this.syncAutoStart,
      reminderShortcuts: reminderShortcuts ?? this.reminderShortcuts,
      highPrecisionNotification: highPrecisionNotification ?? this.highPrecisionNotification,
      notificationIntensity: notificationIntensity ?? this.notificationIntensity,
      linkPreviewApiKey: linkPreviewApiKey ?? this.linkPreviewApiKey,
      environment: environment ?? this.environment,
    );
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
