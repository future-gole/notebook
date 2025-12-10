import 'dart:io';

/// 全局 HTTP 代理配置
class GlobalHttpOverrides extends HttpOverrides {
  final String proxyString;
  final bool allowBadCertificates;

  /// [proxyString] 格式示例: "127.0.0.1:7890"
  GlobalHttpOverrides(this.proxyString, {this.allowBadCertificates = false});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // 设置代理
    client.findProxy = (uri) {
      return 'PROXY $proxyString;';
    };

    // 处理 HTTPS 证书问题 (有些代理可能会导致证书校验失败)
    // 警告：在生产环境中盲目返回 true 是不安全的，但个人使用为了方便通常会开启
    if (allowBadCertificates) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }

    return client;
  }
}