import 'package:isar_community/isar.dart';
import '../../model/note.dart';
import '../../util/logger_service.dart';
import '../../util/image_storage_helper.dart';

/// 数据清理服务
///
/// 负责定期清理逻辑删除的数据和孤立的图片文件
class CleanupService {
  static const String _tag = 'CleanupService';
  final Isar _isar;

  CleanupService(this._isar);

  /// 物理删除所有标记为已删除的笔记
  ///
  /// [olderThanDays] 只删除标记为删除超过指定天数的数据
  /// 默认为 30 天，设置为 0 则删除所有已标记删除的数据
  Future<int> physicallyDeleteNotes({int olderThanDays = 30}) async {
    try {
      final threshold = olderThanDays > 0
          ? DateTime.now()
                .subtract(Duration(days: olderThanDays))
                .millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch;

      int deletedCount = 0;

      await _isar.writeTxn(() async {
        // 查找所有标记为删除的笔记
        final deletedNotes = await _isar.notes
            .filter()
            .isDeletedEqualTo(true)
            .updatedAtLessThan(threshold)
            .findAll();

        PMlog.i(
          _tag,
          'Found ${deletedNotes.length} notes to physically delete',
        );

        for (final note in deletedNotes) {
          // 删除对应的图片文件（如果有）
          if (note.url != null && note.url!.startsWith('pocket_images/')) {
            try {
              await ImageStorageHelper().deleteImage(note.url!);
              PMlog.d(_tag, 'Deleted image: ${note.url}');
            } catch (e) {
              PMlog.w(_tag, 'Failed to delete image ${note.url}: $e');
            }
          }

          // 物理删除笔记
          if (note.id != null) {
            await _isar.notes.delete(note.id!);
            deletedCount++;
          }
        }
      });

      PMlog.i(_tag, 'Physically deleted $deletedCount notes');
      return deletedCount;
    } catch (e) {
      PMlog.e(_tag, 'Failed to physically delete notes: $e');
      rethrow;
    }
  }

  /// 清理孤立的图片文件
  ///
  /// 查找 pocket_images 目录中不被任何笔记引用的图片文件并删除
  Future<int> cleanupOrphanedImages() async {
    try {
      // 获取所有笔记的图片路径
      final allNotes = await _isar.notes.where().findAll();
      final referencedImages = allNotes
          .where(
            (note) =>
                note.url != null && note.url!.startsWith('pocket_images/'),
          )
          .map((note) => note.url!)
          .toSet();

      PMlog.d(
        _tag,
        'Found ${referencedImages.length} images referenced by notes',
      );

      // 扫描 pocket_images 目录，删除未被引用的图片
      final allImagePaths = await ImageStorageHelper().getAllImagePaths();
      PMlog.d(_tag, 'Found ${allImagePaths.length} total images in storage');

      int deletedCount = 0;
      for (final imagePath in allImagePaths) {
        if (!referencedImages.contains(imagePath)) {
          try {
            await ImageStorageHelper().deleteImage(imagePath);
            deletedCount++;
            PMlog.d(_tag, 'Deleted orphaned image: $imagePath');
          } catch (e) {
            PMlog.w(_tag, 'Failed to delete orphaned image $imagePath: $e');
          }
        }
      }

      PMlog.i(_tag, 'Cleaned up $deletedCount orphaned images');
      return deletedCount;
    } catch (e) {
      PMlog.e(_tag, 'Failed to cleanup orphaned images: $e');
      rethrow;
    }
  }

  /// 执行完整的清理流程
  Future<Map<String, int>> performFullCleanup({int olderThanDays = 10}) async {
    PMlog.i(_tag, 'Starting full cleanup (older than $olderThanDays days)...');

    final deletedNotes = await physicallyDeleteNotes(
      olderThanDays: olderThanDays,
    );
    final deletedImages = await cleanupOrphanedImages();

    PMlog.i(
      _tag,
      'Full cleanup completed: $deletedNotes notes, $deletedImages orphaned images',
    );

    return {'notes': deletedNotes, 'images': deletedImages};
  }
}
