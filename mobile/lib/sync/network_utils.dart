import 'dart:io';

import '../util/logger_service.dart';

class LocalIpInfo {
  final String ip;
  final String interfaceName;
  final String subnetMask;

  const LocalIpInfo({
    required this.ip,
    required this.interfaceName,
    this.subnetMask = LanNetworkHelper.defaultSubnetMask,
  });
}

/// LAN IP 选择和子网数学助手。
/// 过滤掉 CGNAT/公网/回环地址，以避免选择不可用的对等节点。
class LanNetworkHelper {
  static const String defaultSubnetMask = '255.255.255.0';
  static const int _maxUint32 = 0xFFFFFFFF;

  /// 选择适合 P2P 的 LAN IPv4 地址。
  /// 优先选择 Wi-Fi/热点接口，仅返回 RFC1918 地址。
  static Future<LocalIpInfo?> pickLanIPv4({
    String logTag = 'LanNetwork',
  }) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: true,
    );

    final ifaceLog = interfaces
        .map((i) => '${i.name}:${i.addresses.map((a) => a.address).join(',')}')
        .join('; ');
    PMlog.i(logTag, '网络接口: $ifaceLog');

    final candidates = <LocalIpInfo>[];
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type != InternetAddressType.IPv4) continue;
        final ip = addr.address;
        if (addr.isLoopback) continue;
        if (!isPrivateIPv4(ip)) continue;
        candidates.add(LocalIpInfo(ip: ip, interfaceName: iface.name));
      }
    }

    if (candidates.isEmpty) {
      PMlog.w(logTag, '未找到 LAN IPv4 地址（请连接 Wi-Fi 或启用热点）');
      return null;
    }

    final wifiCandidate = candidates.firstWhere(
      (c) => _looksLikeWifi(c.interfaceName),
      orElse: () => candidates.first,
    );

    PMlog.i(
      logTag,
      '已选择 LAN IP ${wifiCandidate.ip} 在 ${wifiCandidate.interfaceName} 上（掩码 $defaultSubnetMask）',
    );
    return wifiCandidate;
  }

  static bool isPrivateIPv4(String ip) {
    if (isCgnat(ip)) return false;

    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;

    if (first == 10) return true;
    if (first == 172 && second >= 16 && second <= 31) return true;
    if (first == 192 && second == 168) return true;
    return false;
  }

  /// 100.64.0.0/10 CGNAT should not be used for LAN P2P.
  static bool isCgnat(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;
    return first == 100 && second >= 64 && second <= 127;
  }

  static bool isSameSubnet(
    String ip1,
    String ip2, {
    String subnetMask = defaultSubnetMask,
  }) {
    final mask = ipv4ToInt(subnetMask);
    return (ipv4ToInt(ip1) & mask) == (ipv4ToInt(ip2) & mask);
  }

  static List<String> hostsInSubnet(
    String ip, {
    String subnetMask = defaultSubnetMask,
  }) {
    final ipInt = ipv4ToInt(ip);
    final maskInt = ipv4ToInt(subnetMask);
    final network = ipInt & maskInt;
    final broadcast = network | (_maxUint32 ^ maskInt);

    final hosts = <String>[];
    for (int addr = network + 1; addr < broadcast; addr++) {
      hosts.add(_intToIpv4(addr));
    }
    return hosts;
  }

  static int ipv4ToInt(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) {
      throw ArgumentError('无效的 IPv4: $ip');
    }

    var result = 0;
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        throw ArgumentError('无效的 IPv4 八位字节: $ip');
      }
      result = (result << 8) + value;
    }
    return result & _maxUint32;
  }

  static String _intToIpv4(int value) {
    final b1 = (value >> 24) & 0xFF;
    final b2 = (value >> 16) & 0xFF;
    final b3 = (value >> 8) & 0xFF;
    final b4 = value & 0xFF;
    return '$b1.$b2.$b3.$b4';
  }

  static bool _looksLikeWifi(String name) {
    final lower = name.toLowerCase();
    return lower.contains('wlan') ||
        lower.contains('wifi') ||
        lower.contains('wi-fi') ||
        lower.contains('wlp');
  }
}
