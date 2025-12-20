class LanIdentity {
  final String deviceId;
  final String deviceName;
  final int wsPort;

  const LanIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.wsPort,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'wsPort': wsPort,
    'v': 1,
  };

  static LanIdentity? tryFromJson(Map<String, dynamic> json) {
    final deviceId = json['deviceId'] as String?;
    final deviceName = json['deviceName'] as String?;
    final wsPort = json['wsPort'] as int?;
    if (deviceId == null || deviceName == null || wsPort == null) return null;
    return LanIdentity(
      deviceId: deviceId,
      deviceName: deviceName,
      wsPort: wsPort,
    );
  }
}
