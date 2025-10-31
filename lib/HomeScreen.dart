import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notebook/main.dart';
import 'package:notebook/model/note.dart';
import 'package:notebook/page/widget/nav_bar.dart';
import 'package:notebook/page/widget/note_Item.dart';
import 'package:notebook/server/note_service.dart';
import 'package:notebook/util/logger_service.dart';
import 'package:share_handler/share_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

String tag = "HomeScreen";

class _HomeScreenState extends State<HomeScreen> {
  // 获取插件单例
  final handler = ShareHandler.instance;
  final NoteService _noteService = NoteService(isar);
  String? sharedContent;

  // 用于UI展示的状态
  String? _shareText;

  // 笔记列表
  List<Note> _notes = [];
  StreamSubscription<List<Note>>? _notesSubscription;

  @override
  void initState() {
    super.initState();
    _initShareHandler();
    _loadNotes();
  }

  // 加载笔记列表
  void _loadNotes() {
    _notesSubscription = _noteService.watchAllNotes().listen((notes) {
      setState(() {
        _notes = notes;
      });
    });
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initShareHandler() async {
    // 监听：当App在后台/前台运行时，接收到新的分享
    handler.sharedMediaStream.listen((SharedMedia media) {
      log.d(tag, 'Received shared media while running');
      _handleSharedData(media);
    });

    // 获取：当App是关闭状态，通过分享第一次启动
    final media = await handler.getInitialSharedMedia();
    if (media != null) {
      log.d(tag, 'Received shared media on launch');
      _handleSharedData(media);
    }
  }

  // 统一的处理入口
  void _handleSharedData(SharedMedia media) {
    setState(() {
      // 先处理文本/URL
      if (media.content != null && media.content!.isNotEmpty) {
        _shareText = media.content;
        log.d(tag, "Detected shared text/url: $_shareText");
      }

      // 设置title
      _showAddNoteDialog(context, content: _shareText);
    });

    // 提取分享的内容，通常是URL或文本
    log.d(tag, "Detected shared content: $sharedContent");
  }

  @override
  Widget build(BuildContext context) {
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
          GlassNavBar(),
          Expanded(
            child: _notes.isEmpty
                ? Center(
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.only(top: 8, bottom: 80),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                // 确保 noteItem(note, _noteService) 返回的是一个 Widget
                return noteItem(note, _noteService);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        icon: Icon(Icons.add),
        label: Text('新建笔记'),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
    );
  }

  // 显示添加笔记对话框
  void _showAddNoteDialog(BuildContext context, {String? content}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController(text: content);

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
                if (title.isNotEmpty && content.isNotEmpty) {
                  await _noteService.addOrUpdateNote(title, content);
                  log.d(tag, 'Note added: $title');
                  Navigator.of(context).pop();

                  // 显示成功提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('笔记已保存'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
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
