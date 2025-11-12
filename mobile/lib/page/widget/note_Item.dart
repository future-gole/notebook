import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/server/note_service.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'link_preview_card.dart';
import '../home/note_add_sheet.dart';
import '../home/note_detail_page.dart';
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

  // 显示笔记详情页
  void _showNoteDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: widget.note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build，让 AutomaticKeepAliveClientMixin 工作
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否为纯文本笔记
    final isTextOnly = widget.note.url == null ? true : false;

    final content = widget.note.content;

    // 使用传入的 isGridMode 参数，而不是 watch provider
    // 这样可以避免不必要的 rebuild, 和 构建参数异常

    return Container(
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
          onTap: () => _showNoteDetail(context),
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
                              content ?? "",
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
                            content ?? "",
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
                      child: (!isTextOnly)
                          ? Column(
                              children: [
                                LinkPreviewCard(
                                  url: widget.note.url!,
                                  isVertical: widget.isGridMode,
                                  hasContent:
                                      content != null && content.isNotEmpty,
                                  onTap: () => _showNoteDetail(context),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // 链接卡片下面的文字部分
                    Visibility(
                      visible: content != null && content.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 12,
                        ),
                        child: Text(
                          content ?? "",
                          style: textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
  }
}
