import 'package:flutter/material.dart';
import 'package:pocketmind/util/app_config.dart';
import 'dart:io';
import 'package:pocketmind/util/proxy_config.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _config = AppConfig();
  final _apiKeyController = TextEditingController();
  final _meteCacheTimeController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();

  bool _proxyEnabled = false;
  bool _titleEnabled = false;
  bool _isWaterfallLayout = true;
  bool _isLoading = true;
  Environment _currentEnvironment = Environment.development;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _meteCacheTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    await _config.init();

    setState(() {
      _proxyEnabled = _config.proxyEnabled;
      _titleEnabled = _config.titleEnabled;
      _currentEnvironment = _config.environment;
      _proxyHostController.text = _config.proxyHost;
      _proxyPortController.text = _config.proxyPort.toString();
      _apiKeyController.text = _config.linkPreviewApiKey;
      _meteCacheTimeController.text = _config.metaCacheTime.toString();
      _isWaterfallLayout = _config.waterfallLayoutEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // 保存代理设置
    await _config.setProxyEnabled(_proxyEnabled);
    await _config.setProxyHost(_proxyHostController.text);
    await _config.setProxyPort(int.tryParse(_proxyPortController.text) ?? 7890);

    // 保存 Title 显示设置
    await _config.setTitleEnabled(_titleEnabled);

    // 保存 布局 显示设置
    await _config.setWaterFallLayout(_isWaterfallLayout);

    // 保存环境设置
    await _config.setEnvironment(_currentEnvironment);

    // 保存 API Key
    await _config.setLinkPreviewApiKey(_apiKeyController.text);

    // 保存 缓存时间
    await _config.setMetaCacheTime(
      int.tryParse(_meteCacheTimeController.text) ?? 10,
    );

    // 应用代理设置
    _applyProxySettings();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置已保存')));
    }
  }

  void _applyProxySettings() {
    if (_proxyEnabled) {
      HttpOverrides.global = GlobalHttpOverrides(
        "${_config.proxyHost}:${_config.proxyPort}",
        allowBadCertificates: true,
      );
    } else {
      HttpOverrides.global = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title 显示设置
          _buildSectionTitle('显示设置', theme),
          _buildTitleSettingCard(theme),
          const SizedBox(height: 24),

          // API 环境设置
          // todo 暂且不需要
          // _buildSectionTitle('API 环境', theme),
          // _buildEnvironmentCard(theme),
          // const SizedBox(height: 24),

          // 网络代理设置
          _buildSectionTitle('网络代理', theme),
          _buildProxyCard(theme),
          const SizedBox(height: 24),

          // LinkPreview API 设置
          _buildSectionTitle('LinkPreview API', theme),
          _buildApiKeyCard(theme),
          const SizedBox(height: 24),
          // 说明
          _buildInfoCard(theme),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }

  Widget _buildTitleSettingCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('布局排版', style: theme.textTheme.bodyLarge),
                  subtitle: Text(
                    _isWaterfallLayout ? '瀑布流' : '传统列表',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _isWaterfallLayout,
                  onChanged: (value) {
                    setState(() => _isWaterfallLayout = value);
                  },
                ),
                const Divider(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('显示标题字段', style: theme.textTheme.bodyLarge),
                  subtitle: Text(
                    _titleEnabled ? '笔记卡片和编辑时将显示标题' : '隐藏标题，仅保留内容',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _titleEnabled,
                  onChanged: (value) {
                    setState(() => _titleEnabled = value);
                  },
                ),
              ],
          )
      )
    );
  }

  Widget _buildEnvironmentCard(ThemeData theme) {
    // 获取当前环境的显示信息
    String getCurrentEnvDescription() {
      switch (_currentEnvironment) {
        case Environment.development:
          return 'http://localhost:8080';
        case Environment.staging:
          return 'https://staging-api.pocketmind.com';
        case Environment.production:
          return 'https://api.pocketmind.com';
      }
    }

    String getEnvLabel(Environment env) {
      switch (env) {
        case Environment.development:
          return '开发环境（本地）';
        case Environment.staging:
          return '预发布环境';
        case Environment.production:
          return '生产环境';
      }
    }

    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API 环境切换', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentEnvDescription(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 环境选择
            ...Environment.values.map((env) {
              return RadioListTile<Environment>(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  getEnvLabel(env),
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  _getEnvUrl(env),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                value: env,
                groupValue: _currentEnvironment,
                onChanged: (Environment? value) {
                  if (value != null) {
                    setState(() {
                      _currentEnvironment = value;
                    });
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getEnvUrl(Environment env) {
    switch (env) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.pocketmind.com';
      case Environment.production:
        return 'https://api.pocketmind.com';
    }
  }

  Widget _buildProxyCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 启用开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('启用代理', style: theme.textTheme.bodyLarge),
              subtitle: Text(
                _proxyEnabled ? '代理已启用' : '代理已禁用',
                style: theme.textTheme.bodySmall,
              ),
              value: _proxyEnabled,
              onChanged: (value) {
                setState(() => _proxyEnabled = value);
              },
            ),

            if (_proxyEnabled) ...[
              const Divider(height: 32),

              // 代理主机
              TextField(
                controller: _proxyHostController,
                decoration: InputDecoration(
                  labelText: '代理主机',
                  hintText: '127.0.0.1',
                  prefixIcon: const Icon(Icons.computer),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 代理端口
              TextField(
                controller: _proxyPortController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '代理端口',
                  hintText: '7890',
                  prefixIcon: const Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Key', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              '用于国外网站（X/Twitter/YouTube）链接预览',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: '输入 LinkPreview.net API Key',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 1,
            ),
            const Divider(height: 32),
            Text(
              '获取的meta元数据进行本地缓存,减少对应api的开销',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meteCacheTimeController,
              decoration: InputDecoration(
                hintText: '输入缓存的时间（天)',
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.surfaceContainerHighest,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '使用说明',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('• 代理设置', '启用代理后，国外网站（X/Twitter）的图片才能正常显示', theme),
            const SizedBox(height: 8),
            _buildInfoItem(
              '• API Key',
              '从 linkpreview.net 获取，用于国外网站链接预览',
              theme,
            ),
            const SizedBox(height: 8),
            _buildInfoItem('• 国内网站', '国内网站无需代理，自动使用直连方式', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
