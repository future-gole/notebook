import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pocketmind/util/image_storage_helper.dart';

class LocalImageWidget extends StatelessWidget {
  final String relativePath;

  const LocalImageWidget({
    super.key,
    required this.relativePath
  });

  @override
  Widget build(BuildContext context) {
    // 1. 从服务中获取真实的 File 对象
    final imageFile = ImageStorageHelper().getFileByRelativePath(relativePath);

    return FutureBuilder<bool>(
      // 简单的检查文件是否存在，避免红屏报错
      future: imageFile.exists(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
          );
        } else {
          // 文件不存在 (可能同步还未完成，或者被误删)
          return Container(
            color: Colors.grey[200],
            child: const Center(child: Text("图片加载中或丢失")),
          );
        }
      },
    );
  }
}