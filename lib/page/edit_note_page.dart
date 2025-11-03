// 路径: lib/pages/edit_note_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/providers/note_providers.dart';
import 'package:notebook/server/note_service.dart';

import 'package:notebook/services/share_background_service.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final String initialTitle;
  final String initialContent;
  final VoidCallback onDone; // 添加 onDone 回调
  final int id;

  const EditNotePage({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.onDone,
    required this.id,
  });

  @override
  ConsumerState<EditNotePage> createState() => EditNotePageState();
}
class EditNotePageState extends ConsumerState<EditNotePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _categoryController = TextEditingController(text: "");
    _tagController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onDone() async {
    final newTitle = _titleController.text;
    final newContent = _contentController.text;
    final newCategory = _categoryController.text;
    final newTag = _tagController.text;
    final editId = widget.id;

    final noteService = ref.read(noteServiceProvider);
    await noteService.addOrUpdateNote(
      id: editId,
      title: newTitle,
      content: newContent,
      category: newCategory,
      tag: newTag,
    );

    //todo 发送至后端写在这里

    // 2. 关闭整个 ShareHostActivity
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.1),
            child:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 这是编辑卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(hintText: "标题", border: InputBorder.none),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(hintText: "内容...", border: InputBorder.none),
                      minLines: 3,
                      maxLines: 6,
                    ),
                    Divider(),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(hintText: "分类", border: InputBorder.none),
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(),
                    TextField(
                      controller: _tagController,
                      decoration: InputDecoration(hintText: "标签", border: InputBorder.none),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24), // 卡片和按钮的间距

              // 这是 "Done" 按钮
              ElevatedButton(
                onPressed: _onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // 匹配 mymind 截图
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}