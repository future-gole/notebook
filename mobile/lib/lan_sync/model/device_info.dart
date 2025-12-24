import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';
part 'device_info.g.dart';

/// 设备信息
///
/// 用于设备发现和握手时交换设备信息
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    /// 设备唯一标识符 (UUID)
    required String deviceId,

    /// 设备名称（用户可读）
    required String deviceName,

    /// 设备 IP 地址
    String? ipAddress,

    /// 同步服务端口
    @Default(54322) int port,

    /// 设备平台 (android, ios, windows, etc.)
    String? platform,

    /// App 版本
    String? appVersion,

    /// 最后活跃时间
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _dateTimeFromMillis, toJson: _dateTimeToMillis)
    DateTime? lastSeen,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

DateTime? _dateTimeFromMillis(int? millis) =>
    millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;

int? _dateTimeToMillis(DateTime? date) => date?.millisecondsSinceEpoch;
