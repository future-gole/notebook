import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import './logger_service.dart';

/// 图片存储服务
///
/// 负责管理本地图片的存储、路径解析。
/// 实现了“相对路径”与“绝对路径”的转换。
class ImageStorageHelper {
  static String tag = "ImageStorageHelper";
  // 单例模式，方便全局调用
  static final ImageStorageHelper _instance = ImageStorageHelper._internal();
  factory ImageStorageHelper() => _instance;
  ImageStorageHelper._internal();

  // 应用的文档根目录 (绝对路径)
  late String _rootDir;

  // 图片存放的子文件夹名称
  static const String _folderName = 'pocket_images';

  /// 初始化服务
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _rootDir = dir.path;

    // 确保图片目录存在
    final directory = Directory(p.join(_rootDir, _folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    PMlog.d(tag,"图片存储根目录已初始化: $_rootDir");
  }

  /// 保存图片：将临时文件移动到我们的存储目录
  ///
  /// [sourceFile] : 原始文件（来自系统分享或相册）
  /// 返回 : 相对路径 (例如 "pocket_images/uuid.jpg")，用于存入数据库
  Future<String> saveImage(File sourceFile) async {
    // 1. 生成唯一文件名，防止冲突
    final String fileName = "${const Uuid().v4()}${p.extension(sourceFile.path)}";

    // 2. 构建相对路径
    final String relativePath = p.join(_folderName, fileName);

    // 3. 构建完整的目标绝对路径
    final String destinationPath = p.join(_rootDir, relativePath);

    // 4. 复制文件 (Copy 优于 Move，因为源文件可能在缓存区会被系统清理)
    await sourceFile.copy(destinationPath);

    // 5. 返回相对路径给数据库使用
    return relativePath;
  }

  /// 获取完整路径：将数据库里的相对路径转换为当前设备的绝对路径
  File getFileByRelativePath(String relativePath) {
    // 拼接：根目录 + 相对路径
    final fullPath = p.join(_rootDir, relativePath);
    return File(fullPath);
  }

  /// 根据相对路径删除本地图片文件
  Future<void> deleteImage(String relativePath) async {
    try {
      final file = getFileByRelativePath(relativePath);
      if (await file.exists()) {
        await file.delete();
        PMlog.d(tag, "已删除本地图片: $relativePath");
      }
    } catch (e) {
      PMlog.e(tag, "删除图片失败: $relativePath,e:$e");
    }
  }

  /// 获取 pocket_images 目录下所有图片文件的相对路径
  Future<List<String>> getAllImagePaths() async {
    try {
      final directory = Directory(p.join(_rootDir, _folderName));
      if (!await directory.exists()) {
        return [];
      }

      final files = await directory.list().toList();
      final imagePaths = <String>[];

      for (final entity in files) {
        if (entity is File) {
          // 转换为相对路径
          final fileName = p.basename(entity.path);
          imagePaths.add(p.join(_folderName, fileName));
        }
      }

      return imagePaths;
    } catch (e) {
      PMlog.e(tag, "获取图片文件列表失败: $e");
      return [];
    }
  }
}