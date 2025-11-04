import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/main.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/page/widget/glass_nav_bar.dart';
import 'package:notebook/page/widget/note_Item.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/providers/note_providers.dart';
import 'package:notebook/server/note_service.dart';
import 'package:notebook/util/logger_service.dart';
final String tag = "HomeScreen";
class HomeScreen extends ConsumerWidget {

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    // 对应 Category 下的 note
    final noteByCategory = ref.watch(noteByCategoryProvider);

    final noteService = ref.watch(noteServiceProvider);
    // 获取激活的下标
    return Scaffold(
      backgroundColor: Color.fromARGB(1, 11, 1, 1),
      appBar: AppBar(
        title: Text(
          'NoteBook',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Color.fromARGB(100, 9, 156, 189),
        foregroundColor: Colors.black87,
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: GlassNavBar(),
          ),
          Expanded(
            child: noteByCategory.when(
                data: (notes){
                  if(notes.isEmpty) {
                    return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无笔记',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '点击右下角按钮添加新笔记',
                              style: TextStyle(fontSize: 14,
                                  color: Colors.grey[500]),
                            ),
                          ],
                        )
                    );
                  }
                  return ListView.builder(
                      padding: EdgeInsets.only(top: 8,bottom: 80),
                      itemCount: notes.length,
                      itemBuilder: (context,index){
                        final note = notes[index];
                        return noteItem(note, noteService);
                  });
                },
                error: (error,stack) {
                  log.e(tag, "stack: $error,stack:$stack");
                  return Center(child: Text('加载笔记失败'));
                },
                loading: () => Center(child: CircularProgressIndicator()))
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddNoteDialog(context: context,noteService : noteService,ref : ref);
        },
        icon: Icon(Icons.add),
        label: Text('新建笔记'),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
    );
  }

  // 显示添加笔记对话框
  void _showAddNoteDialog({
    required BuildContext context,
    required NoteService noteService,
    required WidgetRef ref,String? content}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController(text: content);
    final categoryController = TextEditingController(text: "home");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('添加笔记'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '标题',
                    hintText: '给你的笔记起个名字...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.title),
                  ),
                  autofocus: content == null,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: '分类',
                    hintText: '选一个分类吧',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 1,
                  autofocus: content != null,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: '内容',
                    hintText: '记录你的想法或分享的内容...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  autofocus: content != null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                final category = categoryController.text.trim();
                if (title.isNotEmpty && content.isNotEmpty) {
                  await noteService.addOrUpdateNote(title: title, content:  content,category: category);
                  // 标记
                  ref.invalidate(noteByCategoryProvider);
                  if(!context.mounted) return;
                  // 显示成功提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('笔记已保存'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('保存'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
