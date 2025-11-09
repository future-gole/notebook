import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/server/note_service.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'link_preview_card.dart';
import 'note_editor_sheet.dart';
import 'package:pocketmind/util/link_preview_cache.dart';
import 'package:pocketmind/util/app_config.dart';

String tag = "noteItem";

// 改为 StatefulWidget 以支持 AutomaticKeepAliveClientMixin
class NoteItem extends ConsumerStatefulWidget {
  final NoteEntity note;
  final bool isGridMode;

  final NoteService noteService;

  const NoteItem({
    required this.note,
    required this.noteService,
    required this.isGridMode,
    super.key,
  });

  @override
  ConsumerState<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends ConsumerState<NoteItem>
    with AutomaticKeepAliveClientMixin {
  // 保持 widget 状态，避免滚动时被销毁重建
  @override
  bool get wantKeepAlive => true;

  final _config = AppConfig();
  bool _titleEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTitleSetting();
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    if (mounted) {
      setState(() {
        _titleEnabled = _config.titleEnabled;
      });
    }
  }

  // 显示编辑笔记模态框
  void _showEditNoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(note: widget.note),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build，让 AutomaticKeepAliveClientMixin 工作
    super.build(context);

    final hasUrl = UrlHelper.containsUrl(widget.note.content);
    final extractedUrl = hasUrl
        ? UrlHelper.extractUrl(widget.note.content)
        : null;
    final contentWithoutUrl = hasUrl
        ? UrlHelper.removeUrls(widget.note.content)
        : widget.note.content;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否为纯文本笔记
    final isTextOnly = !hasUrl;

    // 使用传入的 isGridMode 参数，而不是 watch provider
    // 这样可以避免不必要的 rebuild, 和 构建参数异常

    // 使用 Dismissible 实现滑动删除
    return Dismissible(
      key: Key(widget.note.id.toString()),
      direction: DismissDirection.endToStart,
      // 动画时长：让删除过程更平滑
      movementDuration: const Duration(milliseconds: 250),
      resizeDuration: const Duration(milliseconds: 250),
      // 使用 confirmDismiss 在动画开始前就更新 UI
      confirmDismiss: (direction) async {
        if (extractedUrl != null) {
          // 删除对应的链接缓存
          await LinkPreviewCache.clearCache(extractedUrl);
        }
        // 立即更新 UI
        final noteId = widget.note.id;
        if (noteId != null) {
          ref.read(noteByCategoryProvider.notifier).deleteNote(noteId);
        }
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
          child: Icon(Icons.delete_outline, color: colorScheme.error, size: 28),
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
                  // 这样它就有了"填充"的视觉效果
                  constraints: const BoxConstraints(minHeight: 80.0),

                  // 只需要水平 padding 来防止文字碰到左右边缘
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),

                  child: _titleEnabled && widget.note.title != null
                      // 启用标题且标题存在时，显示标题+内容
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题
                            Text(
                              widget.note.title!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // 分割线
                            Divider(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                            const SizedBox(height: 8),
                            // 内容
                            Text(
                              contentWithoutUrl ?? "",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                                height: 1.5,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      // 不显示标题时，居中显示内容
                      : Center(
                          child: Text(
                            contentWithoutUrl ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w300,
                              color: colorScheme.primary,
                              height: 1.7,
                            ),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    //     // // 时间信息
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
