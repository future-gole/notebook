import 'dart:convert';
import 'dart:io';
import '../model/sync_message.dart';
import '../../util/logger_service.dart';

typedef MessageHandler = void Function(SyncMessage message, WebSocket socket);

class SyncProtocolHandler {
  static const String _tag = 'SyncProtocolHandler';

  final Map<String, MessageHandler> _handlers = {};

  void registerHandler(String type, MessageHandler handler) {
    _handlers[type] = handler;
  }

  void unregisterHandler(String type) {
    _handlers.remove(type);
  }

  void handleMessage(WebSocket socket, dynamic data, {String? sourceInfo}) {
    try {
      if (data is String) {
        final json = jsonDecode(data);
        final message = SyncMessage.fromJson(json);
        _dispatch(message, socket, sourceInfo: sourceInfo);
      } else {
        PMlog.w(_tag, 'Received non-string message from $sourceInfo');
      }
    } catch (e) {
      PMlog.e(_tag, 'Error parsing message from $sourceInfo: $e');
    }
  }

  void _dispatch(SyncMessage message, WebSocket socket, {String? sourceInfo}) {
    final handler = _handlers[message.type];
    if (handler != null) {
      handler(message, socket);
    } else {
      // PMlog.d(_tag, 'No handler for message type: ${message.type} from $sourceInfo');
    }
  }

  static String serialize(SyncMessage message) {
    return jsonEncode(message.toJson());
  }

  static void send(WebSocket socket, SyncMessage message) {
    if (socket.readyState == WebSocket.open) {
      socket.add(serialize(message));
    } else {
      PMlog.w(_tag, 'Attempted to send message to closed socket');
    }
  }
}
