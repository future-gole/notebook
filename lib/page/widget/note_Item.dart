import 'package:flutter/material.dart';
import '../../model/note.dart';
import '../../server/note_service.dart';
import '../../util/logger_service.dart';
import '../../util/url_helper.dart';
import 'link_preview_card.dart';

String tag = "noteItem";

class noteItem extends StatelessWidget {
  final Note _note;
  final NoteService _noteService;

  const noteItem(this._note, this._noteService);

  // 格式化时间
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes} 分钟前';
      }
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    }
  }

  // 删除笔记
  Future<void> _deleteNote(BuildContext context, int noteId) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _noteService.deleteNote(noteId);
      log.d(tag, 'Note deleted: $noteId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = UrlHelper.containsUrl(_note.content);
    final extractedUrl = hasUrl ? UrlHelper.extractUrl(_note.content) : null;
    final contentWithoutUrl = hasUrl
        ? UrlHelper.removeUrls(_note.content)
        : _note.content;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditNoteDialog(context, _note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮行
              Row(
                children: [
                  // 标题
                  Expanded(
                    child: Text(
                      _note.title ?? '无标题',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 删除按钮
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: Colors.grey[600],
                    onPressed: () => _deleteNote(context, _note.id),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),

              // 时间信息
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(_note.time),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),

              // 如果有文本内容（去除URL后）
              if (contentWithoutUrl != null &&
                  contentWithoutUrl.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    contentWithoutUrl,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // 如果有URL，显示链接预览卡片
              if (hasUrl && extractedUrl != null) ...[
                SizedBox(height: 12),
                LinkPreviewCard(url: extractedUrl),
              ],
            ],
          ),
        ),
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
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('编辑笔记'),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
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
                  // 更新笔记
                  note.title = title;
                  note.content = content;
                  note.time = DateTime.now();
                  await _noteService.addOrUpdateNote(title, content);
                  log.d(tag, 'Note updated: $title');
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
