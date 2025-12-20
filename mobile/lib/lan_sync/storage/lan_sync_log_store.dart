import 'package:shared_preferences/shared_preferences.dart';

class LanSyncLogStore {
  static const String _prefix = 'lan_sync_last_sync_';

  Future<int> getLastSync(String peerDeviceId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$peerDeviceId') ?? 0;
  }

  Future<void> setLastSync(String peerDeviceId, int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$peerDeviceId', timestamp);
  }

  Future<void> clearLastSync(String peerDeviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$peerDeviceId');
  }
}
