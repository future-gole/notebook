import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/note.dart';
import '../../server/note_service.dart';
import '../../util/logger_service.dart';


String tag = "noteItem";
class  noteItem extends StatelessWidget{

  final Note _note;

  final NoteService _noteService;

  const noteItem(this._note,this._noteService);

  // 格式化时间
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 删除笔记
  Future<void> _deleteNote(int noteId) async {
    await _noteService.deleteNote(noteId);
    log.d(tag, 'Note deleted: $noteId');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          _note.title ?? '无标题',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              _note.content ?? '无内容',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(_note.time),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _deleteNote(_note.id);
          },
        ),
        onTap: () {
          _showEditNoteDialog(context, _note);
        },
      ),
    );
  }

  // 显示编辑笔记对话框
  void _showEditNoteDialog(BuildContext context, Note note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑笔记'),
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
                  // 更新笔记
                  note.title = title;
                  note.content = content;
                  note.time = DateTime.now();
                  await _noteService.addOrUpdateNote(title, content);
                  log.d(tag, 'Note updated: $title');
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