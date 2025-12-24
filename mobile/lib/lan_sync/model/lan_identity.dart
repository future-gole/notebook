import 'package:freezed_annotation/freezed_annotation.dart';

part 'lan_identity.freezed.dart';
part 'lan_identity.g.dart';

@freezed
abstract class LanIdentity with _$LanIdentity {
  const factory LanIdentity({
    required String deviceId,
    required String deviceName,
    required int wsPort,
    @Default(1) int v,
  }) = _LanIdentity;

  factory LanIdentity.fromJson(Map<String, dynamic> json) =>
      _$LanIdentityFromJson(json);

  static LanIdentity? tryFromJson(Map<String, dynamic> json) {
    try {
      return LanIdentity.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
