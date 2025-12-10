import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/util/app_config.dart';
import 'package:pocketmind/page/home/sync_settings_page.dart';
import 'dart:io';
import 'package:pocketmind/util/proxy_config.dart';
import 'package:pocketmind/data/repositories/cleanup_service.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import '../widget/creative_toast.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _config = AppConfig();
  final _apiKeyController = TextEditingController();
  final _meteCacheTimeController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();
  final _log = LogService();

  bool _proxyEnabled = false;
  bool _titleEnabled = false;
  bool _isWaterfallLayout = true;
  bool _isLoading = true;
  bool _highPrecisionNotification = false;
  int _notificationIntensity = 2;
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
      _highPrecisionNotification = _config.highPrecisionNotification;
      _notificationIntensity = _config.notificationIntensity;
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

    // 保存通知设置
    await _config.setHighPrecisionNotification(_highPrecisionNotification);
    await _config.setNotificationIntensity(_notificationIntensity);

    // 应用代理设置
    _applyProxySettings();

    if (mounted) {
      CreativeToast.success(
        context,
        title: '设置已保存',
        message: '您的设置已成功保存',
        direction: ToastDirection.bottom,
      );
    }
  }

  void _applyProxySettings() {
    if (_proxyEnabled) {
      HttpOverrides.global = GlobalHttpOverrides(
        '${_config.proxyHost}:${_config.proxyPort}',
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
        padding: EdgeInsets.all(16.r),
        children: [
          // Title 显示设置
          _buildSectionTitle('显示设置', theme),
          _buildTitleSettingCard(theme),
          SizedBox(height: 24.h),

          // 提醒设置
          _buildSectionTitle('提醒设置', theme),
          _buildNotificationCard(theme),
          SizedBox(height: 24.h),

          // 局域网同步设置
          _buildSectionTitle('数据同步', theme),
          _buildSyncSettingCard(theme),
          SizedBox(height: 24.h),

          // 存储管理
          _buildSectionTitle('存储管理', theme),
          _buildStorageCard(theme),
          SizedBox(height: 24.h),

          // API 环境设置
          // todo 暂且不需要
          // _buildSectionTitle('API 环境', theme),
          // _buildEnvironmentCard(theme),
          // const SizedBox(height: 24),

          // 网络代理设置
          _buildSectionTitle('网络代理', theme),
          _buildProxyCard(theme),
          SizedBox(height: 24.h),

          // LinkPreview API 设置
          _buildSectionTitle('LinkPreview API', theme),
          _buildApiKeyCard(theme),
          SizedBox(height: 24.h),
          // 说明
          _buildInfoCard(theme),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }

  Widget _buildTitleSettingCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            Divider(height: 10.h),
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
        ),
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('高精度提醒', style: theme.textTheme.bodyLarge),
              subtitle: Text(
                _highPrecisionNotification
                    ? '使用闹钟通道，耗电量较高但更准时'
                    : '使用省电通道，可能会有几分钟延迟',
                style: theme.textTheme.bodySmall,
              ),
              value: _highPrecisionNotification,
              onChanged: (value) {
                setState(() => _highPrecisionNotification = value);
              },
            ),
            Divider(height: 24.h),
            Text('提醒强度', style: theme.textTheme.bodyMedium),
            SizedBox(height: 12.h),
            _buildIntensityOption(
              theme,
              2,
              '强提醒',
              '弹窗 + 声音 + 震动',
              Icons.notifications_active,
            ),
            SizedBox(height: 8.h),
            _buildIntensityOption(
              theme,
              1,
              '标准',
              '声音 + 状态栏',
              Icons.notifications,
            ),
            SizedBox(height: 8.h),
            _buildIntensityOption(
              theme,
              0,
              '静音',
              '仅状态栏显示',
              Icons.notifications_off,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(Icons.sync, color: theme.colorScheme.primary),
        title: Text('局域网同步', style: theme.textTheme.bodyLarge),
        subtitle: Text('在多设备间同步笔记数据', style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SyncSettingsPage()),
          );
        },
      ),
    );
  }

  Widget _buildStorageCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                SizedBox(width: 12.w),
                Text('清理数据', style: theme.textTheme.bodyLarge),
              ],
            ),
            SizedBox(height: 16.h),
            Text('定期清理已删除的笔记和孤立的图片文件，释放存储空间', style: theme.textTheme.bodySmall),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _performCleanup,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('执行清理'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCleanup() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '确认清理',
      message: '将清理,10天前软删除的所有笔记以及图片',
      cancelText: '取消',
      confirmText: '确认',
    );

    if (confirmed != true) return;

    // 显示加载对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final isar = ref.read(isarProvider);
      final cleanupService = CleanupService(isar);
      final result = await cleanupService.performFullCleanup();

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载对话框

      // 显示结果
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清理完成'),
          content: Text(
            '清理结果：\n\n'
            '• 删除笔记：${result['notes']} 条\n'
            '• 删除图片：${result['images']} 张',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      _log.i('SettingsPage', 'Cleanup completed: $result');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载对话框

      _log.e('SettingsPage', 'Cleanup failed: $e');

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清理失败'),
          content: Text('清理过程中发生错误：\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
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
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API 环境切换', style: theme.textTheme.bodyLarge),
                      SizedBox(height: 4.h),
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
            Divider(height: 24.h),
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
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
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
              Divider(height: 32.h),

              // 代理主机
              TextField(
                controller: _proxyHostController,
                decoration: InputDecoration(
                  labelText: '代理主机',
                  hintText: '127.0.0.1',
                  prefixIcon: const Icon(Icons.computer),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 代理端口
              TextField(
                controller: _proxyPortController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '代理端口',
                  hintText: '7890',
                  prefixIcon: const Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
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
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Key', style: theme.textTheme.bodyLarge),
            SizedBox(height: 8.h),
            Text(
              '用于国外网站（X/Twitter/YouTube）链接预览',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: '输入 LinkPreview.net API Key',
                hintStyle: theme.textTheme.bodySmall,
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 1,
            ),
            Divider(height: 32.h),
            Text(
              '获取的meta元数据进行本地缓存,减少对应api的开销',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _meteCacheTimeController,
              decoration: InputDecoration(
                hintText: '输入缓存的时间（天)',
                hintStyle: theme.textTheme.bodySmall,
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.surfaceContainerHighest,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '使用说明',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildInfoItem('• 代理设置', '启用代理后，国外网站（X/Twitter）的图片才能正常显示', theme),
            SizedBox(height: 8.h),
            _buildInfoItem(
              '• API Key',
              '从 linkpreview.net 获取，用于国外网站链接预览',
              theme,
            ),
            SizedBox(height: 8.h),
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
        SizedBox(height: 4.h),
        Text(content, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildIntensityOption(
    ThemeData theme,
    int value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _notificationIntensity == value;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _notificationIntensity = value),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : theme.iconTheme.color?.withOpacity(0.7),
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.8)
                            : null,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
