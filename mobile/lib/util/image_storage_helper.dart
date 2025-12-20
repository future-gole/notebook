import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:pocketmind/api/http_client.dart';
import './logger_service.dart';

/// 图片存储服务
///
/// 负责管理本地图片的存储、路径解析。
/// 实现了"相对路径"与"绝对路径"的转换。
class ImageStorageHelper {
  static String tag = 'ImageStorageHelper';
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
    PMlog.d(tag, '图片存储根目录已初始化: $_rootDir');
  }

  /// 保存图片：将临时文件移动到我们的存储目录
  ///
  /// [sourceFile] : 原始文件（来自系统分享或相册）
  /// 返回 : 相对路径 (例如 "pocket_images/uuid.jpg")，用于存入数据库
  Future<String> saveImage(File sourceFile) async {
    final String fileName =
        '${const Uuid().v4()}${p.extension(sourceFile.path)}';
    // 统一使用正斜杠，确保跨平台数据库兼容性
    final String relativePath = '$_folderName/$fileName';
    final String destinationPath = p.join(_rootDir, _folderName, fileName);
    await sourceFile.copy(destinationPath);
    return relativePath;
  }

  /// 下载并保存网络图片
  ///
  /// [url] : 图片网络地址
  /// 返回 : 相对路径
  Future<String?> downloadAndSaveImage(String url) async {
    try {
      final String extension = p.extension(Uri.parse(url).path);
      final String fileName =
          '${const Uuid().v4()}${extension.isEmpty ? ".jpg" : extension}';
      // 统一使用正斜杠，确保跨平台数据库兼容性
      final String relativePath = '$_folderName/$fileName';
      final String destinationPath = p.join(_rootDir, _folderName, fileName);

      await HttpClient().dio.download(url, destinationPath);
      PMlog.d(tag, '图片下载成功: $url -> $relativePath');
      return relativePath;
    } catch (e) {
      PMlog.e(tag, '下载图片失败: $url, e:$e');
      return null;
    }
  }

  /// 获取完整路径：将数据库里的相对路径转换为当前设备的绝对路径
  File getFileByRelativePath(String relativePath) {
    // 兼容旧数据（可能包含反斜杠）
    final normalizedPath = relativePath.replaceAll('\\', '/');
    // 移除 folderName 前缀，因为 p.join 会处理
    final fileName = normalizedPath.replaceFirst('$_folderName/', '');
    final fullPath = p.join(_rootDir, _folderName, fileName);
    return File(fullPath);
  }

  /// 根据相对路径删除本地图片文件
  Future<void> deleteImage(String relativePath) async {
    try {
      final file = getFileByRelativePath(relativePath);
      if (await file.exists()) {
        await file.delete();
        PMlog.d(tag, '已删除本地图片: $relativePath');
      }
    } catch (e) {
      PMlog.e(tag, '删除图片失败: $relativePath, e:$e');
    }
  }

  /// 获取所有存储的图片路径（相对路径）
  Future<List<String>> getAllImagePaths() async {
    final directory = Directory(p.join(_rootDir, _folderName));
    if (!await directory.exists()) {
      return [];
    }

    final List<String> paths = [];
    await for (final entity in directory.list()) {
      if (entity is File) {
        final relativePath = p.join(_folderName, p.basename(entity.path));
        paths.add(relativePath);
      }
    }
    return paths;
  }
}
