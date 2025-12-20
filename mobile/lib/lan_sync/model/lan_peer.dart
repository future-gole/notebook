class LanPeer {
  final String deviceId;
  final String deviceName;
  final String ip;
  final int wsPort;
  final DateTime lastSeen;

  /// True when we currently have an active channel to this peer
  /// (either inbound to our server, or an outbound WebSocket client).
  final bool connected;

  /// True if we are the side initiating the WebSocket connection.
  final bool outbound;

  const LanPeer({
    required this.deviceId,
    required this.deviceName,
    required this.ip,
    required this.wsPort,
    required this.lastSeen,
    required this.connected,
    required this.outbound,
  });

  LanPeer copyWith({
    String? deviceName,
    String? ip,
    int? wsPort,
    DateTime? lastSeen,
    bool? connected,
    bool? outbound,
  }) {
    return LanPeer(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      ip: ip ?? this.ip,
      wsPort: wsPort ?? this.wsPort,
      lastSeen: lastSeen ?? this.lastSeen,
      connected: connected ?? this.connected,
      outbound: outbound ?? this.outbound,
    );
  }
}
