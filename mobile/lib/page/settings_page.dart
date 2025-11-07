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
  bool _isLoading = true;

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
      _proxyHostController.text = _config.proxyHost;
      _proxyPortController.text = _config.proxyPort.toString();
      _apiKeyController.text = _config.linkPreviewApiKey;
      _meteCacheTimeController.text = _config.metaCacheTime.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // 保存代理设置
    await _config.setProxyEnabled(_proxyEnabled);
    await _config.setProxyHost(_proxyHostController.text);
    await _config.setProxyPort(int.tryParse(_proxyPortController.text) ?? 7890);

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
