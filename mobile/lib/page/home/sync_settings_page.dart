import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/sync_service.dart';
import '../../sync/models/device_info.dart';
import '../../util/app_config.dart';
import '../widget/creative_toast.dart';

/// 同步设置页面
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  bool _isScanning = false;
  bool _isTesting = false;
  String? _testResult;
  late bool _syncAutoStart;

  @override
  void initState() {
    super.initState();
    _syncAutoStart = AppConfig().syncAutoStart;
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncServiceProvider);
    final syncNotifier = ref.read(syncServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('局域网同步')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 同步开关设置卡片
          _buildSyncSettingsCard(syncState, syncNotifier),
          const SizedBox(height: 16),

          // 本机设备信息
          _buildLocalDeviceCard(syncState, syncNotifier),
          const SizedBox(height: 16),

          // 发现的设备
          _buildDiscoveredDevicesCard(syncState, syncNotifier),
          const SizedBox(height: 16),

          // 同步状态
          _buildSyncStatusCard(syncState),

          const SizedBox(height: 16),

          // 诊断信息
          _buildDiagnosticsCard(syncState),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _isScanning || syncState.isSyncing || !syncState.isServerRunning
            ? null
            : () => _discoverAndSync(syncNotifier),
        icon: _isScanning || syncState.isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.sync),
        label: Text(
          _isScanning
              ? '扫描中...'
              : syncState.isSyncing
              ? '同步中...'
              : !syncState.isServerRunning
              ? '请先开启同步'
              : '扫描并同步',
        ),
        backgroundColor: !syncState.isServerRunning
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
    );
  }

  /// 同步设置卡片
  Widget _buildSyncSettingsCard(
    SyncServiceState state,
    SyncServiceNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '同步设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 允许其他设备同步开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('允许其他设备同步'),
              subtitle: Text(
                state.isServerRunning ? '其他设备可以发现并同步此设备' : '其他设备无法发现此设备',
                style: TextStyle(
                  color: state.isServerRunning ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              value: state.isServerRunning,
              onChanged: (value) async {
                if (value) {
                  await notifier.startServer();
                } else {
                  await notifier.stopServer();
                }
                // 服务器状态变化时，清除测试结果
                setState(() => _testResult = null);
              },
            ),
            const Divider(),
            // 启动时自动开启开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启动时自动开启同步'),
              subtitle: const Text(
                '下次打开应用时自动允许其他设备同步',
                style: TextStyle(fontSize: 12),
              ),
              value: _syncAutoStart,
              onChanged: (value) async {
                await AppConfig().setSyncAutoStart(value);
                setState(() => _syncAutoStart = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 本机设备信息卡片
  Widget _buildLocalDeviceCard(
    SyncServiceState state,
    SyncServiceNotifier notifier,
  ) {
    final device = state.localDevice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '本机设备',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: state.isServerRunning ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.isServerRunning ? '服务运行中' : '服务已停止',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (device != null) ...[
              _buildInfoRow('设备名称', device.deviceName),
              _buildInfoRow('IP 地址', device.ipAddress ?? '未知'),
              _buildInfoRow('端口', device.port.toString()),
              _buildInfoRow('设备 ID', device.deviceId.substring(0, 8) + '...'),
              const SizedBox(height: 12),
              // 测试服务器按钮
              if (state.isServerRunning)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : () => _testServer(notifier),
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(_isTesting ? '测试中...' : '测试服务器可达性'),
                  ),
                ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _testResult!.startsWith('✅')
                          ? Colors.green.withAlpha(26)
                          : Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testResult!.startsWith('✅')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
            ] else
              const Text('正在获取设备信息...'),
          ],
        ),
      ),
    );
  }

  /// 测试服务器
  Future<void> _testServer(SyncServiceNotifier notifier) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final result = await notifier.testLocalServer();
      if (mounted) {
        setState(() {
          _testResult = result ? '✅ 服务器可达，其他设备应该能发现此设备' : '❌ 服务器不可达，请检查网络设置';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ 测试失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  /// 发现的设备卡片
  Widget _buildDiscoveredDevicesCard(
    SyncServiceState state,
    SyncServiceNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.devices,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '已连接的设备',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: state.discoveredDevices.isNotEmpty
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.discoveredDevices.length} 台',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.discoveredDevices.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sync, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '实时同步已启用 - 数据变化将自动同步',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (state.discoveredDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '未发现其他设备\n点击下方按钮扫描并连接',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...state.discoveredDevices.map(
                (device) => _buildDeviceTile(device, state, notifier),
              ),
          ],
        ),
      ),
    );
  }

  /// 设备列表项
  Widget _buildDeviceTile(
    DeviceInfo device,
    SyncServiceState state,
    SyncServiceNotifier notifier,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withAlpha(50),
        child: const Icon(Icons.phone_android, color: Colors.green),
      ),
      title: Row(
        children: [
          Text(device.deviceName),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      subtitle: Text('${device.ipAddress}:${device.port} · 已连接'),
      trailing: state.isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.sync),
              tooltip: '手动同步',
              onPressed: () => _syncWithDevice(notifier, device),
            ),
    );
  }

  /// 同步状态卡片
  Widget _buildSyncStatusCard(SyncServiceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '同步状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.lastSyncTime != null)
              _buildInfoRow('上次同步', _formatDateTime(state.lastSyncTime!)),
            if (state.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.lastError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (state.lastSyncTime == null && state.lastError == null)
              const Text('尚未进行过同步', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// 诊断信息卡片
  Widget _buildDiagnosticsCard(SyncServiceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '诊断信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '如果设备无法相互发现，请检查：',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildCheckItem('两台设备连接到同一 WiFi 网络'),
            _buildCheckItem('两台设备都开启了"允许其他设备同步"'),
            _buildCheckItem('防火墙允许端口 54321 的访问'),
            _buildCheckItem('路由器未开启 AP 隔离功能'),
            const SizedBox(height: 12),
            const Text(
              '提示：\n• 企业/公共 WiFi 通常会隔离设备\n• 手机热点可能无法被其他设备发现\n• 建议使用家庭 WiFi 或专用路由器',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查项
  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 自动发现并同步
  Future<void> _discoverAndSync(SyncServiceNotifier notifier) async {
    setState(() => _isScanning = true);
    try {
      final results = await notifier.discoverAndSyncAll();

      if (!mounted) return;

      // 显示同步结果
      if (results.isEmpty) {
        CreativeToast.warning(context, title: '未发现设备', message: '局域网中未发现其他可同步设备', direction: ToastDirection.bottom);
      } else {
        final successCount = results.values.where((r) => r.success).length;
        final totalChanges = results.values
            .where((r) => r.success)
            .fold<int>(0, (sum, r) => sum + r.totalChanges);

        CreativeToast.success(
          context,
          title: '同步完成',
          message: '$successCount 台设备, $totalChanges 条变更',
          direction: ToastDirection.bottom,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  /// 与设备同步
  Future<void> _syncWithDevice(
    SyncServiceNotifier notifier,
    DeviceInfo device,
  ) async {
    if (device.ipAddress == null) return;

    final result = await notifier.syncWithDevice(
      device.ipAddress!,
      port: device.port,
    );

    if (!mounted) return;

    if (result.success) {
      CreativeToast.success(context, title: '同步成功', message: '${result.totalChanges} 条变更已同步', direction: ToastDirection.bottom);
    } else {
      CreativeToast.error(context, title: '同步失败', message: result.error ?? '未知错误', direction: ToastDirection.bottom);
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
