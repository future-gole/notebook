import '../../model/note.dart';
import '../../model/category.dart';
import '../model/sync_log.dart';
import '../model/device_info.dart';

/// 同步数据仓库接口
///
/// 定义了同步过程中所需的所有数据操作，解耦业务逻辑与底层数据库实现。
abstract class ISyncDataRepository {
  /// 获取自指定时间戳以来的所有笔记变更
  /// 用于响应远程的 sync_request
  Future<List<Note>> getNoteChanges(int sinceTimestamp);

  /// 获取自指定时间戳以来的所有分类变更
  Future<List<Category>> getCategoryChanges(int sinceTimestamp);

  /// 通过 UUID 查找笔记（用于冲突检测）
  Future<Note?> getNoteByUuid(String uuid);

  /// 通过 UUID 查找分类
  Future<Category?> getCategoryByUuid(String uuid);

  /// 通过名称查找分类（用于兼容旧数据）
  Future<Category?> getCategoryByName(String name);

  /// 保存或更新笔记
  /// 实现层需负责：根据 uuid 查找本地 id，如果存在则复用 id (Update)，不存在则新生成 id (Insert)
  Future<void> saveNote(Note note);

  /// 保存或更新分类
  Future<void> saveCategory(Category category);

  /// 监听笔记变更
  Stream<void> watchNotes();

  /// 监听分类变更
  Stream<void> watchCategories();

  /// 获取最后一次同步的时间戳 (用于断点续传)
  Future<int> getLastSyncTimestamp(String deviceId);

  /// 更新同步状态
  Future<void> updateSyncStatus(
    String deviceId,
    SyncStatus status, {
    int? timestamp,
    String? error,
    String? ip,
    String? deviceName,
  });

  /// 获取已知设备列表
  Future<List<DeviceInfo>> getKnownDevices();
}
