import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_message.freezed.dart';
part 'sync_message.g.dart';

@freezed
abstract class SyncMessage with _$SyncMessage {
  const factory SyncMessage({
    required String type,
    Map<String, dynamic>? data,
    @Default(0) int timestamp,
  }) = _SyncMessage;

  factory SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);
}

class SyncMessageType {
  static const String hello = 'hello'; // 握手
  static const String deviceInfo = 'device_info'; // 设备信息
  static const String dataChanged = 'data_changed'; // 数据变化通知
  static const String syncRequest = 'sync_request'; // 请求同步
  static const String syncResponse = 'sync_response'; // 同步响应
  static const String imageRequest = 'image_request'; // 请求图片
  static const String imageData = 'image_data'; // 图片数据
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String serverShutdown = 'server_shutdown'; // 服务器即将关闭
  static const String discover = 'discover'; // 设备发现请求
  static const String discoverResponse = 'discover_response'; // 设备发现响应
}
