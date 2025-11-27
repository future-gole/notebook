import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/util/app_config.dart';

void main() {
  group('AppConfig 单例模式测试', () {
    test('AppConfig 是单例', () {
      final config1 = AppConfig();
      final config2 = AppConfig();
      expect(identical(config1, config2), true);
    });

    test('多次获取同一实例', () {
      final instances = [AppConfig(), AppConfig(), AppConfig(), AppConfig()];

      for (int i = 1; i < instances.length; i++) {
        expect(identical(instances[0], instances[i]), true);
      }
    });
  });

  group('Environment 枚举测试', () {
    test('Environment 有三个值', () {
      expect(Environment.values.length, 3);
    });

    test('Environment.development', () {
      expect(Environment.development, isNotNull);
    });

    test('Environment.staging', () {
      expect(Environment.staging, isNotNull);
    });

    test('Environment.production', () {
      expect(Environment.production, isNotNull);
    });

    test('Environment 枚举名称', () {
      expect(Environment.development.toString(), 'Environment.development');
      expect(Environment.staging.toString(), 'Environment.staging');
      expect(Environment.production.toString(), 'Environment.production');
    });
  });

  group('代理配置默认值测试', () {
    test('proxyEnabled 默认为 false', () {
      final config = AppConfig();
      // 未初始化时，SharedPreferences 为 null，应该返回默认值
      expect(config.proxyEnabled, false);
    });

    test('proxyHost 默认为 127.0.0.1', () {
      final config = AppConfig();
      expect(config.proxyHost, '127.0.0.1');
    });

    test('proxyPort 默认为 7890', () {
      final config = AppConfig();
      expect(config.proxyPort, 7890);
    });

    test('metaCacheTime 默认为 10', () {
      final config = AppConfig();
      expect(config.metaCacheTime, 10);
    });
  });

  group('特性开关默认值测试', () {
    test('titleEnabled 默认为 false', () {
      final config = AppConfig();
      expect(config.titleEnabled, false);
    });

    test('waterfallLayoutEnabled 默认为 true', () {
      final config = AppConfig();
      expect(config.waterfallLayoutEnabled, true);
    });
  });

  group('API Key 默认值测试', () {
    test('linkPreviewApiKey 默认为空字符串', () {
      final config = AppConfig();
      expect(config.linkPreviewApiKey, '');
    });
  });

  group('Environment 字符串转换测试', () {
    test('development 字符串转换', () {
      final envString = Environment.development.toString().split('.').last;
      expect(envString, 'development');
    });

    test('staging 字符串转换', () {
      final envString = Environment.staging.toString().split('.').last;
      expect(envString, 'staging');
    });

    test('production 字符串转换', () {
      final envString = Environment.production.toString().split('.').last;
      expect(envString, 'production');
    });
  });

  group('baseUrl 测试', () {
    test('development 环境 baseUrl', () {
      final config = AppConfig();
      // 未设置环境时，默认为 development
      expect(config.baseUrl, 'http://localhost:8080');
    });

    test('isDevelopment 默认为 true', () {
      final config = AppConfig();
      expect(config.isDevelopment, true);
    });

    test('isProduction 默认为 false', () {
      final config = AppConfig();
      expect(config.isProduction, false);
    });
  });

  group('AppConfig ChangeNotifier 特性测试', () {
    test('AppConfig 继承 ChangeNotifier', () {
      final config = AppConfig();
      expect(config, isA<ChangeNotifier>());
    });

    test('可以注册监听器', () {
      final config = AppConfig();
      var notified = false;

      config.addListener(() {
        notified = true;
      });

      expect(notified, false);
      config.removeListener(() {});
    });
  });

  group('配置键常量测试', () {
    test('存在代理相关的配置键', () {
      // 这些是私有字段，但我们可以通过对外接口来验证它们的存在
      final config = AppConfig();
      expect(config.proxyEnabled, isA<bool>());
      expect(config.proxyHost, isA<String>());
      expect(config.proxyPort, isA<int>());
    });

    test('存在 API Key 配置', () {
      final config = AppConfig();
      expect(config.linkPreviewApiKey, isA<String>());
    });

    test('存在环境配置', () {
      final config = AppConfig();
      expect(config.environment, isA<Environment>());
    });

    test('存在缓存时间配置', () {
      final config = AppConfig();
      expect(config.metaCacheTime, isA<int>());
    });

    test('存在标题开关配置', () {
      final config = AppConfig();
      expect(config.titleEnabled, isA<bool>());
    });

    test('存在瀑布流开关配置', () {
      final config = AppConfig();
      expect(config.waterfallLayoutEnabled, isA<bool>());
    });
  });

  group('配置值范围测试', () {
    test('proxyPort 是有效的端口号', () {
      final config = AppConfig();
      expect(config.proxyPort, greaterThanOrEqualTo(0));
      expect(config.proxyPort, lessThanOrEqualTo(65535));
    });

    test('metaCacheTime 是正数', () {
      final config = AppConfig();
      expect(config.metaCacheTime, greaterThan(0));
    });

    test('proxyHost 不为空', () {
      final config = AppConfig();
      expect(config.proxyHost, isNotEmpty);
    });
  });

  group('环境检查方法测试', () {
    test('isDevelopment 和 isProduction 互斥', () {
      final config = AppConfig();
      // 在默认的 development 环境
      expect(config.isDevelopment, true);
      expect(config.isProduction, false);
    });

    test('至少有一个环境标志为 true', () {
      final config = AppConfig();
      final isDev = config.isDevelopment;
      final isProd = config.isProduction;
      final isStaging = config.environment == Environment.staging;

      expect(isDev || isProd || isStaging, true);
    });
  });

  group('AppConfig 边界值测试', () {
    test('proxyHost 可以是 IP 地址', () {
      expect(AppConfig().proxyHost, matches(RegExp(r'^\d+\.\d+\.\d+\.\d+$')));
    });

    test('proxyPort 在有效范围内', () {
      final port = AppConfig().proxyPort;
      expect(port, greaterThanOrEqualTo(1));
      expect(port, lessThanOrEqualTo(65535));
    });

    test('metaCacheTime 是合理的天数', () {
      final days = AppConfig().metaCacheTime;
      expect(days, greaterThan(0));
      expect(days, lessThan(365)); // 通常不超过一年
    });
  });

  group('baseUrl 完整性测试', () {
    test('development baseUrl 包含 localhost', () {
      final config = AppConfig();
      expect(config.baseUrl, contains('localhost'));
    });

    test('development baseUrl 包含端口', () {
      final config = AppConfig();
      expect(config.baseUrl, contains('8080'));
    });

    test('development baseUrl 是有效的 URL 格式', () {
      final config = AppConfig();
      expect(config.baseUrl, startsWith('http://'));
    });
  });

  group('配置方法的类型检查', () {
    test('setProxyEnabled 接受 bool', () {
      final config = AppConfig();
      expect(() => config.setProxyEnabled(true), returnsNormally);
      expect(() => config.setProxyEnabled(false), returnsNormally);
    });

    test('setProxyHost 接受 String', () {
      final config = AppConfig();
      expect(() => config.setProxyHost('192.168.1.1'), returnsNormally);
    });

    test('setProxyPort 接受 int', () {
      final config = AppConfig();
      expect(() => config.setProxyPort(8080), returnsNormally);
    });

    test('setLinkPreviewApiKey 接受 String', () {
      final config = AppConfig();
      expect(() => config.setLinkPreviewApiKey('test-key'), returnsNormally);
    });

    test('setMetaCacheTime 接受 int', () {
      final config = AppConfig();
      expect(() => config.setMetaCacheTime(7), returnsNormally);
    });

    test('setTitleEnabled 接受 bool', () {
      final config = AppConfig();
      expect(() => config.setTitleEnabled(true), returnsNormally);
    });

    test('setWaterFallLayout 接受 bool', () {
      final config = AppConfig();
      expect(() => config.setWaterFallLayout(false), returnsNormally);
    });

    test('setEnvironment 接受 Environment', () {
      final config = AppConfig();
      expect(
        () => config.setEnvironment(Environment.production),
        returnsNormally,
      );
    });
  });
}
