import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/providers/nav_providers.dart';
import 'package:notebook/providers/note_providers.dart';
import '../../model/note.dart';
import '../../server/note_service.dart';
import '../../util/logger_service.dart';
import '../../util/url_helper.dart';
import 'link_preview_card.dart';
import 'note_editor_sheet.dart';

String tag = "noteItem";

class noteItem extends ConsumerWidget {
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

  // 显示编辑笔记模态框
  void _showEditNoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(note: _note),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUrl = UrlHelper.containsUrl(_note.content);
    final extractedUrl = hasUrl ? UrlHelper.extractUrl(_note.content) : null;
    final contentWithoutUrl = hasUrl
        ? UrlHelper.removeUrls(_note.content)
        : _note.content;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否为纯文本笔记
    final isTextOnly = !hasUrl;

    // 获取当前布局模式
    final currentLayout = ref.watch(noteLayoutProvider);
    final isGridMode = currentLayout == NoteLayout.grid;

    // 使用 Dismissible 实现滑动删除
    return Dismissible(
      key: Key(_note.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => ref.read(noteServiceProvider).deleteNote(_note.id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: isGridMode
            ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 28),
      ),
      child: Container(
        margin: isGridMode
            ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
            : const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _showEditNoteModal(context),
          borderRadius: BorderRadius.circular(16),
          child: isTextOnly
              // 1. 纯文本模式：
              ? Container(
                  // (关键!) 给卡片一个最小高度，比如 80
                  // 这样它就有了“填充”的视觉效果
                  constraints: const BoxConstraints(minHeight: 80.0),

                  // (关键!) 自动在垂直和水平方向上居中 child (Text)
                  alignment: Alignment.center,

                  // 只需要水平 padding 来防止文字碰到左右边缘
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),

                  child: Text(
                    contentWithoutUrl ?? "",
                    textAlign: TextAlign.center, // 确保多行文本也居中
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w300,
                      color: colorScheme.primary,
                      height: 1.7,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              // 链接模式
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 链接卡片部分
                    Container(
                      child: (hasUrl && extractedUrl != null)
                          ? Column(
                              children: [
                                LinkPreviewCard(
                                  url: extractedUrl,
                                  isVertical: isGridMode,
                                  hasContent:
                                      contentWithoutUrl != null &&
                                      contentWithoutUrl.isNotEmpty,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // 链接卡片下面的文字部分
                    Visibility(
                      visible:
                          contentWithoutUrl != null &&
                          contentWithoutUrl.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 12,
                        ),
                        child: Text(
                          contentWithoutUrl ?? "",
                          style: textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     // // 标题 先不用了，感觉没啥用
                    //     // Expanded(
                    //     //   child: Text(
                    //     //     _note.title ?? '无标题',
                    //     //     style: textTheme.titleMedium,
                    //     //     maxLines: 1,
                    //     //     overflow: TextOverflow.ellipsis,
                    //     //   ),
                    //     // ),
                    //     // SizedBox(width: 1),
                    //     // Container(
                    //     //   height: 16, // 尝试一个和 titleMedium 字体差不多的高度
                    //     //   width: 1.0,
                    //     //   color: Colors.white, // 你要的白色
                    //     // ),
                    //     // 时间信息
                    //     // Text(
                    //     //   _formatTime(_note.time),
                    //     //   style: textTheme.bodySmall,
                    //     // ),
                    //   ],
                  ],
                ),
        ),
      ),
    );
  }
}
