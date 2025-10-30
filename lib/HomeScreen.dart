import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notebook/model/note.dart';
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
  final NoteService _noteService = NoteService();
  SharedMedia? _sharedMedia; // 用于存储分享过来的媒体对象
  String? sharedContent;

  // 用于UI展示的状态
  String? _shareText;
  List<ShareAttachment>? _shareAttachment;
  
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
      log.d(tag,'Received shared media while running');
      _handleSharedData(media);
    });

    // 获取：当App是关闭状态，通过分享第一次启动
    final media = await handler.getInitialSharedMedia();
    if (media != null) {
      log.d(tag,'Received shared media on launch');
      _handleSharedData(media);
    }
  }

  // 统一的处理入口
  void _handleSharedData(SharedMedia media) {
    setState(() {
      _sharedMedia = media;

      // 先处理文本/URL
      if(media.content != null && media.content!.isNotEmpty){
        _shareText = media.content;
        log.d(tag, "Detected shared text/url: $_shareText");
      }
      if (media.attachments != null && media.attachments!.isNotEmpty){
        _shareAttachment = media.attachments!.map((e) {
          return ShareAttachment(
              path: e!.path,
              type: e.type,
          );
        }).toList();
      }

      // 设置title
      _showAddNoteDialog(context,content: _shareText);
    });

    // 提取分享的内容，通常是URL或文本
    log.d(tag,"Detected shared content: $sharedContent");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('noteBook'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _notes.isEmpty
              ? Center(
                  child: Text(
                    '暂无笔记',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return noteItem(note,_noteService);
                  }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: '添加笔记',
      ),
    );
  }

  // 显示添加笔记对话框
  void _showAddNoteDialog(BuildContext context,{String? content}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('添加笔记'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
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
                }
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }
}


class ShareAttachment {
  final String path;
  final SharedAttachmentType type;

  // 构造函数
  ShareAttachment({
    required this.path,
    required this.type,
  });
}