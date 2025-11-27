/// 设备信息
/// 
/// 用于设备发现和握手时交换设备信息
class DeviceInfo {
  /// 设备唯一标识符 (UUID)
  final String deviceId;

  /// 设备名称（用户可读）
  final String deviceName;

  /// 设备 IP 地址
  final String? ipAddress;

  /// 同步服务端口
  final int port;

  /// 设备平台 (android, ios, windows, etc.)
  final String? platform;

  /// App 版本
  final String? appVersion;

  /// 最后活跃时间
  final DateTime? lastSeen;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    this.ipAddress,
    this.port = 54321,
    this.platform,
    this.appVersion,
    this.lastSeen,
  });

  /// 从 JSON 创建设备信息
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int? ?? 54321,
      platform: json['platform'] as String?,
      appVersion: json['appVersion'] as String?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'port': port,
      'platform': platform,
      'appVersion': appVersion,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, deviceName: $deviceName, ip: $ipAddress:$port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;
}
