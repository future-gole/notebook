import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook/providers/note_providers.dart';
import '../../model/note.dart';
import '../../server/note_service.dart';
import '../../util/url_helper.dart';
import 'link_preview_card.dart';
import 'note_editor_sheet.dart';

String tag = "noteItem";

// 改为 StatefulWidget 以支持 AutomaticKeepAliveClientMixin
class noteItem extends ConsumerStatefulWidget {
  final Note _note;
  final bool isGridMode;

  const noteItem(
    this._note,
    NoteService noteService, {
    required this.isGridMode,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<noteItem> createState() => _noteItemState();
}

class _noteItemState extends ConsumerState<noteItem> 
    with AutomaticKeepAliveClientMixin {
  
  // 保持 widget 状态，避免滚动时被销毁重建
  @override
  bool get wantKeepAlive => true;

  // 显示编辑笔记模态框
  void _showEditNoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(note: widget._note),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build，让 AutomaticKeepAliveClientMixin 工作
    super.build(context);
    
    final hasUrl = UrlHelper.containsUrl(widget._note.content);
    final extractedUrl = hasUrl ? UrlHelper.extractUrl(widget._note.content) : null;
    final contentWithoutUrl = hasUrl
        ? UrlHelper.removeUrls(widget._note.content)
        : widget._note.content;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否为纯文本笔记
    final isTextOnly = !hasUrl;

    // 使用传入的 isGridMode 参数，而不是 watch provider
    // 这样可以避免不必要的 rebuild, 和 构建参数异常

    // 使用 Dismissible 实现滑动删除
    return Dismissible(
      key: Key(widget._note.id.toString()),
      direction: DismissDirection.endToStart,
      // 动画时长：让删除过程更平滑
      movementDuration: const Duration(milliseconds: 250),
      resizeDuration: const Duration(milliseconds: 250),
      // 使用 confirmDismiss 在动画开始前就更新 UI
      confirmDismiss: (direction) async {
        // 立即更新 UI（Optimistic UI）
        ref.read(noteByCategoryProvider.notifier).deleteNote(widget._note.id);
        // 返回 true 让 Dismissible 继续完成动画
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: widget.isGridMode
            ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          // 使用接近背景的颜色，减少删除时的视觉闪烁
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
            size: 28,
          ),
        ),
      ),
      child: Container(
        margin: widget.isGridMode
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
                                  isVertical: widget.isGridMode,
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
